# Public Dotfiles

Standalone macOS/Linux dotfiles using GNU Stow. This repository installs public tools and configuration without a private checkout, work token, internal package feed, or work keychain. A private orchestrator may supply one explicit overlay; the public installer never discovers or clones one itself.

**Validation status:** This repository starts with fresh history rather than importing the original private repository's history. Real installation and regression checks have been exercised in disposable Ubuntu ARM64 containers; host installation and native Codespaces validation have not been performed. Third-party notices for copied components are recorded in `THIRD_PARTY_NOTICES.md`.

## Prerequisites

Bash, Python 3.9+, Git, curl, and platform build prerequisites are needed. Python is used only through the standard library; no Python packages are installed. Linux Homebrew bootstrap requires a supported image and compiler/system libraries. On macOS, install the Command Line Tools first. If Homebrew is missing, the tools phase runs its official non-interactive installer; it does not configure sudo access or change the login shell.

```bash
./install.sh --help
./install.sh --plan
./install.sh
```

Read the plan and resolve conflicts before applying. The default profile is `codespaces` when `CODESPACES=true`, otherwise `desktop`. Desktop casks and terminal packages are selected only on macOS. Nothing installs or upgrades on shell startup through the installer.

| Option                                       | Behavior                                                                                                         |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `--plan`                                     | Read-only ownership/filesystem plan; no downloads, locks, log files, dependency installs, or destination changes |
| `--profile desktop` / `--profile codespaces` | Select an explicit package manifest; Codespaces excludes macOS desktop tools                                     |
| `--tools-only`                               | Provision selected dependencies without linking configuration                                                    |
| `--config-only`                              | Require tools to exist, then apply configuration without downloading dependencies                                |
| `--with-optional`                            | Also install the optional Brewfile                                                                               |
| `--overlay /absolute/root`                   | Explicitly add one compatible private source root                                                                |
| `--target /existing/directory`               | Configuration target for an isolated plan or config-only run; tools may only target the real home                |
| `--backup-file relative/path`                | Authorize backing up exactly one selected conflicting file; repeat for other individually approved files         |
| `--non-interactive`                          | Explicit automation intent; operations already avoid prompts and never infer overwrite permission                |

`--plan`, `--tools-only`, and `--config-only` are mutually exclusive. Planning validates destinations without invoking Stow; an actual apply also runs Stow simulations after any authorized backups. A plan is not evidence that dependencies, plugin downloads, credentials, or remote services work.

## Sources of Truth

`profiles/*.packages` lists Stow package directories. `desktop.macos.packages` adds desktop-only files. `profiles/required.commands` lists the binaries that must exist before activation. Required dependencies are installed serially from `Brewfile.essential`; optional dependencies require `--with-optional`, and desktop casks use `Brewfile.macos`.

The tools phase installs shared CLI tools, including GitHub CLI, Copilot CLI, Node, Rust, Neovim, and shell utilities. GitHub Copilot CLI is declared as the `copilot-cli` cask, including on Linux; the similarly named `copilot` formula is a different product. Copilot CLI installation does not authenticate it or provision work integrations. Rust is supplied by Homebrew here rather than a new automatic rustup bootstrap; existing toolchain preferences can be maintained locally. Homebrew auto-update and Bundle upgrades are disabled for these provisioning commands; no cleanup/uninstall is performed.

Oh My Zsh is installed only if absent, preserving startup files and leaving the login shell unchanged. Neovim and tmux retain their existing plugin-manager behavior, including downloads on first application launch; these are separate from the installer's completion checks. Authentication-dependent editor features still require their normal product sign-in.

## Configuration Layers

Shared entrypoints load optional work extensions first, then machine-local files. Missing optional extensions are normal; a present configuration that fails to load should be corrected, not silently ignored.

| Tool | Work extension | Local extension |
| --- | --- | --- |
| Zsh | `~/.config/dotfiles-work/zsh/*.zsh` | `~/.config/dotfiles-local/zsh/*.zsh` |
| Git | `~/.config/dotfiles-work/git/config` | `~/.config/dotfiles-local/git/config` |
| Neovim before setup | `~/.config/dotfiles-work/nvim/before.lua` | `~/.config/dotfiles-local/nvim/before.lua` |
| Neovim after setup | `~/.config/dotfiles-work/nvim/init.lua` | `~/.config/dotfiles-local/nvim/init.lua` |
| tmux | `~/.config/dotfiles-work/tmux.conf` | `~/.config/dotfiles-local/tmux.conf` |
| WezTerm | `~/.config/dotfiles-work/wezterm.lua` | `~/.config/dotfiles-local/wezterm.lua` |
| Ghostty | Not currently used | `~/.config/dotfiles-local/ghostty/config` |

WezTerm extensions return a function accepting the configuration object. Neovim `before.lua` files run before common configuration and lazy.nvim setup. Zsh extensions run before final zoxide initialization. These files are trusted code, not sandboxed input.

Git defaults are installed at `~/.config/git/config`, not over `~/.gitconfig`. This preserves the existing user/Codespaces Git configuration and its credential helper; that existing file may also take precedence over the new defaults. No identity, token, or credential helper is installed by this repository. `user.useConfigOnly` prevents inventing an identity where none is configured. Define directory-based `includeIf` rules and real identity files in the local layer, and verify `git var GIT_AUTHOR_IDENT` in the repositories you use.

