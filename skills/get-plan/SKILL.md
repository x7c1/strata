---
description: Get README.md path from current branch name
---

# Get Plan Skill

Identifies and returns the README.md file path based on the current branch name.

## Instructions

- Run `get-plan.sh` to get the README.md path for the current branch
- If the branch is a plan branch, read the README.md file
- If not a plan branch (exploratory), inform the user

## Usage

```bash
bash get-plan.sh
```

## Branch to Plan Mapping

| Branch Format | Plan Path |
|---------------|-----------|
| `plan/<year>-<number>-<description>` | `docs/plans/<year>/<number>-<description>/README.md` |
| `YYYY-MM-DD_HHMM` | No plan (exploratory branch) |

## Examples

| Branch | Plan Path |
|--------|-----------|
| `plan/2026-1-add-dark-mode` | `docs/plans/2026/1-add-dark-mode/README.md` |
| `plan/2026-12-refactor-auth` | `docs/plans/2026/12-refactor-auth/README.md` |
| `2026-01-31_1400` | (none) |
