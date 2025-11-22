---
name: new-github-repo
description: Create new GitHub repository with infrastructure setup and configuration
---

# New GitHub Repository Skill

Creates a new GitHub repository with predefined settings, branch protection rules, and infrastructure setup (Dockerfile, docker-compose.yml, Makefile).

## Instructions

1. Create YAML configuration file with repository settings
2. Before running the script, prepare Dockerfile from template:
   - Check latest Rust version: https://hub.docker.com/_/rust
   - Check latest Node.js LTS version: https://nodejs.org/
   - Copy templates/Dockerfile.template and replace placeholders:
     - Replace `<RUST_VERSION>` with latest stable version (e.g., 1.83)
     - Replace `<NODEJS_VERSION>` with latest LTS version (e.g., 22)
   - Save as Dockerfile (temporary file for this execution)
3. Run new-github-repo.sh with configuration file path
4. Script will:
   - Create GitHub repository
   - Copy infrastructure files (Dockerfile, docker-compose.yml, Makefile)
   - Copy scripts/install-ubuntu-deps.sh
   - Create initial commit with all files
   - Configure repository settings
   - Apply branch protection rules

## Usage

Create configuration file (example.yaml):
```yaml
name: my-repo
description: My new repository
visibility: public
default_branch: main
delete_branch_on_merge: true
merge_methods:
  allow_squash_merge: true
  allow_merge_commit: false
  allow_rebase_merge: false
branch_protection:
  required_approving_review_count: 1
  require_status_checks: true
  allow_force_pushes: false
  enforce_admins: true
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
- Templates assume vendor/strata submodule will be added to the repository
- Repository created with initial commit containing infrastructure files
