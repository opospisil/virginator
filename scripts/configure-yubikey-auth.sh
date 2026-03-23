#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
export VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-/etc/virginator/config.sh}

# shellcheck source=../lib/common.sh
. "$VIRGINATOR_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  sudo ./scripts/configure-yubikey-auth.sh enable [sudo] [login] [polkit]
  sudo ./scripts/configure-yubikey-auth.sh disable [sudo] [login] [polkit]

Defaults to `enable sudo`.
The script keeps password fallback in place and writes backups as *.virginator.bak.
EOF
}

pam_service_name() {
  case "$1" in
    sudo) printf 'sudo\n' ;;
    login) printf 'system-local-login\n' ;;
    polkit) printf 'polkit-1\n' ;;
    *) die "unsupported service target: $1" ;;
  esac
}

main() {
  local action service service_name pam_file auth_line authfile_path
  local services=("${@:2}")

  require_root
  load_config "$VIRGINATOR_CONFIG"
  require_command pamu2fcfg

  action=${1:-enable}
  if [[ "$action" != "enable" && "$action" != "disable" ]]; then
    usage
    exit 1
  fi

  if ((${#services[@]} == 0)); then
    services=(sudo)
  fi

  authfile_path="/home/$PRIMARY_USER_NAME/.config/Yubico/u2f_keys"
  [[ "$action" == "disable" || -f "$authfile_path" ]] || die "expected YubiKey mapping at $authfile_path; run scripts/enroll-yubikey.sh first"

  for service in "${services[@]}"; do
    service_name=$(pam_service_name "$service")
    pam_file=$(ensure_pam_service_file "$service_name")

    if [[ "$action" == "disable" ]]; then
      backup_file_once "$pam_file" >/dev/null
      remove_managed_block "$pam_file" "yubikey-auth"
      log "removed YubiKey auth block from $pam_file"
      continue
    fi

    auth_line="auth       sufficient   pam_u2f.so cue origin=pam://$HOSTNAME appid=pam://$HOSTNAME"
    insert_pam_auth_block "$pam_file" "yubikey-auth" "$auth_line"
    log "enabled YubiKey auth in $pam_file"
  done

  warn "keep an existing root shell open while testing new PAM changes"
}

main "$@"
