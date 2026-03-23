#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
export VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-/etc/virginator/config.sh}

# shellcheck source=../lib/common.sh
. "$VIRGINATOR_ROOT/lib/common.sh"

load_config "$VIRGINATOR_CONFIG"

[[ $(id -un) == "$PRIMARY_USER_NAME" ]] || die "run this script as $PRIMARY_USER_NAME"

for script in \
  "$SCRIPT_DIR/10-copy-user-skel.sh" \
  "$SCRIPT_DIR/20-install-neovim-nightly.sh" \
  "$SCRIPT_DIR/30-install-go.sh" \
  "$SCRIPT_DIR/40-install-node.sh" \
  "$SCRIPT_DIR/50-install-bitwarden.sh"
do
  log "executing ${script##*/}"
  bash "$script"
done

log "post-user setup complete"

if vault_enabled; then
  printf 'launch i3 with startx, then mount the vault with sudo %s/scripts/mount-vault.sh\n' "$REPO_INSTALL_DIR"
else
  printf 'launch i3 with startx\n'
fi
