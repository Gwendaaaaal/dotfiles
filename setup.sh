#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"

STOW_VERSION="2.4.1"
ATUIN_VERSION="18.18.1"
RIPGREP_VERSION="15.2.0"
FD_VERSION="10.4.2"
TMUX_VERSION="3.6b"
NVIM_VERSION="0.12.5"
TREE_SITTER_VERSION="0.26.13"

export PATH="$HOME/.cargo/bin:$LOCAL_BIN:$PATH"

mkdir -p "$LOCAL_BIN"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: '$1' is required."
        exit 1
    fi
}

download_stdout() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
    else
        echo "Error: curl or wget is required." >&2
        exit 1
    fi
}

download_file() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$output" "$url"
    else
        echo "Error: curl or wget is required." >&2
        exit 1
    fi
}

linux_target() {
    local arch

    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "Error: automatic binary installation currently supports Linux only." >&2
        exit 1
    fi

    case "$(uname -m)" in
        x86_64|amd64)
            arch="x86_64"
            ;;
        aarch64|arm64)
            arch="aarch64"
            ;;
        *)
            echo "Error: unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac

    printf '%s-unknown-linux-musl\n' "$arch"
}

tmux_target() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "Error: automatic tmux installation currently supports Linux only." >&2
        exit 1
    fi

    case "$(uname -m)" in
        x86_64|amd64)
            printf 'linux-x86_64\n'
            ;;
        aarch64|arm64)
            printf 'linux-arm64\n'
            ;;
        *)
            echo "Error: unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

nvim_target() {
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "Error: automatic Neovim installation currently supports Linux only." >&2
        exit 1
    fi

    case "$(uname -m)" in
        x86_64|amd64)
            printf 'x86_64\n'
            ;;
        aarch64|arm64)
            printf 'arm64\n'
            ;;
        *)
            echo "Error: unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

tree_sitter_asset() {
    case "$(uname -m)" in
        x86_64|amd64)
            printf 'tree-sitter-linux-x86_64\n'
            ;;
        aarch64|arm64)
            printf 'tree-sitter-linux-arm64\n'
            ;;
        *)
            echo "Error: unsupported architecture: $(uname -m)" >&2
            exit 1
            ;;
    esac
}

install_tar_binary() {
    local url="$1"
    local binary_name="$2"
    local tmp
    local binary

    require tar
    require find

    tmp="$(mktemp -d)"

    download_file "$url" "$tmp/archive.tar.gz"
    tar -xzf "$tmp/archive.tar.gz" -C "$tmp"

	binary="$(find "$tmp" -type f -name "$binary_name" -print -quit)"

    if [[ -z "$binary" ]]; then
        rm -rf "$tmp"
        echo "Error: '$binary_name' was not found in downloaded archive." >&2
        exit 1
    fi

    cp "$binary" "$LOCAL_BIN/$binary_name"
    chmod +x "$LOCAL_BIN/$binary_name"

    rm -rf "$tmp"
}

# ------------------------------------------------------------
# Stow
# ------------------------------------------------------------

install_stow() {
    if command -v stow >/dev/null 2>&1 &&
       stow --version | head -n 1 | grep -q "$STOW_VERSION"; then
        echo "[OK] stow 2.4.1 already installed"
        return
    fi

    echo "[+] Installing stow ${STOW_VERSION}..."

    require perl
    require make
    require tar

    local tmp
    tmp="$(mktemp -d)"

    download_file \
        "https://ftp.gnu.org/gnu/stow/stow-${STOW_VERSION}.tar.gz" \
        "$tmp/stow.tar.gz"

    tar -xzf "$tmp/stow.tar.gz" -C "$tmp"

    (
        cd "$tmp/stow-${STOW_VERSION}"
        ./configure --prefix="$HOME/.local"
        make
        make install
    )

    rm -rf "$tmp"

	hash -r

    echo "[OK] stow ${STOW_VERSION} installed"
}

# ------------------------------------------------------------
# zoxide
# ------------------------------------------------------------

install_zoxide() {
    if command -v zoxide >/dev/null 2>&1; then
        echo "[OK] zoxide already installed"
        return
    fi

    echo "[+] Installing zoxide..."

    download_stdout \
        "https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh" |
        sh

    echo "[OK] zoxide installed"
}

# ------------------------------------------------------------
# fzf
# ------------------------------------------------------------

