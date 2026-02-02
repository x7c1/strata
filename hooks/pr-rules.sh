#!/bin/bash

# Shared PR rules for create and update hooks

# Branch detection functions

is_exploratory_branch() {
    local branch="$1"
    # Match YYYY-MM-DD_HHMM format
    [[ "$branch" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}$ ]]
}

is_implementation_branch() {
    local branch="$1"
    # Match feature/ or fix/ branches
    [[ "$branch" =~ ^(feature|fix)/[0-9]{4}-[0-9]+-[a-z0-9-]+$ ]]
}

get_plan_identifier() {
    local branch="$1"
    # Extract the identifier part (e.g., "2026-17-subscription-licensing" from "feature/2026-17-subscription-licensing")
    echo "$branch" | sed -E 's/^(feature|fix)\///'
}

print_related_plan_section() {
    local branch="$1"
    local plan_id year number_and_name repo_url
    plan_id=$(get_plan_identifier "$branch")
    # Extract year (first 4 digits) and the rest (e.g., "2026-17-foo" -> "2026" and "17-foo")
    year=$(echo "$plan_id" | cut -d'-' -f1)
    number_and_name=$(echo "$plan_id" | cut -d'-' -f2-)
    # Get repo URL for absolute links (relative links don't work in PR bodies)
    repo_url=$(gh repo view --json url -q '.url' 2>/dev/null || echo "https://github.com/OWNER/REPO")

    cat << EOF
### Related Section
This branch implements a plan.
Add at the end of PR body:
\`\`\`
## Related
- [plan/$plan_id]($repo_url/tree/main/docs/plans/$year/$number_and_name/)
\`\`\`

EOF
}

# Template functions

print_title_rules() {
    cat << 'EOF'
### Title Format
```
<type>(<scope>): <subject>
```

**Types**: feat, fix, refactor, docs, chore
**Constraints**:
- Max 60 characters
- Lowercase, imperative mood
- No period at end
EOF
}

print_body_rules() {
    cat << 'EOF'
### Body Format
```markdown
## New Features
- [ ] Feature description

## Bug Fixes
- [ ] Bug fix description

## Refactoring
- Refactoring description

## Breaking Changes
- Breaking change description
```

**Rules**:
- Use checkboxes (`- [ ]`) for New Features and Bug Fixes
- Use regular bullets (`-`) for Refactoring and Breaking Changes
- Skip sections with no items
- Keep descriptions concise
EOF
}

print_forbidden_patterns() {
    cat << 'EOF'
### Forbidden Patterns
- "Files Added", "Files Modified", "Files Changed"
- "Generated with"
EOF
}

print_labels_rules() {
    cat << 'EOF'
### Labels (Required)
Add at least one label using `--add-label`:
- `enhancement` - New features or improvements
- `bug` - Bug fixes
- `documentation` - Documentation changes
EOF
}

print_full_template() {
    print_title_rules
    echo ""
    print_body_rules
    echo ""
    print_forbidden_patterns
}

# Validation functions

extract_body_from_command() {
    local command="$1"
    # Extract body content from --body "..." or --body '...'
    # Handle HEREDOC style: --body "$(cat <<'EOF' ... EOF)"
    if echo "$command" | grep -qE -- '--body\s+"?\$\(cat'; then
        # HEREDOC style - extract content between the markers
        echo "$command" | sed -E 's/.*--body\s+"?\$\(cat <<['\''"]?EOF['\''"]?//' | sed -E 's/EOF\s*\)\"?.*//'
    elif echo "$command" | grep -qE -- '--body\s+""'; then
        # Empty body
        echo ""
    else
        # Simple --body "content" style
        echo "$command" | sed -E 's/.*--body\s+["\x27]([^"\x27]*)["\x27].*/\1/' || echo ""
    fi
}

validate_exploratory_pr() {
    local command="$1"
    local body
    body=$(extract_body_from_command "$command")

    # Exploratory PRs must have empty body
    if [[ -n "$body" && "$body" != "$command" ]]; then
        cat >&2 << 'EOF'
ERROR: Exploratory branch PRs must have an empty body.

Use: gh pr create --title "since YYYY-MM-DD" --body "" --draft
EOF
        exit 2
    fi
}

validate_pr_body_format() {
    local command="$1"
    local body
    body=$(extract_body_from_command "$command")

    # Check if body extraction failed (returns original command) or no --body flag
    if [[ "$body" == "$command" ]]; then
        return 0  # Cannot validate, allow
    fi

    # Empty body is not allowed for non-exploratory PRs
    if [[ -z "$body" ]]; then
        cat >&2 << 'EOF'
ERROR: PR body is required.

Required sections (include at least one):
- ## New Features
- ## Bug Fixes
- ## Refactoring
- ## Breaking Changes
EOF
        exit 2
    fi

    # Check for valid section headers
    local valid_sections="## New Features|## Bug Fixes|## Refactoring|## Breaking Changes"
    if ! echo "$body" | grep -qE "$valid_sections"; then
        cat >&2 << 'EOF'
ERROR: PR body must contain at least one valid section header.

Required format:
## New Features
- [ ] Feature description

## Bug Fixes
- [ ] Bug fix description

## Refactoring
- Refactoring description

## Breaking Changes
- Breaking change description

Do NOT use: ## Summary, ## Test plan, or other custom headers.
EOF
        exit 2
    fi

    # Check for forbidden patterns
    local forbidden_patterns=("Summary" "Test plan" "Files Added" "Files Modified" "Files Changed" "Generated with")
    for pattern in "${forbidden_patterns[@]}"; do
        if echo "$body" | grep -qi "## $pattern"; then
            cat >&2 << EOF
ERROR: PR body contains forbidden section header: "## $pattern"

Use the required sections instead:
- ## New Features
- ## Bug Fixes
- ## Refactoring
- ## Breaking Changes
EOF
            exit 2
        fi
        if [[ "$pattern" != "Summary" && "$pattern" != "Test plan" ]] && echo "$body" | grep -qi "$pattern"; then
            echo "ERROR: PR body contains forbidden pattern: '$pattern'" >&2
            exit 2
        fi
    done
}
