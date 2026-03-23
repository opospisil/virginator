#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

require_root
require_command arch-chroot
load_config "${VIRGINATOR_CONFIG:-}"

log "running base system configuration inside chroot"
arch-chroot "$INSTALL_MOUNTPOINT" /usr/bin/env \
  VIRGINATOR_ROOT="$REPO_INSTALL_DIR" \
  VIRGINATOR_CONFIG="$CONFIG_INSTALL_DIR/config.sh" \
  bash "$REPO_INSTALL_DIR/chroot/10-base-system.sh"