install_fzf() {
    if command -v fzf >/dev/null 2>&1; then
        echo "[OK] fzf already installed"
        return
    fi

    echo "[+] Installing fzf..."

    require git

    local tmp
    tmp="$(mktemp -d)"

    git clone --depth 1 \
        https://github.com/junegunn/fzf.git \
        "$tmp/fzf"

    "$tmp/fzf/install" --bin

    cp "$tmp/fzf/bin/fzf" "$LOCAL_BIN/fzf"
    chmod +x "$LOCAL_BIN/fzf"

    rm -rf "$tmp"

    echo "[OK] fzf installed"
}

# ------------------------------------------------------------
# Atuin
# ------------------------------------------------------------

install_atuin() {
    if command -v atuin >/dev/null 2>&1; then
        echo "[OK] atuin already installed"
        return
    fi

    echo "[+] Installing atuin..."

    local target
    target="$(linux_target)"

    install_tar_binary \
        "https://github.com/atuinsh/atuin/releases/download/v${ATUIN_VERSION}/atuin-${target}.tar.gz" \
        atuin

    echo "[OK] atuin installed"
}

# ------------------------------------------------------------
# ripgrep
# ------------------------------------------------------------

install_ripgrep() {
    if command -v rg >/dev/null 2>&1; then
        echo "[OK] ripgrep already installed"
        return
    fi

    echo "[+] Installing ripgrep..."

    local target
    target="$(linux_target)"

    install_tar_binary \
        "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-${target}.tar.gz" \
        rg

    echo "[OK] ripgrep installed"
}

# ------------------------------------------------------------
# fd
# ------------------------------------------------------------

install_fd() {
    if command -v fd >/dev/null 2>&1; then
        echo "[OK] fd already installed"
        return
    fi

    echo "[+] Installing fd..."

    local target
    target="$(linux_target)"

    install_tar_binary \
        "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${target}.tar.gz" \
        fd

    echo "[OK] fd installed"
}

# ------------------------------------------------------------
# tmux
# ------------------------------------------------------------

install_tmux() {
    if command -v tmux >/dev/null 2>&1; then
        echo "[OK] tmux already installed"
        return
    fi

    echo "[+] Installing tmux..."

    local target
    target="$(tmux_target)"

    install_tar_binary \
        "https://github.com/tmux/tmux-builds/releases/download/v${TMUX_VERSION}/tmux-${TMUX_VERSION}-${target}.tar.gz" \
        tmux

    echo "[OK] tmux installed"
}

# ------------------------------------------------------------
# Tree-sitter CLI
# ------------------------------------------------------------

install_tree_sitter() {
    if command -v tree-sitter >/dev/null 2>&1 &&
       tree-sitter --version >/dev/null 2>&1 &&
       [[ "$(tree-sitter --version)" == "tree-sitter ${TREE_SITTER_VERSION}"* ]]; then
        echo "[OK] tree-sitter ${TREE_SITTER_VERSION} already installed"
        return
    fi

    echo "[+] Installing tree-sitter ${TREE_SITTER_VERSION}..."

	local tmp
	local asset

	tmp="$(mktemp -d)"
	asset="$(tree_sitter_asset)"

	download_file \
		"https://github.com/Gwendaaaaal/dotfiles/releases/download/tree-sitter-cli-v${TREE_SITTER_VERSION}/${asset}" \
		"$tmp/$asset"

	download_file \
		"https://github.com/Gwendaaaaal/dotfiles/releases/download/tree-sitter-cli-v${TREE_SITTER_VERSION}/${asset}.sha256" \
		"$tmp/$asset.sha256"

    (
        cd "$tmp"

        # The checksum file contains the original absolute path generated
        # on GitHub Actions, so only compare the hash itself.
		expected="$(cut -d ' ' -f1 "$tmp/$asset.sha256")"
		actual="$(sha256sum "$tmp/$asset" | cut -d ' ' -f1)"

        if [[ "$expected" != "$actual" ]]; then
            echo "Error: tree-sitter checksum mismatch." >&2
            exit 1
        fi
    )

	cp "$tmp/$asset" "$LOCAL_BIN/tree-sitter"
	chmod +x "$LOCAL_BIN/tree-sitter"

    rm -rf "$tmp"

    hash -r

    echo "[OK] tree-sitter ${TREE_SITTER_VERSION} installed"
}

# ------------------------------------------------------------
# Neovim
# ------------------------------------------------------------

