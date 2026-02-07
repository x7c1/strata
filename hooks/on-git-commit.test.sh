#!/bin/bash

# Test script for on-git-commit.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Test counters
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

run_hook_get_exit_code() {
    local command="$1"
    local exit_code
    jq -n --arg cmd "$command" '{"tool_input":{"command": $cmd}}' | \
        "$SCRIPT_DIR/on-git-commit.sh" >/dev/null 2>&1
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

echo "=== Testing non-commit commands pass through ==="

assert_exit_code "git push passes through" 0 "git push"
assert_exit_code "echo passes through" 0 "echo hello"
assert_exit_code "git status passes through" 0 "git status"

echo ""
echo "=== Testing simple -m format ==="

assert_exit_code "Clean message passes" 0 \
    'git commit -m "docs(plans): valid message"'

assert_exit_code "Co-Authored-By is rejected" 2 \
    'git commit -m "docs: msg Co-Authored-By: Someone"'

echo ""
echo "=== Testing HEREDOC format ==="

# HEREDOC with clean single-line message
HEREDOC_CLEAN=$(cat <<'TESTCMD'
git commit -m "$(cat <<'EOF'
docs(plans): clean message
EOF
)"
TESTCMD
)

assert_exit_code "HEREDOC with clean message passes" 0 "$HEREDOC_CLEAN"

# HEREDOC with Co-Authored-By (should be rejected)
HEREDOC_COAUTHOR=$(cat <<'TESTCMD'
git commit -m "$(cat <<'EOF'
docs(plans): restructure plan 29

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
TESTCMD
)

assert_exit_code "HEREDOC with Co-Authored-By is rejected" 2 "$HEREDOC_COAUTHOR"

# HEREDOC with multi-line message (rejected per "single line" rule)
HEREDOC_MULTILINE=$(cat <<'TESTCMD'
git commit -m "$(cat <<'EOF'
docs(plans): first line

Body text here.
EOF
)"
TESTCMD
)

assert_exit_code "HEREDOC with multi-line message is rejected" 2 "$HEREDOC_MULTILINE"

echo ""
echo "=== Testing chained commands with HEREDOC ==="

CHAINED_HEREDOC=$(cat <<'TESTCMD'
git add file.txt && git commit -m "$(cat <<'EOF'
docs(plans): message

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
TESTCMD
)

assert_exit_code "Chained command with HEREDOC Co-Authored-By is rejected" 2 "$CHAINED_HEREDOC"

echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
