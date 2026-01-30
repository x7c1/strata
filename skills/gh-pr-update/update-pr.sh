#!/bin/bash
# scripts/update-pr.sh

json_file="$1"

# Check required argument
if [ -z "$json_file" ]; then
    echo "Usage: $0 <json_file>"
    exit 1
fi

if [ ! -f "$json_file" ]; then
    echo "Error: File not found: $json_file"
    exit 1
fi

# Parse JSON
pr_number=$(jq -r '.pr_number' "$json_file")
title=$(jq -r '.title' "$json_file")
description=$(jq -r '.description' "$json_file")
labels=$(jq -r '.labels // [] | join(",")' "$json_file")

# Validate required fields
if [ -z "$pr_number" ] || [ "$pr_number" = "null" ]; then
    echo "Error: pr_number is required"
    exit 1
fi

if [ -z "$title" ] || [ "$title" = "null" ]; then
    echo "Error: title is required"
    exit 1
fi

if [ -z "$description" ] || [ "$description" = "null" ]; then
    echo "Error: description is required"
    exit 1
fi

# Check title length limit (60 characters)
if [ ${#title} -gt 60 ]; then
    echo "Error: Title exceeds 60 characters (${#title}): $title"
    exit 1
fi

# Check for unnecessary content in description
forbidden_patterns=(
    "Files Added"
    "Files Modified"
    "Files Changed"
    "Generated with"
)
for pattern in "${forbidden_patterns[@]}"; do
    if echo "$description" | grep -q "$pattern"; then
        echo "Error: Description contains unnecessary '$pattern' section - please remove it"
        exit 1
    fi
done

# Update PR
gh pr edit "$pr_number" --title "$title" --body "$description"
if [ -n "$labels" ]; then
    gh pr edit "$pr_number" --add-label "$labels"
fi

echo "PR #$pr_number updated successfully"
echo "Title: $title (${#title} characters)"
