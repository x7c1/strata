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

# ANSI colors
RST='\033[0m'
DIM='\033[2m'
PURPLE='\033[35m'
RED='\033[31m'
TEAL='\033[36m'

main() {
  local input
  input=$(cat)

  local model ctx cwd project_dir branch display_path
  model=$(echo "$input" | jq -r '.model.display_name // "?"')
  ctx=$(printf "%.1f" "$(echo "$input" | jq -r '.context_window.used_percentage // 0')")
  cwd=$(echo "$input" | jq -r '.workspace.current_dir // ""')
  project_dir=$(echo "$input" | jq -r '.workspace.project_dir // ""')
  branch=$(git -C "$project_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  display_path="${cwd/$HOME/\~}"

  local cols
  cols=$(tput cols 2>/dev/null || echo 80)

  local usage_file="${HOME}/.claude/token-logs/usage.jsonl"
  local f5 s7 f5r s7r
  {
    read -r f5
    read -r s7
    read -r f5r
    read -r s7r
  } < <(load_usage "$usage_file")

  render "$display_path" "$model" "$ctx" "$branch" "$f5" "$s7" "$f5r" "$s7r" "$cols"
}

# Render the status line.
# All data is passed as arguments; this function produces no side effects
# beyond writing to stdout.
#
# Usage: render <display_path> <model> <ctx> <branch> <f5> <s7> <f5r> <s7r> <cols>
render() {
  local display_path="$1" model="$2" ctx="$3" branch="$4"
  local f5="$5" s7="$6" f5r="$7" s7r="$8"
  local cols="${9:-80}"

  # Reset utilization to 0.0 if the reset time has already passed
  f5=$(effective_utilization "$f5" "$f5r")
  s7=$(effective_utilization "$s7" "$s7r")

  local model_label="[${model}]"

  # Line 1: path (left) | context + model (right)
  local l1="${DIM}${display_path}${RST}"
  local r1="${TEAL}ctx${RST} $(bar "$ctx" "$TEAL") $(printf "${TEAL}%5s%%${RST}" "$ctx") $(printf "${DIM}%12s${RST}" "$model_label")"
  lr "$l1" "$r1" "$cols"

  # Line 2: spacer (left) | 5h usage (right)
  local l2="${DIM} ${RST}"
  local r2=""
  if [ -n "$f5" ]; then
    local f5_bar="$f5"; [ "$f5" = "?" ] && f5_bar="0"
    r2="${PURPLE}5h${RST} $(bar "$f5_bar" "$PURPLE") $(printf "${PURPLE}%5s%%${RST}" "$f5") ${DIM}reset $(remaining "$f5r")${RST}"
  fi
  lr "$l2" "$r2" "$cols"

  # Line 3: branch (left) | 7d usage (right)
  local l3=""
  [ -n "$branch" ] && l3="${branch}"
  local r3=""
  if [ -n "$s7" ]; then
    local s7_bar="$s7"; [ "$s7" = "?" ] && s7_bar="0"
    r3="${RED}7d${RST} $(bar "$s7_bar" "$RED") $(printf "${RED}%5s%%${RST}" "$s7") ${DIM}reset $(remaining "$s7r")${RST}"
  fi
  lr "$l3" "$r3" "$cols"
}

# Load usage data from the last line of usage.jsonl.
# Outputs four lines: f5 s7 f5r s7r (empty lines when no data).
load_usage() {
  local usage_file="$1"
  local last=""
  if [ -f "$usage_file" ]; then
    last=$(tail -1 "$usage_file")
  fi

  if [ -z "$last" ]; then
    printf '?\n?\n\n\n'
    return
  fi

  local f5 s7 f5r s7r
  f5=$(printf "%.1f" "$(echo "$last" | jq -r '.five_hour.utilization // 0')")
  s7=$(printf "%.1f" "$(echo "$last" | jq -r '.seven_day.utilization // 0')")
  f5r=$(echo "$last" | jq -r '.five_hour.resets_at // empty')
  s7r=$(echo "$last" | jq -r '.seven_day.resets_at // empty')
  printf '%s\n%s\n%s\n%s\n' "$f5" "$s7" "$f5r" "$s7r"
}

# Return visible width (strip ANSI escapes)
vlen() {
  printf '%b' "$1" | sed $'s/\033\[[0-9;]*m//g' | LC_ALL=C.UTF-8 wc -m 2>/dev/null | tr -d ' '
}

# Print a left-right aligned line
lr() {
  local left="$1" right="$2" cols="$3"
  local lw=0 rw=0
  [ -n "$left" ] && lw=$(vlen "$left")
  [ -n "$right" ] && rw=$(vlen "$right")
  local pad=$((cols - lw - rw))
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

# Return utilization, or "0.0" if the reset time has already passed.
effective_utilization() {
  local util="$1" reset_at="$2"
  if [ -z "$reset_at" ] || [ "$util" = "?" ]; then
    echo "$util"
    return
  fi
  local reset_epoch
  reset_epoch=$(parse_iso_date "$reset_at")
  if [ -z "$reset_epoch" ]; then
    echo "$util"
    return
  fi
  local now
  now=$(date +%s)
  if [ "$now" -ge "$reset_epoch" ]; then
    echo "0.0"
  else
    echo "$util"
  fi
}

# Calculate remaining time until reset
remaining() {
  local reset_at=$1
  if [ -z "$reset_at" ]; then printf "%6s" "?"; return; fi

  local reset_epoch
  reset_epoch=$(parse_iso_date "$reset_at")
  if [ -z "$reset_epoch" ]; then printf "%6s" "?"; return; fi

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

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main
fi
