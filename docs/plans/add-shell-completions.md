# Plano: Adicionar Shell Completions com clap_complete

## Objetivo

Adicionar um subcomando `completions` ao CLI `scrut` que gera scripts de auto-complete para diferentes shells (bash, zsh, fish, powershell, elvish).

## Restrições

Por instruções dos maintainers upstream, todas as alterações devem estar confinadas a:
- `src/bin/main.rs`, ou
- Um novo ficheiro em `src/bin/` com prefixo `oss-`

## Abordagem

Modificar apenas `src/bin/main.rs` criando um novo enum `CliCommands` que encapsula os comandos existentes (`Create`, `Test`, `Update`) e adiciona o novo comando `Completions`. O enum original `Commands` de `root.rs` deixa de ser usado diretamente.

## Ficheiros a Modificar

### 1. `Cargo.toml`

Adicionar dependência:

```toml
clap_complete = "4.5"
```

### 2. `src/bin/main.rs`

Alterações:

1. **Novos imports:**
   ```rust
   use std::io;
   use clap::CommandFactory;
   use clap_complete::generate;
   use clap_complete::Shell;
   ```

2. **Remover import não utilizado:**
   ```rust
   // Remover: use commands::root::Commands;
   ```

3. **Novo struct para argumentos de completions:**
   ```rust
   #[derive(Debug, Parser)]
   struct CompletionsArgs {
       /// The shell to generate completions for
       #[clap(value_enum)]
       shell: Shell,
   }
   ```

4. **Novo enum que combina todos os comandos:**
   ```rust
   #[derive(Debug, Subcommand)]
   enum CliCommands {
       /// Create a test from a shell expression
       Create(commands::create::Args),
       /// Run tests from test files
       Test(commands::test::Args),
       /// Update test files with actual output
       Update(commands::update::Args),
       /// Generate shell completions
       Completions(CompletionsArgs),
   }
   ```

5. **Atualizar struct Args:**
   ```rust
   struct Args {
       #[clap(subcommand)]
       command: CliCommands,  // Era: commands: Commands
       // ...
   }
   ```

6. **Atualizar função main:**
   ```rust
   match app.command {
       CliCommands::Create(cmd) => handle_result(cmd.run()),
       CliCommands::Test(cmd) => handle_result(cmd.run()),
       CliCommands::Update(cmd) => handle_result(cmd.run()),
       CliCommands::Completions(args) => {
           let mut cmd = Args::command();
           generate(args.shell, &mut cmd, "scrut", &mut io::stdout());
           ExitCode::SUCCESS
       }
   }
   ```

7. **Extrair lógica de tratamento de erros para função auxiliar:**
   ```rust
   fn handle_result(result: anyhow::Result<()>) -> ExitCode {
       // ... lógica existente
   }
   ```

## Uso

Após implementação:

```bash
# Bash
scrut completions bash > ~/.bash_completion.d/scrut

# Zsh
scrut completions zsh > ~/.zfunc/_scrut

# Fish
scrut completions fish > ~/.config/fish/completions/scrut.fish
```

## Verificação

1. `cargo build` - deve compilar sem erros
2. `cargo test` - testes existentes devem passar
3. `./target/debug/scrut --help` - deve mostrar o subcomando `completions`
4. `./target/debug/scrut completions bash` - deve gerar script válido
5. `./target/debug/scrut completions zsh` - deve gerar script válido
