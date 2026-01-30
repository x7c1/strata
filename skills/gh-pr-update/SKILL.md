---
description: Update current branch's pull request title and description based on commit history
context: fork
---

# Update PR Skill

Identifies the current branch's pull request and updates its title and description based on recent commit history.

## Instructions

- Use get-current-branch-pr.sh to find PR number for current branch
- Analyze commit history to understand changes
- Generate title and description following the Title Format, Description Format, and Constraints sections below
- Determine appropriate labels following the Labels section below
- Create a JSON file with pr_number, title, description, and labels
- Use update-pr.sh with the JSON file path to update the PR

## Usage

Get current PR:
```bash
bash get-current-branch-pr.sh
```

Update PR:
```bash
bash update-pr.sh <json_file>
```

JSON file format:
```json
{
  "pr_number": 28,
  "title": "feat(ci): improve release PR workflow",
  "description": "## New Features\n- [ ] Add feature...",
  "labels": ["enhancement"]
}
```

**Fields:**
- `pr_number` (required): PR number to update
- `title` (required): PR title
- `description` (required): PR body in markdown
- `labels` (optional): Array of label names to add

## Title Format

Generate PR titles following conventional commit format:

```
<type>(<scope>): <subject>
```

**Types:**
- `feat` - New features
- `fix` - Bug fixes
- `refactor` - Code refactoring
- `docs` - Documentation changes
- `chore` - Maintenance tasks

**Rules:**
- Scope is optional but recommended
- Subject should be lowercase and imperative mood
- No period at the end

**Examples:**
- `feat(auth): add login with Google`
- `fix(api): handle null response`
- `refactor: simplify navigation logic`

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

- Title must follow conventional commit format
- Title must not exceed 60 characters
- Description must not contain "Files Added", "Files Modified", "Generated with" sections

