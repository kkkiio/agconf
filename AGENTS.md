# AGENTS.md

## Domain Language

- **Skill** — A directory containing `SKILL.md` with YAML frontmatter (`name`, `description`). Provides reusable agent instructions.
- **Prompt** — A standalone `.md` file (no frontmatter) placed in an agent's prompts directory.
- **Command** — Same as Prompt; some agents (Claude Code, Cursor) call it "command", others (Pi, Codex) call it "prompt".
- **Agent** — A target coding agent CLI (Pi, Codex, Claude Code, Cursor, OpenCode) identified by `--agent` / `-a`.
- **Universal** — The shared agent path `.agents/skills/`, read by multiple agents. Pass via `-a universal`.
- **`--as-prompt`** — Conversion: strip YAML frontmatter from SKILL.md, write as standalone prompt named after the skill directory.

## Policies & Mandatory Rules

### No State Management

agconf does not track installations, maintain lockfiles, or record package metadata. It copies files from source to destination. Do not introduce install-state tracking, dependency resolution, or package registries.

### Compatibility Policy

When changing public APIs, CLI flags, or output paths, follow this project's compatibility policy.

- Project at 0.x: zero stability guarantees.
- Prefer direct migrations over compatibility layers.
- Document intentional breaking changes in commit messages; update README.md when output paths or CLI flags change.

### Documentation Intent Principle

Documents record intent, code implements it. Intent is the source of truth.

- Write docs before changing code when intent changes.
- Treat docs as living — record current intent, never intermediate states. Update when intent shifts.

### Drift Notes

When implementation reveals unknown unknowns that force deviations from the plan, log them in `.agents/drift-notes/<topic>.md`. Keep notes brief — what was planned, what changed, and why.

### Content Recognition

When scanning a source directory, only these patterns are copied:

- `skills/<name>/SKILL.md` → Skill
- `prompts/**/*.md` → Prompt
- `commands/**/*.md` → Prompt
- Explicit single `.md` file path (not under `skills/`) → Prompt

Never copy `README.md`, `CHANGELOG.md`, or other non-matching `.md` files during directory scans.

### Output Path Rules

- No `-a` equals `-a universal`.
- Skills → write to the agent's skills directory per the mapping table in README.md.
- Prompts/commands with `-a <agent>` → write to the agent's prompts directory.
- `--as-prompt` requires `-a`; universal has no prompts path → error.
- Codex prompts require `-g`; error if `-g` is not passed.

## Project Structure Guide

### Repo Structure & Important Files

```text
.
├── cmd/
│   └── agconf/
│       ├── main.mbt           # CLI entry point (executable)
│       └── moon.pkg           # Package config (kind: executable)
├── agconf.mbt                 # Library: public API and shared helpers
├── agconf_test.mbt            # Blackbox tests (public API)
├── agconf_wbtest.mbt          # Whitebox tests (internal helpers)
├── moon.mod                   # Module metadata and dependencies
├── moon.pkg                   # Root package config
├── README.md                  # User-facing documentation
├── .githooks/
│   └── pre-commit             # Git pre-commit hook
├── .github/
│   └── workflows/             # CI workflows
└── .agents/
    └── drift-notes/           # Implementation deviation logs
```

### Architecture Guidelines

- Keep `cmd/agconf/main.mbt` thin; move logic into the root library package (`agconf.mbt`).
- MoonBit code uses block style — blocks separated by `///|`, order irrelevant.
- Deprecated blocks go in `deprecated.mbt` per directory.
- The library package exposes public types and functions; CLI package handles argument parsing and I/O.
- CLI argument parsing uses `moonbitlang/core/argparse` (declarative, clap-inspired).

### Dependencies

```bash
moon add moonbitlang/core/argparse
moon add moonbitlang/async
```

- CLI argument parsing: `moonbitlang/core/argparse` (declarative, clap-inspired).
- File I/O and async runtime: `moonbitlang/async`.
- YAML frontmatter: parse manually (simple `---` delimiters + `key: value` lines).

## Operation Guide

### Build

```bash
moon build
```

### Run

```bash
moon run cmd/agconf
```

### Test

```bash
moon test
```

Update snapshots when output changes:

```bash
moon test --update
```

### CLI Integration Tests (cram)

Write CLI integration tests in `.md` files with `mooncram` code blocks:

````markdown
# Test Case Name

```mooncram
$ agconf fetch ./my-skills/web-design --dry-run
[SKILL] ./my-skills/web-design/SKILL.md → .agents/skills/web-design/SKILL.md
```
````

Run cram tests:

```bash
moon cram test tests/cram/*.md
```

Builds the CLI binary with native backend, adds it to PATH, then executes cram tests.

### Format & Interface

```bash
moon fmt && moon info
```

Check `.mbti` diffs to verify whether changes affect external package consumers. No `.mbti` change = safe refactoring.

### Coverage

```bash
moon coverage analyze > uncovered.log
```

### Testing Conventions

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for stable results.
- Use `debug_inspect` (requires `Debug` derive) for snapshot tests, not `Show`.
- Use `moon cram test` for CLI-level integration tests that verify end-to-end behavior.
