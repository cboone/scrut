---
sidebar_position: 1
---

import OssNote from '../fb/components/_oss-note.md';

# Installation

<FbInternalOnly><OssNote /></FbInternalOnly>


We provide a couple of different ways to install Scrut. Choose whatever fits best for you:

## Install via Script (Linux, Mac)

Execute the following from your shell:

```bash title="Terminal"
$ curl --proto '=https' --tlsv1.2 -sSf https://facebookincubator.github.io/scrut/install.sh | sh
```

This will
- Download and unpack the latest Scrut binary
- Install the binary in your local path (either `~/bin` or `~/.local/bin`, whichever exists)

The following parameters are supported:

| Name                        | Description                                           | Default                           |
| --------------------------- | ----------------------------------------------------- | --------------------------------- |
| `--verbose`, `-v`           | Explicitly log everything that is executed (`set -x`) | -                                 |
| `--owner-repo`, `-r`        | Github owner and repository in format OWNER/REPO      | `facebookincubator/scrut`         |
| `--installation-path`, `-p` | Set installation path                                 | `$HOME/bin` or `$HOME/.local/bin` |

You can supply them by appending them like so:

```bash title="Terminal"
$ curl --proto '=https' --tlsv1.2 -LsSf https://facebookincubator.github.io/scrut/install.sh | sh -s -- -p /my/install/directory
```

## Install via Pre-Build Binaries (Linux, Mac, Windows)

Head over to [https://github.com/facebookincubator/scrut/releases/latest](https://github.com/facebookincubator/scrut/releases/latest) and select the appropriate binary for your operating system.

Once downloaded and unpacked move the binary `scrut` (or `scrut.exe` on Windows) to a directory in your `PATH`.

## Install via Cargo (Linux, Mac, Windows)

You need to have a working [Rust setup](https://www.rust-lang.org/tools/install) installed on your local machine. Then you can build and install the `scrut` binary as any other Rust binary:

```bash
$ cargo install scrut
```

This will install the `scrut` binary after building it in your local cargo binary folder (`~/.cargo/bin` on Linux and Mac, `%USERPROFILE%\.cargo\bin` on Windows).

If you want to install the binary manually then you need to check out the [repository](https://github.com/facebookincubator/scrut) and then build it with:

```
$ cargo build --release --bin scrut
```

This will create `target/release/scrut` which you now can move to a directory in your `PATH`.

## Install via Homebrew (Linux, Mac)

If you have [Homebrew](https://brew.sh/) installed, you can install Scrut with:

```bash title="Terminal"
$ brew tap facebookincubator/scrut
$ brew install scrut
```

This will download the latest pre-built binary for your platform and install it in your Homebrew prefix (typically `/opt/homebrew/bin` on Apple Silicon Macs or `/usr/local/bin` on Intel Macs and Linux). Shell completions for Bash, Fish, PowerShell, and Zsh are installed automatically. For Elvish, you'll have to install completions manually; see [the instructions below](#shell-completions).

## Verify

Now that you have downloaded the binary and stored it in your `PATH` verify that you can execute the following before proceeding:

```bash title="Terminal"
$ scrut --version
scrut v0.X.Y
```

(You will see the latest version here)

## Shell Completions

Scrut can generate shell completion scripts for tab-completion of commands and options.

:::note
If you installed via Homebrew, completions are already installed automatically.
:::

Generate and install completions for your shell using the `completions` subcommand:

### Bash

```bash title="Terminal"
$ scrut completions bash > ~/.local/share/bash-completion/completions/scrut
```

Or, if using an older setup:

```bash title="Terminal"
$ scrut completions bash > ~/.bash_completion.d/scrut
```

### Zsh

```bash title="Terminal"
$ scrut completions zsh > ~/.zfunc/_scrut
```

Then ensure your `~/.zshrc` includes:

```bash
fpath=(~/.zfunc $fpath)
autoload -Uz compinit && compinit
```

### Fish

```bash title="Terminal"
$ scrut completions fish > ~/.config/fish/completions/scrut.fish
```

### PowerShell

```powershell title="PowerShell"
$ scrut completions powershell > scrut.ps1
$ . ./scrut.ps1
```

To load completions automatically, add the above to your PowerShell profile.

### Elvish

```elvish title="Elvish"
$ scrut completions elvish > ~/.config/elvish/lib/scrut.elv
```

Then add to your `~/.config/elvish/rc.elv`:

```elvish
use scrut
```
