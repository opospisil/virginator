#!/usr/bin/env bash

HOSTNAME="arch-fresh"
TIMEZONE="Europe/Prague"
LOCALE="en_US.UTF-8"
KEYMAP="us"

PRIMARY_USER_NAME="freshuser"
PRIMARY_USER_UID="1100"
PRIMARY_USER_GID="1100"
PRIMARY_USER_GROUPS=(wheel)

BOOT_PARTITION="PARTLABEL=EFI"
ROOT_PARTITION="PARTLABEL=ROOT"
HOME_PARTITION="PARTLABEL=HOME"
VAULT_ENABLED="yes"
VAULT_PARTITION="PARTLABEL=VAULT"

# For machines without the encrypted vault, use:
# VAULT_ENABLED="no"
# VAULT_PARTITION=""

BOOT_FS_LABEL="EFI"
ROOT_FS_LABEL="arch-root"

VAULT_MAPPER_NAME="vault"
VAULT_MOUNTPOINT="/vault"

GO_VERSION="1.24.2"
NODE_VERSION="22.14.0"

# Set these only if you want a non-interactive install.
# Use something like: openssl passwd -6
ROOT_PASSWORD_HASH=""
PRIMARY_USER_PASSWORD_HASH=""

# Optional, but recommended for boot stability.
# CPU_MICROCODE_PACKAGE="amd-ucode"
# CPU_MICROCODE_IMAGE="amd-ucode.img"
