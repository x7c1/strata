# Managing Hooks in Claude Code Plugins

## Overview

This guide documents best practices for managing hooks when distributing Claude Code plugins, particularly in organizational settings. Since Claude Code does not currently support toggling individual hooks on/off, this guide provides workarounds for achieving granular control over hook activation.

## Current Limitations

As of early 2026, Claude Code has the following limitations regarding hooks in plugins:

| Feature | Supported |
|---------|-----------|
| Disable entire plugin | Yes (`claude plugin disable`) |
| Disable all hooks globally | Yes (`disableAllHooks: true`) |
| Disable individual hooks | **No** |
| Toggle specific hooks on/off | **No** |

When a plugin is installed, **all hooks contained within it are automatically enabled**. There is no mechanism to selectively enable or disable specific hooks while keeping the plugin active.

### Conflict Resolution

When multiple plugins define hooks for the same event/tool:

- All matching hooks run **in parallel**
- Identical hook commands are deduplicated automatically
- Conflict resolution behavior (when hooks return contradicting decisions) is **not documented**

## Recommended Strategy: Split by Hook Groups

To provide granular control over hooks in organizational settings, split hooks into separate plugins based on their purpose or target audience.

### Directory Structure Example

Instead of a monolithic plugin:

```
company-plugins/
└── all-hooks/                    # Everything bundled together
    └── .claude-plugin/
        └── plugin.json
    └── hooks/
        └── hooks.json            # All hooks in one file
```

Split into purpose-specific plugins:

```
company-plugins/
├── security-hooks/               # Security-related hooks
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── hooks/
│       └── hooks.json
├── formatting-hooks/             # Code formatting hooks
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── hooks/
│       └── hooks.json
├── notification-hooks/           # Notification hooks
│   ├── .claude-plugin/
│   │   └── plugin.json
│   └── hooks/
│       └── hooks.json
└── compliance-hooks/             # Compliance/audit hooks
    ├── .claude-plugin/
    │   └── plugin.json
    └── hooks/
        └── hooks.json
```

### Marketplace Configuration

You can host all plugins in a single repository while allowing selective installation. In your `marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "security-hooks",
      "source": "./security-hooks",
      "description": "Security validation hooks for Bash commands and file operations"
    },
    {
      "name": "formatting-hooks",
      "source": "./formatting-hooks",
      "description": "Auto-formatting hooks for code files"
    },
    {
      "name": "notification-hooks",
      "source": "./notification-hooks",
      "description": "Desktop notification hooks"
    },
    {
      "name": "compliance-hooks",
      "source": "./compliance-hooks",
      "description": "Compliance and audit logging hooks"
    }
  ]
}
```

Users can then selectively install only the plugins they need:

```bash
# Add the marketplace first
claude plugin marketplace add company-org/company-plugins

# Then install specific plugins
claude plugin install security-hooks@company-plugins
claude plugin install formatting-hooks@company-plugins
```

### Private Repository Support

Claude Code supports installing plugins from **private repositories**. This is essential for organizations that cannot expose internal tooling publicly.

#### Authentication Methods

| Use Case | Authentication Method |
|----------|----------------------|
| Manual install/update | Existing git credential helpers (`gh auth login`, SSH keys, etc.) |
| Background auto-updates | Environment variables with tokens |

If `git clone` works for a private repository in your terminal, it works in Claude Code too.

#### Environment Variables for Auto-Updates

For background auto-updates to work with private repositories, set the appropriate token:

| Provider | Environment Variable |
|----------|---------------------|
| GitHub | `GITHUB_TOKEN` or `GH_TOKEN` |
| GitLab | `GITLAB_TOKEN` or `GL_TOKEN` |
| Bitbucket | `BITBUCKET_TOKEN` |

```bash
# Add to your shell configuration (.bashrc, .zshrc, etc.)
export GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

**Token Requirements:**
- GitHub: `repo` scope for private repositories
- GitLab: `read_repository` scope

#### Team-Wide Configuration

You can configure automatic marketplace installation for your team by adding to `.claude/settings.json` in your project:

```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    }
  }
}
```

## Use Cases

### Team-Based Distribution

Different teams may require different hooks:

| Team | Required Plugins |
|------|------------------|
| Security Team | `security-hooks`, `compliance-hooks` |
| Frontend Team | `formatting-hooks`, `notification-hooks` |
| DevOps Team | `security-hooks`, `notification-hooks` |
| All Teams | (none mandatory) |

### Gradual Rollout

Split plugins enable phased rollouts:

1. Release `security-hooks` to security team for testing
2. After validation, expand to all engineering teams
3. Later, release `formatting-hooks` as optional enhancement

### Conflict Avoidance

Splitting by purpose reduces the risk of conflicting hooks. For example:

- `security-hooks` handles `PreToolUse` for Bash security validation
- `formatting-hooks` handles `PostToolUse` for code formatting

These operate at different lifecycle points, minimizing conflicts.

## Future Considerations

This workaround addresses a current limitation in Claude Code. If individual hook toggling is added in the future, these split plugins can still be maintained for organizational clarity, or consolidated if preferred.

Monitor the Claude Code changelog and GitHub issues for updates:
- https://github.com/anthropics/claude-code/issues

## References

- [Hooks Reference](https://code.claude.com/docs/en/hooks)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
