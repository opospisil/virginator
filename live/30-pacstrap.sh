#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

require_root
require_command genfstab pacstrap
load_config "${VIRGINATOR_CONFIG:-}"

PACKAGE_FILE="$VIRGINATOR_ROOT/packages/bootstrap.txt"
mapfile -t BOOTSTRAP_PACKAGES < <(read_packages_from_file "$PACKAGE_FILE")

log "installing bootstrap package set"
pacstrap -K "$INSTALL_MOUNTPOINT" "${BOOTSTRAP_PACKAGES[@]}"

log "generating fstab"
genfstab -U "$INSTALL_MOUNTPOINT" > "$INSTALL_MOUNTPOINT/etc/fstab"

log "copying repository and config into target system"
copy_repo_to_target "$INSTALL_MOUNTPOINT"
