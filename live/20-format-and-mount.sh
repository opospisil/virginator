#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

require_root
require_command mkfs.ext4 mkfs.fat mount mountpoint
load_config "${VIRGINATOR_CONFIG:-}"

BOOT_DEVICE=$(resolve_block_device "$BOOT_PARTITION")
ROOT_DEVICE=$(resolve_block_device "$ROOT_PARTITION")
HOME_DEVICE=$(resolve_block_device "$HOME_PARTITION")

mountpoint -q "$INSTALL_MOUNTPOINT" && die "$INSTALL_MOUNTPOINT is already mounted"

log "formatting $BOOT_DEVICE as FAT32"
mkfs.fat -F 32 -n "$BOOT_FS_LABEL" "$BOOT_DEVICE"

log "formatting $ROOT_DEVICE as ext4"
mkfs.ext4 -F -L "$ROOT_FS_LABEL" "$ROOT_DEVICE"

log "mounting target filesystem tree"
mkdir -p "$INSTALL_MOUNTPOINT"
mount -t "$ROOT_FS_TYPE" -o "$ROOT_MOUNT_OPTIONS" "$ROOT_DEVICE" "$INSTALL_MOUNTPOINT"
mkdir -p "$INSTALL_MOUNTPOINT/$BOOT_MOUNT_SUBDIR" "$INSTALL_MOUNTPOINT/home"
mount -t "$BOOT_FS_TYPE" "$BOOT_DEVICE" "$INSTALL_MOUNTPOINT/$BOOT_MOUNT_SUBDIR"
mount -t "$HOME_FS_TYPE" -o "$HOME_MOUNT_OPTIONS" "$HOME_DEVICE" "$INSTALL_MOUNTPOINT/home"

log "mounted root, boot, and preserved home; vault remains untouched"
