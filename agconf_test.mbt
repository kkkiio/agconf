// Blackbox tests run against the package's public API. Use `@agconf` to import.
// Prefer high-level behaviors over implementation details.

///|
async test "discover treats a directory containing SKILL.md as one skill" {
  @async.with_task_group() <| group => {
    let root = @fs.tmpdir(prefix="agconf-discover")
    group.add_defer() <| () => {
      @async.protect_from_cancel(() => @fs.rmdir(root, recursive=true))
    }
    @fs.mkdir(root + "/skills/web", recursive=true)
    @fs.mkdir(root + "/prompts/nested", recursive=true)
    @fs.mkdir(root + "/commands", recursive=true)
    @fs.mkdir(root + "/other", recursive=true)
    @fs.write_file(root + "/SKILL.md", "root", create_mode=CreateOrTruncate)
    @fs.write_file(
      root + "/skills/web/SKILL.md",
      "web",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(
      root + "/prompts/nested/review.md",
      "review",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(
      root + "/commands/check.md",
      "check",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(root + "/README.md", "ignore", create_mode=CreateOrTruncate)
    @fs.write_file(
      root + "/other/notes.md",
      "ignore",
      create_mode=CreateOrTruncate,
    )

    let items = @agconf.discover(root)
    assert_eq(items.length(), 1)
    assert_eq(@agconf.discover(root + "/SKILL.md").length(), 1)
  }
}

///|
async test "discover supports selected content directories and explicit Markdown files" {
  @async.with_task_group() <| group => {
    let root = @fs.tmpdir(prefix="agconf-selected-content")
    group.add_defer() <| () => {
      @async.protect_from_cancel(() => @fs.rmdir(root, recursive=true))
    }
    @fs.mkdir(root + "/skills/web", recursive=true)
    @fs.mkdir(root + "/prompts/nested", recursive=true)
    @fs.write_file(
      root + "/skills/web/SKILL.md",
      "skill",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(
      root + "/prompts/nested/review.md",
      "prompt",
      create_mode=CreateOrTruncate,
    )
    @fs.write_file(root + "/README.md", "readme", create_mode=CreateOrTruncate)
    @fs.write_file(
      root + "/skills/web/notes.md",
      "not a prompt",
      create_mode=CreateOrTruncate,
    )

    assert_eq(@agconf.discover(root + "/skills").length(), 1)
    assert_eq(@agconf.discover(root + "/prompts").length(), 1)
    // Explicit Markdown files outside skills are prompts, including README.md.
    assert_eq(@agconf.discover(root + "/README.md").length(), 1)
    assert_eq(@agconf.discover(root + "/skills/web/notes.md").length(), 0)
  }
}
