---
description: Check CI, auto-fix trivial failures, squash merge, and update local main
argument-hint: [pr-number]
---

# Merge PR Skill

Checks CI status, auto-fixes trivial failures (formatter, linter), squash merges the PR, and updates the local main branch.

## Arguments

- `$0`: PR number (optional)
  - If not provided, uses the PR associated with the current branch

## Instructions

- Determine the target PR from argument or current branch
- Run `gh pr checks` to get CI status
- If all checks pass, proceed to merge
- If any checks are pending, wait with `gh pr checks --watch`
- If any checks fail:
  - Fetch failure logs using `gh run view <run-id> --log-failed`
  - Determine failure category from the log output:
    - **Trivial** (formatter, linter, style checks): auto-fix and continue
    - **Non-trivial** (test failures, build errors, type errors): abort
  - For trivial failures:
    - Run `/fix-ci` to apply the fix
    - Wait for CI to pass with `gh pr checks --watch`
    - If CI still fails after the fix attempt, abort with error
  - For non-trivial failures:
    - Show which checks failed with relevant log excerpts
    - Suggest running `/fix-ci` manually
    - Abort
- Once all checks pass:
  - Run `gh pr merge --squash` to merge
  - Run `git checkout main` to switch to main
  - Run `git pull` to update local main
  - Run `git branch -d <branch>` to delete the merged branch

## Commands

```bash
# Check CI status
gh pr checks
gh pr checks <pr-number>

# Wait for pending checks
gh pr checks --watch

# View failed run logs
gh run view <run-id> --log-failed

# Squash merge
gh pr merge --squash
gh pr merge <pr-number> --squash

# Update local
git checkout main
git pull
git branch -d <branch-name>
```

## Output Format

### Success

```
## Merge: ✓ Complete

- PR #<number> merged via squash
- Local main updated
- Branch <name> deleted
```

### Non-trivial CI failure (abort)

```
## Merge: ✗ CI Failing

<failed checks with log excerpts>

The failures require manual investigation. Run `/fix-ci` to diagnose.
```

### Trivial CI fix attempted but still failing

```
## Merge: ✗ CI Still Failing

/fix-ci was run but checks are still failing after the fix attempt.

<failed checks list>
```

## Example Usage

```
/merge-pr
```

Or with a specific PR:

```
/merge-pr 30
```
