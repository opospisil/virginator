#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

require_root
load_config "${VIRGINATOR_CONFIG:-}"

log "enabling required services"
systemctl enable --now NetworkManager.service
systemctl enable --now bluetooth.service
systemctl enable --now pcscd.socket
systemctl enable --now systemd-timesyncd.service

if systemctl list-unit-files | grep -q '^fprintd\.service'; then
  systemctl enable --now fprintd.service
else
  warn "fprintd.service not found; fingerprint enrollment may need manual follow-up"
fi

log "ensuring podman can run rootless"
ensure_subid_entries "$PRIMARY_USER_NAME"
install -d /etc/containers/registries.conf.d
cat > /etc/containers/registries.conf.d/00-docker-io.conf <<'EOF'
unqualified-search-registries = ["docker.io"]
EOF

log "enabling lemurs for graphical login"
systemctl enable lemurs.service

log "service setup complete"
warn "PAM integration for YubiKey and fingerprint is intentionally left manual to avoid lockouts"
warn "use the helpers under $REPO_INSTALL_DIR/scripts/ when you are ready to opt in"
warn "reboot or start lemurs manually when you are ready to leave the current console"
