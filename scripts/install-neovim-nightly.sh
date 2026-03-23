#!/usr/bin/env bash

set -euo pipefail

resolve_archive_name() {
  case $(uname -m) in
    x86_64) printf 'nvim-linux-x86_64.tar.gz\n' ;;
    aarch64) printf 'nvim-linux-arm64.tar.gz\n' ;;
    *)
      printf 'unsupported architecture for Neovim nightly: %s\n' "$(uname -m)" >&2
      exit 1
      ;;
  esac
}

INSTALL_ROOT=${INSTALL_ROOT:-$HOME/.local/opt}
INSTALL_DIR="$INSTALL_ROOT/neovim-nightly"
BIN_DIR="$HOME/.local/bin"
ARCHIVE_NAME=$(resolve_archive_name)
DOWNLOAD_URL=${NEOVIM_NIGHTLY_URL:-"https://github.com/neovim/neovim/releases/download/nightly/$ARCHIVE_NAME"}
ARCHIVE_PATH="$INSTALL_ROOT/$ARCHIVE_NAME"

mkdir -p "$INSTALL_ROOT" "$BIN_DIR"
rm -rf "$INSTALL_DIR"

curl -fsSL "$DOWNLOAD_URL" -o "$ARCHIVE_PATH"
mkdir -p "$INSTALL_DIR"
tar -C "$INSTALL_DIR" -xzf "$ARCHIVE_PATH" --strip-components=1
rm -f "$ARCHIVE_PATH"

ln -sfn "$INSTALL_DIR/bin/nvim" "$BIN_DIR/nvim"
ln -sfn "$INSTALL_DIR/bin/nvimdiff" "$BIN_DIR/nvimdiff"

printf 'Neovim nightly installed at %s\n' "$INSTALL_DIR"
