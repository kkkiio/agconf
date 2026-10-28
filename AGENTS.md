# AGENTS.md

## Project Structure Guide

### Repo Structure & Important Files

```text
.
├── main.mbt                   # CLI entry point (root package, executable)
├── lib/
│   ├── agconf.mbt             # Library: public API and shared helpers
│   ├── agconf_test.mbt        # Blackbox tests (public API)
│   └── moon.pkg               # Library package config
├── moon.mod                   # Module metadata and dependencies
├── moon.pkg                   # Root package config (kind: executable)
├── README.md                  # User-facing documentation
├── .githooks/
│   └── pre-commit             # Git pre-commit hook
├── .github/
│   └── workflows/             # CI workflows
└── .agents/
    └── drift-notes/           # Implementation deviation logs
```

### Architecture Guidelines

- Keep `main.mbt` thin; move logic into the `lib` package (`KKKIIO/agconf/lib`). Main packages cannot host blackbox `_test.mbt` tests, and depending on a main package is deprecated.

## Domain Language

- **Skill** — A directory containing `SKILL.md` with YAML frontmatter (`name`, `description`).
- **Prompt** — A standalone `.md` file (no frontmatter) placed in an agent's prompts directory.
- **Command** — The same artifact as Prompt under the terminology used by Claude Code and Cursor.
- **Agent** — A target coding agent CLI identified by `--agent` / `-a`.
- **Universal** — The shared agent path `.agents/skills/`, read by multiple agents.

## Policies & Mandatory Rules

### No State Management

When changing installation behavior, keep agconf stateless: copy files from source to destination without install-state tracking, lockfiles, dependency resolution, or package registries.

### Compatibility Policy

When changing public APIs, CLI flags, or output paths:

- Treat the 0.x project as having zero stability guarantees.
- Prefer direct migrations over compatibility layers.
- Document intentional breaking changes in commit messages and update `README.md` when output paths or CLI flags change.

### Less Comments

Don't comments in implementations.

Write API docs comments with:

- One line description.
- Edge Cases.

### Documentation Intent Principle

When intent changes, update documents before code. Record current intent only, and keep implementation aligned with it.

## Operation Guide

### Feedback Loop

```bash
just check
just fmt
just test
just build
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

### Coverage

```bash
moon coverage analyze > uncovered.log
```

### Release

1. Bump `version` in `moon.mod` (the release tag must match it).
2. Create a **draft** GitHub release for the tag.
3. Review it, then click Publish.
   `release.yml` triggers on `release: published`: it uploads the built
   artifacts to that release and runs `moon publish` to mooncakes (needs the
   `MOONCAKES_TOKEN` repo secret). mooncakes then builds the prebuilt wasm
   asset that `moonx KKKIIO/agconf` downloads.

### Testing Conventions

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for stable results.
- Use `debug_inspect` (requires `Debug` derive) for snapshot tests, not `Show`.
- Use `moon cram test` for CLI-level integration tests that verify end-to-end behavior.
