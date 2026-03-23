#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

require_root
require_command blkid lsblk mountpoint
load_config "${VIRGINATOR_CONFIG:-}"

[[ -d /sys/firmware/efi/efivars ]] || die "UEFI firmware support is required"

if [[ -d "$INSTALL_MOUNTPOINT" ]] && mountpoint -q "$INSTALL_MOUNTPOINT"; then
  die "$INSTALL_MOUNTPOINT is already mounted"
fi

BOOT_DEVICE=$(resolve_block_device "$BOOT_PARTITION")
ROOT_DEVICE=$(resolve_block_device "$ROOT_PARTITION")
HOME_DEVICE=$(resolve_block_device "$HOME_PARTITION")

DEVICES=("$BOOT_DEVICE" "$ROOT_DEVICE" "$HOME_DEVICE")

declare -A SEEN_DEVICES=()
for DEVICE in "${DEVICES[@]}"; do
  [[ -z ${SEEN_DEVICES[$DEVICE]:-} ]] || die "device $DEVICE is assigned to more than one partition role"
  SEEN_DEVICES[$DEVICE]=1
done

HOME_TYPE=$(blkid -s TYPE -o value "$HOME_DEVICE" || true)

[[ "$HOME_TYPE" == "$HOME_FS_TYPE" ]] || die "expected HOME partition $HOME_DEVICE to be $HOME_FS_TYPE, got ${HOME_TYPE:-unknown}"

if vault_enabled; then
  VAULT_DEVICE=$(resolve_block_device "$VAULT_PARTITION")
  [[ -z ${SEEN_DEVICES[$VAULT_DEVICE]:-} ]] || die "device $VAULT_DEVICE is assigned to more than one partition role"
  SEEN_DEVICES[$VAULT_DEVICE]=1

  VAULT_TYPE=$(blkid -s TYPE -o value "$VAULT_DEVICE" || true)
  [[ "$VAULT_TYPE" == "crypto_LUKS" ]] || die "expected VAULT partition $VAULT_DEVICE to be crypto_LUKS, got ${VAULT_TYPE:-unknown}"
  DEVICES+=("$VAULT_DEVICE")
fi

log "validated partition layout"
printf '  boot : %s (%s)\n' "$BOOT_DEVICE" "$BOOT_PARTITION"
printf '  root : %s (%s)\n' "$ROOT_DEVICE" "$ROOT_PARTITION"
printf '  home : %s (%s)\n' "$HOME_DEVICE" "$HOME_PARTITION"

if vault_enabled; then
  printf '  vault: %s (%s)\n' "$VAULT_DEVICE" "$VAULT_PARTITION"
else
  printf '  vault: disabled\n'
fi

printf '\n'
lsblk -o PATH,SIZE,FSTYPE,PARTLABEL "${DEVICES[@]}"
