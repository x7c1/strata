# Migrate from Submodule to Marketplace Distribution

Status: Completed

## Overview

Restructure strata from a single-plugin submodule into a multi-plugin marketplace. The strata repository becomes a marketplace that distributes two independent plugins: **workflows** (skills + hooks) and **statusline** (usage display). Consumer repositories declare plugin dependencies in `.claude/settings.json` instead of vendoring strata as a git submodule.

## Background

Strata is currently distributed as a git submodule. Consumer repositories clone it at `vendor/strata/` and load it via `claude --plugin-dir vendor/strata`. All functionality — skills, hooks, and statusline scripts — lives in a flat structure at the repository root.

This approach has drawbacks:
- Every consumer repository must maintain a submodule reference and keep it updated
- `start-claude-code.sh` must pass `--plugin-dir` explicitly
- Docker Compose files must mount strata scripts manually
- Submodule state can drift across repositories
- Statusline is coupled with workflow automation despite being independently useful

Claude Code supports marketplace-based plugin distribution, where a single marketplace can host multiple plugins. Repositories declare plugin dependencies via `extraKnownMarketplaces` and `enabledPlugins` in `.claude/settings.json`, and plugins are installed automatically when a developer trusts the project.

## Target Structure

```
strata/                              ← marketplace root
├── .claude-plugin/
│   └── marketplace.json             ← declares 2 plugins
├── plugins/
│   ├── workflows/                   ← plugin: dev workflow automation
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── hooks/
│   │   │   ├── hooks.json
│   │   │   ├── on-git-commit.sh
│   │   │   ├── on-git-branch.sh
│   │   │   ├── on-git-c-flag.sh
│   │   │   ├── on-gh-pr-create.sh
│   │   │   ├── on-gh-pr-edit.sh
│   │   │   ├── on-file-edit.sh
│   │   │   ├── branch-rules.sh
│   │   │   └── pr-rules.sh
│   │   └── skills/
│   │       ├── new-plan/
│   │       ├── get-plan/
│   │       ├── implement-plan/
│   │       ├── review-plan/
│   │       ├── fix-ci/
│   │       ├── gh-repo-create/
│   │       ├── new-proposals/
│   │       └── review-proposals/
│   └── statusline/                  ← plugin: usage rate display
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── scripts/
│       │   ├── statusline.sh
│       │   ├── platform.sh
│       │   └── poll-usage.sh
│       └── skills/
│           └── setup/
│               └── SKILL.md         ← /statusline:setup
└── docs/
    └── plans/
```

## Requirements

### Functional Requirements
- All existing skills and hooks work identically after migration
- Consumer repositories declare plugin dependencies in `.claude/settings.json`
- Plugins are installed automatically when a developer trusts the project
- Statusline setup is available as `/statusline:setup` (opt-in, writes to `.claude/settings.local.json`)
- `gh-repo-create` bootstraps new repositories with marketplace declaration instead of submodule
- Consumer repositories can enable either or both plugins independently

### Technical Requirements
- Hook scripts use `${CLAUDE_PLUGIN_ROOT}` for path resolution
- Each plugin has its own `.claude-plugin/plugin.json`
- Root `marketplace.json` declares both plugins with relative source paths
- Marketplace entry uses GitHub source (`x7c1/strata`)

### Non-functional Requirements
- Clear migration path for consumer repositories

## Current State

### Repository Structure
- Flat layout: `hooks/`, `skills/`, `.claude-plugin/` at root
- Single `plugin.json` covering everything
- `marketplace.json` uses `"source": "./"` (local, single plugin)

### Hook Path References
All 6 hooks in `hooks/hooks.json` reference scripts via:
```
"$CLAUDE_PROJECT_DIR"/vendor/strata/hooks/<script>.sh
```

### gh-repo-create Templates
- `templates/scripts/start-claude-code.sh` — uses `--plugin-dir vendor/strata`
- `templates/docker-compose.yml` — mounts strata hook files

### Statusline
- `hooks/statusline.sh`, `hooks/platform.sh`, `hooks/poll-usage.sh` — mixed in with hook scripts

## Implementation Plan

### Phase 1: Restructure into Multi-Plugin Layout
- Create `plugins/workflows/` and `plugins/statusline/` directories
- Move hooks and skills into `plugins/workflows/`
- Move statusline scripts into `plugins/statusline/scripts/`
- Create `plugin.json` for each plugin
- Update root `marketplace.json` to declare both plugins:
  ```json
  {
    "plugins": [
      { "name": "workflows", "source": "./plugins/workflows" },
      { "name": "statusline", "source": "./plugins/statusline" }
    ]
  }
  ```
- Move `docs/` and other non-plugin files to remain at repository root

### Phase 2: Update Hook Path References
- Change all 6 hook commands in `hooks.json` from `"$CLAUDE_PROJECT_DIR"/vendor/strata/hooks/<script>` to `${CLAUDE_PLUGIN_ROOT}/hooks/<script>`
- Verify hooks still work with `--plugin-dir` during local development

