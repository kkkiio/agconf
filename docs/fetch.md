# agconf fetch

从 GitHub 仓库或本地路径复制 skills、prompts 和 commands 到 agent 配置目录。

```mooncram
$ cp -R "$TESTDIR/../testdata" .
```

## Skill 完整目录复制

Skill 目录下的辅助文件（scripts、references 等）随 `SKILL.md` 一起复制。

```mooncram
$ agconf.exe fetch testdata/full-skill/skills/web --dry-run -a pi
testdata/full-skill/skills/web/SKILL.md → .pi/skills/web/SKILL.md
testdata/full-skill/skills/web/references/api.md → .pi/skills/web/references/api.md
testdata/full-skill/skills/web/scripts/check.sh → .pi/skills/web/scripts/check.sh
```

## 多个 Agent（全局）

`-g` 配合多个 `-a` 输出到各 agent 的全局目录。

```mooncram
$ HOME=home agconf.exe fetch testdata/basic/prompts/nested/review.md --dry-run -a pi -a codex -g
testdata/basic/prompts/nested/review.md → home/.pi/agent/prompts/review.md
testdata/basic/prompts/nested/review.md → home/.codex/prompts/review.md
```

## 全局安装（Pi）

`-g` 写入用户级目录。Pi 全局路径为 `~/.pi/agent/`。

```mooncram
$ HOME=home agconf.exe fetch testdata/skill-only/skills/web --dry-run -g -a pi
testdata/skill-only/skills/web/SKILL.md → home/.pi/agent/skills/web/SKILL.md
```

## 本地目录扫描

传入目录时递归发现 skills 和 prompts。`README.md` 等无关文件被忽略。

```mooncram
$ agconf.exe fetch testdata/basic --dry-run -a pi
testdata/basic/skills/web/SKILL.md → .pi/skills/web/SKILL.md
testdata/basic/prompts/nested/review.md → .pi/prompts/nested/review.md
testdata/basic/commands/check.md → .pi/prompts/check.md
```

## Skill → Prompt 转换

`--as-prompt` 去掉 YAML frontmatter，以 skill 目录名作为文件名。

```mooncram
$ agconf.exe fetch testdata/skill-only/skills/web --as-prompt -a pi
testdata/skill-only/skills/web/SKILL.md → .pi/prompts/web.md
```

```mooncram
$ cat .pi/prompts/web.md
Web UI.
```

## 冲突跳过

冲突策略为 `skip` 时，跳过的文件以 `Skipping` 开头输出。

```mooncram
$ agconf.exe fetch testdata/skill-only/skills/web --as-prompt -a pi --conflict skip
Skipping testdata/skill-only/skills/web/SKILL.md → .pi/prompts/web.md
```

## 默认 Agent

不传 `-a` 时依次安装到 Pi、Codex 和 universal。共享输出目录的 agent 会去重，
因此 Codex 与 universal 的 skill 只安装一次。

```mooncram
$ agconf.exe fetch testdata/skill-only/skills/web --dry-run
testdata/skill-only/skills/web/SKILL.md → .pi/skills/web/SKILL.md
testdata/skill-only/skills/web/SKILL.md → .agents/skills/web/SKILL.md
```

## 跳过不支持的 prompt 目标

universal 没有 prompts 目录，Codex prompts 需要 `-g`。这些组合会在 stderr
输出 warning 并跳过，不会阻止其他目标安装。同一 fetch 命令中，每个 agent 和
内容类型只会 warning 一次。

```mooncram
$ agconf.exe fetch testdata/basic --dry-run -a universal 2>&1
warning: universal has no prompts directory; skipping prompts for universal
testdata/basic/skills/web/SKILL.md → .agents/skills/web/SKILL.md
```

```mooncram
$ agconf.exe fetch testdata/prompt-only/prompts/review.md --dry-run -a codex 2>&1
warning: codex prompts require -g / --global; skipping prompts for codex
```

## `--as-prompt` 默认目标

不传 `-a` 的 `--as-prompt` 会安装到 Pi；Codex 与 universal 会 warning 并跳过，
因为前者需要 `-g`，后者不支持 prompts。

```mooncram
$ agconf.exe fetch testdata/skill-only/skills/web --as-prompt --dry-run 2>&1
warning: codex prompts require -g / --global; skipping prompts for codex
warning: universal has no prompts directory; skipping prompts for universal
testdata/skill-only/skills/web/SKILL.md → .pi/prompts/web.md
```

