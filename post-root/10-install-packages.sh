#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

require_root
load_config "${VIRGINATOR_CONFIG:-}"

install_packages_from_files \
  "$VIRGINATOR_ROOT/packages/base.txt" \
  "$VIRGINATOR_ROOT/packages/desktop-i3.txt" \
  "$VIRGINATOR_ROOT/packages/audio.txt" \
  "$VIRGINATOR_ROOT/packages/auth.txt" \
  "$VIRGINATOR_ROOT/packages/containers.txt"

if [[ -n "$CPU_MICROCODE_PACKAGE" ]]; then
  pacman -S --needed --noconfirm "$CPU_MICROCODE_PACKAGE"
fi

log "package installation complete"
