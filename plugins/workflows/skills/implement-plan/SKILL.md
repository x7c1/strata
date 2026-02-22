---
description: Implement features according to a plan document, then create branch, commit, push, and PR
argument-hint: <plan-path>
---

# Implement Plan Skill

Implements features according to a specified plan document, then automates the git workflow including branch creation, commit, push, and pull request creation.

## Arguments

- `$0`: Path to the plan document (e.g., `docs/plans/2026/001-add-feature/README.md`)

## Instructions

- Read and understand the plan document at the specified path
- If on the main branch, create a new branch based on the plan directory name (see Branch Naming Convention)
- Implement all items specified in the plan document
- After implementation is complete:
  - Stage all relevant changes
  - Create a commit with a descriptive message summarizing the implementation
  - Push the branch to remote
  - Create a pull request with summary of changes

## Branch Naming Convention

The branch name is derived from the plan path. Use `feature/` for new features and enhancements, `fix/` for bug fixes.

### Top-Level Plans

- Plan path: `docs/plans/2026/001-add-feature/README.md`
- Branch name: `feature/2026-1-add-feature`

### Sub-Plans

Sub-plan branches use `{year}-{parent-number}` as prefix, followed by the sub-plan's `{number}-{description}`:

- Plan path: `docs/plans/2026/017-licensing/plans/001-payment-flow/README.md`
- Branch name: `feature/2026-17/1-payment-flow`

### Deeper Nesting

Intermediate parents use their number only; the last segment (target plan) includes the description:

- Plan path: `docs/plans/2026/017-licensing/plans/001-payment-flow/plans/002-validation/README.md`
- Branch name: `feature/2026-17/1/2-validation`

- Plan path: `docs/plans/2026/017-licensing/plans/001-payment-flow/plans/002-validation/plans/001-edge-case/README.md`
- Branch name: `feature/2026-17/1/2/1-edge-case`

## Workflow

- **Step 1: Read Plan**
  - Parse the plan document
  - Identify all implementation tasks
  - Understand the scope and requirements
  - If this is a sub-plan, also read the parent plan for context

- **Step 2: Branch**
  - If on the main branch: pull latest, then create a new branch following the naming convention above and switch to it
  - If on a feature branch:
    - Check if the branch has a PR that is merged (`gh pr view --json state -q '.state'`)
    - If merged: checkout main, pull latest, then create a new branch and switch to it
    - If not merged (open/draft): stay on the current branch (implementation continues on the existing branch)

- **Step 3: Implement**
  - Follow the plan document step by step
  - Implement all required changes
  - Run build and tests to verify (check the project's CLAUDE.md for specific commands)

- **Step 4: Update Plan Status**
  - Change the plan's `Status:` line from `Open` to `Completed`
  - If the plan has no `Status:` line, add `Status: Completed` immediately after the `#` heading

- **Step 5: Commit**
  - Stage all changes related to the implementation
  - Create a commit with message describing what was implemented

- **Step 6: Push**
  - Push the branch to origin

- **Step 7: Create Pull Request**
  - Create PR using `gh pr create`
  - Include summary of implemented features
  - Reference the plan document in PR description

## Example Usage

Top-level plan:
```
/implement-plan docs/plans/2026/001-add-dark-mode/README.md
```

Sub-plan:
```
/implement-plan docs/plans/2026/017-licensing/plans/001-payment-flow/README.md
```

## Notes

- Requires GitHub CLI (gh) to be installed and authenticated
- The plan document should follow the standard README.md format
- Always run tests before committing to ensure implementation is correct
