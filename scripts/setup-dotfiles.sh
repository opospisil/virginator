#!/usr/bin/env bash

set -euo pipefail

DOTFILES_REPO_URL="https://github.com/opospisil/dotfiles.git"
DOTFILES_DIR="$HOME/code/dotfiles"
STOW_PACKAGES=(tmux nvim i3 alacritty rofi fish)

remove_conflicting_path() {
  local target_path

  target_path=$1

  [[ -e "$target_path" || -L "$target_path" ]] || return 0
  [[ -L "$target_path" ]] && return 0

  rm -rf "$target_path"
  printf 'removed bootstrap path %s\n' "$target_path"
}

mkdir -p "$HOME/code"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  git -C "$DOTFILES_DIR" pull --ff-only
elif [[ -e "$DOTFILES_DIR" ]]; then
  printf 'path exists and is not a git clone: %s\n' "$DOTFILES_DIR" >&2
  exit 1
else
  git clone "$DOTFILES_REPO_URL" "$DOTFILES_DIR"
fi

remove_conflicting_path "$HOME/.config/fish"
remove_conflicting_path "$HOME/.config/i3"
remove_conflicting_path "$HOME/.config/i3blocks"
remove_conflicting_path "$HOME/.config/alacritty"

cd "$DOTFILES_DIR"
stow -R "${STOW_PACKAGES[@]}"

printf 'dotfiles ready in %s\n' "$DOTFILES_DIR"
