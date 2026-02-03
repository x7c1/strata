#!/bin/bash

# Test script for branch-rules.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/branch-rules.sh"

# Test counters
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_valid() {
    local branch="$1"
    if is_valid_branch_name "$branch"; then
        echo -e "${GREEN}PASS${NC}: '$branch' is valid"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: '$branch' should be valid"
        ((++FAIL))
    fi
}

assert_invalid() {
    local branch="$1"
    if ! is_valid_branch_name "$branch"; then
        echo -e "${GREEN}PASS${NC}: '$branch' is invalid"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: '$branch' should be invalid"
        ((++FAIL))
    fi
}

echo "=== Testing exploratory branch pattern ==="

assert_valid "2026-01-15_1430"
assert_valid "2026-12-31_0000"
assert_valid "2026-02-03_0930"

assert_invalid "2026-1-15_1430"    # single digit month
assert_invalid "2026-01-5_1430"    # single digit day
assert_invalid "2026-01-15_143"    # 3 digit time
assert_invalid "2026-01-15-1430"   # dash instead of underscore
assert_invalid "26-01-15_1430"     # 2 digit year

echo ""
echo "=== Testing task branch patterns ==="

echo ""
echo "--- plan/ branches ---"
assert_valid "plan/2026-1-add-feature"
assert_valid "plan/2026-18-layer-architecture-refactoring"
assert_valid "plan/2026-123-long-number"

echo ""
echo "--- feature/ branches ---"
assert_valid "feature/2026-1-user-auth"
assert_valid "feature/2026-42-dark-mode"

echo ""
echo "--- fix/ branches ---"
assert_valid "fix/2026-1-login-error"
assert_valid "fix/2026-99-null-pointer"

echo ""
echo "--- refactor/ branches ---"
assert_valid "refactor/2026-18-layer-architecture"
assert_valid "refactor/2026-1-cleanup-code"

echo ""
echo "=== Testing invalid patterns ==="

assert_invalid "main"
assert_invalid "develop"
assert_invalid "feature/add-login"           # missing year-number
assert_invalid "feature/2026-add-login"      # missing number
assert_invalid "docs/2026-1-update-readme"   # invalid prefix
assert_invalid "chore/2026-1-cleanup"        # invalid prefix
assert_invalid "FEATURE/2026-1-test"         # uppercase prefix
assert_invalid "feature/2026-1-Test"         # uppercase in description
assert_invalid "feature/2026-1-test_foo"     # underscore in description

echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
