# agconf

> rsync for AI agent configs — copy skills, prompts, and commands from
> GitHub repos to your agent directories.

No registry. No lockfile. No install tracking. Just copy.

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

# Convert a skill to a prompt
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --as-prompt -a codex -g

# Install globally
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design -g

# Preview
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --dry-run
```

## Motivation

Existing tools either handle skills only, require a registry, or can only
sync whole repos. agconf fills the gap: **copy a single file or directory
on demand from a GitHub repo, straight into the agent's config directory**.

| Capability          | skills | PRPM | Rulesync | agentctl | **agconf** |
| ------------------- | ------ | ---- | -------- | -------- | ---------- |
| Skills              | ✅     | ✅   | ✅       | ✅       | ✅         |
| Prompts / Commands  | ❌     | ✅   | ✅       | ✅       | ✅         |
| GitHub Repo         | ✅     | weak | ✅       | ❌       | ✅         |
| Single file         | ✅     | ❌   | ❌       | ❌       | ✅         |
| No registry         | ✅     | ❌   | ✅       | ✅       | ✅         |
| No install tracking | ❌     | ❌   | ❌       | ❌       | ✅         |

## How It Works

```
Source (GitHub repo)  ─→  [--as-prompt?]  ─→  Agent config dir
```

### Content Recognition

agconf infers content types from file names and directory structure:

| Pattern                                | Recognised as                                    |
| -------------------------------------- | ------------------------------------------------ |
| Any `SKILL.md` file                    | Skill (parent directory is the skill root)       |
| A directory containing `SKILL.md`      | Skill (the whole directory is copied)            |
| `prompts/**/*.md`                      | Prompt                                           |
| `commands/**/*.md`                     | Prompt / Command                                 |
| An explicit single `.md` file          | Prompt (not `SKILL.md`, not under `skills/`)     |

Only the patterns above are recognised and copied. `README.md`,
`CHANGELOG.md`, and other files are never installed by accident.

### Output Path Rules

| Content type       | Condition     | Project path      | Global path (`-g`) |
| ------------------ | ------------- | ----------------- | ------------------ |
| Skill              | —             | agent-mapped      | agent-mapped       |
| Skill as prompt    | `--as-prompt` | agent-mapped      | agent-mapped       |
| Prompt / Command   | —             | agent-mapped      | agent-mapped       |

- Skills without `-a` go to the standard directory: `.agents/skills/` per
  project, or `~/.agents/skills/` with `-g`.
- Prompts without `-a` try every supported agent; unsupported targets are
  skipped with a warning.
- Skills → each agent's skills directory.
- Prompts / commands → each agent's prompts directory. Unsupported agents
  are skipped with a warning.
- `--as-prompt` converts a skill to a prompt and writes it to each agent's
  prompts directory.

### Agent Path Mapping

| Agent     | `--agent`   | Skills (project)  | Prompts (project) | Skills (global)       | Prompts (global)       |
| --------- | ----------- | ----------------- | ----------------- | --------------------- | ---------------------- |
| Universal | `universal` | `.agents/skills/` | —                 | `~/.agents/skills/`   | —                      |
| Pi        | `pi`        | `.pi/skills/`     | `.pi/prompts/`    | `~/.pi/agent/skills/` | `~/.pi/agent/prompts/` |
| Codex     | `codex`     | `.agents/skills/` | —                 | `~/.agents/skills/`   | `~/.codex/prompts/`    |

> Codex prompts are global-only (`~/.codex/prompts/`). Without `-g` they are
> skipped with a warning.
> Universal supports skills only; there is no prompts path. When installing
> prompts, universal is skipped with a warning.

## Usage

```
agconf fetch <source> [options]

Sources:
  https://github.com/owner/repo                         Full repo URL
  https://github.com/owner/repo/tree/main/skills/foo    tree URL (subdirectory)
  https://github.com/owner/repo/blob/main/SKILL.md      blob URL (single file)
  ./local-path                                          Local path

Options:
  -a, --agent <agent>   Target agent (repeatable: -a pi -a codex)
                        Skills default to the standard .agents/skills/ dir;
                        prompts default to all supported agents.
  -g, --global          Install to the user-level directory
  --as-prompt           Convert SKILL.md to a single-file prompt (strip
                        frontmatter, named after the skill directory)
  --ref <branch|tag>    GitHub branch or tag (defaults to HEAD)
  --dry-run             Preview operations without writing
  --conflict <mode>     Conflict policy: overwrite (default) | skip | ask
```

### `--as-prompt`

Converts `SKILL.md` into a prompt file:

- Strips the YAML frontmatter (`---` block)
- Keeps the Markdown body
- Uses the skill directory name (not `SKILL`) as the output file name
- Writes to each agent's prompts directory

```bash
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --as-prompt -a pi
# Output: .pi/prompts/web-design.md
```

## Examples

```bash
# Fetch a single skill from a GitHub repo
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design

# Address a skill by its full URL
agconf fetch https://github.com/user/repo/blob/main/skills/foo/SKILL.md

# Pin a branch
agconf fetch https://github.com/owner/repo/tree/main/skills/foo --ref develop

# Output one file to multiple agents
agconf fetch https://github.com/owner/repo/blob/main/prompts/review.md -a pi -a codex -g

# Convert a skill to a prompt
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --as-prompt -a pi

# Install globally
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design -g

# Codex prompts need -g (otherwise skipped)
agconf fetch https://github.com/owner/repo/blob/main/prompts/review.md -a codex -g

# Preview
agconf fetch https://github.com/vercel-labs/agent-skills --dry-run
```

## Source Conventions

Content in GitHub repos is recognised by this layout:

```
source/
├── skills/
│   └── <name>/
│       └── SKILL.md          ← skill (with YAML frontmatter)
├── commands/
│   └── <name>.md             ← command / prompt
└── prompts/
    └── <name>.md             ← prompt
```

## License

Apache-2.0
