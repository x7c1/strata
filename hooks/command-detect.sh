#!/bin/bash

# Shared command detection functions for hooks

# Check if command is a git commit
is_git_commit() {
    local command="$1"
    echo "$command" | grep -qE '\bgit\b.*\bcommit\b'
}

# Check if command is a non-branch-creating git command
# These commands may contain "branch" in arguments (e.g., commit messages)
is_non_branch_command() {
    local command="$1"
    echo "$command" | grep -qE 'git\b.*\b(commit|push|pull|fetch|merge|rebase|stash|log|diff|show|status|add|rm|mv|reset|revert|cherry-pick|tag|remote|clone)\b'
}

# Check if command is a branch creation command
is_branch_creation() {
    local command="$1"
    if is_non_branch_command "$command"; then
        return 1
    fi
    echo "$command" | grep -qE 'git\b.*\b(checkout -b|switch -c)\b' ||
    echo "$command" | grep -qE 'git\b.*\bbranch [^-]'
}

# Extract branch name from a branch creation command
# Returns empty string if not a branch creation command
get_branch_name() {
    local command="$1"

    if is_non_branch_command "$command"; then
        echo ""
        return
    fi

    if echo "$command" | grep -qE 'git\b.*\b(checkout -b|switch -c)'; then
        echo "$command" | sed -E 's/.*\b(checkout -b|switch -c) +([^ ]+).*/\2/'
    elif echo "$command" | grep -qE 'git\b.*\bbranch [^-]'; then
        echo "$command" | sed -E 's/.*\bbranch +([^-][^ ]*).*/\1/'
    else
        echo ""
    fi
}

# Check if command is gh pr create
is_gh_pr_create() {
    local command="$1"
    echo "$command" | grep -qE '^gh pr create\b'
}

# Check if command is gh pr edit
is_gh_pr_edit() {
    local command="$1"
    echo "$command" | grep -qE '^gh pr edit\b'
}
