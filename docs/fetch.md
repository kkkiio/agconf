# agconf fetch

从 GitHub 仓库或本地路径复制 skills、prompts 和 commands 到 agent 配置目录。

```mooncram
$ cp -R "$TESTDIR/../tests/fixtures" .
```

## Skill 完整目录复制

Skill 目录下的辅助文件（scripts、references 等）随 `SKILL.md` 一起复制。

```mooncram
$ agconf.exe fetch fixtures/full-skill/skills/web --dry-run -a pi
[SKILL] fixtures/full-skill/skills/web/SKILL.md → .pi/skills/web/SKILL.md
[SKILL] fixtures/full-skill/skills/web/references/api.md → .pi/skills/web/references/api.md
[SKILL] fixtures/full-skill/skills/web/scripts/check.sh → .pi/skills/web/scripts/check.sh
```

## 多个 Agent（全局）

`-g` 配合多个 `-a` 输出到各 agent 的全局目录。

```mooncram
$ HOME=home agconf.exe fetch fixtures/basic/prompts/nested/review.md --dry-run -a pi -a codex -g
[PROMPT] fixtures/basic/prompts/nested/review.md → home/.pi/agent/prompts/review.md
[PROMPT] fixtures/basic/prompts/nested/review.md → home/.codex/prompts/review.md
```

## 全局安装（Pi）

`-g` 写入用户级目录。Pi 全局路径为 `~/.pi/agent/`。

```mooncram
$ HOME=home agconf.exe fetch fixtures/skill-only/skills/web --dry-run -g -a pi
[SKILL] fixtures/skill-only/skills/web/SKILL.md → home/.pi/agent/skills/web/SKILL.md
```

## 本地目录扫描

传入目录时递归发现 skills 和 prompts。`README.md` 等无关文件被忽略。

```mooncram
$ agconf.exe fetch fixtures/basic --dry-run -a pi
[SKILL] fixtures/basic/skills/web/SKILL.md → .pi/skills/web/SKILL.md
[PROMPT] fixtures/basic/prompts/nested/review.md → .pi/prompts/nested/review.md
[PROMPT] fixtures/basic/commands/check.md → .pi/prompts/check.md
```

## Skill → Prompt 转换

`--as-prompt` 去掉 YAML frontmatter，以 skill 目录名作为文件名。

```mooncram
$ agconf.exe fetch fixtures/skill-only/skills/web --as-prompt -a pi
[PROMPT] fixtures/skill-only/skills/web/SKILL.md → .pi/prompts/web.md
```

```mooncram
$ cat .pi/prompts/web.md
Web UI.
```

## 默认 Agent

不传 `-a` 等价于 `-a universal`，skills 写入 `.agents/skills/`。

```mooncram
$ agconf.exe fetch fixtures/skill-only/skills/web --dry-run
[SKILL] fixtures/skill-only/skills/web/SKILL.md → .agents/skills/web/SKILL.md
```

## 错误：universal 不支持 prompts

目标为 universal 且需要 prompts 时报错。

```mooncram
$ agconf.exe fetch fixtures/prompt-only/prompts/review.md --dry-run 2>&1
universal has no prompts directory; pass -a pi or -a codex
[1]
```

## 错误：Codex prompts 需要 -g

Codex 只支持全局 prompts，未传 `-g` 时报错。

```mooncram
$ agconf.exe fetch fixtures/prompt-only/prompts/review.md --dry-run -a codex 2>&1
Codex prompts require -g / --global
[1]
```

## 错误：--as-prompt 需要 -a

`--as-prompt` 必须指定目标 agent，因为 universal 无 prompts 路径。

```mooncram
$ agconf.exe fetch fixtures/skill-only/skills/web --as-prompt --dry-run 2>&1
--as-prompt requires -a <agent>
[1]
```

## 显式 .md 文件

传入单个 `.md` 文件（非 `skills/` 路径下）识别为 prompt。

```mooncram
$ agconf.exe fetch fixtures/basic/README.md --dry-run -a pi
[PROMPT] fixtures/basic/README.md → .pi/prompts/README.md
```
