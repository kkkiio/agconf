# AGENTS.md

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

## Domain Language

- **Skill** — A directory containing `SKILL.md` with YAML frontmatter (`name`, `description`).
- **Prompt** — A standalone `.md` file (no frontmatter) placed in an agent's prompts directory.
- **Command** — The same artifact as Prompt under the terminology used by Claude Code and Cursor.
- **Agent** — A target coding agent CLI identified by `--agent` / `-a`.
- **Universal** — The shared agent path `.agents/skills/`, read by multiple agents.
- **`--as-prompt`** — Conversion from a Skill to a standalone Prompt named after the skill directory.

## Policies & Mandatory Rules

### No State Management

When changing installation behavior, keep agconf stateless: copy files from source to destination without install-state tracking, lockfiles, dependency resolution, or package registries.

### Compatibility Policy

When changing public APIs, CLI flags, or output paths:

- Treat the 0.x project as having zero stability guarantees.
- Prefer direct migrations over compatibility layers.
- Document intentional breaking changes in commit messages and update `README.md` when output paths or CLI flags change.

### Documentation Intent Principle

When intent changes, update documents before code. Record current intent only, and keep implementation aligned with it.

### Drift Notes

When implementation reveals unknown unknowns that force deviations from the plan, log what changed and why in `.agents/drift-notes/<topic>.md`. Do not create a note when implementation follows the documented intent.

### Content Recognition

When scanning a source path:

- Recognize any file named `SKILL.md` as a Skill and treat its parent directory as the skill root.
- Stop recursively discovering other content below a recognized skill root; copy that directory as one Skill.
- Recognize `prompts/**/*.md` and `commands/**/*.md` as Prompts.
- Recognize an explicit single `.md` file outside `skills/` as a Prompt unless it is named `SKILL.md`.
- Never copy `README.md`, `CHANGELOG.md`, or other non-matching `.md` files during directory scans.

### Output Path Rules

- When no `-a` is passed for a Skill, write to `.agents/skills/`, or `~/.agents/skills/` with `-g`.
- When no `-a` is passed for a Prompt, try all supported agents and skip unsupported targets with a warning.
- When `-a` is passed, write Skills and Prompts to each selected agent's mapped directory.
- When `--as-prompt` is passed, convert the Skill and use Prompt target rules.
- When Codex prompts are selected without `-g`, skip them with a warning.

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
$ agconf fetch ./my-skills/web-design --dry-run -a universal
./my-skills/web-design/SKILL.md → .agents/skills/web-design/SKILL.md
```
````

Run cram tests:

```bash
moon cram test docs/fetch.md
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
