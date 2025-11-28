---
name: git-commit
description: Format staged files and create git commit with conventional commit message
---

# Git Commit Skill

Analyzes staged changes and creates a git commit with a properly formatted conventional commit message.

## Instructions

- Analyze staged changes using analyze-staged-changes.sh
- Determine commit type (feat, fix, refactor, docs, test, chore, etc.)
- Extract scope from file paths if applicable
- Generate conventional commit message (type(scope): description)
- Keep commit message on a single line
- Use git-commit.sh to create the commit

## Usage

```bash
bash git-commit.sh "feat(auth): add login functionality"
```

The script will:
- Format staged files automatically
- Validate git repository and staged changes
- Create commit with provided message
- Display commit hash and summary

