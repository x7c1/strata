---
description: Get README.md path from current branch name
---

# Get Plan Skill

Identifies and returns the README.md file path based on the current branch name. Supports top-level plans and nested sub-plans.

## Instructions

- Run `get-plan.sh` to get the README.md path for the current branch
- If the branch is a plan branch, read the README.md file
- If not a plan branch (exploratory), inform the user

## Usage

```bash
bash get-plan.sh
```

## Branch to Plan Mapping

Recognized branch prefixes: `plan/`, `feature/`, `fix/`

### Top-Level Plans

| Branch Format | Plan Path |
|---------------|-----------|
| `{prefix}{year}-{number}-{description}` | `docs/plans/{year}/{number}-{description}/README.md` |

### Sub-Plans (Nested)

| Branch Format | Plan Path |
|---------------|-----------|
| `{prefix}{year}-{number}/{sub-number}-{sub-desc}` | `docs/plans/{year}/{number}-*/plans/{sub-number}-{sub-desc}/README.md` |
| `{prefix}{year}-{number}/{sub-number}/{subsub-number}-{desc}` | `docs/plans/{year}/{number}-*/plans/{sub-number}-*/plans/{subsub-number}-{desc}/README.md` |

- Only the last segment (the target plan) includes the description; all intermediate segments use the number only
- The script resolves each number to the full directory name by matching `{number}-*`
- Nesting depth is unlimited

### Non-Plan Branches

| Branch Format | Plan Path |
|---------------|-----------|
| `YYYY-MM-DD_HHMM` | No plan (exploratory branch) |

## Examples

| Branch | Plan Path |
|--------|-----------|
| `plan/2026-1-add-dark-mode` | `docs/plans/2026/1-add-dark-mode/README.md` |
| `feature/2026-12-refactor-auth` | `docs/plans/2026/12-refactor-auth/README.md` |
| `feature/2026-17/1-payment-flow` | `docs/plans/2026/17-subscription-licensing/plans/1-payment-flow/README.md` |
| `feature/2026-17/1/2-validation` | `docs/plans/2026/17-subscription-licensing/plans/1-payment-flow/plans/2-validation/README.md` |
| `fix/2026-17/1/2/1-edge-case` | `docs/plans/2026/17-subscription-licensing/plans/1-payment-flow/plans/2-validation/plans/1-edge-case/README.md` |
| `2026-01-31_1400` | (none) |
