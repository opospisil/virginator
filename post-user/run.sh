#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
export VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-$VIRGINATOR_ROOT/config/current.sh}

# shellcheck source=../lib/common.sh
. "$VIRGINATOR_ROOT/lib/common.sh"

start_sudo_keepalive() {
  if ! command -v sudo >/dev/null 2>&1; then
    return 0
  fi

  sudo -v

  while true; do
    sleep 50
    sudo -n true >/dev/null 2>&1 || exit 0
  done &

  SUDO_KEEPALIVE_PID=$!
  trap 'kill "$SUDO_KEEPALIVE_PID" >/dev/null 2>&1 || true' EXIT
}

load_config "$VIRGINATOR_CONFIG"

[[ $(id -un) == "$PRIMARY_USER_NAME" ]] || die "run this script as $PRIMARY_USER_NAME"

start_sudo_keepalive

for script in \
  "$SCRIPT_DIR/10-copy-user-skel.sh" \
  "$SCRIPT_DIR/20-install-neovim-nightly.sh" \
  "$SCRIPT_DIR/30-install-go.sh" \
  "$SCRIPT_DIR/40-install-node.sh" \
  "$SCRIPT_DIR/50-install-bitwarden.sh" \
  "$SCRIPT_DIR/55-install-rustup.sh" \
  "$SCRIPT_DIR/60-install-aur-helper.sh" \
  "$SCRIPT_DIR/70-install-aur-packages.sh"
do
  log "executing ${script##*/}"
  bash "$script"
done

log "post-user setup complete"

if vault_enabled; then
  printf 'lemurs is the default login manager; mount the vault with sudo %s/scripts/mount-vault.sh when you are ready\n' "$REPO_INSTALL_DIR"
else
  printf 'lemurs is the default login manager\n'
fi
