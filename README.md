# Strata

A Claude Code plugin marketplace that distributes development automation tools.

## Plugins

| Plugin | Description |
|--------|-------------|
| **workflows** | Development workflow automation — skills and hooks for git, PR, and plan management |
| **statusline** | Claude Code status line displaying rate-limit usage and context window stats |

## Installation

Add the strata marketplace to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "strata-dev": {
      "source": {
        "source": "github",
        "repo": "x7c1/strata"
      }
    }
  },
  "enabledPlugins": {
    "workflows@strata-dev": true,
    "statusline@strata-dev": true
  }
}
```

Plugins are installed automatically when a developer trusts the project.

## Guides

- [Statusline: Rate-Limit Usage Display](docs/guides/statusline/README.md)

## License

MIT
