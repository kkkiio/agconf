///|
/// The kind of configuration file recognised by agconf.
pub(all) enum ContentKind {
  Skill
  Prompt
} derive(Eq, Debug)

///|
pub extend ContentKind with Eq::{not_equal, equal}

///|
pub extend ContentKind with Debug::{to_repr}

///|
pub(all) enum ConflictMode {
  Overwrite
  Skip
  Ask
} derive(Eq, Debug)

///|
pub extend ConflictMode with Eq::{not_equal, equal}

///|
pub extend ConflictMode with Debug::{to_repr}

///|
pub struct Item {
  kind : ContentKind
  source : String
  relative : String
  skill_name : String?
} derive(Eq, Debug)

///|
pub extend Item with Eq::{not_equal, equal}

///|
pub extend Item with Debug::{to_repr}

///|
fn join(left : String, right : String) -> String {
  if left == "" {
    right
  } else if left.has_suffix("/") {
    left + right
  } else {
    left + "/" + right
  }
}

///|
fn basename(path : String) -> String {
  let path = path.trim_end(chars="/")
  match path.rev_find("/") {
    Some(i) => path[i + 1:].to_owned()
    None => path.to_owned()
  }
}

///|
fn dirname(path : String) -> String {
  match path.rev_find("/") {
    Some(i) => path[:i].to_owned()
    None => ""
  }
}

///|
fn is_markdown(path : String) -> Bool {
  path.has_suffix(".md")
}

///|
fn is_inside_skills_directory(path : String) -> Bool {
  path.has_prefix("skills/") || path.find("/skills/") is Some(_)
}

///|
fn is_inside_content_directory(path : String) -> Bool {
  let name = basename(path)
  name == "prompts" ||
  name == "commands" ||
  path.has_prefix("prompts/") ||
  path.has_prefix("commands/") ||
  path.find("/prompts/") is Some(_) ||
  path.find("/commands/") is Some(_)
}

///|
fn discover_file(
  root : String,
  file : String,
  relative : String,
  explicit : Bool,
) -> Item? {
  let name = basename(file)
  if !explicit && (name == "README.md" || name == "CHANGELOG.md") {
    return None
  }
  if name == "SKILL.md" {
    return Some({
      kind: Skill,
      source: file,
      relative,
      skill_name: Some(basename(dirname(file))),
    })
  }
  if explicit && is_markdown(file) && !is_inside_skills_directory(file) {
    return Some({
      kind: Prompt,
      source: file,
      relative: basename(file),
      skill_name: None,
    })
  }
  if is_markdown(file) &&
    (
      relative.has_prefix("prompts/") ||
      relative.has_prefix("commands/") ||
      is_inside_content_directory(root)
    ) {
    let output_relative = if is_inside_content_directory(root) {
      relative
    } else {
      match relative.find("/") {
        Some(i) => relative[i + 1:].to_owned()
        None => relative
      }
    }
    return Some({
      kind: Prompt,
      source: file,
      relative: output_relative,
      skill_name: None,
    })
  }
  None
}

///|
async fn discover_tree(
  root : String,
  path : String,
  relative : String,
  items : Array[Item],
) -> Unit {
  let skill_file = join(path, "SKILL.md")
  if @fs.exists(skill_file) && @fs.kind(skill_file) is Regular {
    let skill_relative = if relative == "" {
      "SKILL.md"
    } else {
      join(relative, "SKILL.md")
    }
    match discover_file(root, skill_file, skill_relative, false) {
      Some(item) => items.push(item)
      None => ()
    }
    return
  }
  let entries = @fs.readdir(path, include_hidden=false, sort=true)
  for entry in entries {
    let child = join(path, entry)
    let child_relative = if relative == "" {
      entry
    } else {
      join(relative, entry)
    }
    match @fs.kind(child) {
      Directory => discover_tree(root, child, child_relative, items)
      Regular =>
        match discover_file(root, child, child_relative, false) {
          Some(item) => items.push(item)
          None => ()
        }
      _ => ()
    }
  }
}

