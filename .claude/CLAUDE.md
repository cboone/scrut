# Scrut

Scrut is a CLI testing toolkit for terminal programs, inspired by Cram. It validates CLI behavior using Markdown (`.md`) or Cram (`.t`) test files.

This is Christopher Boone's fork <https://github.com/cboone/scrut> of the primary repo <https://github.com/facebookincubator/scrut>.

## Commit messages

While working in this repo, follow the upstream repo's commit message conventions, **not my usual Conventional Commits style**. That means short messages, just one line with the overall summary of what was done; beginning with an uppercase letter; no category indicator at the beginning; just an imperative verb and then the rest. For example: `Add completions using clap_complete`.

## Project Structure

- `src/lib.rs` - Library entry point with public modules
- `src/bin/` - CLI application (`scrut` binary)
  - `commands/` - Subcommands: `create`, `test`, `update`
  - `utils/` - CLI utilities
- `src/executors/` - Test execution engines
- `src/parsers/` - Markdown and Cram file parsers
- `src/generators/` - Output generators
- `src/renderers/` - Result renderers (pretty, diff, JSON, YAML)
- `src/rules/` - Matching rules (equal, glob, regex, escaped)
- `selftest/` - Integration tests using Scrut's own format

## Development

### Build

```bash
cargo build --bin scrut
```

### Testing

Run all tests:

```bash
make test
```

Run only unit tests:

```bash
cargo test --features volatile_tests
```

Run only selftests (integration tests):

```bash
make selftest
```

Update selftests when expected output changes:

```bash
make update_tests
```

### Test Files

- Markdown tests: `selftest/**/*.md`
- Cram tests: `selftest/**/*.t`
- Files with `fail` in the name are expected to fail and are excluded from normal test runs

## Code Style

- Rust edition 2024, minimum Rust version 1.85
- Uses `#[macro_use]` for `derivative` and `lazy_static`
- Error handling with `anyhow` and `thiserror`
- CLI parsing with `clap` (derive macros)
- Snapshot testing with `insta` in dev dependencies

## Architecture Notes

- `DocumentConfig` - Per-document configuration
- `TestCaseConfig` - Per-test configuration
- `OutputStreamControl` - Controls stdout/stderr handling
- `Escaper` - Output escaping (Unicode for Markdown, ASCII for Cram)
- `ParserType` - Markdown or Cram parser selection