Packages currently target `~/.config`; a custom `XDG_CONFIG_HOME` is explicitly rejected rather than installing into one location while applications read another.

## Machine-Local Preferences

Create local override files outside this checkout. They are not copied or synchronized by either installer. Desktop images, prayer-location coordinates/timezone, local account identity, and machine-specific launcher aliases are not baked into the public configuration. For WezTerm prayer status, set `PRAYER_LATITUDE`, `PRAYER_LONGITUDE`, and `PRAYER_TIMEZONE` in the GUI application's environment; for tmux, set its corresponding options in the local tmux extension.

The original permission-bypassing shell aliases and Sidekick launch flags are not public defaults. Normal CLI launches retain permission prompts. Work secret loading and work helper commands belong to the private extension, not this repository.

## Conflict Handling and Recovery

The installer rejects cross-package file collisions, file/directory collisions, package symlinks, symlinked destination ancestors, and existing unowned files. It does not auto-adopt existing configuration or overwrite fixed-name backups.

After inspecting one conflicting file, a targeted invocation may authorize its backup:

```bash
./install.sh --config-only --backup-file .zshrc
```

Existing directory symlinks from a previous Stow setup require an explicit old-package migration first; `--backup-file` is not a recursive directory replacement mechanism. Switching profiles or removing an overlay also stops if previous managed links would become orphaned. Explicitly unstow the old selected packages after reviewing their ownership; do not remove configuration roots wholesale.

Runs record ownership and unique backups under `~/.local/state/dotfiles/`. Application failures attempt to remove only the new matching links and restore the files backed up by that run. Read the reported journal if recovery is interrupted or blocked. Created empty directories can remain. Package installation is not rolled back or automatically uninstalled.

The installer locks the state directory during provisioning/application. If an interrupted run leaves `install.lock`, confirm no installer is active and inspect the journal before removing that exact empty lock directory. Do not blindly delete state.

## Updates and Current Limits

Shared changes belong in this repository regardless of which machine originated them. Updating a linked checkout changes the effective file contents immediately; run risky changes in an isolated checkout before updating a live one.

The installer verifies selected commands and installed links, not every interactive feature. It does not initialize external work services, register plugin credentials, switch login shells, guarantee toolchain versions, or resolve old home-directory conflicts without approval. It deliberately fails on a missing prerequisite or unavailable dependency.

Copied public packages include the current Neovim, alternate editor, shell, tmux, terminal, Yazi, theme, and generic script configuration. Copilot customizations, organization-oriented snippets, and ambiguous integrations were kept on the private side for review rather than indiscriminately published.

## Container Regression Checks

Run checks only in disposable Docker containers after provisioning tools. Mount this repository read-only at `/input/public` and use a writable copy at `/home/vscode/dotfiles-public`. The integration suite exercises the actual CLI and Stow with temporary targets, including an induced filesystem write failure to verify rollback.

From this repository's root, build the prerequisite image with only the Dockerfile as build input, then install into a disposable container:

```bash
docker build -t dotfiles-test - < tests/Dockerfile
docker run -d --name dotfiles-public-test -e CODESPACES=true \
  --mount "type=bind,source=$PWD,target=/input/public,readonly" \
  --entrypoint sleep dotfiles-test infinity
docker exec dotfiles-public-test bash -c \
  'set -euo pipefail; cp -R /input/public "$HOME/dotfiles-public"; "$HOME/dotfiles-public/install.sh" --backup-file .zshrc'
```

The explicit backup authorization above applies to the test image's stock `.zshrc`, not to any host configuration. Do not mount your real home directory, credentials, SSH agent, or Docker socket. A work test uses a separate fresh container with the private repo mounted read-only at `/input/work`, copies it to `/home/vscode/dotfiles-work`, and invokes that copy's installer with `--public-root /home/vscode/dotfiles-public --backup-file .zshrc`.

```bash
docker exec -t CONTAINER bash /input/public/tests/container-smoke.sh config /home/vscode/dotfiles-public
docker exec CONTAINER python3 -B /input/public/tests/installer-integration.py
```

For a work container, append `/home/vscode/dotfiles-work` to the smoke command and pass `-e DOTFILES_TEST_WORK_ROOT=/home/vscode/dotfiles-work` to `docker exec` for the integration suite. The public-only container intentionally skips the work-only case because it must not have private source mounted.

The interactive shell check requires `docker exec -t`; running an interactive Zsh startup without a terminal can emit line-editor diagnostics unrelated to a real terminal session. Checks cover tool identity, configuration ownership, local overrides, credential boundaries, conflict protection, repeat runs, and recovery. They do not authenticate external services or validate GitHub's native private-dotfiles fetch.

Keep test scripts and other repository-only material outside the Stow package directories; even an empty directory inside a package can be created in the target home by Stow. After inspecting a test container, stop it with `docker stop CONTAINER`; remove that exact container with `docker rm CONTAINER` only when its logs and filesystem are no longer needed.