///|
/// Discover only documented skill and prompt patterns below a source path.
pub async fn discover(path : String) -> Array[Item] {
  match @fs.kind(path) {
    Regular =>
      match discover_file(path, path, basename(path), true) {
        Some(item) => [item]
        None => []
      }
    Directory => {
      let items = []
      discover_tree(path, path, "", items)
      items
    }
    _ => []
  }
}

///|
fn parse_agent(agent : String) -> String raise {
  match agent {
    "universal" | "pi" | "codex" => agent
    _ =>
      raise Failure::Failure(
        "unknown agent: \{agent}; expected universal, pi, or codex",
      )
  }
}

///|
fn home() -> String raise {
  match @env.get_env_var("HOME") {
    Some(value) => value
    None => raise Failure::Failure("HOME is required for --global")
  }
}

///|
fn skills_directory(agent : String, global : Bool) -> String raise {
  let agent = parse_agent(agent)
  if global {
    let prefix = home()
    match agent {
      "pi" => join(prefix, ".pi/agent/skills")
      _ => join(prefix, ".agents/skills")
    }
  } else {
    match agent {
      "universal" | "codex" => ".agents/skills"
      "pi" => ".pi/skills"
      _ => abort("validated agent")
    }
  }
}

///|
fn prompts_directory(agent : String, global : Bool) -> String? raise {
  let agent = parse_agent(agent)
  match agent {
    "universal" => None
    "codex" if !global => None
    "codex" => Some(join(home(), ".codex/prompts"))
    "pi" if global => Some(join(home(), ".pi/agent/prompts"))
    "pi" => Some(".pi/prompts")
    _ => abort("validated agent")
  }
}

///|
async fn warn_unsupported_prompt(
  agent : String,
  global : Bool,
  warned_content : Array[String],
) -> Unit {
  let warning_key = agent + ":prompt"
  if warned_content.contains(warning_key) {
    return
  }
  warned_content.push(warning_key)
  let reason = match agent {
    "universal" => "universal has no prompts directory"
    "codex" if !global => "codex prompts require -g / --global"
    _ => abort("supported prompt destination")
  }
  @stdio.stderr.write("warning: \{reason}; skipping prompts for \{agent}\n")
}

///|
fn output_directory(
  kind : ContentKind,
  agent : String,
  global : Bool,
  as_prompt : Bool,
) -> String? raise {
  if as_prompt || kind is Prompt {
    prompts_directory(agent, global)
  } else {
    Some(skills_directory(agent, global))
  }
}

///|
fn unique_agents_for_item(
  item : Item,
  agents : Array[String],
  global : Bool,
  as_prompt : Bool,
) -> Array[String] raise {
  let target_agents = if agents.length() == 0 {
    if item.kind is Skill && !as_prompt {
      ["universal"]
    } else {
      ["pi", "codex", "universal"]
    }
  } else {
    agents
  }
  let unique_agents = []
  let seen_agents = []
  let seen_directories = []
  for agent in target_agents {
    if !seen_agents.contains(agent) {
      seen_agents.push(agent)
      match output_directory(item.kind, agent, global, as_prompt) {
        Some(directory) =>
          if !seen_directories.contains(directory) {
            seen_directories.push(directory)
            unique_agents.push(agent)
          }
        None => unique_agents.push(agent)
      }
    }
  }
  unique_agents
}

///|
fn frontmatter_close(text : String, from : Int32) -> Int32? {
  match text[from:].find("\n---") {
    None => None
    Some(offset) => {
      let after = from + offset + 4
      if after == text.length() ||
        text[after] == '\n' ||
        (
          after + 1 < text.length() &&
          text[after] == '\r' &&
          text[after + 1] == '\n'
        ) {
        Some(after)
      } else {
        frontmatter_close(text, after)
      }
    }
  }
}