### Phase 3: Create statusline:setup Skill
- Create `plugins/statusline/skills/setup/SKILL.md`
- The skill locates `statusline.sh` under `~/.claude/plugins/cache/`, resolves its absolute path, and writes the statusline configuration to the project's `.claude/settings.local.json`
- If the plugin is updated and the cache path changes, the user re-runs `/statusline:setup`

### Phase 4: Update gh-repo-create Templates
- Remove submodule addition logic from `new-github-repo.sh` (`add_submodule` function and its call)
- Update `templates/scripts/start-claude-code.sh`:
  - Remove `--plugin-dir` flag; launch `claude` directly
- Update `templates/docker-compose.yml`:
  - Remove strata hook file mounts
- Add `.claude/settings.json` template with marketplace declaration:
  ```json
  {
    "extraKnownMarketplaces": {
      "strata-dev": {
        "source": { "source": "github", "repo": "x7c1/strata" }
      }
    },
    "enabledPlugins": {
      "workflows@strata-dev": true,
      "statusline@strata-dev": true
    }
  }
  ```
- Update SKILL.md to reflect the new setup flow

### Phase 5: Documentation
- Update strata `README.md` with marketplace installation instructions and multi-plugin overview
- Update `CLAUDE.md` if needed
- Remove obsolete root-level `.claude-plugin/plugin.json` (replaced by per-plugin manifests)

## Files to Create

| File | Purpose |
|------|---------|
| `plugins/workflows/.claude-plugin/plugin.json` | Workflows plugin manifest |
| `plugins/statusline/.claude-plugin/plugin.json` | Statusline plugin manifest |
| `plugins/statusline/skills/setup/SKILL.md` | `/statusline:setup` skill |

## Files to Move

Operations are ordered — statusline scripts are extracted first, then the remaining hooks move in bulk.

| Order | From | To | Note |
|-------|------|-----|------|
| 1 | `hooks/statusline.sh` | `plugins/statusline/scripts/statusline.sh` | |
| 2 | `hooks/platform.sh` | `plugins/statusline/scripts/platform.sh` | |
| 3 | `hooks/platform.test.sh` | `plugins/statusline/scripts/platform.test.sh` | Test for `platform.sh` |
| 4 | `hooks/poll-usage.sh` | `plugins/statusline/scripts/poll-usage.sh` | |
| 5 | `hooks/*` (remaining) | `plugins/workflows/hooks/` | Includes helper scripts (`command-detect.sh`, `format-staged-files.sh`) and their tests |
| 6 | `skills/*` | `plugins/workflows/skills/` | |

## Files to Modify

| File | Change |
|------|--------|
| `.claude-plugin/marketplace.json` | Rewrite to declare 2 plugins with relative sources |
| `plugins/workflows/hooks/hooks.json` | Replace `$CLAUDE_PROJECT_DIR/vendor/strata/hooks/` with `${CLAUDE_PLUGIN_ROOT}/hooks/` |
| `plugins/workflows/skills/gh-repo-create/new-github-repo.sh` | Remove `add_submodule` function and call |
| `plugins/workflows/skills/gh-repo-create/SKILL.md` | Remove submodule references, add marketplace setup |
| `plugins/workflows/skills/gh-repo-create/templates/scripts/start-claude-code.sh` | Remove `--plugin-dir` |
| `plugins/workflows/skills/gh-repo-create/templates/docker-compose.yml` | Remove strata mounts |
| `README.md` | Add marketplace installation instructions |

## Files to Delete

| File | Reason |
|------|--------|
| `.claude-plugin/plugin.json` | Replaced by per-plugin manifests |

## Files Remaining at Root

These files are not part of either plugin and stay at the repository root:

- `README.md`, `LICENSE`, `CLAUDE.md`, `.gitignore` — project metadata
- `Dockerfile`, `docker-compose.yml`, `Makefile` — development infrastructure
- `scripts/` — utility scripts (`install-ubuntu-deps.sh`, `setup-claude-container.sh`, `start-claude-code.sh`)
- `.github/` — CI workflows
- `docs/` — plans and guides
- `claude.local/` — local development directory

## Out of Scope
- Migration of individual consumer repositories — handled per-repo
- Changes to hook logic itself — only paths change
- Statusline script functionality — unchanged, only distribution method changes

## Timeline (Estimates in Points)

- Phase 1: 5 points — directory restructure and plugin manifests
- Phase 2: 2 points — hook path migration
- Phase 3: 3 points — statusline:setup skill
- Phase 4: 5 points — gh-repo-create template overhaul
- Phase 5: 1 point — documentation

**Total: 16 points**

## Risks and Mitigation

### Risk: Plugin Cache Path Changes on Update
- The plugin cache path (`~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/`) may change when the plugin is updated to a new version
- **Mitigation**: `/statusline:setup` re-run resolves the new path; document this as a post-update step

## Success Criteria
- `claude --plugin-dir plugins/workflows` works for local development of the workflows plugin
- `claude --plugin-dir plugins/statusline` works for local development of the statusline plugin
- Hooks function correctly when workflows is installed from marketplace
- `gh-repo-create` produces repositories that use marketplace declaration instead of submodule
- `/statusline:setup` correctly configures statusline for the current project
- No references to `vendor/strata` remain in strata's own codebase (except migration docs)
