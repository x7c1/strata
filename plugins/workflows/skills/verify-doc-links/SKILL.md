---
description: Verify that relative links in Markdown files resolve to existing targets and that files end with a newline. Use when checking documentation quality or before committing docs changes.
argument-hint: "<file_or_dir> [<file_or_dir> ...]"
---

# Verify Documentation Links

## Instructions

- Run `verify-doc-links.sh` with the provided file paths or directories (directories are recursively expanded to `*.md` files)
- Report the results to the user, highlighting:
  - Broken relative links (target file/directory does not exist)
  - Files missing a trailing newline
- If no arguments are provided, ask the user which directory to check (e.g., `docs/`)

## Usage

```bash
bash verify-doc-links.sh $ARGUMENTS
```
