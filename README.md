# agconf

> rsync for AI agent configs — copy skills, prompts, and commands from
> GitHub repos to your agent directories.

No registry. No lockfile. No install tracking. Just copy.

## Motivation

现有工具要么只管 skills，要么必须走 registry，要么只能整仓同步。
agconf 填的空白是：**从 GitHub 仓库按需复制单个文件或目录，
直接写到对应 agent 的配置目录**。

| 能力 | skills | PRPM | Rulesync | agentctl | **agconf** |
|---|---|---|---|---|---|
| Skills | ✅ | ✅ | ✅ | ✅ | ✅ |
| Prompts / Commands | ❌ | ✅ | ✅ | ✅ | ✅ |
| GitHub Repo | ✅ | 较弱 | ✅ | ❌ | ✅ |
| 单个文件 | ✅ | ❌ | ❌ | ❌ | ✅ |
| 无 Registry | ✅ | ❌ | ✅ | ✅ | ✅ |
| 无安装记录 | ❌ | ❌ | ❌ | ❌ | ✅ |

## Quick Start

```bash
# 从 GitHub 仓库安装一个 skill
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design

# 安装一个 prompt 到指定 agent
agconf fetch https://github.com/owner/repo/blob/main/prompts/review.md -a pi

# 用完整 URL 指定一个 skill
agconf fetch https://github.com/user/repo/blob/main/skills/foo/SKILL.md

# skill 转 prompt
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --as-prompt -a codex -g

# 全局安装
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design -g

# 预览
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --dry-run
```

## Install

```bash
moon install KKKIIO/agconf/cmd/agconf
```

或从源码构建：

```bash
git clone https://github.com/kkkiio/agconf
cd agconf
moon install && moon build
```

## How It Works

```
Source (GitHub repo)  ─→  [--as-prompt?]  ─→  Agent config dir
```

### 内容识别

agconf 按文件名和目录结构推断内容类型：

| 模式 | 识别为 |
|---|---|
| `skills/<name>/SKILL.md` | Skill |
| `prompts/**/*.md` | Prompt |
| `commands/**/*.md` | Prompt / Command |
| 显式传入的单个 `.md` 文件 | Prompt（非 `skills/` 路径下） |

只有以上模式会被识别并复制。`README.md`、`CHANGELOG.md` 等不会误安装。

### 输出路径规则

| 内容类型 | 条件 | 项目级路径 | 全局路径 (`-g`) |
|---|---|---|---|
| Skill | — | 按 agent 映射 | 按 agent 映射 |
| Skill 转 Prompt | `--as-prompt` | 按 agent 映射 | 按 agent 映射 |
| Prompt / Command | — | 按 agent 映射 | 按 agent 映射 |

- 无 `-a` 时安装到所有支持的 agent。
- Skills → 按 agent 写入 skills 目录。
- Prompts / commands → 按 agent 写入 prompts 目录。不支持的 agent 跳过并 warning。
- `--as-prompt` 将 skill 转为 prompt，写入对应 agent 的 prompts 目录。

### Agent 路径映射

| Agent | `--agent` | Skills (project) | Prompts (project) | Skills (global) | Prompts (global) |
|---|---|---|---|---|---|
| Universal | `universal` | `.agents/skills/` | — | `~/.agents/skills/` | — |
| Pi | `pi` | `.pi/skills/` | `.pi/prompts/` | `~/.pi/agent/skills/` | `~/.pi/agent/prompts/` |
| Codex | `codex` | `.agents/skills/` | — | `~/.agents/skills/` | `~/.codex/prompts/` |

> Codex prompts 仅支持全局（`~/.codex/prompts/`）。未传 `-g` 时跳过并 warning。
> universal 仅支持 skills，无 prompts 路径。安装 prompts 时跳过 universal 并 warning。

## Usage

```
agconf fetch <source> [options]

Sources:
  https://github.com/owner/repo                         完整仓库 URL
  https://github.com/owner/repo/tree/main/skills/foo    tree URL（子目录）
  https://github.com/owner/repo/blob/main/SKILL.md      blob URL（单个文件）
  ./local-path                                          本地路径

Options:
  -a, --agent <agent>   目标 agent（可重复：-a pi -a codex）
                        无 `-a` 安装到所有支持的 agent。
  -g, --global          安装到用户级目录
  --as-prompt           将 SKILL.md 转为单文件 prompt（去 frontmatter，
                        以 skill 目录名作为文件名）
  --ref <branch|tag>    指定 GitHub 分支或 tag（默认 HEAD）
  --dry-run             预览操作，不实际写入
  --conflict <mode>     冲突策略：overwrite（默认）| skip | ask
```

### `--as-prompt`

将 `SKILL.md` 转换为 prompt 文件：
- 去掉 YAML frontmatter（`---` 块）
- 保留正文 Markdown 内容
- 以 skill 目录名（而非 `SKILL`）作为输出文件名
- 写入对应 agent 的 prompts 目录

```bash
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --as-prompt -a pi
# 输出: .pi/prompts/web-design.md
```

## Examples

```bash
# 从 GitHub 仓库拉取单个 skill
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design

# 用完整 URL 指定一个 skill
agconf fetch https://github.com/user/repo/blob/main/skills/foo/SKILL.md

# 指定分支
agconf fetch https://github.com/owner/repo/tree/main/skills/foo --ref develop

# 同一文件输出到多个 agent
agconf fetch https://github.com/owner/repo/blob/main/prompts/review.md -a pi -a codex -g

# skill 转 prompt
agconf fetch https://github.com/owner/repo/tree/main/skills/web-design --as-prompt -a pi

# 全局安装
agconf fetch https://github.com/vercel-labs/agent-skills/tree/main/skills/frontend-design -g

# Codex prompt 需要加 -g（否则跳过）
agconf fetch https://github.com/owner/repo/blob/main/prompts/review.md -a codex -g

# 预览
agconf fetch https://github.com/vercel-labs/agent-skills --dry-run
```

## Source Conventions

GitHub 仓库按以下结构识别内容类型：

```
source/
├── skills/
│   └── <name>/
│       └── SKILL.md          ← skill（含 YAML frontmatter）
├── commands/
│   └── <name>.md             ← command / prompt
└── prompts/
    └── <name>.md             ← prompt
```

## License

Apache-2.0
