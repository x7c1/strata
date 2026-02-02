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

if echo "$output" | grep -q "## Related"; then
    echo -e "${GREEN}PASS${NC}: Related plan section contains '## Related' header"
    ((++PASS))
else
    echo -e "${RED}FAIL${NC}: Related plan section missing '## Related' header"
    ((++FAIL))
fi

if echo "$output" | grep -q "docs/plans/2026/17-subscription-licensing/"; then
    echo -e "${GREEN}PASS${NC}: Related plan section contains correct plan link"
    ((++PASS))
else
    echo -e "${RED}FAIL${NC}: Related plan section missing plan link"
    ((++FAIL))
fi

echo ""
echo "=== Testing extract_body_from_command ==="

assert_equals "Extract simple body" \
    "hello world" \
    "$(extract_body_from_command 'gh pr create --body "hello world" --draft')"

assert_equals "Extract empty body" \
    "" \
    "$(extract_body_from_command 'gh pr create --body "" --draft')"

assert_equals "Extract body with ## header" \
    "## Bug Fixes" \
    "$(extract_body_from_command 'gh pr create --body "## Bug Fixes" --draft')"

echo ""
echo "=== Testing validate_exploratory_pr ==="

# Test: empty body should pass
assert_exit_code() {
    local description="$1"
    local expected_code="$2"
    shift 2
    local actual_code
    "$@" >/dev/null 2>&1 && actual_code=0 || actual_code=$?
    if [[ "$expected_code" == "$actual_code" ]]; then
        echo -e "${GREEN}PASS${NC}: $description"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: $description (expected exit $expected_code, got $actual_code)"
        ((++FAIL))
    fi
}

run_validate_exploratory() {
    echo "{\"tool_input\":{\"command\":\"$1\"}}" | (
        source "$SCRIPT_DIR/pr-rules.sh"
        validate_exploratory_pr "$1"
    )
}

run_validate_body_format() {
    echo "{\"tool_input\":{\"command\":\"$1\"}}" | (
        source "$SCRIPT_DIR/pr-rules.sh"
        validate_pr_body_format "$1"
    )
}

assert_exit_code "Exploratory: empty body passes" 0 \
    run_validate_exploratory 'gh pr create --body "" --draft'

assert_exit_code "Exploratory: non-empty body fails" 2 \
    run_validate_exploratory 'gh pr create --body "content" --draft'

echo ""
echo "=== Testing validate_pr_body_format ==="

assert_exit_code "Valid body with ## Bug Fixes passes" 0 \
    run_validate_body_format 'gh pr create --body "## Bug Fixes" --draft'

assert_exit_code "Valid body with ## New Features passes" 0 \
    run_validate_body_format 'gh pr create --body "## New Features" --draft'

assert_exit_code "Valid body with ## Refactoring passes" 0 \
    run_validate_body_format 'gh pr create --body "## Refactoring" --draft'

assert_exit_code "Valid body with ## Breaking Changes passes" 0 \
    run_validate_body_format 'gh pr create --body "## Breaking Changes" --draft'

assert_exit_code "Invalid body with ## Summary fails" 2 \
    run_validate_body_format 'gh pr create --body "## Summary" --draft'

assert_exit_code "Invalid body with ## Test plan fails" 2 \
    run_validate_body_format 'gh pr create --body "## Test plan" --draft'

assert_exit_code "Empty body fails" 2 \
    run_validate_body_format 'gh pr create --body "" --draft'

assert_exit_code "Body without valid section fails" 2 \
    run_validate_body_format 'gh pr create --body "just some text" --draft'

echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
