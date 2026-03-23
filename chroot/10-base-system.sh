#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

set_account_password() {
  local account_name

  account_name=$1
  log "set the password for $account_name"
  passwd "$account_name"
}

write_bootloader_config() {
  local root_source root_uuid loader_entry

  root_source=$(findmnt -n -o SOURCE /)
  root_uuid=$(blkid -s UUID -o value "$root_source")
  loader_entry=/boot/loader/entries/arch.conf

  mkdir -p /boot/loader/entries

  cat > /boot/loader/loader.conf <<EOF
default arch.conf
timeout ${LOADER_TIMEOUT}
editor no
EOF

  {
    printf 'title Arch Linux\n'
    printf 'linux /vmlinuz-linux\n'
    if [[ -n "$CPU_MICROCODE_IMAGE" ]]; then
      printf 'initrd /%s\n' "$CPU_MICROCODE_IMAGE"
    fi
    printf 'initrd /initramfs-linux.img\n'
    printf 'options root=UUID=%s rw\n' "$root_uuid"
  } > "$loader_entry"
}

configure_networkmanager() {
  install -d /etc/NetworkManager/conf.d

  cat > /etc/NetworkManager/conf.d/20-wifi-backend.conf <<'EOF'
[device]
wifi.backend=iwd
EOF

  cat > /etc/NetworkManager/conf.d/20-wifi-powersave.conf <<'EOF'
[connection]
wifi.powersave=2
EOF
}

create_primary_user() {
  local group_args=()
  local user_args=()
  local groups_csv

  [[ ! -e "/home/$PRIMARY_USER_NAME" ]] || die "target home directory /home/$PRIMARY_USER_NAME already exists"
  ! id "$PRIMARY_USER_NAME" >/dev/null 2>&1 || die "user $PRIMARY_USER_NAME already exists"

  if ! getent group "$PRIMARY_USER_NAME" >/dev/null 2>&1; then
    if [[ -n ${PRIMARY_USER_GID:-} ]]; then
      group_args=(-g "$PRIMARY_USER_GID")
    fi
    groupadd "${group_args[@]}" "$PRIMARY_USER_NAME"
  fi

  groups_csv=$(IFS=,; printf '%s' "${PRIMARY_USER_GROUPS[*]}")

  user_args=(-m -g "$PRIMARY_USER_NAME" -s "$PRIMARY_USER_SHELL")
  if [[ -n ${PRIMARY_USER_UID:-} ]]; then
    user_args+=(-u "$PRIMARY_USER_UID")
  fi
  if [[ -n "$groups_csv" ]]; then
    user_args+=(-G "$groups_csv")
  fi

  useradd "${user_args[@]}" "$PRIMARY_USER_NAME"
}

require_root
require_command blkid bootctl findmnt hwclock locale-gen passwd sed systemctl useradd
load_config "${VIRGINATOR_CONFIG:-}"

log "configuring locale and time settings"
sed -i "s/^#\(${LOCALE} .*\)/\1/" /etc/locale.gen
grep -Eq "^${LOCALE} " /etc/locale.gen || printf '%s UTF-8\n' "$LOCALE" >> /etc/locale.gen
locale-gen
printf 'LANG=%s\n' "$LOCALE" > /etc/locale.conf
printf 'KEYMAP=%s\n' "$KEYMAP" > /etc/vconsole.conf
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

log "configuring hostname and hosts file"
printf '%s\n' "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<EOF
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

if [[ -n "$CPU_MICROCODE_PACKAGE" ]]; then
  log "installing CPU microcode package $CPU_MICROCODE_PACKAGE"
  pacman -S --needed --noconfirm "$CPU_MICROCODE_PACKAGE"
fi

log "installing systemd-boot"
bootctl install
write_bootloader_config

log "preparing sudo access"
install -d /etc/sudoers.d
cat > /etc/sudoers.d/10-wheel <<'EOF'
%wheel ALL=(ALL:ALL) ALL
EOF
chmod 440 /etc/sudoers.d/10-wheel

log "creating the fresh primary user"
create_primary_user

log "configuring NetworkManager to use iwd"
configure_networkmanager

log "setting account passwords"
set_account_password root
set_account_password "$PRIMARY_USER_NAME"

if vault_enabled; then
  mkdir -p "$VAULT_MOUNTPOINT"
fi

log "enabling base services"
systemctl enable iwd.service
systemctl enable NetworkManager.service
systemctl enable systemd-timesyncd.service

log "base system setup complete"
