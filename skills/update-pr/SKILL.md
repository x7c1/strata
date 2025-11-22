---
name: update-pr
description: Update current branch's pull request title and description based on commit history
---

# Update PR Skill

Identifies the current branch's pull request and updates its title and description based on recent commit history.

## Instructions

1. Use get-current-branch-pr.sh to find PR number for current branch
2. Analyze commit history to understand changes
3. Generate appropriate title (max 60 characters) and description
4. Use update-pr.sh to update the PR

## Usage

Get current PR:
```bash
bash get-current-branch-pr.sh
```

Update PR:
```bash
bash update-pr.sh <pr_number> <title> <description> [labels]
```

## Notes

- Title must not exceed 60 characters
- Description must not contain "Files Added", "Files Modified", "Generated with" sections
