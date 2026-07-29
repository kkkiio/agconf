# agconf

> rsync for AI agent configs — copy skills, prompts, and commands from
> local paths to your agent directories.

No registry. No lockfile. No install tracking. Just copy.

## Motivation

现有工具要么只管 skills，要么必须走 registry，要么只能整仓同步。
agconf 填的空白是：**从本地路径按需复制单个文件或目录，
直接写到对应 agent 的配置目录**。

| 能力 | skills | PRPM | Rulesync | agentctl | **agconf** |
|---|---|---|---|---|---|
| Skills | ✅ | ✅ | ✅ | ✅ | ✅ |
| Prompts / Commands | ❌ | ✅ | ✅ | ✅ | ✅ |
| 本地路径安装 | ✅ | ✅ | ❌ | ❌ | ✅ |
| 单个文件 | ✅ | ❌ | ❌ | ❌ | ✅ |
| 无 Registry | ✅ | ❌ | ✅ | ✅ | ✅ |
| 无安装记录 | ❌ | ❌ | ❌ | ❌ | ✅ |

## Quick Start

```bash
# 安装一个 skill
agconf fetch ./my-skills/web-design

# 安装一个 prompt，指定目标 agent
agconf fetch ./my-prompts/review.md -a pi

# skill 转 prompt 安装
agconf fetch ./my-skills/web-design --as-prompt -a codex

# 全局安装
agconf fetch ./my-skills/web-design -g

# 预览，不实际写入
agconf fetch ./my-skills/web-design --dry-run
```

## Install

```bash
moon install KKKIIO/agconf
```

## How It Works

```
Local path  ─→  [--as-prompt?]  ─→  Agent config dir
```

### 内容识别

agconf 按文件名和目录结构推断内容类型：

| 模式 | 识别为 |
|---|---|
| `skills/<name>/SKILL.md` | Skill |
| `SKILL.md`（根目录） | Skill |
| `prompts/**/*.md` | Prompt |
| `commands/**/*.md` | Prompt / Command |
| 显式传入的单个 `.md` 文件 | Prompt |

只有以上模式会被识别并复制。`README.md`、`CHANGELOG.md` 等不会误安装。

### 输出路径规则

| 内容类型 | 条件 | 项目级路径 | 全局路径 (`-g`) |
|---|---|---|---|
| Skill | 默认 | `.agents/skills/` | `~/.agents/skills/` |
| Skill 转 Prompt | `--as-prompt -a <agent>` | `.<agent>/prompts/` | `~/.<agent>/prompts/` |
| Prompt / Command | `-a <agent>` | 按 agent 映射 | 按 agent 映射 |

- Skills 不传 `-a` 时默认写入 `.agents/skills/`（等价于 `-a universal`）。
- Prompts / commands **必须**通过 `-a` 指定目标 agent，否则跳过并输出 warning。
- **`universal` 仅支持 skills，不支持 prompts**。prompts 必须指定具体 agent。

### Agent 路径映射

| Agent | `--agent` | Skills | Prompts |
|---|---|---|---|
| Universal | `universal` | `.agents/skills/` | — |
| Pi | `pi` | `.agents/skills/` | `.pi/prompts/` |
| Codex | `codex` | `.agents/skills/` | `~/.codex/prompts/` |
| Claude Code | `claude-code` | `.agents/skills/` | `.claude/commands/` |
| Cursor | `cursor` | `.agents/skills/` | `.cursor/commands/` |
| OpenCode | `opencode` | `.agents/skills/` | `.opencode/prompts/` |

> Codex 仅支持全局 prompts（`~/.codex/prompts/`）。未传 `-g` 时 **报错退出**，不会静默写入 home 目录。
> Claude Code 和 Cursor 使用 `commands/` 目录名但语义等价于 prompts，agconf 写入对应目录，内容格式不变。

更多 agent 的支持会逐步添加。

## Usage

```
agconf fetch <source> [options]

Source:
  ./path/to/skill          本地目录（递归处理）
  ./path/to/file.md        本地文件
  ./path/to/SKILL.md       本地 SKILL.md 文件

Options:
  -a, --agent <agent>   目标 agent（可重复：-a pi -a codex）
                        对 prompt / command 必须指定；
                        skills 可选，默认 universal。
  -g, --global          安装到用户级目录
  --as-prompt           将 SKILL.md 转为单文件 prompt（去 frontmatter，
                        以 skill 目录名作为文件名）
  --dry-run             预览操作，不实际写入
  --conflict <mode>     冲突策略：overwrite（默认）| skip | ask
```

### `--as-prompt`

将 `SKILL.md` 转换为 prompt 文件：
- 去掉 YAML frontmatter（`---` 块）
- 保留正文 Markdown 内容
- 以 skill 目录名（而非 `SKILL`）作为输出文件名
- 写入 `.<agent>/prompts/`（或 agent 对应的 prompts/commands 目录）

```bash
# 源: ./my-skills/web-design/SKILL.md
# 输出: .pi/prompts/web-design.md
agconf fetch ./my-skills/web-design --as-prompt -a pi
```

## Examples

```bash
# 安装整个 skills 目录
agconf fetch ./my-skills

# 安装单个 skill
agconf fetch ./my-skills/web-design

# 安装单个 prompt 到 pi
agconf fetch ./my-prompts/review.md -a pi

# 同一文件输出到多个 agent
agconf fetch ./my-prompts/review.md -a pi -a claude-code

# skill 转 prompt
agconf fetch ./my-skills/web-design --as-prompt -a pi

# 全局安装
agconf fetch ./my-skills/web-design -g

# Codex prompt 必须加 -g（否则报错）
agconf fetch ./my-prompts/review.md -a codex -g

# 预览
agconf fetch ./my-skills --dry-run

# 整目录安装（skills → .agents/skills/，prompts 跳过并 warning）
agconf fetch ./my-stuff

# 整目录同时装 skill 和 prompt
agconf fetch ./my-stuff -a pi
```

## Source Directory Conventions

agconf 按路径结构推断内容类型：

```
source/
├── skills/
│   └── <name>/
│       └── SKILL.md          ← skill（含 YAML frontmatter）
├── commands/
│   └── <name>.md             ← command / prompt
├── prompts/
│   └── <name>.md             ← prompt
└── SKILL.md                  ← root skill
```

## License

Apache-2.0
