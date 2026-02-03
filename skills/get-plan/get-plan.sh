#!/bin/bash

# Get README.md path from current branch name

set -euo pipefail

main() {
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")

    if [[ -z "$branch" ]]; then
        echo "Error: Not in a git repository or no branch checked out" >&2
        exit 1
    fi

    if is_plan_branch "$branch"; then
        get_plan_path "$branch"
    else
        echo "No plan associated with branch: $branch"
        echo "This appears to be an exploratory branch."
        exit 0
    fi
}

is_plan_branch() {
    local branch="$1"
    [[ "$branch" =~ ^plan/ ]]
}

get_plan_path() {
    local branch="$1"
    local plan_part year number_and_desc plan_path

    # Remove "plan/" prefix
    plan_part="${branch#plan/}"

    # Extract year (first part before -)
    year="${plan_part%%-*}"

    # Extract number-description (everything after year-)
    number_and_desc="${plan_part#*-}"

    # Build path: docs/plans/<year>/<number>-<description>/README.md
    plan_path="docs/plans/${year}/${number_and_desc}/README.md"

    if [[ -f "$plan_path" ]]; then
        echo "$plan_path"
    else
        echo "Plan path: $plan_path"
        echo "Warning: File does not exist" >&2
        exit 1
    fi
}

main
