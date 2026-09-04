# Dotfiles

Personal Zsh, tmux, and Neovim configuration, installed locally with GNU Stow.

## Included

- Zsh with Oh My Zsh, Powerlevel10k, Atuin, fzf, and zoxide
- tmux with vi-style navigation, mouse support, and OSC 52 clipboard support
- Neovim with LSP, Treesitter, Telescope, completion, formatting, Git signs, and custom plugins
- User-local installs of Stow, Atuin, ripgrep, fd, tmux, Tree-sitter, Neovim, and Zsh

## Prerequisites

The installer supports Linux on x86-64 and ARM64. It does not use `sudo`.

Install these system dependencies first:

- Bash, Git, `curl` or `wget`
- `tar`, `find`, `make`, Perl, `sha256sum`, and a C compiler available as `cc`
- Development headers required to build Zsh

A Nerd Font is recommended for the prompt and Neovim icons.

## Install

```sh
git clone https://github.com/Gwendaaaaal/dotfiles.git
cd dotfiles
./setup.sh
```

The script installs tools under `~/.local`, then links the tracked configuration into `$HOME`. Start a new shell when it finishes.

**Backup warning:** existing files that conflict with managed paths are moved to a timestamped directory under `~/.dotfiles-backup/`. They are not deleted, but they are not restored automatically.

To remove the current Stow links and run the installation again:

```sh
./setup.sh reset
```

Reset does not uninstall tools or restore backups.

## Structure

```text
zsh/                    Zsh and Powerlevel10k configuration
tmux/                   tmux configuration
nvim/                   Neovim configuration and plugin lockfile
setup.sh                Installer, backup, reset, and Stow deployment
.github/workflows/      Tree-sitter release build
```

## Customization

Edit files under `zsh/`, `tmux/`, and `nvim/`; Stow links make repository changes effective at their installed paths. Review the personal aliases in `zsh/.zshrc` before use. Add Neovim plugins under `nvim/lua/custom/plugins/`, run `p10k configure` to update the prompt, and set `vim.g.have_nerd_font = false` if needed.
