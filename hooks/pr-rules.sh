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
    local plan_id
    plan_id=$(get_plan_identifier "$branch")

    cat << EOF
### Related Plan
This branch implements plan \`$plan_id\`.
Include in PR body:
\`\`\`
Related: plan/$plan_id
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
### Labels
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