///|
fn strip_frontmatter(text : String) -> String {
  let has_lf_open = text.has_prefix("---\n")
  let has_crlf_open = text.has_prefix("---\r\n")
  if !has_lf_open && !has_crlf_open {
    return text
  }
  let start = if has_crlf_open { 5 } else { 4 }
  match frontmatter_close(text, start) {
    None => text
    Some(after) =>
      if after == text.length() {
        ""
      } else if text[after] == '\n' {
        text[after + 1:].to_owned()
      } else {
        text[after + 2:].to_owned()
      }
  }
}

///|
async fn ensure_parent(path : String) -> Unit {
  let parent = dirname(path)
  if parent != "" && !@fs.exists(parent) {
    @fs.mkdir(parent, recursive=true)
  }
}

///|
async fn wants_overwrite(path : String, mode : ConflictMode) -> Bool {
  if !@fs.exists(path) {
    return true
  }
  match mode {
    Overwrite => true
    Skip => false
    Ask => {
      println("\{path} exists; overwrite? [y/N]")
      match @stdio.stdin.read_until("\n") {
        Some(answer) => answer.trim() == "y" || answer.trim() == "Y"
        None => false
      }
    }
  }
}

///|
fn validate_items(items : Array[Item], as_prompt : Bool) -> Unit raise {
  for item in items {
    if as_prompt && item.kind is Prompt {
      raise Failure::Failure("--as-prompt only accepts skills")
    }
  }
}

///|
async fn copy_source_file(
  source : String,
  shown_source : String,
  destination : String,
  dry_run : Bool,
  conflict : ConflictMode,
) -> Unit {
  if dry_run {
    println("\{shown_source} → \{destination}")
    return
  }
  if !wants_overwrite(destination, conflict) {
    println("Skipping \{shown_source} → \{destination}")
    return
  }
  ensure_parent(destination)
  @fs.write_file(
    destination,
    @fs.read_file(source),
    create_mode=CreateOrTruncate,
  )
  println("\{shown_source} → \{destination}")
}

///|
async fn copy_text_file(
  shown_source : String,
  destination : String,
  content : String,
  dry_run : Bool,
  conflict : ConflictMode,
) -> Unit {
  if dry_run {
    println("\{shown_source} → \{destination}")
    return
  }
  if !wants_overwrite(destination, conflict) {
    println("Skipping \{shown_source} → \{destination}")
    return
  }
  ensure_parent(destination)
  @fs.write_file(destination, content, create_mode=CreateOrTruncate)
  println("\{shown_source} → \{destination}")
}

///|
fn skill_shown_source(
  display_source : String,
  source : String,
  source_relative : String,
) -> String {
  if display_source == "" {
    source
  } else if display_source.has_suffix(".md") {
    join(dirname(display_source), source_relative)
  } else {
    join(display_source, source_relative)
  }
}

///|
async fn copy_skill_entry(
  source : String,
  relative : String,
  destination : String,
  display_source : String,
  dry_run : Bool,
  conflict : ConflictMode,
) -> Unit {
  match @fs.kind(source) {
    Directory =>
      copy_skill_tree(
        source, relative, destination, display_source, dry_run, conflict,
      )
    Regular =>
      copy_source_file(
        source,
        skill_shown_source(display_source, source, relative),
        destination,
        dry_run,
        conflict,
      )
    _ => ()
  }
}

