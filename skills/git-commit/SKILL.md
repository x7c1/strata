---
name: git-commit
description: Format staged files and create git commit with conventional commit message
---

# Git Commit Skill

Analyzes staged changes and automatically creates a git commit with a properly formatted conventional commit message.

## Instructions

1. Run format-staged-files.sh to format staged files:
   - Removes trailing whitespace from text files (except markdown)
   - Ensures files end with newline characters
   - Re-stages modified files
2. Analyze git diff --cached to understand changes
3. Generate conventional commit message (type(scope): description)
4. Execute git commit

## Usage

```bash
bash format-staged-files.sh
```

The script will:
- Process all staged files
- Update formatting as needed
- Report modified files
