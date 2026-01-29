---
name: git-commit
description: Format staged files and create git commit with conventional commit message
context: fork
disable-model-invocation: true
---

# Git Commit Skill

Analyzes staged changes and creates a git commit with a properly formatted conventional commit message.

## Instructions

When this skill is invoked, follow these steps in order:

- **Step 1**: Run `analyze-staged-changes.sh` to view the staged changes
- **Step 2**: Analyze the output to understand what was changed
- **Step 3**: Determine the appropriate commit type (feat, fix, refactor, docs, test, chore, etc.)
- **Step 4**: Extract scope from file paths or changed functionality if applicable
- **Step 5**: Generate a conventional commit message: `type(scope): description`
  - Keep the message on a single line
  - Make it descriptive but concise
- **Step 6**: Run `git-commit.sh "your-commit-message"` with the generated message as an argument

**IMPORTANT**: The `git-commit.sh` script REQUIRES a commit message argument. Never run it without a message.

## Usage Example

```bash
# Step 1: Analyze changes
bash analyze-staged-changes.sh

# Step 2: Create commit with generated message
bash git-commit.sh "feat(auth): add login functionality"
```

The script will:
- Format staged files automatically
- Validate git repository and staged changes
- Create commit with provided message
- Display commit hash and summary