///|
async fn copy_skill_tree(
  source_root : String,
  source_relative : String,
  destination_root : String,
  display_source : String,
  dry_run : Bool,
  conflict : ConflictMode,
) -> Unit {
  let entries = @fs.readdir(source_root, include_hidden=true, sort=true)
  let skill_source = join(source_root, "SKILL.md")
  if @fs.exists(skill_source) && @fs.kind(skill_source) is Regular {
    copy_skill_entry(
      skill_source,
      join(source_relative, "SKILL.md"),
      join(destination_root, "SKILL.md"),
      display_source,
      dry_run,
      conflict,
    )
  }
  // @fs.readdir sorts descending; visit the remaining paths in reverse.
  for index = entries.length() - 1; index >= 0; {
    let entry = entries[index]
    if entry != "SKILL.md" {
      copy_skill_entry(
        join(source_root, entry),
        join(source_relative, entry),
        join(destination_root, entry),
        display_source,
        dry_run,
        conflict,
      )
    }
    continue index - 1
  }
}

///|
fn source_relative(source : String, root : String) -> String {
  let prefix = join(root, "")
  if source.has_prefix(prefix) {
    source[prefix.length():].to_owned()
  } else {
    basename(source)
  }
}

///|
async fn copy_item(
  item : Item,
  display_source : String,
  source_root : String,
  agent : String,
  global : Bool,
  as_prompt : Bool,
  dry_run : Bool,
  conflict : ConflictMode,
  warned_content : Array[String],
) -> Unit {
  match (item.kind, as_prompt) {
    (Skill, true) => {
      let name = item.skill_name.unwrap_or(basename(dirname(item.source)))
      let shown_source = skill_shown_source(
        display_source,
        item.source,
        item.relative,
      )
      match prompts_directory(agent, global) {
        Some(directory) =>
          copy_text_file(
            shown_source,
            join(directory, name + ".md"),
            strip_frontmatter(@fs.read_file(item.source).text()),
            dry_run,
            conflict,
          )
        None => warn_unsupported_prompt(agent, global, warned_content)
      }
    }
    (Skill, false) => {
      let name = item.skill_name.unwrap_or(basename(dirname(item.source)))
      copy_skill_tree(
        dirname(item.source),
        dirname(item.relative),
        join(skills_directory(agent, global), name),
        display_source,
        dry_run,
        conflict,
      )
    }
    (Prompt, false) => {
      let shown_source = if display_source == "" {
        item.source
      } else if display_source.has_suffix(".md") {
        display_source
      } else {
        join(display_source, source_relative(item.source, source_root))
      }
      match prompts_directory(agent, global) {
        Some(directory) =>
          copy_source_file(
            item.source,
            shown_source,
            join(directory, item.relative),
            dry_run,
            conflict,
          )
        None => warn_unsupported_prompt(agent, global, warned_content)
      }
    }
    (Prompt, true) => raise Failure::Failure("--as-prompt only accepts skills")
  }
}

///|
/// Parse a GitHub URL into (repo, ref, subpath).
/// Accepted forms:
///   https://github.com/<owner>/<repo>
///   https://github.com/<owner>/<repo>/tree/<ref>/<path>
///   https://github.com/<owner>/<repo>/blob/<ref>/<path>
fn github_source(source : String) -> (String, String, String) raise {
  let raw = source[19:].to_owned()
  // Strip query, fragment, and an optional trailing slash.
  let path_only = match raw.find("?") {
    Some(i) => raw[:i]
    None =>
      match raw.find("#") {
        Some(i) => raw[:i]
        None => raw
      }
  }
  let pieces = path_only
    .trim_end(chars="/")
    .split("/")
    .map(piece => piece.to_owned())
    .collect()
  guard pieces.length() >= 2 else {
    raise Failure::Failure("invalid GitHub URL: \{source}")
  }
  if pieces.contains(".") || pieces.contains("..") {
    raise Failure::Failure(
      "invalid GitHub URL: path must not contain '..' or '.' segments",
    )
  }
  let repo = pieces[0] + "/" + pieces[1]
  if pieces.length() == 2 {
    (repo, "", "")
  } else if pieces.length() >= 4 && (pieces[2] == "tree" || pieces[2] == "blob") {
    let rest = if pieces.length() > 4 { pieces[4:].join("/") } else { "" }
    if pieces[2] == "blob" && rest == "" {
      raise Failure::Failure(
        "invalid GitHub URL: blob URL requires a file path",
      )
    }
    (repo, pieces[3], rest)
  } else {
    raise Failure::Failure(
      "invalid GitHub URL: expected /tree/<ref>/<path> or /blob/<ref>/<path>",
    )
  }
}

