#!/usr/bin/env bash

set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
BACKUP_ROOT="$HOME/.dotfiles-backup"
BACKUP_DIR=""

STOW_VERSION="2.4.1"
ATUIN_VERSION="18.18.1"
RIPGREP_VERSION="15.2.0"
FD_VERSION="10.4.2"
TMUX_VERSION="3.6b"
NVIM_VERSION="0.12.5"
TREE_SITTER_VERSION="0.26.13"

export PATH="$LOCAL_BIN:$PATH"

mkdir -p "$LOCAL_BIN"

# ------------------------------------------------------------
# Arguments
# ------------------------------------------------------------

RESET=false

case "${1:-}" in
    reset)
        RESET=true
        ;;
    "")
        ;;
    *)
        echo "Usage: $0 [reset]" >&2
        exit 1
        ;;
esac

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------

require() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Error: '$1' is required." >&2
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
    if [[ "$(uname -s)" != "Linux" ]]; then
        echo "Error: automatic Tree-sitter installation currently supports Linux only." >&2
        exit 1
    fi

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
    hash -r
}

# ------------------------------------------------------------
# Conflict backup
# ------------------------------------------------------------

ensure_backup_dir() {
    if [[ -n "$BACKUP_DIR" ]]; then
        return
    fi

    mkdir -p "$BACKUP_ROOT"
    BACKUP_DIR="$(mktemp -d "$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)-XXXXXX")"
}

