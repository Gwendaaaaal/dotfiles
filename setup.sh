#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
STOW_VERSION="2.4.1"

export PATH="$LOCAL_BIN:$PATH"

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

# ------------------------------------------------------------
# Stow
# ------------------------------------------------------------

install_stow() {
    if command -v stow >/dev/null 2>&1; then
        echo "[OK] stow already installed"
        return
    fi

    echo "[+] Installing stow..."

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

    echo "[OK] stow installed"
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
# Install tools
# ------------------------------------------------------------

install_stow
install_zoxide
install_fzf

# ------------------------------------------------------------
# Dotfiles
# ------------------------------------------------------------

echo "[+] Installing dotfiles..."

mkdir -p "$HOME/.config/nvim"

stow -d "$DOTFILES" --target="$HOME" zsh
stow -d "$DOTFILES" --target="$HOME/.config/nvim" nvim

echo
echo "Done."
echo "stow:   $(command -v stow)"
echo "zoxide: $(command -v zoxide)"
echo "fzf:    $(command -v fzf)"
