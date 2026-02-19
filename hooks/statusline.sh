#!/usr/bin/env bash
# statusLine script: display branch, context window, and rate-limit usage.
#
# This script cannot be distributed via hooks.json.
# Add the following to settings.json for manual setup:
#
#   {
#     "statusLine": {
#       "type": "command",
#       "command": "<path to this script>"
#     }
#   }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=platform.sh
source "$SCRIPT_DIR/platform.sh"

INPUT=$(cat)

MODEL=$(echo "$INPUT" | jq -r '.model.display_name // "?"')
CTX=$(printf "%.1f" "$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0')")
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // ""')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.workspace.project_dir // ""')
BRANCH=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

# Display path relative to home
DISPLAY_PATH="${CWD/$HOME/\~}"

# ANSI colors
RST='\033[0m'
DIM='\033[2m'
PURPLE='\033[35m'
RED='\033[31m'
TEAL='\033[36m'

# Terminal width (fallback: 80)
COLS=$(tput cols 2>/dev/null || echo 80)

# Return visible width (strip ANSI escapes)
vlen() {
  printf '%b' "$1" | sed $'s/\033\[[0-9;]*m//g' | LC_ALL=C.UTF-8 wc -m 2>/dev/null | tr -d ' '
}

# Print a left-right aligned line
lr() {
  local left="$1" right="$2"
  local lw=0 rw=0
  [ -n "$left" ] && lw=$(vlen "$left")
  [ -n "$right" ] && rw=$(vlen "$right")
  local pad=$((COLS - lw - rw))
  [ "$pad" -lt 1 ] && pad=1
  printf '%b%*s%b\n' "$left" "$pad" "" "$right"
}

# Generate a colored progress bar (width 10)
bar() {
  local val=${1%.*}
  val=${val:-0}
  local color=$2
  local filled=$((val / 10))
  [ "$val" -gt 0 ] && [ "$filled" -eq 0 ] && filled=1
  local empty=$((10 - filled))
  printf "${DIM}▕${RST}"
  [ "$filled" -gt 0 ] && printf "${color}%0.s█${RST}" $(seq 1 $filled)
  [ "$empty" -gt 0 ] && printf "${DIM}%0.s░${RST}" $(seq 1 $empty)
  printf "${DIM}▏${RST}"
}

# Calculate remaining time until reset
remaining() {
  local reset_at=$1
  if [ -z "$reset_at" ]; then echo "?"; return; fi

  local reset_epoch
  reset_epoch=$(parse_iso_date "$reset_at")
  if [ -z "$reset_epoch" ]; then echo "?"; return; fi

  local now
  now=$(date +%s)
  local diff=$((reset_epoch - now))
  if [ "$diff" -le 0 ]; then printf "%6s" "now"; return; fi

  local hours=$((diff / 3600))
  local mins=$(( (diff % 3600) / 60 ))
  if [ "$hours" -gt 0 ]; then
    printf "%6s" "$(printf "%dh%02dm" "$hours" "$mins")"
  else
    printf "%6s" "$(printf "%dm" "$mins")"
  fi
}

# --- Output ---
USAGE_FILE="${HOME}/.claude/token-logs/usage.jsonl"
LAST=""
if [ -f "$USAGE_FILE" ]; then
  LAST=$(tail -1 "$USAGE_FILE")
fi

F5=$(printf "%.1f" "$(echo "$LAST" | jq -r '.five_hour.utilization // 0' 2>/dev/null)")
S7=$(printf "%.1f" "$(echo "$LAST" | jq -r '.seven_day.utilization // 0' 2>/dev/null)")
F5R=$(echo "$LAST" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
S7R=$(echo "$LAST" | jq -r '.seven_day.resets_at // empty' 2>/dev/null)

# Line 1: path (left) | context (right)
L1="${DIM}${DISPLAY_PATH}${RST}"
MODEL_LABEL="[${MODEL}]"
R1="${TEAL}ctx${RST} $(bar "$CTX" "$TEAL") $(printf "${TEAL}%5s%%${RST}" "$CTX") $(printf "${DIM}%12s${RST}" "$MODEL_LABEL")"
lr "$L1" "$R1"

# Line 2: (spacer) | 5h usage (right)
L2="${DIM} ${RST}"
R2=""
[ -n "$F5" ] && [ "$F5" != "?" ] && R2="${PURPLE}5h${RST} $(bar "$F5" "$PURPLE") $(printf "${PURPLE}%5s%%${RST}" "$F5") ${DIM}reset $(remaining "$F5R")${RST}"
lr "$L2" "$R2"

# Line 3: branch (left) | 7d usage (right)
L3=""
[ -n "$BRANCH" ] && L3="${BRANCH}"
R3=""
[ -n "$S7" ] && [ "$S7" != "?" ] && R3="${RED}7d${RST} $(bar "$S7" "$RED") $(printf "${RED}%5s%%${RST}" "$S7") ${DIM}reset $(remaining "$S7R")${RST}"
lr "$L3" "$R3"