backup_existing_path() {
    local path="$1"
    local relative
    local destination

    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return
    fi

    if [[ "$path" != "$HOME"/* ]]; then
        echo "Error: refusing to back up path outside HOME: $path" >&2
        exit 1
    fi

    ensure_backup_dir

    relative="${path#"$HOME"/}"
    destination="$BACKUP_DIR/$relative"

    mkdir -p "$(dirname "$destination")"

    echo "[BACKUP] $path -> $destination"
    mv "$path" "$destination"
}

prepare_target_dir() {
    local target="$1"

    # A Stow target must be a real directory. If the target itself is a
    # symlink/file, preserve it before replacing it with a directory.
    if [[ -L "$target" || ( -e "$target" && ! -d "$target" ) ]]; then
        backup_existing_path "$target"
    fi

    mkdir -p "$target"
}

backup_conflicts() {
    local package="$1"
    local target="$2"
    local package_dir="$DOTFILES/$package"
    local source
    local relative
    local destination

    require find

    if [[ ! -d "$package_dir" ]]; then
        echo "Error: Stow package does not exist: $package_dir" >&2
        exit 1
    fi

    prepare_target_dir "$target"

    # First handle directory-shaped paths. A normal directory can be merged by
    # Stow, but a file or foreign symlink at that location blocks the package.
    while IFS= read -r -d '' source; do
        relative="${source#"$package_dir"/}"
        destination="$target/$relative"

        if [[ -L "$destination" ]]; then
            if [[ "$destination" -ef "$source" ]]; then
                continue
            fi
            backup_existing_path "$destination"
        elif [[ -e "$destination" && ! -d "$destination" ]]; then
            backup_existing_path "$destination"
        fi
    done < <(find "$package_dir" -mindepth 1 -type d -print0)

    # Then handle files/symlinks. Existing links that already point into this
    # package are ours and are left untouched; everything else is backed up.
    while IFS= read -r -d '' source; do
        relative="${source#"$package_dir"/}"
        destination="$target/$relative"

        if [[ -e "$destination" || -L "$destination" ]]; then
            if [[ "$destination" -ef "$source" ]]; then
                continue
            fi
            backup_existing_path "$destination"
        fi
    done < <(find "$package_dir" -mindepth 1 \( -type f -o -type l \) -print0)
}

# ------------------------------------------------------------
# Stow
# ------------------------------------------------------------

install_stow() {
    local current=""

    if command -v stow >/dev/null 2>&1; then
        current="$(stow --version 2>/dev/null | head -n 1 | awk '{print $NF}')"
    fi

    if [[ "$current" == "$STOW_VERSION" ]]; then
        echo "[OK] stow ${STOW_VERSION} already installed"
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

reset_dotfiles() {
    echo "[+] Removing existing dotfile symlinks..."

    # HOME always exists.
    stow -D -d "$DOTFILES" --target="$HOME" zsh || true
    stow -D -d "$DOTFILES" --target="$HOME" tmux || true

    # The nvim target may not exist yet on a fresh machine.
    if [[ -d "$HOME/.config/nvim" ]]; then
        stow -D -d "$DOTFILES" --target="$HOME/.config/nvim" nvim || true
    fi

    echo "[OK] Existing dotfile symlinks removed"
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

    hash -r
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
    hash -r

    echo "[OK] fzf installed"
}

# ------------------------------------------------------------
# Atuin
# ------------------------------------------------------------

install_atuin() {
    local current=""

    if command -v atuin >/dev/null 2>&1; then
        current="$(atuin --version 2>/dev/null | awk '{print $2}')"
    fi

    if [[ "$current" == "$ATUIN_VERSION" ]]; then
        echo "[OK] atuin ${ATUIN_VERSION} already installed"
        return
    fi

    echo "[+] Installing atuin ${ATUIN_VERSION}..."

    local target
    target="$(linux_target)"

    install_tar_binary \
        "https://github.com/atuinsh/atuin/releases/download/v${ATUIN_VERSION}/atuin-${target}.tar.gz" \
        atuin

    echo "[OK] atuin ${ATUIN_VERSION} installed"
}

# ------------------------------------------------------------
# ripgrep
# ------------------------------------------------------------

install_ripgrep() {
    local current=""

    if command -v rg >/dev/null 2>&1; then
        current="$(rg --version 2>/dev/null | head -n 1 | awk '{print $2}')"
    fi

    if [[ "$current" == "$RIPGREP_VERSION" ]]; then
        echo "[OK] ripgrep ${RIPGREP_VERSION} already installed"
        return
    fi

    echo "[+] Installing ripgrep ${RIPGREP_VERSION}..."

    local target
    target="$(linux_target)"

    install_tar_binary \
        "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-${target}.tar.gz" \
        rg

    echo "[OK] ripgrep ${RIPGREP_VERSION} installed"
}

# ------------------------------------------------------------
# fd
# ------------------------------------------------------------

install_fd() {
    local current=""

    if command -v fd >/dev/null 2>&1; then
        current="$(fd --version 2>/dev/null | awk '{print $2}')"
    fi

    if [[ "$current" == "$FD_VERSION" ]]; then
        echo "[OK] fd ${FD_VERSION} already installed"
        return
    fi

    echo "[+] Installing fd ${FD_VERSION}..."

    local target
    target="$(linux_target)"

    install_tar_binary \
        "https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-${target}.tar.gz" \
        fd

    echo "[OK] fd ${FD_VERSION} installed"
}

# ------------------------------------------------------------
# tmux
# ------------------------------------------------------------

install_tmux() {
    local current=""

    if command -v tmux >/dev/null 2>&1; then
        current="$(tmux -V 2>/dev/null | awk '{print $2}')"
    fi

    if [[ "$current" == "$TMUX_VERSION" ]]; then
        echo "[OK] tmux ${TMUX_VERSION} already installed"
        return
    fi

    echo "[+] Installing tmux ${TMUX_VERSION}..."

    local target
    target="$(tmux_target)"

    install_tar_binary \
        "https://github.com/tmux/tmux-builds/releases/download/v${TMUX_VERSION}/tmux-${TMUX_VERSION}-${target}.tar.gz" \
        tmux

    echo "[OK] tmux ${TMUX_VERSION} installed"
}

# ------------------------------------------------------------
# Tree-sitter CLI
# ------------------------------------------------------------

install_tree_sitter() {
    local current=""

    if command -v tree-sitter >/dev/null 2>&1 &&
       tree-sitter --version >/dev/null 2>&1; then
        current="$(tree-sitter --version | awk '{print $2}')"
    fi

    if [[ "$current" == "$TREE_SITTER_VERSION" ]]; then
        echo "[OK] tree-sitter ${TREE_SITTER_VERSION} already installed"
        return
    fi

    echo "[+] Installing tree-sitter ${TREE_SITTER_VERSION}..."

    # nvim-treesitter uses the CLI to build parsers, which also requires a C
    # compiler to be available on the destination machine.
    require cc
    require sha256sum

    local tmp
    local asset
    local expected
    local actual

    tmp="$(mktemp -d)"
    asset="$(tree_sitter_asset)"

    download_file \
        "https://github.com/Gwendaaaaal/dotfiles/releases/download/tree-sitter-cli-v${TREE_SITTER_VERSION}/${asset}" \
        "$tmp/$asset"

    download_file \
        "https://github.com/Gwendaaaaal/dotfiles/releases/download/tree-sitter-cli-v${TREE_SITTER_VERSION}/${asset}.sha256" \
        "$tmp/$asset.sha256"

    expected="$(awk '{print $1}' "$tmp/$asset.sha256")"
    actual="$(sha256sum "$tmp/$asset" | awk '{print $1}')"

    if [[ "$expected" != "$actual" ]]; then
        rm -rf "$tmp"
        echo "Error: tree-sitter checksum mismatch." >&2
        exit 1
    fi

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
# Bootstrap / reset
# ------------------------------------------------------------

# Stow is special: reset needs it before anything can be unstowed.
install_stow

if [[ "$RESET" == true ]]; then
    reset_dotfiles
fi

# Back up real files/symlinks that would conflict with the repository.
# This also runs on a normal first install, so cloning onto an already
# configured machine is safe.
echo "[+] Checking dotfile conflicts..."
backup_conflicts zsh "$HOME"
backup_conflicts nvim "$HOME/.config/nvim"
backup_conflicts tmux "$HOME"
echo "[OK] Dotfile conflicts checked"

# ------------------------------------------------------------
# Install tools
# ------------------------------------------------------------

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
# Dotfiles
# ------------------------------------------------------------

echo "[+] Installing dotfiles..."

stow -d "$DOTFILES" --target="$HOME" zsh
stow -d "$DOTFILES" --target="$HOME/.config/nvim" nvim
stow -d "$DOTFILES" --target="$HOME" tmux

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

echo
echo "Done."

if [[ -n "$BACKUP_DIR" ]]; then
    echo "backup: $BACKUP_DIR"
fi

echo "stow:        $(command -v stow)"
echo "zoxide:      $(command -v zoxide)"
echo "fzf:         $(command -v fzf)"
echo "atuin:       $(command -v atuin)"
echo "rg:          $(command -v rg)"
echo "fd:          $(command -v fd)"
echo "tmux:        $(command -v tmux)"
echo "tree-sitter: $(command -v tree-sitter)"
echo "nvim:        $(command -v nvim)"
echo "omz:         $HOME/.oh-my-zsh"
echo "p10k:        ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
