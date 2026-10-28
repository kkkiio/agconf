# agconf

Rsync for AI agent configs — copy skills, prompts, and commands from GitHub repos to your agent directories.

## Install

```bash
brew install kkkiio/tap/agconf
```

Or install via the MoonBit package manager:

```bash
moon install KKKIIO/agconf
```

Or run it directly with `moonx`:

```bash
moonx KKKIIO/agconf@latest fetch -g https://github.com/kkkiio/skills/tree/main/skills/write-agents-md
```

## Quick Start

```bash
# Install a skill from a GitHub repo
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design

# Install a prompt for a specific agent
agconf fetch https://github.com/owner/repo/blob/main/prompts/review.md -a pi

# Address a skill by its full URL
agconf fetch https://github.com/user/repo/blob/main/skills/foo/SKILL.md

# Install globally
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design -g

# Preview
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --dry-run
```

## Source Conventions

Content in GitHub repos is recognised by this layout:

```
source/
├── skills/
│   └── <name>/
│       └── SKILL.md          ← skill
├── commands/
│   └── <name>.md             ← command / prompt
└── prompts/
    └── <name>.md             ← prompt
```

## Agent Path Mapping

| Agent     | `--agent`   | Skills (project)  | Prompts (project) | Skills (global)       | Prompts (global)       |
| --------- | ----------- | ----------------- | ----------------- | --------------------- | ---------------------- |
| Universal | `universal` | `.agents/skills/` | —                 | `~/.agents/skills/`   | —                      |
| Pi        | `pi`        | `.pi/skills/`     | `.pi/prompts/`    | `~/.pi/agent/skills/` | `~/.pi/agent/prompts/` |
| Codex     | `codex`     | `.agents/skills/` | —                 | `~/.agents/skills/`   | `~/.codex/prompts/`    |

## License

Apache-2.0
