# Add merge-pr skill

Status: Draft

## Overview

Add a `/merge-pr` skill to the workflows plugin that checks PR CI status, automatically fixes CI failures via `/fix-ci`, merges via squash, and updates the local main branch in a single operation.

## Background

After PR review, the merge workflow is always the same: check CI, squash merge, checkout main, pull, delete the branch. Running these steps manually is tedious and error-prone. Combining them into one skill eliminates missed steps and wasted time.

## Implementation

### Skill definition

- Skill name: `merge-pr`
- Location: `plugins/workflows/skills/merge-pr/SKILL.md`
- Argument: PR number (optional, defaults to current branch's PR)

### Flow

- Run `gh pr checks` to verify CI status
- If any check is failing:
  - Fetch failure logs with `gh run view <run-id> --log-failed`
  - Determine failure category from the log output:
    - **Trivial failures** (formatter, linter, etc.): auto-fix and continue to merge
    - **Non-trivial failures** (test failures, build errors, etc.): abort and report
  - For trivial failures:
    - Run `/fix-ci` to apply the fix
    - Wait for CI to pass (`gh pr checks --watch`)
    - If CI still fails after fix, abort with error
  - For non-trivial failures:
    - Show which checks failed with relevant log excerpts
    - Abort without attempting a fix
- Once all checks pass:
  - Run `gh pr merge --squash` to merge
  - Run `git checkout main && git pull` to update local main
  - Run `git branch -d <branch>` to delete the merged branch

### Output format

Success:
```
## Merge: ✓ Complete

- PR #<number> merged via squash
- Local main updated
- Branch <name> deleted
```

Non-trivial CI failure (abort):
```
## Merge: ✗ CI Failing

<failed checks with log excerpts>

The failures require manual investigation. Run `/fix-ci` to diagnose.
```

Trivial CI fix attempted but still failing:
```
## Merge: ✗ CI Still Failing

/fix-ci was run but checks are still failing after the fix attempt.

<failed checks list>
```

## Out of scope

- Merge conflict resolution
- Merge method selection (squash only)

## Work items

- [ ] Create `plugins/workflows/skills/merge-pr/SKILL.md`
- [ ] Register in plugin configuration if needed
- [ ] Verify with a real PR
