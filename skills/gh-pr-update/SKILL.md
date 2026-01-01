---
name: strata-gh-pr-update
description: Update current branch's pull request title and description based on commit history
---

# Update PR Skill

Identifies the current branch's pull request and updates its title and description based on recent commit history.

## Instructions

- Use get-current-branch-pr.sh to find PR number for current branch
- Analyze commit history to understand changes
- Generate title and description following the Description Format and Constraints sections below
- Determine appropriate labels following the Labels section below
- Use update-pr.sh to update the PR with title, description, and labels

## Usage

Get current PR:
```bash
bash get-current-branch-pr.sh
```

Update PR:
```bash
bash update-pr.sh <pr_number> <title> <description> [labels]
```

## Description Format

Generate PR descriptions in this format:

```markdown
## New Features
- [ ] Feature description
- [ ] Another feature

## Bug Fixes
- [ ] Bug fix description

## Refactoring
- Refactoring description

## Breaking Changes
- Breaking change description
```

**Rules:**
- Use checkboxes (`- [ ]`) for New Features and Bug Fixes
- Use regular bullets (`-`) for Refactoring and Breaking Changes
- Skip sections with no items
- Keep descriptions concise and casual
- Extract info from commit messages to categorize changes

## Labels

Choose appropriate labels based on the type of changes:
- `enhancement` - New features or improvements
- `bug` - Bug fixes
- `documentation` - Documentation changes

## Constraints

- Title must not exceed 60 characters
- Description must not contain "Files Added", "Files Modified", "Generated with" sections
