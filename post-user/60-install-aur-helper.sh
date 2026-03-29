#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

load_config "${VIRGINATOR_CONFIG:-}"

if [[ -d "$HOME/.cargo/bin" ]]; then
  PATH="$HOME/.cargo/bin:$PATH"
fi

[[ -n ${AUR_HELPER_PACKAGE:-} ]] || {
  log "AUR helper package is empty; skipping AUR helper install"
  exit 0
}

if command -v paru >/dev/null 2>&1 && [[ "$AUR_HELPER_PACKAGE" == "paru" || "$AUR_HELPER_PACKAGE" == "paru-bin" ]]; then
  log "paru is already installed"
  exit 0
fi

require_command git makepkg

BUILD_ROOT=${BUILD_ROOT:-$HOME/.local/src}
PACKAGE_DIR="$BUILD_ROOT/$AUR_HELPER_PACKAGE"

mkdir -p "$BUILD_ROOT"

if [[ ! -d "$PACKAGE_DIR/.git" ]]; then
  rm -rf "$PACKAGE_DIR"
  git clone "https://aur.archlinux.org/${AUR_HELPER_PACKAGE}.git" "$PACKAGE_DIR"
else
  git -C "$PACKAGE_DIR" pull --ff-only
fi

log "building and installing $AUR_HELPER_PACKAGE"
(cd "$PACKAGE_DIR" && makepkg -Csi --noconfirm --needed)
