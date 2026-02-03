#!/bin/bash

# Test script for on-gh-pr-create.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test counters
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

run_hook() {
    local command="$1"
    echo "{\"tool_input\":{\"command\":\"$command\"}}" | "$SCRIPT_DIR/on-gh-pr-create.sh" 2>/dev/null
}

run_hook_get_exit_code() {
    local command="$1"
    # Escape double quotes in command for JSON
    local escaped_command="${command//\"/\\\"}"
    local json_input="{\"tool_input\":{\"command\":\"$escaped_command\"}}"
    local exit_code
    echo "$json_input" | "$SCRIPT_DIR/on-gh-pr-create.sh" >/dev/null 2>&1
    exit_code=$?
    echo "$exit_code"
}

assert_exit_code() {
    local description="$1"
    local expected_code="$2"
    local command="$3"
    local actual_code
    actual_code=$(run_hook_get_exit_code "$command")
    if [[ "$expected_code" == "$actual_code" ]]; then
        echo -e "${GREEN}PASS${NC}: $description"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: $description (expected exit $expected_code, got $actual_code)"
        ((++FAIL))
    fi
}

echo "=== Testing --draft flag requirement ==="

# Use valid body for non-exploratory branches (CI environment has no branch or unknown branch)
VALID_BODY="## New Features\n- [ ] Test feature"

assert_exit_code "gh pr create with --draft passes" 0 \
    "gh pr create --title \"test\" --body \"$VALID_BODY\" --draft"

assert_exit_code "gh pr create without --draft fails" 2 \
    "gh pr create --title \"test\" --body \"$VALID_BODY\""

assert_exit_code "gh pr create with --draft at end passes" 0 \
    "gh pr create --title \"test\" --body \"$VALID_BODY\" --draft"

assert_exit_code "gh pr create with --draft in middle passes" 0 \
    "gh pr create --draft --title \"test\" --body \"$VALID_BODY\""

echo ""
echo "=== Testing non-gh-pr-create commands ==="

assert_exit_code "gh pr view passes through" 0 \
    'gh pr view'

assert_exit_code "gh pr edit passes through" 0 \
    'gh pr edit 123'

assert_exit_code "git commit passes through" 0 \
    'git commit -m "test"'

assert_exit_code "random command passes through" 0 \
    'echo hello'

echo ""
echo "=== Testing edge cases ==="

assert_exit_code "--draft as part of title should fail" 2 \
    "gh pr create --title \"--draft test\" --body \"$VALID_BODY\""

assert_exit_code "--draft as part of body should fail" 2 \
    "gh pr create --title \"test\" --body \"--draft $VALID_BODY\""

echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
