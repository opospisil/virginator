#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '==> %s\n' "$*"
}

has_systemd_unit() {
  local unit_name

  unit_name=$1
  systemctl list-unit-files "$unit_name" --no-legend 2>/dev/null | grep -q "^${unit_name}[[:space:]]"
}

write_iwd_config() {
  local config_file

  config_file=/etc/iwd/main.conf
  install -d -m 755 /etc/iwd

  cat > "$config_file" <<'EOF'
[DriverQuirks]
PowerSaveDisable=*
EOF
}

disable_interface_powersave() {
  local key iface _ applied_any=0

  command -v iw >/dev/null 2>&1 || return 0

  while read -r key iface _; do
    [[ $key == "Interface" ]] || continue
    iw dev "$iface" set power_save off || true
    printf '  - disabled interface powersave on %s\n' "$iface"
    applied_any=1
  done < <(iw dev)

  (( applied_any == 1 )) || printf '  - no wireless interfaces found for immediate power-save disable\n'
}

write_networkmanager_config() {
  install -d -m 755 /etc/NetworkManager/conf.d
  cat > /etc/NetworkManager/conf.d/20-wifi.conf <<'EOF'
[device]
wifi.backend=iwd

[connection]
wifi.powersave=2
EOF
}

restart_service_if_present() {
  local unit_name

  unit_name=$1

  if has_systemd_unit "$unit_name"; then
    systemctl restart "$unit_name" || systemctl start "$unit_name" || true
    return 0
  fi

  printf '  - skipped %s because it is not installed in this environment\n' "$unit_name"
}

[[ $(id -u) -eq 0 ]] || {
  printf 'run this script as root\n' >&2
  exit 1
}

write_iwd_config

log "applying iwd power-save settings"
printf '  - /etc/iwd/main.conf: [DriverQuirks] PowerSaveDisable=*\n'
restart_service_if_present iwd.service

sleep 2

if has_systemd_unit NetworkManager.service; then
  log "applying NetworkManager Wi-Fi settings"
  write_networkmanager_config
  printf '  - /etc/NetworkManager/conf.d/20-wifi.conf: wifi.backend=iwd, wifi.powersave=2\n'
else
  log "skipping NetworkManager config because NetworkManager.service is not present"
fi

restart_service_if_present NetworkManager.service

log "disabling immediate interface power save"
disable_interface_powersave

printf 'Applied Wi-Fi reliability settings:\n'

if has_systemd_unit iwd.service; then
  systemctl is-active --quiet iwd.service && printf '  - iwd.service active\n' || printf '  - iwd.service not active\n'
fi

if has_systemd_unit NetworkManager.service; then
  systemctl is-active --quiet NetworkManager.service && printf '  - NetworkManager.service active\n' || printf '  - NetworkManager.service not active\n'
fi
