#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

load_config "${VIRGINATOR_CONFIG:-}"

command -v paru >/dev/null 2>&1 || die "paru is not available; run 60-install-aur-helper.sh first"

if ((${#AUR_PACKAGES[@]} == 0)); then
  log "no AUR packages configured; skipping AUR package install"
  exit 0
fi

log "installing configured AUR packages: ${AUR_PACKAGES[*]}"
paru -S --needed --noconfirm "${AUR_PACKAGES[@]}"
