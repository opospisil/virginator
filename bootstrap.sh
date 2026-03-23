#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT="$SCRIPT_DIR"

# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: sudo ./bootstrap.sh <config-path>

Example:
  sudo ./bootstrap.sh config/machines/example.sh
EOF
}

main() {
  local config_path
  config_path=${1:-}

  if [[ -z "$config_path" ]]; then
    usage
    exit 1
  fi

  if [[ "$config_path" != /* ]]; then
    config_path="$VIRGINATOR_ROOT/$config_path"
  fi

  require_root
  require_command arch-chroot blkid genfstab mkfs.ext4 mkfs.fat mount pacstrap
  load_config "$config_path"

  log "running live installer with config $VIRGINATOR_CONFIG"

  local live_scripts=(
    "$VIRGINATOR_ROOT/live/10-validate-layout.sh"
    "$VIRGINATOR_ROOT/live/20-format-and-mount.sh"
    "$VIRGINATOR_ROOT/live/30-pacstrap.sh"
    "$VIRGINATOR_ROOT/live/40-chroot-handoff.sh"
  )

  local script
  for script in "${live_scripts[@]}"; do
    log "executing ${script##*/}"
    VIRGINATOR_ROOT="$VIRGINATOR_ROOT" VIRGINATOR_CONFIG="$VIRGINATOR_CONFIG" bash "$script"
  done

  log "base install finished"
  printf '\n'
  printf 'Next steps:\n'
  printf '  1. reboot into the new system\n'
  printf '  2. run sudo %s/post-root/run.sh\n' "$REPO_INSTALL_DIR"
  printf '  3. log in as %s and run %s/post-user/run.sh\n' "$PRIMARY_USER_NAME" "$REPO_INSTALL_DIR"

  if vault_enabled; then
    printf '  4. mount the vault manually with sudo %s/scripts/mount-vault.sh\n' "$REPO_INSTALL_DIR"
  fi
}

main "$@"
