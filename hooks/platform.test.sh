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

# --- get_oauth_token: no credentials ---
# On CI or a fresh machine, there are no credentials stored.
# We cannot guarantee the result is empty (the developer machine may have
# credentials), so we just verify the function runs without error.

token_exit=0
get_oauth_token > /dev/null 2>&1 || token_exit=$?
assert_eq "get_oauth_token exits without error" "0" "$token_exit"

# --- Results ---

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
  exit 1
fi
