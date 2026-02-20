#!/usr/bin/env bash
# Cross-platform helper functions for hooks.
# Source this file; do not execute it directly.

# Detect the current OS.
# Returns "darwin" or "linux".
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    *)      echo "linux" ;;
  esac
}

# Convert 12-hour time string to 24-hour HH:MM format.
# Usage: normalize_12h_time "2pm" -> "14:00"
#        normalize_12h_time "8:59pm" -> "20:59"
normalize_12h_time() {
  local t="$1"
  if [ -z "$t" ]; then return; fi

  local hour min ampm
  if [[ "$t" =~ ^([0-9]+):([0-9]+)(am|pm)$ ]]; then
    hour="${BASH_REMATCH[1]}"
    min="${BASH_REMATCH[2]}"
    ampm="${BASH_REMATCH[3]}"
  elif [[ "$t" =~ ^([0-9]+)(am|pm)$ ]]; then
    hour="${BASH_REMATCH[1]}"
    min="00"
    ampm="${BASH_REMATCH[2]}"
  else
    return
  fi

  if [ "$ampm" = "pm" ] && [ "$hour" -ne 12 ]; then
    hour=$((hour + 12))
  elif [ "$ampm" = "am" ] && [ "$hour" -eq 12 ]; then
    hour=0
  fi

  printf "%02d:%02d" "$hour" "$min"
}

# Parse human-readable reset time from /status Usage tab to ISO 8601 UTC.
# Input formats:
#   "Resets 2pm (Asia/Tokyo)"
#   "Resets Feb 26, 9pm (Asia/Tokyo)"
#   "Resets Feb 26, 8:59pm (Asia/Tokyo)"
# Output: ISO 8601 UTC string, e.g. "2026-02-20T05:00:00Z"
parse_human_reset_time() {
  local raw="$1"
  if [ -z "$raw" ]; then return; fi

  # Extract timezone from parentheses
  local tz
  tz=$(echo "$raw" | grep -oP '\(([^)]+)\)' | tr -d '()')
  if [ -z "$tz" ]; then return; fi

  # Extract content between "Resets " and " (timezone)"
  local content
  content=$(echo "$raw" | sed -E 's/.*Resets[[:space:]]+//' | sed -E 's/[[:space:]]*\([^)]+\).*//')
  if [ -z "$content" ]; then return; fi

  local date_ymd time_24h time_only=false

  if [[ "$content" =~ ^([A-Z][a-z]+[[:space:]]+[0-9]+),[[:space:]]+(.*) ]]; then
    # "Feb 26, 9pm" -> date_part="Feb 26", time_12h="9pm"
    local month_day="${BASH_REMATCH[1]}"
    local time_12h="${BASH_REMATCH[2]}"
    time_24h=$(normalize_12h_time "$time_12h")
    if [ -z "$time_24h" ]; then return; fi
    date_ymd=$(date -d "$month_day" +%Y-%m-%d 2>/dev/null)
    if [ -z "$date_ymd" ]; then return; fi
  else
    # Time only: "2pm" or "8:59pm"
    time_24h=$(normalize_12h_time "$content")
    if [ -z "$time_24h" ]; then return; fi
    date_ymd=$(TZ="$tz" date +%Y-%m-%d)
    time_only=true
  fi

  # Two-step conversion: parse in source timezone to epoch, then format as UTC.
  # Using -u directly would override TZ for input parsing too.
  local os
  os="$(detect_os)"

  local epoch=""
  if [ "$os" = "darwin" ]; then
    epoch=$(TZ="$tz" date -j -f "%Y-%m-%d %H:%M" "${date_ymd} ${time_24h}" +%s 2>/dev/null)
  else
    epoch=$(TZ="$tz" date -d "${date_ymd} ${time_24h}" +%s 2>/dev/null)
  fi

  # Time-only patterns always mean the next occurrence.
  # If the resolved time is in the past, advance by 24 hours.
  if [ -n "$epoch" ] && $time_only; then
    local now
    now=$(date +%s)
    if [ "$epoch" -lt "$now" ]; then
      epoch=$((epoch + 86400))
    fi
  fi

  if [ -n "$epoch" ]; then
    date -u -d "@${epoch}" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null
  fi
}

# Parse an ISO 8601 datetime string to epoch seconds.
# Usage: parse_iso_date "2025-01-01T12:00:00.000Z"
# Strips fractional seconds and trailing Z before parsing.
parse_iso_date() {
  local input="$1"
  if [ -z "$input" ]; then
    return
  fi

  # Strip fractional seconds and trailing Z:
  #   "2025-01-01T12:00:00.123Z" -> "2025-01-01T12:00:00"
  local cleaned="${input%%.*}"
  cleaned="${cleaned%Z}"

  local os
  os="$(detect_os)"

  local epoch=""
  if [ "$os" = "darwin" ]; then
    epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$cleaned" +%s 2>/dev/null)
  else
    epoch=$(date -u -d "$cleaned" +%s 2>/dev/null)
  fi

  if [ -n "$epoch" ]; then
    echo "$epoch"
  fi
}
