---
description: Create new GitHub repository with infrastructure setup and configuration
context: fork
---

# New GitHub Repository Skill

Creates a new GitHub repository with predefined settings, rulesets, and infrastructure setup (Dockerfile, docker-compose.yml, Makefile).

## Instructions

- Determine repository owner by asking the user:
  - Run `gh api user --jq '.login'` to get the authenticated user
  - Run `gh api user/orgs --jq '.[].login'` to list available organizations
  - Present the options (personal account + organizations) and ask the user where to create the repository
  - Set the chosen owner in the `owner` field of the YAML configuration
- Create YAML configuration file with repository settings
- Before running the script, prepare Dockerfile from template:
  - Check latest Rust version: https://hub.docker.com/_/rust
  - Check latest Node.js LTS version: https://nodejs.org/
  - Copy templates/Dockerfile.template and replace placeholders:
    - Replace `<RUST_VERSION>` with latest stable version (e.g., 1.83)
    - Replace `<NODEJS_VERSION>` with latest LTS version (e.g., 22)
  - Save as Dockerfile (temporary file for this execution)
- Run new-github-repo.sh with configuration file path

## Usage

Create configuration file (example.yaml):
```yaml
name: my-repo
owner: my-org
description: My new repository
visibility: public
default_branch: main
delete_branch_on_merge: true
merge_methods:
  allow_squash_merge: true
  allow_merge_commit: false
  allow_rebase_merge: false
ruleset:
  required_approving_review_count: 1
  require_status_checks: true
  status_checks:
    - "ci/build"
  allow_force_pushes: false
```

Run the script:
```bash
bash new-github-repo.sh example.yaml
```

## Template Files

The skill includes the following templates:
- **Dockerfile.template**: Rust + Node.js development environment with Claude Code support
  - Contains placeholders: `<RUST_VERSION>` and `<NODEJS_VERSION>`
  - Skill checks latest versions and generates Dockerfile before repository creation
- **docker-compose.yml**: Docker Compose configuration for Claude Code
- **Makefile**: Common development tasks (claude-setup, claude-run, pr)
- **scripts/install-ubuntu-deps.sh**: Essential Ubuntu dependencies

## Notes

- Requires GitHub CLI (gh) to be installed and authenticated
- Requires yq for YAML parsing
- Automatically adds x7c1/strata as git submodule at vendor/strata
- Repository created with initial commit containing infrastructure files and submodule
- Submodule requires SSH access to git@github.com:x7c1/strata.git
