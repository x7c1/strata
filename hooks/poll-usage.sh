#!/bin/bash
# Poll Claude Code's /status Usage tab via tmux and write rate-limit data
# to ~/.claude/token-logs/usage.jsonl in the format statusline.sh expects.
#
# Usage:
#   ./poll-usage.sh           # continuous polling (default)
#   ./poll-usage.sh --once    # single capture then exit
#
# Prerequisites: tmux, jq

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=platform.sh
source "$SCRIPT_DIR/platform.sh"

SESSION_NAME="claude-status-poll"
MAX_LINES=5000
ACTIVE_THRESHOLD_MIN=2
POLL_SESSION_FILE=""

# Resolve the log directory: detect Docker container's .claude mount if available,
# otherwise fall back to the host's ~/.claude/token-logs.
resolve_log_dir() {
  if [ -n "${USAGE_LOG_DIR:-}" ]; then
    echo "$USAGE_LOG_DIR"
    return
  fi
  local container_claude_dir
  container_claude_dir=$(docker ps -q 2>/dev/null | while read -r id; do
    docker inspect "$id" --format '{{range .Mounts}}{{if eq .Destination "/home/developer/.claude"}}{{.Source}}{{end}}{{end}}' 2>/dev/null
  done | head -1)
  if [ -n "$container_claude_dir" ]; then
    echo "${container_claude_dir}/token-logs"
  else
    echo "${HOME}/.claude/token-logs"
  fi
}

LOG_DIR="$(resolve_log_dir)"
LOG_FILE="${LOG_DIR}/usage.jsonl"
RAW_DIR="${LOG_DIR}/poll-raw"
RAW_LOG="${RAW_DIR}/usage-$(date '+%Y-%m-%d').log"

main() {
  local once=false
  if [[ "${1:-}" == "--once" ]]; then
    once=true
  fi

  mkdir -p "$LOG_DIR" "$RAW_DIR"

  trap cleanup SIGINT SIGTERM

  # Start tmux session with Claude Code (kill stale session if exists)
  if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux kill-session -t "$SESSION_NAME"
    echo "Killed stale session '${SESSION_NAME}'"
  fi

  tmux new-session -d -s "$SESSION_NAME" 'claude'
  echo "Started Claude Code in tmux session '${SESSION_NAME}'"
  echo "Waiting for Claude Code to initialize..."
  wait_for_stable "$SESSION_NAME" 60 || true

  echo "Polling started. Logging to ${LOG_FILE}"
  echo ""

  # Identify the polling session's JSONL file via Session ID from /status
  POLL_SESSION_FILE=$(detect_poll_session_file)
  echo "Poll session file: ${POLL_SESSION_FILE:-(not detected)}"

  # Initial capture
  capture_usage

  if $once; then
    echo "Single capture complete."
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    return
  fi

  echo "Press Ctrl+C to stop polling."
  echo ""

  while true; do
    interval=$(( RANDOM % 61 + 60 ))
    sleep "$interval"
    if is_claude_active; then
      capture_usage
    else
      echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] No active session, skipping"
    fi
  done
}

cleanup() {
  echo ""
  echo "Polling stopped. tmux session '${SESSION_NAME}' is still running."
  echo "  Attach:  tmux attach -t ${SESSION_NAME}"
  echo "  Kill:    tmux kill-session -t ${SESSION_NAME}"
  exit 0
}

# Discover .claude/projects directories from host and all running containers
find_claude_project_dirs() {
  echo ~/.claude/projects
  docker ps -q 2>/dev/null | while read -r id; do
    docker inspect "$id" --format '{{range .Mounts}}{{if eq .Destination "/home/developer/.claude"}}{{.Source}}/projects{{end}}{{end}}' 2>/dev/null
  done
}

# Check if any Claude Code session (other than the polling one) is actively being used
is_claude_active() {
  local dirs
  dirs=$(find_claude_project_dirs)
  local files
  files=$(echo "$dirs" | xargs -I{} find {} -name '*.jsonl' -mmin "-${ACTIVE_THRESHOLD_MIN}" 2>/dev/null)
  if [[ -n "$POLL_SESSION_FILE" ]]; then
    files=$(echo "$files" | grep -v -F "$POLL_SESSION_FILE")
  fi
  echo "$files" | grep -q .
}

# Wait until pane content stabilizes (no change for ~0.9s)
wait_for_stable() {
  local target=$1
  local max_wait=${2:-30}
  local prev="" curr="" count=0 elapsed=0

  while [[ $count -lt 3 ]]; do
    if [[ $elapsed -ge $max_wait ]]; then
      echo "[WARN] Timed out waiting for stable output after ${max_wait}s" >&2
      return 1
    fi
    curr=$(tmux capture-pane -t "$target" -p)
    if [[ "$curr" == "$prev" ]]; then
      ((count++))
    else
      count=0
    fi
    prev="$curr"
    sleep 0.3
    elapsed=$(( elapsed + 1 ))
  done
}

