#!/bin/bash

# Shared command detection functions for hooks

# Split compound command (&&, ||, ;) into individual sub-commands
_split_commands() {
    local command="$1"
    echo "$command" | sed 's/ *&& */\n/g; s/ *|| */\n/g; s/ *; */\n/g'
}

# Check if a single sub-command is a git commit
_is_single_git_commit() {
    local command="$1"
    echo "$command" | grep -qE '\bgit\b.*\bcommit\b'
}

# Check if a single sub-command is a non-branch-creating git command
# These commands may contain "branch" in arguments (e.g., commit messages)
_is_single_non_branch_command() {
    local command="$1"
    echo "$command" | grep -qE 'git\b.*\b(commit|push|pull|fetch|merge|rebase|stash|log|diff|show|status|add|rm|mv|reset|revert|cherry-pick|tag|remote|clone)\b'
}

# Check if a single sub-command is a branch creation command
_is_single_branch_creation() {
    local command="$1"
    # checkout -b and switch -c are always branch creation regardless of branch name
    if echo "$command" | grep -qE 'git\b.*\b(checkout -b|switch -c)\b'; then
        return 0
    fi
    if _is_single_non_branch_command "$command"; then
        return 1
    fi
    echo "$command" | grep -qE 'git\b.*\bbranch [^-]'
}

# Check if command (possibly compound) contains a git commit
is_git_commit() {
    local command="$1"
    local subcmd
    while IFS= read -r subcmd; do
        [[ -z "$subcmd" ]] && continue
        if _is_single_git_commit "$subcmd"; then
            return 0
        fi
    done <<< "$(_split_commands "$command")"
    return 1
}

# Check if command is a non-branch-creating git command (kept for compatibility)
is_non_branch_command() {
    local command="$1"
    _is_single_non_branch_command "$command"
}

# Check if command (possibly compound) contains a branch creation
is_branch_creation() {
    local command="$1"
    local subcmd
    while IFS= read -r subcmd; do
        [[ -z "$subcmd" ]] && continue
        if _is_single_branch_creation "$subcmd"; then
            return 0
        fi
    done <<< "$(_split_commands "$command")"
    return 1
}

# Extract branch name from a command (possibly compound)
# Returns empty string if no branch creation found
get_branch_name() {
    local command="$1"
    local subcmd
    while IFS= read -r subcmd; do
        [[ -z "$subcmd" ]] && continue
        # checkout -b and switch -c are always branch creation regardless of branch name
        if echo "$subcmd" | grep -qE 'git\b.*\b(checkout -b|switch -c)'; then
            echo "$subcmd" | sed -E 's/.*\b(checkout -b|switch -c) +([^ ]+).*/\2/'
            return
        fi
        if _is_single_non_branch_command "$subcmd"; then
            continue
        fi
        if echo "$subcmd" | grep -qE 'git\b.*\bbranch [^-]'; then
            echo "$subcmd" | sed -E 's/.*\bbranch +([^-][^ ]*).*/\1/'
            return
        fi
    done <<< "$(_split_commands "$command")"
    echo ""
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
