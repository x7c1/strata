#!/usr/bin/env bash
# Stop hook: fetch rate-limit utilization via the OAuth API and append to usage.jsonl.
#
# Called on every Stop event, but skips if less than INTERVAL seconds have
# elapsed since the last API call. This is best-effort data collection;
# failures exit silently with 0.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=platform.sh
source "$SCRIPT_DIR/platform.sh"

LOG_DIR="${HOME}/.claude/token-logs"
LOG_FILE="${LOG_DIR}/usage.jsonl"
LAST_CALL_FILE="${LOG_DIR}/.last-api-call"
INTERVAL=120  # 2 minutes
MAX_LINES=5000  # rotation threshold

mkdir -p "$LOG_DIR"

# --- Cooldown check ---
NOW=$(date +%s)
if [ -f "$LAST_CALL_FILE" ]; then
  LAST=$(cat "$LAST_CALL_FILE")
  ELAPSED=$((NOW - LAST))
  if [ "$ELAPSED" -lt "$INTERVAL" ]; then
    exit 0
  fi
fi

# --- Retrieve OAuth token ---
TOKEN=$(get_oauth_token)
if [ -z "$TOKEN" ]; then
  exit 0
fi

# --- Call the usage API ---
RESP=$(curl -s --max-time 5 \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "anthropic-beta: oauth-2025-04-20" \
  "https://api.anthropic.com/api/oauth/usage")

if [ -z "$RESP" ]; then
  exit 0
fi

# Verify the response is valid JSON
echo "$RESP" | jq empty 2>/dev/null || exit 0

# --- Read hook input from stdin ---
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
PROJECT=$(basename "$CWD" 2>/dev/null || echo "")

# --- Append to log ---
FIVE_UTIL=$(echo "$RESP" | jq '.five_hour.utilization // null')
FIVE_RESET=$(echo "$RESP" | jq -r '.five_hour.resets_at // empty')
SEVEN_UTIL=$(echo "$RESP" | jq '.seven_day.utilization // null')
SEVEN_RESET=$(echo "$RESP" | jq -r '.seven_day.resets_at // empty')

jq -n -c \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg sid "$SESSION_ID" \
  --arg project "$PROJECT" \
  --argjson five_hour_util "$FIVE_UTIL" \
  --arg five_hour_resets "$FIVE_RESET" \
  --argjson seven_day_util "$SEVEN_UTIL" \
  --arg seven_day_resets "$SEVEN_RESET" \
  '{
    timestamp: $ts,
    session_id: $sid,
    project: $project,
    five_hour: { utilization: $five_hour_util, resets_at: $five_hour_resets },
    seven_day: { utilization: $seven_day_util, resets_at: $seven_day_resets }
  }' >> "$LOG_FILE"

# --- Rotation ---
# statusline.sh only reads the last line, so older entries can be trimmed.
LINE_COUNT=$(wc -l < "$LOG_FILE")
if [ "$LINE_COUNT" -gt "$MAX_LINES" ]; then
  KEEP=$((MAX_LINES / 2))
  tail -n "$KEEP" "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

# Record the timestamp of this API call
echo "$NOW" > "$LAST_CALL_FILE"

exit 0