# Wait for Usage tab data to load (not just "Loading usage data...")
wait_for_usage_data() {
  local max_wait=${1:-10}
  local elapsed=0
  while [[ $elapsed -lt $max_wait ]]; do
    local content
    content=$(tmux capture-pane -t "$SESSION_NAME" -p -S -30)
    if echo "$content" | grep -q '% used'; then
      return 0
    fi
    sleep 0.5
    elapsed=$(( elapsed + 1 ))
  done
  return 1
}

# Open /status, read Session ID from Status tab, close dialog
detect_poll_session_file() {
  tmux send-keys -t "$SESSION_NAME" '/status'
  wait_for_stable "$SESSION_NAME" || true
  tmux send-keys -t "$SESSION_NAME" Enter
  wait_for_stable "$SESSION_NAME" || true

  local output session_id
  output=$(tmux capture-pane -t "$SESSION_NAME" -p -S -30)
  session_id=$(echo "$output" | grep -oP 'Session ID: \K[a-f0-9-]+')

  tmux send-keys -t "$SESSION_NAME" Escape
  wait_for_stable "$SESSION_NAME" || true

  if [[ -n "$session_id" ]]; then
    local dirs
    dirs=$(find_claude_project_dirs)
    echo "$dirs" | xargs -I{} find {} -name "${session_id}.jsonl" 2>/dev/null | head -1
  fi
}

# Capture usage from /status dialog and write statusline.sh-compatible JSONL
capture_usage() {
  # Open /status dialog
  tmux send-keys -t "$SESSION_NAME" '/status'
  wait_for_stable "$SESSION_NAME" || true
  tmux send-keys -t "$SESSION_NAME" Enter
  wait_for_stable "$SESSION_NAME" || true

  # Navigate to Usage tab (Status -> Config -> Usage)
  tmux send-keys -t "$SESSION_NAME" Tab
  wait_for_stable "$SESSION_NAME" || true
  tmux send-keys -t "$SESSION_NAME" Tab
  wait_for_stable "$SESSION_NAME" || true

  # Wait for usage data to actually load
  if ! wait_for_usage_data 10; then
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] Usage data not loaded, skipping"
    tmux send-keys -t "$SESSION_NAME" Escape
    return
  fi

  local timestamp
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
  local output
  output=$(tmux capture-pane -t "$SESSION_NAME" -p -S -30)

  # Save raw log
  {
    echo "=== ${timestamp} ==="
    echo "$output"
    echo ""
  } >> "$RAW_LOG"

  # Parse usage data
  local session_pct session_reset week_pct week_reset
  session_pct=$(echo "$output" | grep -A1 'Current session' | grep -oP '\d+(?=% used)' || echo "")
  session_reset=$(echo "$output" | grep -A2 'Current session' | grep -oP 'Resets .+ \(.+\)' || echo "")
  week_pct=$(echo "$output" | grep -A1 'Current week (all models)' | grep -oP '\d+(?=% used)' || echo "")
  week_reset=$(echo "$output" | grep -A2 'Current week (all models)' | grep -oP 'Resets .+ \(.+\)' || echo "")

  # Skip if no data parsed
  if [[ -z "$session_pct" ]] && [[ -z "$week_pct" ]]; then
    echo "[${timestamp}] Parse failed, skipping"
    tmux send-keys -t "$SESSION_NAME" Escape
    return
  fi

  # Convert reset times to ISO 8601 UTC
  local session_reset_iso week_reset_iso
  session_reset_iso=$(parse_human_reset_time "$session_reset")
  week_reset_iso=$(parse_human_reset_time "$week_reset")

  # Write statusline.sh-compatible JSONL
  jq -n -c \
    --arg ts "$timestamp" \
    --argjson f5_util "${session_pct:-0}" \
    --arg f5_reset "${session_reset_iso}" \
    --argjson s7_util "${week_pct:-0}" \
    --arg s7_reset "${week_reset_iso}" \
    '{
      timestamp: $ts,
      five_hour: { utilization: $f5_util, resets_at: $f5_reset },
      seven_day: { utilization: $s7_util, resets_at: $s7_reset }
    }' >> "$LOG_FILE"

  echo "[${timestamp}] session=${session_pct:-?}% (reset ${session_reset_iso:-?}) week=${week_pct:-?}% (reset ${week_reset_iso:-?})"

  # Rotate log if needed
  if [[ -f "$LOG_FILE" ]]; then
    local line_count
    line_count=$(wc -l < "$LOG_FILE")
    if [[ "$line_count" -gt "$MAX_LINES" ]]; then
      local keep=$((MAX_LINES / 2))
      tail -n "$keep" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
    fi
  fi

  # Close the status dialog
  tmux send-keys -t "$SESSION_NAME" Escape
}

main "$@"
