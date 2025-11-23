# Add Submodule Support to new-github-repo Skill

## Overview
Add automatic git submodule integration to the `new-github-repo` skill to include `x7c1/strata` as a submodule at `vendor/strata` in all newly created repositories.

## Background
The `new-github-repo` skill currently creates repositories with infrastructure files (Dockerfile, docker-compose.yml, Makefile, scripts). The SKILL.md documentation already mentions that "Templates assume vendor/strata submodule will be added to the repository", but this functionality is not yet implemented. This feature will automate the submodule setup process.

## Requirements

### Functional Requirements
- Automatically add `x7c1/strata` as a git submodule during repository creation
- Place submodule at `vendor/strata` path
- Initialize submodule automatically (`git submodule update --init`)
- Feature is always enabled (no configuration needed)
- Submodule should be included in the initial commit

### Technical Requirements
- Integrate into existing `create_initial_files` function in `new-github-repo.sh`
- Add submodule after infrastructure files are copied
- Ensure proper error handling for git submodule commands
- Maintain compatibility with existing infrastructure setup

### Non-functional Requirements
- Should not break existing repository creation flow
- Should handle network failures gracefully
- Should provide clear debug messages for submodule operations

## Implementation Plan

### Phase 1: Add Submodule Functionality
- Modify `create_initial_files` function in `skills/new-github-repo/new-github-repo.sh`
- Add `add_submodule` helper function to encapsulate submodule logic
- Add git submodule commands after infrastructure files are copied
- Include submodule in initial commit

### Phase 2: Error Handling
- Add error checking for git submodule commands
- Add debug messages for each submodule operation
- Handle potential network failures when cloning submodule

### Phase 3: Testing
- Test repository creation with submodule
- Verify submodule is properly initialized
- Verify submodule is included in initial commit
- Test error scenarios (network failure, invalid repository)

### Phase 4: Documentation
- Update SKILL.md to reflect implemented submodule functionality
- Update usage examples if needed

## Implementation Details

### Code Changes
- File: `skills/new-github-repo/new-github-repo.sh`
- Function to modify: `create_initial_files`
- New function to add: `add_submodule`

### Submodule Configuration
- Repository: `git@github.com:x7c1/strata.git`
- Path: `vendor/strata`
- Initialization: Automatic (`git submodule update --init`)

### Integration Point
Add submodule after line 307 (after `copy_infrastructure_files`) and before line 310 (before `git add .`):

```bash
# Copy infrastructure files
copy_infrastructure_files "$temp_dir"

# Add strata submodule
add_submodule

# Commit all files
git add .
```

## Timeline (Estimates in Points)

- Phase 1: 3 points
  - Implement `add_submodule` function
  - Integrate into `create_initial_files`
- Phase 2: 2 points
  - Add error handling
  - Add debug messages
- Phase 3: 2 points
  - Manual testing
  - Error scenario testing
- Phase 4: 1 point
  - Update documentation

**Total: 8 points**

## Risks and Mitigation

### Risk: Network Failures
- **Mitigation**: Add proper error handling and retry logic for git submodule commands

### Risk: Breaking Existing Functionality
- **Mitigation**: Thorough testing of existing repository creation flow

### Risk: Submodule Repository Access Issues
- **Mitigation**: Verify x7c1/strata repository is publicly accessible

## Success Criteria
- New repositories automatically include `vendor/strata` submodule
- Submodule is fully initialized after repository creation
- No breaking changes to existing functionality
- Clear error messages when submodule operations fail

## Notes
- This feature assumes the `x7c1/strata` repository is accessible via SSH
- The submodule will be added using SSH URL
- SSH key authentication must be properly configured for git operations
