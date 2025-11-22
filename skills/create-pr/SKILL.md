---
name: create-pr
description: Create draft pull request from current branch with automatic title based on first commit date
---

# Create PR Skill

Creates a draft pull request for the current branch with title derived from the first commit date.

## Instructions

1. Verify not on main branch
2. Check for uncommitted changes
3. Push current branch to remote
4. Get first commit date from branch history
5. Create draft PR with title "since YYYY-MM-DD"

## Usage

```bash
bash create-pr-auto.sh
```

The script will:
- Validate current branch
- Push to origin with upstream tracking
- Create draft PR automatically
- Return PR URL