install_neovim() {
    if command -v nvim >/dev/null 2>&1 &&
       [[ "$(nvim --version | head -n 1)" == "NVIM v${NVIM_VERSION}" ]]; then
        echo "[OK] neovim ${NVIM_VERSION} already installed"
        return
    fi

    echo "[+] Installing neovim ${NVIM_VERSION}..."

    require tar

    local target
    local tmp
    local install_dir

    target="$(nvim_target)"
    tmp="$(mktemp -d)"
    install_dir="$HOME/.local/opt/nvim-${NVIM_VERSION}"

    mkdir -p "$HOME/.local/opt"

    download_file \
        "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux-${target}.tar.gz" \
        "$tmp/nvim.tar.gz"

    rm -rf "$install_dir"
    mkdir -p "$install_dir"

    tar -xzf "$tmp/nvim.tar.gz" \
        -C "$install_dir" \
        --strip-components=1

    ln -sfn "$install_dir/bin/nvim" "$LOCAL_BIN/nvim"

    rm -rf "$tmp"

    hash -r

    echo "[OK] neovim ${NVIM_VERSION} installed"
}

# ------------------------------------------------------------
# Powerlevel10k
# ------------------------------------------------------------

install_powerlevel10k() {
    local p10k_dir
    p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

    if [[ -f "$p10k_dir/powerlevel10k.zsh-theme" ]]; then
        echo "[OK] powerlevel10k already installed"
        return
    fi

    echo "[+] Installing powerlevel10k..."

    require git

    mkdir -p "$(dirname "$p10k_dir")"

    git clone --depth=1 \
        https://github.com/romkatv/powerlevel10k.git \
        "$p10k_dir"

    echo "[OK] powerlevel10k installed"
}

# ------------------------------------------------------------
# Oh My Zsh
# ------------------------------------------------------------

install_oh_my_zsh() {
    local omz_dir="$HOME/.oh-my-zsh"

    if [[ -f "$omz_dir/oh-my-zsh.sh" ]]; then
        echo "[OK] oh-my-zsh already installed"
        return
    fi

    echo "[+] Installing oh-my-zsh..."

    require git
    require zsh

    if [[ -e "$omz_dir" ]]; then
        echo "Error: '$omz_dir' already exists but doesn't look like an Oh My Zsh installation." >&2
        exit 1
    fi

    git clone --depth=1 \
        https://github.com/ohmyzsh/ohmyzsh.git \
        "$omz_dir"

    echo "[OK] oh-my-zsh installed"
}

# ------------------------------------------------------------
# Install tools
# ------------------------------------------------------------

install_stow
install_zoxide
install_fzf
install_atuin
install_ripgrep
install_fd
install_tmux
install_tree_sitter
install_neovim
install_oh_my_zsh
install_powerlevel10k

# ------------------------------------------------------------
# Reset
# ------------------------------------------------------------

reset_dotfiles() {
    echo "[+] Removing dotfile symlinks..."

    if ! command -v stow >/dev/null 2>&1; then
        echo "Error: stow is required to reset dotfiles." >&2
        exit 1
    fi

    stow -D -d "$DOTFILES" --target="$HOME" zsh
    stow -D -d "$DOTFILES" --target="$HOME/.config/nvim" nvim
    stow -D -d "$DOTFILES" --target="$HOME" tmux

    echo "[OK] Dotfile symlinks removed"
}

case "${1:-}" in
    reset)
        reset_dotfiles
        ;;
    "")
        ;;
    *)
        echo "Usage: $0 [reset]" >&2
        exit 1
        ;;
esac

# ------------------------------------------------------------
# Dotfiles
# ------------------------------------------------------------

echo "[+] Installing dotfiles..."

mkdir -p "$HOME/.config/nvim"

stow -d "$DOTFILES" --target="$HOME" zsh
stow -d "$DOTFILES" --target="$HOME/.config/nvim" nvim
stow -d "$DOTFILES" --target="$HOME" tmux

echo
echo "Done."
echo "stow:   $(command -v stow)"
echo "zoxide: $(command -v zoxide)"
echo "fzf:    $(command -v fzf)"
echo "atuin:  $(command -v atuin)"
echo "rg:     $(command -v rg)"
echo "fd:     $(command -v fd)"
echo "tmux:   $(command -v tmux)"
echo "tree-sitter: $(command -v tree-sitter)"
echo "nvim:   $(command -v nvim)"
echo "omz:    $HOME/.oh-my-zsh"
echo "p10k:   ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
