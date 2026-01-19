# Plan: Click-style Shell Completions for Scrut

## Summary

Implement shell completions following Click's environment variable model, as requested in [PR #47](https://github.com/facebookincubator/scrut/pull/47) feedback. The approach checks an environment variable (`_SCRUT_COMPLETE`) **before** argument parsing to avoid issues with required arguments.

## Background

The upstream maintainers rejected the original subcommand approach because:
> "adding a subcommand means we have to be able to parse the arguments which you cannot always do. For example when you have a global required option."

They requested following Click's model where completions are triggered via environment variable, checked before parsing.

## Design

### Click's Model

Click uses `_PROGRAM_COMPLETE` environment variable with values like:
- `bash_source` - Generate bash completion script
- `zsh_source` - Generate zsh completion script
- `fish_source` - Generate fish completion script
- `powershell_source` - Generate PowerShell completion script
- `elvish_source` - Generate elvish completion script

### Implementation Approach

Check `_SCRUT_COMPLETE` at the very start of `main()`, before `Args::parse()`. If set, generate the completion script using stable `clap_complete` and exit. This avoids clap's argument validation entirely.

## Changes

### 1. Cargo.toml

Add `clap_complete` dependency:

```toml
clap_complete = "4.5"
```

### 2. src/bin/main.rs

Add imports:
```rust
use clap::CommandFactory;
use clap_complete::aot::generate;
use clap_complete::aot::Shell;
```

Add completion handler function:
```rust
fn handle_completion_request() -> Option<ExitCode> {
    let completion_value = env::var("_SCRUT_COMPLETE").ok()?;

    let shell = match completion_value.as_str() {
        "bash_source" => Shell::Bash,
        "elvish_source" => Shell::Elvish,
        "fish_source" => Shell::Fish,
        "powershell_source" => Shell::PowerShell,
        "zsh_source" => Shell::Zsh,
        _ => {
            eprintln!(
                "Error: Invalid value for _SCRUT_COMPLETE: '{}'\n\
                Valid values: bash_source, elvish_source, fish_source, powershell_source, zsh_source",
                completion_value
            );
            return Some(ExitCode::FAILURE);
        }
    };

    let mut command = Args::command();
    generate(shell, &mut command, "scrut", &mut std::io::stdout());
    Some(ExitCode::SUCCESS)
}
```

Modify `main()` to call handler first:
```rust
pub fn main() -> ExitCode {
    // Handle Click-style completions before argument parsing
    if let Some(exit_code) = handle_completion_request() {
        return exit_code;
    }

    // ... rest of existing code unchanged ...
}
```

## Usage

Users generate completion scripts with:

```bash
# Bash
_SCRUT_COMPLETE=bash_source scrut > ~/.local/share/bash-completion/completions/scrut

# Zsh
_SCRUT_COMPLETE=zsh_source scrut > ~/.zsh/completions/_scrut

# Fish
_SCRUT_COMPLETE=fish_source scrut > ~/.config/fish/completions/scrut.fish
```

Or add to shell config for dynamic generation:
```bash
# ~/.bashrc
eval "$(_SCRUT_COMPLETE=bash_source scrut)"
```

## Files Modified

| File | Change |
|------|--------|
| `Cargo.toml` | Add `clap_complete = "4.5"` dependency |
| `src/bin/main.rs` | Add imports, completion handler, modify `main()` |
| `selftest/commands/completions.md` | New selftest file for completions |

### 3. selftest/commands/completions.md (new file)

Test file to verify completion generation:

```markdown
# Shell Completions

## Bootstrap

```scrut
$ . "${TESTDIR}/setup.sh"
OK
```

## Bash completions contain scrut and subcommands

```scrut
$ _SCRUT_COMPLETE=bash_source "${SCRUT_BIN}" | head -30
_scrut() { (regex)
* (glob+)
```

## Zsh completions contain scrut and subcommands

```scrut
$ _SCRUT_COMPLETE=zsh_source "${SCRUT_BIN}" | head -30
#compdef scrut (regex)
* (glob+)
```

## Fish completions contain scrut and subcommands

```scrut
$ _SCRUT_COMPLETE=fish_source "${SCRUT_BIN}" | head -10
* scrut * (glob+)
```

## Invalid completion value shows error

```scrut
$ _SCRUT_COMPLETE=invalid "${SCRUT_BIN}" 2>&1
Error: Invalid value for _SCRUT_COMPLETE: 'invalid'
Valid values: bash_source, elvish_source, fish_source, powershell_source, zsh_source
[1]
```

## Normal operation unaffected when env var not set

```scrut
$ "${SCRUT_BIN}" --help | head -5
A testing toolkit to scrutinize CLI applications

Usage: scrut(?:\.exe)? * (regex)

Commands:
```
```

## Key Decisions

1. **All code in main.rs**: Keeps changeset minimal. No separate module needed for this simple feature.

2. **Stable API only**: Uses `clap_complete::aot::{generate, Shell}`, not the unstable `CompleteEnv`.

3. **Click naming convention**: `_SCRUT_COMPLETE` with `*_source` suffixes matches Click's pattern.

4. **Early exit**: When generating completions, exit immediately without parsing arguments.

## Verification

```bash
# Build
cargo build --bin scrut

# Test completion generation for each shell
_SCRUT_COMPLETE=bash_source ./target/debug/scrut | head -20
_SCRUT_COMPLETE=zsh_source ./target/debug/scrut | head -20
_SCRUT_COMPLETE=fish_source ./target/debug/scrut | head -20

# Test error handling
_SCRUT_COMPLETE=invalid ./target/debug/scrut
# Should print error and exit with failure

# Verify normal operation unaffected
./target/debug/scrut --help

# Run all tests (includes the new completions selftest)
make test

# Or run just the new completions test
SCRUT_BIN=./target/debug/scrut ./target/debug/scrut test selftest/commands/completions.md
```
