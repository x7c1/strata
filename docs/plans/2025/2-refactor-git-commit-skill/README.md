# Refactor git-commit Skill to Use Shell Script Execution

## Overview
Refactor the `skills/git-commit` skill to follow the same pattern as `skills/create-pr` by implementing the core logic in a shell script (`git-commit.sh`) that can be executed directly.

## Background
- The current `git-commit/SKILL.md` was migrated from commands
- It contains instructions for Claude to execute manually rather than a self-contained script
- The `create-pr` skill provides a good reference pattern with `create-pr-auto.sh`
- Existing helper scripts (`format-staged-files.sh`, `ensure-newline.sh`, `remove-trailing-whitespace.sh`) are already available

## Goals
- Create a self-contained `git-commit.sh` script that handles the entire commit workflow
- Integrate existing formatting scripts into the commit process
- Update `SKILL.md` to provide clear, skill-appropriate instructions
- Follow the same execution pattern as `create-pr` skill

## Current State
The `skills/git-commit/` directory contains:
- `SKILL.md` - Instructions for Claude to execute manually
- `format-staged-files.sh` - Formats staged files
- `ensure-newline.sh` - Ensures files end with newline
- `remove-trailing-whitespace.sh` - Removes trailing whitespace

## Implementation Plan

### Create git-commit.sh Script
- Create executable script that accepts commit message as argument
- Include colored output functions (print_error, print_success, print_info)
- Add git repository validation
- Integrate formatting step using existing `format-staged-files.sh`
- Execute git commit with provided message
- Add proper error handling and validation

### Script Workflow
- Accept commit message as command-line argument
- Validate commit message (check for forbidden patterns)
- Verify we're in a git repository
- Check if there are staged changes
- Run `format-staged-files.sh` to format staged files
- Execute `git commit` with the provided message
- Report success with commit hash

### Update SKILL.md
- Claude should analyze staged changes and generate commit message
- Claude then calls the script with the generated message
- Use bullet points for instructions for easy maintenance
- Keep description clear and skill-appropriate
- Document the two-step process: analyze then commit

### Conventional Commit Message Generation (by Claude)
- Claude analyzes staged changes to determine commit type (feat, fix, refactor, docs, etc.)
- Claude extracts scope from file paths if applicable
- Claude generates concise description
- Claude follows conventional commit format: `type(scope): description`
- Generated message is passed to git-commit.sh script

## Technical Considerations
- The script should integrate seamlessly with existing formatting scripts
- Error handling should provide clear feedback
- The script should fail gracefully if no changes are staged
- Conventional commit message generation should be deterministic and follow best practices
- The script should be executable and follow bash best practices
- Forbidden pattern validation (similar to update-pr.sh) prevents unnecessary content in commit messages

## Testing Plan
- Test with various staged changes (new files, modifications, deletions)
- Verify formatting scripts are executed correctly
- Ensure conventional commit messages are generated appropriately
- Test error cases (no staged changes, not in git repo, etc.)
- Verify the script works in CI/CD environments

## Success Criteria
- `git-commit.sh` executes the entire commit workflow autonomously
- Formatting is applied before commit
- Conventional commit messages are generated correctly
- `SKILL.md` provides clear, skill-appropriate instructions
- The skill follows the same pattern as `create-pr`

## References
- `skills/create-pr/create-pr-auto.sh` - Reference implementation pattern
- `skills/git-commit/format-staged-files.sh` - Existing formatting logic
- Conventional Commits specification: https://www.conventionalcommits.org/
