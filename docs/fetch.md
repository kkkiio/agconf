# agconf fetch

从 GitHub 仓库或本地路径复制 skills、prompts 和 commands 到 agent 配置目录。

```mooncram
$ cp -R "$TESTDIR/../tests/fixtures" .
```

## Skill 完整目录复制

Skill 目录下的辅助文件（scripts、references 等）随 `SKILL.md` 一起复制。

```mooncram
$ agconf.exe fetch fixtures/full-skill/skills/web --dry-run -a pi
fixtures/full-skill/skills/web/SKILL.md → .pi/skills/web/SKILL.md
fixtures/full-skill/skills/web/references/api.md → .pi/skills/web/references/api.md
fixtures/full-skill/skills/web/scripts/check.sh → .pi/skills/web/scripts/check.sh
```

## 多个 Agent（全局）

`-g` 配合多个 `-a` 输出到各 agent 的全局目录。

```mooncram
$ HOME=home agconf.exe fetch fixtures/basic/prompts/nested/review.md --dry-run -a pi -a codex -g
fixtures/basic/prompts/nested/review.md → home/.pi/agent/prompts/review.md
fixtures/basic/prompts/nested/review.md → home/.codex/prompts/review.md
```

## 全局安装（Pi）

`-g` 写入用户级目录。Pi 全局路径为 `~/.pi/agent/`。

```mooncram
$ HOME=home agconf.exe fetch fixtures/skill-only/skills/web --dry-run -g -a pi
fixtures/skill-only/skills/web/SKILL.md → home/.pi/agent/skills/web/SKILL.md
```

## 本地目录扫描

传入目录时递归发现 skills 和 prompts。`README.md` 等无关文件被忽略。

```mooncram
$ agconf.exe fetch fixtures/basic --dry-run -a pi
fixtures/basic/skills/web/SKILL.md → .pi/skills/web/SKILL.md
fixtures/basic/prompts/nested/review.md → .pi/prompts/nested/review.md
fixtures/basic/commands/check.md → .pi/prompts/check.md
```

## Skill → Prompt 转换

`--as-prompt` 去掉 YAML frontmatter，以 skill 目录名作为文件名。

```mooncram
$ agconf.exe fetch fixtures/skill-only/skills/web --as-prompt -a pi
fixtures/skill-only/skills/web/SKILL.md → .pi/prompts/web.md
```

```mooncram
$ cat .pi/prompts/web.md
Web UI.
```

## 冲突跳过

冲突策略为 `skip` 时，跳过的文件以 `Skipping` 开头输出。

```mooncram
$ agconf.exe fetch fixtures/skill-only/skills/web --as-prompt -a pi --conflict skip
Skipping fixtures/skill-only/skills/web/SKILL.md → .pi/prompts/web.md
```

## 默认 Agent

不传 `-a` 时依次安装到 Pi、Codex 和 universal。共享输出目录的 agent 会去重，
因此 Codex 与 universal 的 skill 只安装一次。

```mooncram
$ agconf.exe fetch fixtures/skill-only/skills/web --dry-run
fixtures/skill-only/skills/web/SKILL.md → .pi/skills/web/SKILL.md
fixtures/skill-only/skills/web/SKILL.md → .agents/skills/web/SKILL.md
```

## 跳过不支持的 prompt 目标

universal 没有 prompts 目录，Codex prompts 需要 `-g`。这些组合会在 stderr
输出 warning 并跳过，不会阻止其他目标安装。同一 fetch 命令中，每个 agent 和
内容类型只会 warning 一次。

```mooncram
$ agconf.exe fetch fixtures/basic --dry-run -a universal 2>&1
warning: universal has no prompts directory; skipping prompts for universal
fixtures/basic/skills/web/SKILL.md → .agents/skills/web/SKILL.md
```

```mooncram
$ agconf.exe fetch fixtures/prompt-only/prompts/review.md --dry-run -a codex 2>&1
warning: codex prompts require -g / --global; skipping prompts for codex
```

## `--as-prompt` 默认目标

不传 `-a` 的 `--as-prompt` 会安装到 Pi；Codex 与 universal 会 warning 并跳过，
因为前者需要 `-g`，后者不支持 prompts。

```mooncram
$ agconf.exe fetch fixtures/skill-only/skills/web --as-prompt --dry-run 2>&1
warning: codex prompts require -g / --global; skipping prompts for codex
warning: universal has no prompts directory; skipping prompts for universal
fixtures/skill-only/skills/web/SKILL.md → .pi/prompts/web.md
```

## 显式 .md 文件

传入单个 `.md` 文件（非 `skills/` 路径下）识别为 prompt。

```mooncram
$ agconf.exe fetch fixtures/basic/README.md --dry-run -a pi
fixtures/basic/README.md → .pi/prompts/README.md
```
