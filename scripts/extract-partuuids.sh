#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/extract-partuuids.sh <boot-device> <root-device> <home-device> [vault-device]

Examples:
  ./scripts/extract-partuuids.sh /dev/nvme0n1p1 /dev/nvme0n1p2 /dev/nvme0n1p3 /dev/nvme0n1p4
  ./scripts/extract-partuuids.sh /dev/sda1 /dev/sda2 /dev/sda3

The script prints a config snippet using PARTUUID selectors for the machine config.
EOF
}

require_command() {
  local command_name

  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 || {
      printf 'missing required command: %s\n' "$command_name" >&2
      exit 1
    }
  done
}

require_block_device() {
  local device

  device=$1
  [[ -b "$device" ]] || {
    printf 'not a block device: %s\n' "$device" >&2
    exit 1
  }
}

partuuid_for() {
  local device partuuid

  device=$1
  partuuid=$(blkid -s PARTUUID -o value "$device" || true)

  [[ -n "$partuuid" ]] || {
    printf 'missing PARTUUID for device: %s\n' "$device" >&2
    exit 1
  }

  printf '%s\n' "$partuuid"
}

device_type_for() {
  local device fs_type

  device=$1
  fs_type=$(blkid -s TYPE -o value "$device" || true)
  printf '%s\n' "$fs_type"
}

main() {
  local boot_device root_device home_device vault_device
  local boot_partuuid root_partuuid home_partuuid vault_partuuid
  local home_type vault_type
  local lsblk_devices=()

  if [[ $# -ne 3 && $# -ne 4 ]]; then
    usage
    exit 1
  fi

  require_command blkid lsblk

  boot_device=$1
  root_device=$2
  home_device=$3
  vault_device=${4:-}

  require_block_device "$boot_device"
  require_block_device "$root_device"
  require_block_device "$home_device"

  if [[ -n "$vault_device" ]]; then
    require_block_device "$vault_device"
  fi

  lsblk_devices=("$boot_device" "$root_device" "$home_device")
  if [[ -n "$vault_device" ]]; then
    lsblk_devices+=("$vault_device")
  fi

  boot_partuuid=$(partuuid_for "$boot_device")
  root_partuuid=$(partuuid_for "$root_device")
  home_partuuid=$(partuuid_for "$home_device")
  home_type=$(device_type_for "$home_device")

  if [[ "$home_type" != "ext4" ]]; then
    printf 'warning: home device %s is %s, expected ext4\n' "$home_device" "${home_type:-unknown}" >&2
  fi

  if [[ -n "$vault_device" ]]; then
    vault_partuuid=$(partuuid_for "$vault_device")
    vault_type=$(device_type_for "$vault_device")

    if [[ "$vault_type" != "crypto_LUKS" ]]; then
      printf 'warning: vault device %s is %s, expected crypto_LUKS\n' "$vault_device" "${vault_type:-unknown}" >&2
    fi
  fi

  printf '# generated from:\n'
  printf '#   boot=%s\n' "$boot_device"
  printf '#   root=%s\n' "$root_device"
  printf '#   home=%s\n' "$home_device"
  if [[ -n "$vault_device" ]]; then
    printf '#   vault=%s\n' "$vault_device"
  fi
  printf '\n'
  printf 'BOOT_PARTITION="PARTUUID=%s"\n' "$boot_partuuid"
  printf 'ROOT_PARTITION="PARTUUID=%s"\n' "$root_partuuid"
  printf 'HOME_PARTITION="PARTUUID=%s"\n' "$home_partuuid"

  if [[ -n "$vault_device" ]]; then
    printf 'VAULT_ENABLED="yes"\n'
    printf 'VAULT_PARTITION="PARTUUID=%s"\n' "$vault_partuuid"
  else
    printf 'VAULT_ENABLED="no"\n'
    printf 'VAULT_PARTITION=""\n'
  fi

  printf '\n'
  lsblk -o PATH,SIZE,FSTYPE,PARTLABEL,LABEL,PARTUUID "${lsblk_devices[@]}"
}

main "$@"
