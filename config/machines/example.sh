#!/usr/bin/env bash

HOSTNAME="arch-fresh"
TIMEZONE="Europe/Prague"
LOCALE="en_US.UTF-8"
KEYMAP="us"

PRIMARY_USER_NAME="freshuser"
PRIMARY_USER_UID="1100"
PRIMARY_USER_GID="1100"
PRIMARY_USER_GROUPS=(wheel video)

BOOT_FS_LABEL="EFI"
ROOT_FS_LABEL="arch-root"

VAULT_MAPPER_NAME="vault"
VAULT_MOUNTPOINT="/vault"

GO_VERSION="1.26.1"
NODE_VERSION="24.14.1"

# Optional AUR overrides.
# AUR_HELPER_PACKAGE="paru-bin"
# AUR_PACKAGES=(brave-bin)
