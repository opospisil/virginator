#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
export VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-/etc/virginator/config.sh}

# shellcheck source=../lib/common.sh
. "$VIRGINATOR_ROOT/lib/common.sh"

require_root
require_command cryptsetup mount
load_config "$VIRGINATOR_CONFIG"

vault_enabled || die "vault support is disabled in $VIRGINATOR_CONFIG"

VAULT_DEVICE=$(resolve_block_device "$VAULT_PARTITION")
MAPPER_DEVICE="/dev/mapper/$VAULT_MAPPER_NAME"

mkdir -p "$VAULT_MOUNTPOINT"

if mountpoint -q "$VAULT_MOUNTPOINT"; then
  log "vault is already mounted at $VAULT_MOUNTPOINT"
  exit 0
fi

if [[ ! -e "$MAPPER_DEVICE" ]]; then
  log "unlocking $VAULT_DEVICE as $VAULT_MAPPER_NAME"
  cryptsetup open "$VAULT_DEVICE" "$VAULT_MAPPER_NAME"
fi

log "mounting $MAPPER_DEVICE at $VAULT_MOUNTPOINT"
mount -t ext4 "$MAPPER_DEVICE" "$VAULT_MOUNTPOINT"
chown "$PRIMARY_USER_NAME:$PRIMARY_USER_NAME" "$VAULT_MOUNTPOINT"

log "vault is ready"
