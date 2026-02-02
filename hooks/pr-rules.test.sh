#!/bin/bash

# Test script for pr-rules.sh functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/pr-rules.sh"

# Test counters
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

assert_true() {
    local description="$1"
    shift
    if "$@"; then
        echo -e "${GREEN}PASS${NC}: $description"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: $description"
        ((++FAIL))
    fi
}

assert_false() {
    local description="$1"
    shift
    if ! "$@"; then
        echo -e "${GREEN}PASS${NC}: $description"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: $description"
        ((++FAIL))
    fi
}

assert_equals() {
    local description="$1"
    local expected="$2"
    local actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}PASS${NC}: $description"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: $description"
        echo "  Expected: $expected"
        echo "  Actual:   $actual"
        ((++FAIL))
    fi
}

echo "=== Testing is_exploratory_branch ==="

assert_true "2026-02-02_1430 is exploratory" \
    is_exploratory_branch "2026-02-02_1430"

assert_true "2025-12-31_0000 is exploratory" \
    is_exploratory_branch "2025-12-31_0000"

assert_false "plan/2026-17-foo is NOT exploratory" \
    is_exploratory_branch "plan/2026-17-foo"

assert_false "feature/2026-17-foo is NOT exploratory" \
    is_exploratory_branch "feature/2026-17-foo"

assert_false "main is NOT exploratory" \
    is_exploratory_branch "main"

assert_false "2026-02-02 (no time) is NOT exploratory" \
    is_exploratory_branch "2026-02-02"

echo ""
echo "=== Testing is_implementation_branch ==="

assert_true "feature/2026-17-subscription-licensing is implementation" \
    is_implementation_branch "feature/2026-17-subscription-licensing"

assert_true "fix/2026-3-login-error is implementation" \
    is_implementation_branch "fix/2026-3-login-error"

assert_true "feature/2026-1-a is implementation (minimal)" \
    is_implementation_branch "feature/2026-1-a"

assert_false "plan/2026-17-foo is NOT implementation" \
    is_implementation_branch "plan/2026-17-foo"

assert_false "feature/no-year is NOT implementation" \
    is_implementation_branch "feature/no-year"

assert_false "feature/2026-17-UPPERCASE is NOT implementation" \
    is_implementation_branch "feature/2026-17-UPPERCASE"

assert_false "main is NOT implementation" \
    is_implementation_branch "main"

assert_false "2026-02-02_1430 is NOT implementation" \
    is_implementation_branch "2026-02-02_1430"

echo ""
echo "=== Testing get_plan_identifier ==="

assert_equals "feature/2026-17-subscription-licensing extracts correctly" \
    "2026-17-subscription-licensing" \
    "$(get_plan_identifier "feature/2026-17-subscription-licensing")"

assert_equals "fix/2026-3-login-error extracts correctly" \
    "2026-3-login-error" \
    "$(get_plan_identifier "fix/2026-3-login-error")"

echo ""
echo "=== Testing print_related_plan_section ==="

output=$(print_related_plan_section "feature/2026-17-subscription-licensing")

if echo "$output" | grep -q "plan/2026-17-subscription-licensing"; then
    echo -e "${GREEN}PASS${NC}: Related plan section contains correct plan reference"
    ((++PASS))
else
    echo -e "${RED}FAIL${NC}: Related plan section missing plan reference"
    echo "$output"
    ((++FAIL))
fi

if echo "$output" | grep -q "Related:"; then
    echo -e "${GREEN}PASS${NC}: Related plan section contains 'Related:' marker"
    ((++PASS))
else
    echo -e "${RED}FAIL${NC}: Related plan section missing 'Related:' marker"
    ((++FAIL))
fi

echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
