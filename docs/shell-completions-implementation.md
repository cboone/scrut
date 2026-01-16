# Shell Completions Implementation Guide

This document explains the changes made to add shell completions to scrut, aimed at someone new to Rust.

## Overview

Shell completions allow users to press Tab in their terminal and have the shell automatically suggest or complete command names, flags, and arguments. This feature uses the `clap_complete` crate, which works alongside `clap` (the library scrut uses for command-line argument parsing).

## Changes Made

### 1. Cargo.toml — Adding the Dependency

```toml
clap_complete = "4.5"
```

**What it does:** This line tells Cargo (Rust's package manager) to download and include the `clap_complete` library in the project.

**Why it's needed:** `clap_complete` is a companion crate to `clap` that knows how to generate completion scripts for various shells. Without it, we'd have to write shell-specific completion scripts manually for each shell (bash, zsh, fish, etc.), which would be error-prone and hard to maintain.

---

### 2. New Imports in main.rs

```rust
use std::io;
use clap::CommandFactory;
use clap::Subcommand;
use clap_complete::generate;
use clap_complete::Shell;
```

**What each import does:**

| Import | Purpose |
|--------|---------|
| `std::io` | Provides access to standard input/output. We use `io::stdout()` to write completion scripts to the terminal. |
| `clap::CommandFactory` | A trait that lets us get the `Command` structure from our `Args` struct. This is needed because `clap_complete` needs the full command definition to generate completions. |
| `clap::Subcommand` | A derive macro that tells clap our enum represents subcommands (like `create`, `test`, `update`, `completions`). |
| `clap_complete::generate` | The function that actually generates the completion script for a given shell. |
| `clap_complete::Shell` | An enum representing the supported shells (Bash, Zsh, Fish, PowerShell, Elvish). |

**Why they're needed:** Each import brings in functionality we use in the implementation. Rust requires explicit imports — unlike some languages, nothing is automatically available.

---

### 3. CompletionsArgs Struct

```rust
#[derive(Debug, Parser)]
struct CompletionsArgs {
    /// The shell to generate completions for
    #[clap(value_enum, id = "target_shell")]
    target_shell: Shell,
}
```

**What it does:** Defines the arguments for the `completions` subcommand.

**Breaking it down:**

- `#[derive(Debug, Parser)]` — These are «derive macros» that automatically generate code:
  - `Debug` lets Rust print the struct for debugging
  - `Parser` (from clap) generates the argument parsing code

- `/// The shell to generate completions for` — This doc comment becomes the help text shown when running `scrut completions --help`

- `#[clap(value_enum, id = "target_shell")]` — Attributes that configure the argument:
  - `value_enum` tells clap that `Shell` is an enum and should show its variants as valid values
  - `id = "target_shell"` gives this argument an explicit ID to avoid conflicts (see below)

- `target_shell: Shell` — The actual field. `Shell` is the enum from `clap_complete` with variants like `Bash`, `Zsh`, etc.

**Why `id = "target_shell"`?** The existing `GlobalParameters` struct already has a `--shell` flag (for specifying which shell to run tests in). If we named our field `shell`, clap would get confused because both would have the same ID. Using `target_shell` as the ID avoids this conflict while still showing as a positional argument in the CLI.

---

### 4. CliCommands Enum

```rust
#[derive(Debug, Subcommand)]
enum CliCommands {
    Create(commands::create::Args),
    Test(commands::test::Args),
    Update(commands::update::Args),
    /// Generate shell completions
    Completions(CompletionsArgs),
}
```

**What it does:** Defines all available subcommands, including our new `completions` command.

**Breaking it down:**

- `#[derive(Debug, Subcommand)]` — The `Subcommand` derive macro tells clap this enum represents the CLI's subcommands

- Each variant represents a subcommand:
  - `Create(commands::create::Args)` — The `create` subcommand, with its arguments defined in `commands/create.rs`
  - `Test(commands::test::Args)` — The `test` subcommand
  - `Update(commands::update::Args)` — The `update` subcommand
  - `Completions(CompletionsArgs)` — Our new subcommand, with arguments defined above

- Note that we only add a doc comment (`///`) for `Completions`. The other variants inherit their descriptions from the doc comments on their respective `Args` structs in the original files. This keeps the help text identical to the original.

**Why create a new enum instead of modifying the existing `Commands` enum?** The upstream maintainers requested that changes be confined to `main.rs` or new files with the `oss-` prefix. The existing `Commands` enum is in `commands/root.rs`, which we cannot modify. By creating `CliCommands` in `main.rs`, we respect this constraint while still adding our subcommand.

---

### 5. Updated Args Struct

```rust
#[derive(Debug, Parser)]
#[clap(about = "A testing toolkit to scrutinize CLI applications", version = VERSION)]
struct Args {
    #[clap(subcommand)]
    command: CliCommands,  // Changed from: commands: Commands

    #[clap(flatten)]
    global: GlobalParameters,
}
```

**What changed:** The `commands` field (using the old `Commands` enum) was replaced with `command` (using our new `CliCommands` enum).

**Why:** This connects our new enum to the argument parser. When a user runs `scrut completions bash`, clap will parse this and populate `command` with `CliCommands::Completions(CompletionsArgs { target_shell: Shell::Bash })`.

---

### 6. Updated main() Function

```rust
let result = match app.command {
    CliCommands::Create(cmd) => cmd.run(),
    CliCommands::Test(cmd) => cmd.run(),
    CliCommands::Update(cmd) => cmd.run(),
    CliCommands::Completions(args) => {
        let mut cmd = Args::command();
        generate(args.target_shell, &mut cmd, "scrut", &mut io::stdout());
        return ExitCode::SUCCESS;
    }
};

if let Err(err) = result {
    // ... existing error handling unchanged ...
}
```

**What it does:** Routes to the appropriate code based on which subcommand the user ran.

**Breaking it down:**

- `let result = match app.command` — Rust's pattern matching. It checks which variant of `CliCommands` we have and runs the corresponding code, storing the result.

- For `Create`, `Test`, and `Update`: we call `cmd.run()` and let the existing error handling code process the result.

- For `Completions`:
  1. `Args::command()` — Gets the full command definition from our `Args` struct. This is provided by the `CommandFactory` trait we imported.
  2. `generate(args.target_shell, &mut cmd, "scrut", &mut io::stdout())` — Generates the completion script:
     - `args.target_shell` — Which shell to generate for (bash, zsh, etc.)
     - `&mut cmd` — The command definition (mutable reference because generate modifies it internally)
     - `"scrut"` — The binary name to use in the completion script
     - `&mut io::stdout()` — Where to write the output (standard output)
  3. `return ExitCode::SUCCESS` — Return early with success (exit code 0), bypassing the error handling code which doesn't apply to completions.

The existing error handling logic after the match remains completely unchanged.

---

## What Was Removed

```rust
// Removed import:
use commands::root::Commands;
```

The `Commands` import is no longer needed because we use `CliCommands` instead.

---

## Side Effect: Dead Code Warning

After these changes, you'll see this warning when compiling:

```text
warning: method `run` is never used
  --> src/bin/commands/root.rs:28:19
```

This happens because the `Commands::run()` method in `root.rs` is no longer called — we call each subcommand's `run()` method directly from our `match` statement. Since we cannot modify `root.rs`, this warning will remain. It's harmless and doesn't affect functionality.

---

## How It All Fits Together

1. User runs: `scrut completions bash`
2. Clap parses arguments into `Args { command: CliCommands::Completions(CompletionsArgs { target_shell: Shell::Bash }), global: ... }`
3. The `match` statement sees `CliCommands::Completions` and runs that branch
4. `Args::command()` builds the full command tree (all subcommands, flags, etc.)
5. `generate()` walks that command tree and outputs bash-specific completion code
6. The completion script is printed to stdout
7. User can redirect this to a file and source it in their shell config

---

## Usage Examples

```bash
# Generate and install bash completions
scrut completions bash > ~/.local/share/bash-completion/completions/scrut

# Generate and install zsh completions
scrut completions zsh > ~/.zfunc/_scrut
# Then add to ~/.zshrc: fpath=(~/.zfunc $fpath) && autoload -Uz compinit && compinit

# Generate and install fish completions
scrut completions fish > ~/.config/fish/completions/scrut.fish

# Generate PowerShell completions
scrut completions powershell > scrut.ps1
# Then dot-source it: . ./scrut.ps1

# Generate elvish completions
scrut completions elvish > ~/.elvish/lib/scrut.elv
```
