#!/bin/bash

# Test script for command-detect.sh functions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/command-detect.sh"

# Test counters
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

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
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        ((++FAIL))
    fi
}

echo "=== Testing is_git_commit ==="

assert_true "git commit -m 'message'" \
    is_git_commit "git commit -m 'message'"

assert_true "git commit --amend" \
    is_git_commit "git commit --amend"

assert_false "git checkout -b branch" \
    is_git_commit "git checkout -b branch"

assert_false "git push" \
    is_git_commit "git push"

echo ""
echo "=== Testing is_non_branch_command ==="

assert_true "git commit -m 'message'" \
    is_non_branch_command "git commit -m 'message'"

assert_true "git push origin main" \
    is_non_branch_command "git push origin main"

assert_true "git log --oneline" \
    is_non_branch_command "git log --oneline"

assert_true "git diff HEAD" \
    is_non_branch_command "git diff HEAD"

assert_true "git status" \
    is_non_branch_command "git status"

assert_false "git checkout -b new-branch" \
    is_non_branch_command "git checkout -b new-branch"

assert_false "git branch new-branch" \
    is_non_branch_command "git branch new-branch"

assert_false "git switch -c new-branch" \
    is_non_branch_command "git switch -c new-branch"

echo ""
echo "=== Testing is_branch_creation ==="

assert_true "git checkout -b new-branch" \
    is_branch_creation "git checkout -b new-branch"

assert_true "git switch -c new-branch" \
    is_branch_creation "git switch -c new-branch"

assert_true "git branch new-branch" \
    is_branch_creation "git branch new-branch"

assert_true "git -C /path checkout -b branch" \
    is_branch_creation "git -C /path checkout -b branch"

assert_false "git commit -m 'add branch feature'" \
    is_branch_creation "git commit -m 'add branch feature'"

assert_false "git push origin branch" \
    is_branch_creation "git push origin branch"

assert_false "git branch -d old-branch" \
    is_branch_creation "git branch -d old-branch"

assert_false "git branch -D old-branch" \
    is_branch_creation "git branch -D old-branch"

echo ""
echo "=== Testing is_branch_creation (branch names matching git subcommands) ==="

assert_true "git checkout -b add-pigeon-source" \
    is_branch_creation "git checkout -b add-pigeon-source"

assert_true "git checkout -b status-page" \
    is_branch_creation "git checkout -b status-page"

assert_true "git checkout -b reset-password-flow" \
    is_branch_creation "git checkout -b reset-password-flow"

assert_true "git checkout -b log-viewer" \
    is_branch_creation "git checkout -b log-viewer"

assert_true "git switch -c add-feature" \
    is_branch_creation "git switch -c add-feature"

assert_true "git switch -c remote-config" \
    is_branch_creation "git switch -c remote-config"

echo ""
echo "=== Testing is_branch_creation (compound commands) ==="

assert_true "git branch foo && git reset --hard HEAD~1" \
    is_branch_creation "git branch foo && git reset --hard HEAD~1"

assert_true "git reset --hard HEAD~1 && git branch foo" \
    is_branch_creation "git reset --hard HEAD~1 && git branch foo"

assert_true "git branch foo && git reset --hard HEAD~1 && git checkout foo" \
    is_branch_creation "git branch foo && git reset --hard HEAD~1 && git checkout foo"

assert_false "git add . && git commit -m 'msg' && git push" \
    is_branch_creation "git add . && git commit -m 'msg' && git push"

echo ""
echo "=== Testing get_branch_name ==="

assert_equals "git checkout -b feature/test" \
    "feature/test" \
    "$(get_branch_name "git checkout -b feature/test")"

assert_equals "git switch -c fix/bug" \
    "fix/bug" \
    "$(get_branch_name "git switch -c fix/bug")"

assert_equals "git branch new-branch" \
    "new-branch" \
    "$(get_branch_name "git branch new-branch")"

assert_equals "git -C /path checkout -b 2026-02-02_1300" \
    "2026-02-02_1300" \
    "$(get_branch_name "git -C /path checkout -b 2026-02-02_1300")"

assert_equals "git commit -m 'branch fix' returns empty" \
    "" \
    "$(get_branch_name "git commit -m 'branch fix'")"

assert_equals "git branch -d old returns empty" \
    "" \
    "$(get_branch_name "git branch -d old")"

echo ""
echo "=== Testing get_branch_name (compound commands) ==="

assert_equals "git branch foo && git reset --hard" \
    "foo" \
    "$(get_branch_name "git branch foo && git reset --hard HEAD~1")"

assert_equals "git reset --hard && git checkout -b bar" \
    "bar" \
    "$(get_branch_name "git reset --hard HEAD~1 && git checkout -b bar")"

assert_equals "git add . && git commit -m 'msg' returns empty" \
    "" \
    "$(get_branch_name "git add . && git commit -m 'msg'")"

echo ""
echo "=== Testing get_branch_name (branch names matching git subcommands) ==="

assert_equals "git checkout -b add-pigeon-source" \
    "add-pigeon-source" \
    "$(get_branch_name "git checkout -b add-pigeon-source")"

assert_equals "git checkout -b status-page" \
    "status-page" \
    "$(get_branch_name "git checkout -b status-page")"

assert_equals "git switch -c reset-password" \
    "reset-password" \
    "$(get_branch_name "git switch -c reset-password")"

echo ""
echo "=== Testing is_gh_pr_create ==="

assert_true "gh pr create --title 'test'" \
    is_gh_pr_create "gh pr create --title 'test'"

assert_true "gh pr create --draft" \
    is_gh_pr_create "gh pr create --draft"

assert_false "gh pr edit 123" \
    is_gh_pr_create "gh pr edit 123"

assert_false "gh pr view" \
    is_gh_pr_create "gh pr view"

echo ""
echo "=== Testing is_gh_pr_edit ==="

assert_true "gh pr edit 123" \
    is_gh_pr_edit "gh pr edit 123"

assert_true "gh pr edit --title 'new title'" \
    is_gh_pr_edit "gh pr edit --title 'new title'"

assert_false "gh pr create" \
    is_gh_pr_edit "gh pr create"

assert_false "gh pr view" \
    is_gh_pr_edit "gh pr view"

echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
