---
description: Check the current git status of local repositories. Use when you need to understand the current state of repositories (branch, uncommitted changes, recent commits, remote sync).
argument-hint: "<path> [<path> ...]"
---

# Check Repository Status

## Instructions

- Run `check-repo-status.sh` with the provided repository paths
- Report the results to the user, highlighting:
  - Current branch and whether it's an exploratory or feature branch
  - Any uncommitted changes
  - How far ahead/behind the remote the local branch is
  - Notable recent commits

## Usage

```bash
bash check-repo-status.sh $ARGUMENTS
```
