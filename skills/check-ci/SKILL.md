---
description: Check CI status for a pull request and help diagnose failures
argument-hint: [pr-number]
---

# Check CI Skill

Checks CI status for a pull request and helps diagnose any failures.

## Arguments

- `$0`: PR number (optional)
  - If not provided, uses the PR associated with the current branch

## Instructions

- Determine the target PR from argument or current branch
- Run `gh pr checks` to get CI status
- If all checks pass, report success
- If any checks fail:
  - Show which checks failed
  - Fetch failure logs using `gh run view`
  - Analyze the error and suggest fixes
  - Offer to implement the fix if appropriate

## Commands

```bash
# Check CI status for current branch's PR
gh pr checks

# Check CI status for specific PR
gh pr checks <pr-number>

# View details of a specific run
gh run view <run-id>

# View logs of a failed run
gh run view <run-id> --log-failed
```

## Output Format

### All Checks Passing

```
## CI Status: ✓ All Checks Passing

All CI checks have passed successfully.
```

### Checks Failing

```
## CI Status: ✗ Checks Failing

### Failed Checks

- [check-name]: [status]
  - Error: [brief error description]
  - Log: [relevant log excerpt]

### Analysis

[Explanation of what went wrong]

### Suggested Fix

[How to fix the issue]
```

## Example Usage

```
/check-ci
```

Or with a specific PR:

```
/check-ci 42
```
