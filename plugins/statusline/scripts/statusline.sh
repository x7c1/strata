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

  local f5 s7 f5r s7r
  f5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
  s7=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
  f5r=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
  s7r=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

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

  # Line 1: context bar (left), path (right)
  local l1="$(printf "${TEAL}%3s${RST}" "ctx")$(bar "$ctx" "$TEAL")$(printf "${TEAL}%6s${RST}" "$(printf "%04.1f%%" "$ctx")")"
  printf '%b%*s  %b\n' "$l1" 9 "" "${display_path}"

  # Width of the left section: label(3) + bar(12) + pct(6) + " ↻ "(3) + time(6) = 30
  local left_width=30

  # Line 2: 5h usage + reset (left), branch (right)
  local l2=""
  if [ -n "$f5" ]; then
    local f5_pct
    f5_pct=$(printf "%04.1f%%" "$f5")
    l2="$(printf "${PURPLE}%3s${RST}" "5h")$(bar "$f5" "$PURPLE")$(printf "${PURPLE}%6s${RST}" "$f5_pct") ${DIM}↻ $(remaining "$f5r")${RST}"
  else
    l2="$(printf "${DIM}%3s${RST}" "5h")$(bar "0" "$DIM")$(printf "${DIM}%6s${RST}" "?%") ${DIM}↻ $(remaining "")${RST}"
  fi
  local r2=""
  [ -n "$branch" ] && r2="${branch}"
  printf '%b  %b\n' "$l2" "$r2"

  # Line 3: 7d usage + reset (left), model (right)
  local l3=""
  if [ -n "$s7" ]; then
    local s7_pct
    s7_pct=$(printf "%04.1f%%" "$s7")
    l3="$(printf "${RED}%3s${RST}" "7d")$(bar "$s7" "$RED")$(printf "${RED}%6s${RST}" "$s7_pct") ${DIM}↻ $(remaining "$s7r")${RST}"
  else
    l3="$(printf "${DIM}%3s${RST}" "7d")$(bar "0" "$DIM")$(printf "${DIM}%6s${RST}" "?%") ${DIM}↻ $(remaining "")${RST}"
  fi
  printf '%b  %b\n' "$l3" "${DIM}${model_label}${RST}"
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
# reset_at is expected as Unix epoch seconds.
effective_utilization() {
  local util="$1" reset_epoch="$2"
  if [ -z "$reset_epoch" ] || [ -z "$util" ]; then
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

# Calculate remaining time until reset.
# reset_epoch is expected as Unix epoch seconds.
remaining() {
  local reset_epoch=$1
  if [ -z "$reset_epoch" ]; then printf "%6s" "?"; return; fi

  local now
  now=${REMAINING_NOW:-$(date +%s)}
  local diff=$((reset_epoch - now))
  if [ "$diff" -le 0 ]; then printf "%6s" "now"; return; fi

  local days=$((diff / 86400))
  local hours=$(( (diff % 86400) / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if [ "$days" -gt 0 ]; then
    printf "%02dd%02dh" "$days" "$hours"
  else
    printf "%02dh%02dm" "$hours" "$mins"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main
fi