## 显式 .md 文件

传入单个 `.md` 文件（非 `skills/` 路径下）识别为 prompt。

```mooncram
$ agconf.exe fetch testdata/basic/README.md --dry-run -a pi
testdata/basic/README.md → .pi/prompts/README.md
```

## GitHub blob URL

Blob URL 中的文件按路径识别为 prompt 或 skill。

```mooncram
$ agconf.exe fetch https://github.com/kkkiio/agconf/blob/main/testdata/prompt-only/prompts/review.md --dry-run -a pi
https://github.com/kkkiio/agconf/blob/main/testdata/prompt-only/prompts/review.md → .pi/prompts/review.md
```

## 拒绝非 URL 输入

不接受 `owner/repo` 简写，必须使用完整 GitHub URL。

```mooncram
$ agconf.exe fetch kkkiio/skills --dry-run 2>&1
unsupported source: kkkiio/skills; use a https://github.com/ URL or local path
[1]
```

## 拒绝非标准 GitHub 路径

不带 `tree/` 或 `blob/` 的路径会被拒绝。

```mooncram
$ agconf.exe fetch https://github.com/owner/repo/skills/foo --dry-run 2>&1
invalid GitHub URL: expected /tree/<ref>/<path> or /blob/<ref>/<path>
[1]
```

## 多层 skill 目录

`skills/engineering/grill-with-docs/SKILL.md` 等多层嵌套路径应正确识别为 skill。

```mooncram
$ agconf.exe fetch testdata/nested-skills/skills/engineering/grill-with-docs --dry-run -a pi
testdata/nested-skills/skills/engineering/grill-with-docs/SKILL.md → .pi/skills/grill-with-docs/SKILL.md
```

## 多层 skill --as-prompt

多层 skill 路径配合 `--as-prompt` 应正确提取 skill 目录名为文件名。

```mooncram
$ agconf.exe fetch https://github.com/kkkiio/agconf/blob/main/testdata/nested-skills/skills/engineering/grill-with-docs/SKILL.md --as-prompt -a pi
https://github.com/kkkiio/agconf/blob/main/testdata/nested-skills/skills/engineering/grill-with-docs/SKILL.md → .pi/prompts/grill-with-docs.md
```

## 深层 prompts 目录

选择 `prompts/nested/` 子目录时应发现其中的 prompt 文件。

```mooncram
$ agconf.exe fetch testdata/deep-prompts/prompts/nested --dry-run -a pi
testdata/deep-prompts/prompts/nested/review.md → .pi/prompts/review.md
```

## GitHub tree URL

Tree URL 对应目录下所有识别内容。

```mooncram
$ agconf.exe fetch https://github.com/kkkiio/agconf/tree/main/testdata/basic --dry-run -a pi
https://github.com/kkkiio/agconf/tree/main/testdata/basic/skills/web/SKILL.md → .pi/skills/web/SKILL.md
https://github.com/kkkiio/agconf/tree/main/testdata/basic/prompts/nested/review.md → .pi/prompts/nested/review.md
https://github.com/kkkiio/agconf/tree/main/testdata/basic/commands/check.md → .pi/prompts/check.md
```

## URL 末尾斜杠

`tree/` URL 末尾斜杠正常处理。

```mooncram
$ agconf.exe fetch https://github.com/kkkiio/agconf/tree/main/testdata/prompt-only/ --dry-run -a pi
https://github.com/kkkiio/agconf/tree/main/testdata/prompt-only/prompts/review.md → .pi/prompts/review.md
```

## 拒绝路径穿越

URL 中包含 `..` 或 `.` 路径段时应拒绝。

```mooncram
$ agconf.exe fetch https://github.com/owner/repo/blob/main/../../etc/passwd --dry-run 2>&1
invalid GitHub URL: path must not contain '..' or '.' segments
[1]
```

## GitHub 路径不存在

不存在的 blob/tree 路径应给出清晰的错误信息。

```mooncram
$ agconf.exe fetch https://github.com/kkkiio/agconf/blob/main/testdata/does-not-exist.md --dry-run 2>&1
GitHub path not found: testdata/does-not-exist.md
[1]
```
