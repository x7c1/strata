#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=platform.sh
source "$SCRIPT_DIR/platform.sh"

pass=0
fail=0

assert_eq() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "PASS: $description"
    pass=$((pass + 1))
  else
    echo "FAIL: $description (expected: '$expected', got: '$actual')"
    fail=$((fail + 1))
  fi
}

assert_not_empty() {
  local description="$1"
  local actual="$2"
  if [ -n "$actual" ]; then
    echo "PASS: $description"
    pass=$((pass + 1))
  else
    echo "FAIL: $description (expected non-empty, got empty)"
    fail=$((fail + 1))
  fi
}

assert_empty() {
  local description="$1"
  local actual="$2"
  if [ -z "$actual" ]; then
    echo "PASS: $description"
    pass=$((pass + 1))
  else
    echo "FAIL: $description (expected empty, got: '$actual')"
    fail=$((fail + 1))
  fi
}

# --- detect_os ---

os="$(detect_os)"
case "$os" in
  darwin|linux)
    echo "PASS: detect_os returns darwin or linux (got: $os)"
    pass=$((pass + 1))
    ;;
  *)
    echo "FAIL: detect_os returned unexpected value: $os"
    fail=$((fail + 1))
    ;;
esac

# --- parse_iso_date: known date ---

epoch="$(parse_iso_date "2025-01-01T00:00:00.000Z")"
assert_eq "parse_iso_date returns correct epoch for 2025-01-01T00:00:00.000Z" "1735689600" "$epoch"

# --- parse_iso_date: without fractional seconds ---

epoch="$(parse_iso_date "2025-01-01T00:00:00Z")"
assert_eq "parse_iso_date handles input without fractional seconds" "1735689600" "$epoch"

# --- parse_iso_date: without trailing Z ---

epoch="$(parse_iso_date "2025-01-01T00:00:00")"
assert_eq "parse_iso_date handles input without trailing Z" "1735689600" "$epoch"

# --- parse_iso_date: empty input ---

epoch="$(parse_iso_date "")"
assert_empty "parse_iso_date returns empty for empty input" "$epoch"

# --- parse_iso_date: invalid input ---

epoch="$(parse_iso_date "not-a-date")"
assert_empty "parse_iso_date returns empty for invalid input" "$epoch"

# --- normalize_12h_time ---

assert_eq "normalize_12h_time: 2pm" "14:00" "$(normalize_12h_time "2pm")"
assert_eq "normalize_12h_time: 9pm" "21:00" "$(normalize_12h_time "9pm")"
assert_eq "normalize_12h_time: 12pm (noon)" "12:00" "$(normalize_12h_time "12pm")"
assert_eq "normalize_12h_time: 12am (midnight)" "00:00" "$(normalize_12h_time "12am")"
assert_eq "normalize_12h_time: 8:59pm" "20:59" "$(normalize_12h_time "8:59pm")"
assert_eq "normalize_12h_time: 3am" "03:00" "$(normalize_12h_time "3am")"
assert_empty "normalize_12h_time: empty input" "$(normalize_12h_time "")"
assert_empty "normalize_12h_time: invalid input" "$(normalize_12h_time "nottime")"

# --- parse_human_reset_time: month+day+time ---

YEAR=$(date +%Y)

result="$(parse_human_reset_time "Resets Feb 26, 9pm (Asia/Tokyo)")"
assert_eq "parse_human_reset_time: Feb 26, 9pm JST -> UTC" "${YEAR}-02-26T12:00:00Z" "$result"

result="$(parse_human_reset_time "Resets Feb 24, 3pm (Asia/Tokyo)")"
assert_eq "parse_human_reset_time: Feb 24, 3pm JST -> UTC" "${YEAR}-02-24T06:00:00Z" "$result"

result="$(parse_human_reset_time "Resets Feb 26, 8:59pm (Asia/Tokyo)")"
assert_eq "parse_human_reset_time: Feb 26, 8:59pm JST -> UTC" "${YEAR}-02-26T11:59:00Z" "$result"

# --- parse_human_reset_time: time-only ---
# Time-only patterns always resolve to a future time.
# If "today at X" is already past, the result should be "tomorrow at X".

now_epoch=$(date +%s)

result="$(parse_human_reset_time "Resets 2pm (Asia/Tokyo)")"
result_epoch="$(parse_iso_date "$result")"
assert_not_empty "parse_human_reset_time: 2pm JST resolves" "$result"
if [ -n "$result_epoch" ] && [ "$result_epoch" -gt "$now_epoch" ]; then
  echo "PASS: parse_human_reset_time: 2pm JST is in the future"
  pass=$((pass + 1))
else
  echo "FAIL: parse_human_reset_time: 2pm JST is not in the future (result=$result, now=$(date -u +%Y-%m-%dT%H:%M:%SZ))"
  fail=$((fail + 1))
fi

result="$(parse_human_reset_time "Resets 2am (Asia/Tokyo)")"
result_epoch="$(parse_iso_date "$result")"
assert_not_empty "parse_human_reset_time: 2am JST resolves" "$result"
if [ -n "$result_epoch" ] && [ "$result_epoch" -gt "$now_epoch" ]; then
  echo "PASS: parse_human_reset_time: 2am JST is in the future"
  pass=$((pass + 1))
else
  echo "FAIL: parse_human_reset_time: 2am JST is not in the future (result=$result, now=$(date -u +%Y-%m-%dT%H:%M:%SZ))"
  fail=$((fail + 1))
fi

# --- parse_human_reset_time: edge cases ---

assert_empty "parse_human_reset_time: empty input" "$(parse_human_reset_time "")"
assert_empty "parse_human_reset_time: no timezone" "$(parse_human_reset_time "Resets 2pm")"
assert_empty "parse_human_reset_time: garbage input" "$(parse_human_reset_time "garbage")"

# --- Results ---

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
  exit 1
fi