///|
fn github_clone_url(repo : String) -> String {
  let repository = if repo.has_suffix(".git") { repo } else { repo + ".git" }
  "https://github.com/\{repository}"
}

///|
fn is_local_path(source : String) -> Bool {
  source == "." ||
  source == ".." ||
  source.has_prefix("./") ||
  source.has_prefix("../") ||
  source.has_prefix("/")
}

///|
async fn fetch_local(
  source : String,
  agents : Array[String],
  global : Bool,
  as_prompt : Bool,
  dry_run : Bool,
  conflict : ConflictMode,
) -> Unit {
  if !@fs.exists(source) {
    raise Failure::Failure("local source does not exist: \{source}")
  }
  let items = discover(source)
  if items.length() == 0 {
    raise Failure::Failure("no recognised content in \{source}")
  }
  validate_items(items, as_prompt)
  let warned_content = []
  for item in items {
    for agent in unique_agents_for_item(item, agents, global, as_prompt) {
      copy_item(
        item, "", source, agent, global, as_prompt, dry_run, conflict, warned_content,
      )
    }
  }
}

///|
async fn fetch_github(
  source : String,
  git_ref : String,
  agents : Array[String],
  global : Bool,
  as_prompt : Bool,
  dry_run : Bool,
  conflict : ConflictMode,
) -> Unit {
  let (repo, url_ref, subpath) = github_source(source)
  let selected_ref = if git_ref == "" { url_ref } else { git_ref }
  @async.with_task_group() <| group => {
    let tmp = @fs.tmpdir(prefix="agconf")
    group.add_defer() <| () => {
      @async.protect_from_cancel(() => @fs.rmdir(tmp, recursive=true))
    }
    let checkout = join(tmp, "repo")
    let args = ["clone", "--depth", "1"]
    if selected_ref != "" {
      args.push("--branch")
      args.push(selected_ref)
    }
    args.push(github_clone_url(repo))
    args.push(checkout)
    let (status, _, _) = @process.collect_output("git", args)
    if status != 0 {
      raise Failure::Failure("git clone failed for \{repo}")
    }
    let selected = if subpath == "" {
      checkout
    } else {
      join(checkout, subpath)
    }
    if !@fs.exists(selected) {
      raise Failure::Failure("GitHub path not found: \{subpath}")
    }
    let items = discover(selected)
    if items.length() == 0 {
      raise Failure::Failure("no recognised content in \{source}")
    }
    validate_items(items, as_prompt)
    let warned_content = []
    for item in items {
      for agent in unique_agents_for_item(item, agents, global, as_prompt) {
        copy_item(
          item, source, selected, agent, global, as_prompt, dry_run, conflict, warned_content,
        )
      }
    }
  }
}

///|
/// Fetch a local path or GitHub URL into agent configuration directories.
pub async fn fetch(
  source : String,
  agents~ : Array[String] = [],
  global~ : Bool = false,
  as_prompt~ : Bool = false,
  git_ref~ : String = "",
  dry_run~ : Bool = false,
  conflict~ : ConflictMode = Overwrite,
) -> Unit {
  for agent in agents {
    ignore(parse_agent(agent))
  }
  let local_exists = @fs.exists(source) catch { _ => false }
  if local_exists || is_local_path(source) {
    fetch_local(source, agents, global, as_prompt, dry_run, conflict)
  } else if source.has_prefix("https://github.com/") {
    fetch_github(source, git_ref, agents, global, as_prompt, dry_run, conflict)
  } else {
    raise Failure::Failure(
      "unsupported source: \{source}; use a https://github.com/ URL or local path",
    )
  }
}
