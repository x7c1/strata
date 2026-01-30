---
description: Create draft pull request from current branch with automatic title based on first commit date
context: fork
---

# Create PR Skill

Creates a draft pull request for the current branch with title derived from the first commit date.

## Instructions

- Verify not on main branch
- Check for uncommitted changes
- Push current branch to remote
- Get first commit date from branch history
- Create draft PR with title "since YYYY-MM-DD"

## Usage

```bash
bash create-pr-auto.sh
```

The script will:
- Validate current branch
- Push to origin with upstream tracking
- Create draft PR automatically
- Return PR URL
