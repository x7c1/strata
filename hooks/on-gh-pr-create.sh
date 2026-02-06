#!/bin/bash

# PreToolUse hook for gh pr create
# Provides PR creation rules based on branch type

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/command-detect.sh"
source "$SCRIPT_DIR/pr-rules.sh"

main() {
    local input command branch_name

    input=$(cat)
    command=$(echo "$input" | jq -r '.tool_input.command // empty')

    # Only process gh pr create commands
    if ! is_gh_pr_create "$command"; then
        exit 0
    fi

    # Require --draft flag
    if ! echo "$command" | grep -qE '\s--draft\b'; then
        echo "ERROR: --draft flag is required for gh pr create" >&2
        exit 2
    fi

    branch_name=$(git branch --show-current 2>/dev/null || echo "")

    if is_exploratory_branch "$branch_name"; then
        validate_pr_body_format "$command" "allow_empty"
        local body
        body=$(extract_body_from_command "$command")
        if [[ -n "$body" && "$body" != "$command" ]]; then
            validate_pr_title_typed "$command"
        else
            validate_pr_title_exploratory "$command"
        fi
        print_exploratory_rules
    elif is_implementation_branch "$branch_name"; then
        validate_pr_body_format "$command"
        validate_pr_title_typed "$command"
        print_implementation_rules "$branch_name"
    else
        validate_pr_body_format "$command"
        validate_pr_title_typed "$command"
        print_standard_create_rules
    fi

    exit 0
}

get_first_commit_date() {
    git log main..HEAD --reverse --format="%ad" --date=format:"%Y-%m-%d" 2>/dev/null | head -n 1
}

output_json() {
    local context="$1"
    jq -n --arg context "$context" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "allow",
        "additionalContext": $context
      }
    }'
}

print_exploratory_rules() {
    local first_date
    first_date=$(get_first_commit_date)

    local rules
    rules=$(cat << EOF
## PR Creation Rules (Exploratory Branch)

This is an exploratory branch. Choose one of the following:

### Option A: Minimal (no description yet)
**Title**: \`since ${first_date:-YYYY-MM-DD}\`
**Body**: empty
**Options**: --draft

### Option B: With description (when commits already exist)
Follow the standard PR format:

$(print_full_template)

$(print_labels_rules)

**Options**: --draft
EOF
)
    output_json "$rules"
}

print_implementation_rules() {
    local branch="$1"

    local rules
    rules=$(cat << EOF
## PR Creation Rules (Implementation Branch)

$(print_related_plan_section "$branch")
$(print_full_template)

$(print_labels_rules)

### Options
Always use: --draft
EOF
)
    output_json "$rules"
}

print_standard_create_rules() {
    local rules
    rules=$(cat << EOF
## PR Creation Rules (Standard Branch)

$(print_full_template)

$(print_labels_rules)

### Options
Always use: --draft
EOF
)
    output_json "$rules"
}

main
