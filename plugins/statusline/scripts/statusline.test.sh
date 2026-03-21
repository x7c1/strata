#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/statusline.sh"

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

strip_ansi() {
  sed $'s/\033\[[0-9;]*m//g'
}

# --- effective_utilization ---

echo "=== Testing effective_utilization ==="

now=$(date +%s)
future=$((now + 3600))
past=$((now - 3600))

assert_eq "returns util when reset is in future" \
  "45.2" "$(effective_utilization "45.2" "$future")"

assert_eq "returns 0.0 when reset is in past" \
  "0.0" "$(effective_utilization "45.2" "$past")"

assert_eq "returns util when reset_epoch is empty" \
  "45.2" "$(effective_utilization "45.2" "")"

assert_eq "returns empty when util is empty" \
  "" "$(effective_utilization "" "$future")"

assert_eq "returns empty when both are empty" \
  "" "$(effective_utilization "" "")"

# --- remaining ---

echo ""
echo "=== Testing remaining ==="

assert_eq "returns '?' when reset_epoch is empty" \
  "     ?" "$(remaining "")"

assert_eq "returns 'now' when reset is in past" \
  "   now" "$(remaining "$past")"

# Use a fixed reference point to avoid timing drift between
# the test's "now" and the "now" inside remaining().
far_future=$((now + 86400 * 30))

reset_2h=$((far_future + 7200))
REMAINING_NOW=$far_future assert_eq "formats hours and minutes" \
  "02h00m" "$(REMAINING_NOW=$far_future remaining "$reset_2h")"

reset_1d12h=$((far_future + 86400 + 43200))
assert_eq "formats days and hours" \
  "01d12h" "$(REMAINING_NOW=$far_future remaining "$reset_1d12h")"

reset_3d0h=$((far_future + 259200))
assert_eq "formats multi-day" \
  "03d00h" "$(REMAINING_NOW=$far_future remaining "$reset_3d0h")"

# --- render ---

echo ""
echo "=== Testing render (with rate_limits) ==="

output=$(render "~/project" "Opus 4.6" "32.5" "main" "23.5" "41.2" "$future" "$future" 80)
plain=$(echo "$output" | strip_ansi)

echo ""
echo "--- output preview ---"
printf '%b\n' "$output"
echo "----------------------"
echo ""

line1=$(echo "$plain" | sed -n '1p')
line2=$(echo "$plain" | sed -n '2p')
line3=$(echo "$plain" | sed -n '3p')

echo "$plain" | grep -q "ctx" && { echo "PASS: line 1 contains ctx label"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 1 missing ctx label"; fail=$((fail + 1)); }

echo "$plain" | grep -q "32.5%" && { echo "PASS: line 1 contains ctx percentage"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 1 missing ctx percentage"; fail=$((fail + 1)); }

echo "$plain" | grep -q "~/project" && { echo "PASS: line 1 contains display path"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 1 missing display path"; fail=$((fail + 1)); }

echo "$line2" | grep -q "5h" && { echo "PASS: line 2 contains 5h label"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 2 missing 5h label"; fail=$((fail + 1)); }

echo "$line2" | grep -q "23.5%" && { echo "PASS: line 2 contains 5h percentage"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 2 missing 5h percentage"; fail=$((fail + 1)); }

echo "$line2" | grep -q "main" && { echo "PASS: line 2 contains branch"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 2 missing branch"; fail=$((fail + 1)); }

echo "$line3" | grep -q "7d" && { echo "PASS: line 3 contains 7d label"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 3 missing 7d label"; fail=$((fail + 1)); }

echo "$line3" | grep -q "41.2%" && { echo "PASS: line 3 contains 7d percentage"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 3 missing 7d percentage"; fail=$((fail + 1)); }

echo "$line3" | grep -q "\[Opus 4.6\]" && { echo "PASS: line 3 contains model"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 3 missing model"; fail=$((fail + 1)); }

echo ""
echo "=== Testing render (without rate_limits) ==="

output=$(render "~/project" "Sonnet 4.6" "10.0" "dev" "" "" "" "" 80)
plain=$(echo "$output" | strip_ansi)

echo ""
echo "--- output preview ---"
printf '%b\n' "$output"
echo "----------------------"
echo ""

line2=$(echo "$plain" | sed -n '2p')
line3=$(echo "$plain" | sed -n '3p')

echo "$line2" | grep -qv "5h" && { echo "PASS: line 2 omits 5h when no rate_limits"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 2 should omit 5h when no rate_limits"; fail=$((fail + 1)); }

echo "$line3" | grep -qv "7d" && { echo "PASS: line 3 omits 7d when no rate_limits"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 3 should omit 7d when no rate_limits"; fail=$((fail + 1)); }

echo "$line3" | grep -q "\[Sonnet 4.6\]" && { echo "PASS: line 3 still shows model"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 3 missing model without rate_limits"; fail=$((fail + 1)); }

echo "$line2" | grep -q "dev" && { echo "PASS: line 2 still shows branch"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 2 missing branch without rate_limits"; fail=$((fail + 1)); }

# Verify alignment: branch and model should not be left-aligned.
# With rate_limits, line 2 has a bar section of fixed width before the branch.
# Without rate_limits, the same padding should be preserved.
# " 5h▕██░░░░░░░░▏ 23.5% ↻ 01h00m  main" -> leading width before "main" is ~32 chars
# Without rate_limits, "dev" should start at a similar column, not at column 3.

leading_spaces_l2=$(echo "$line2" | sed 's/[^ ].*//' | wc -c)
[ "$leading_spaces_l2" -ge 20 ] && { echo "PASS: line 2 branch is right-padded (not left-aligned)"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 2 branch is left-aligned (leading spaces: $((leading_spaces_l2 - 1)))"; fail=$((fail + 1)); }

leading_spaces_l3=$(echo "$line3" | sed 's/[^ ].*//' | wc -c)
[ "$leading_spaces_l3" -ge 20 ] && { echo "PASS: line 3 model is right-padded (not left-aligned)"; pass=$((pass + 1)); } \
  || { echo "FAIL: line 3 model is left-aligned (leading spaces: $((leading_spaces_l3 - 1)))"; fail=$((fail + 1)); }

# --- Results ---

echo ""
echo "================================"
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
  exit 1
fi
