---
description: Implement features according to a plan document, then create branch, commit, push, and PR
argument-hint: <plan-path>
---

# Implement Plan Skill

Implements features according to a specified plan document, then automates the git workflow including branch creation, commit, push, and pull request creation.

## Arguments

- `$0`: Path to the plan document (e.g., `docs/plans/2026/1-add-feature/README.md`)

## Instructions

- Read and understand the plan document at the specified path
- Create a new branch based on the plan directory name
  - Branch naming: `feature/<year>-<number>-<description>` or `fix/<year>-<number>-<description>`
  - Use `feature/` for new features, enhancements
  - Use `fix/` for bug fixes
- Implement all items specified in the plan document
- After implementation is complete:
  - Stage all relevant changes
  - Create a commit with a descriptive message summarizing the implementation
  - Push the branch to remote
  - Create a pull request with summary of changes

## Branch Naming Convention

The branch name is derived from the plan path:
- Plan path: `docs/plans/2026/1-add-feature/README.md`
- Branch name: `feature/2026-1-add-feature` or `fix/2026-1-add-feature`

## Workflow

- **Step 1: Read Plan**
  - Parse the plan document
  - Identify all implementation tasks
  - Understand the scope and requirements

- **Step 2: Create Branch**
  - Extract year and directory name from plan path
  - Determine branch type based on plan content (feature or fix)
  - Create branch with format `feature/<year>-<number>-<description>` or `fix/<year>-<number>-<description>`
  - Switch to the new branch

- **Step 3: Implement**
  - Follow the plan document step by step
  - Implement all required changes
  - Run build and tests to verify (check the project's CLAUDE.md for specific commands)

- **Step 4: Commit**
  - Stage all changes related to the implementation
  - Create a commit with message describing what was implemented

- **Step 5: Push**
  - Push the branch to origin

- **Step 6: Create Pull Request**
  - Create PR using `gh pr create`
  - Include summary of implemented features
  - Reference the plan document in PR description

## Example Usage

```
/implement-plan docs/plans/2026/1-add-dark-mode/README.md
```

This will:
- Read the plan at `docs/plans/2026/1-add-dark-mode/README.md`
- Create branch `feature/2026-1-add-dark-mode`
- Implement the dark mode feature as specified
- Commit, push, and create a PR

## Notes

- Requires GitHub CLI (gh) to be installed and authenticated
- The plan document should follow the standard README.md format
- Always run tests before committing to ensure implementation is correct
