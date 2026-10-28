///|
fn conflict_mode(value : String) -> @lib.ConflictMode raise {
  match value {
    "overwrite" => Overwrite
    "skip" => Skip
    "ask" => Ask
    _ =>
      raise Failure::Failure(
        "invalid --conflict value: \{value}; expected overwrite, skip, or ask",
      )
  }
}

///|
async fn run() -> Unit {
  let command = @argparse.Command(
    "agconf",
    about="Copy AI agent skills and prompts from local paths or GitHub",
    subcommand_required=true,
    subcommands=[
      @argparse.Command(
        "fetch",
        about="Fetch recognised skills and prompts",
        flags=[
          @argparse.FlagArg(
            "global",
            short='g',
            about="install to the user directory",
          ),
          @argparse.FlagArg("dry-run", about="show operations without writing"),
        ],
        options=[
          @argparse.OptionArg(
            "agent",
            short='a',
            action=Append,
            about="target agent (repeatable; skills default: universal)",
          ),
          @argparse.OptionArg("ref", about="GitHub branch or tag"),
          @argparse.OptionArg(
            "conflict",
            default_values=["overwrite"],
            about="overwrite, skip, or ask",
          ),
        ],
        positionals=[
          @argparse.PositionArg(
            "source",
            num_args=@argparse.ValueRange::single(),
            about="local path or GitHub source",
          ),
        ],
      ),
    ],
  )
  let matches = command.parse()
  guard matches.subcommand is Some(("fetch", fetch)) else { return }
  guard fetch.values.get("source") is Some([source]) else {
    raise Failure::Failure("source is required")
  }
  let agents = fetch.values.get("agent").unwrap_or([])
  let git_ref = match fetch.values.get("ref") {
    Some([value]) => value
    _ => ""
  }
  let conflict = match fetch.values.get("conflict") {
    Some([value]) => conflict_mode(value)
    _ => Overwrite
  }
  @lib.fetch(
    source,
    agents~,
    global=fetch.flags.get_or_default("global", false),
    git_ref~,
    dry_run=fetch.flags.get_or_default("dry-run", false),
    conflict~,
  )
}

///|
#cfg(target="native")
extern "C" fn exit_with_error(code : Int32) = "exit"

///|
#cfg(target="wasm")
fn exit_with_error(code : Int32) = "moonbitlang/async" "runtime/exit"

///|
async fn main {
  run() catch {
    Failure::Failure(message) => {
      @stdio.stderr.write(message + "\n")
      exit_with_error(1)
    }
    error => {
      @stdio.stderr.write("\{error}\n")
      exit_with_error(1)
    }
  }
}
