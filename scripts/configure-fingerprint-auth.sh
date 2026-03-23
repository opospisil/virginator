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
  sudo ./scripts/configure-fingerprint-auth.sh enable [login]
  sudo ./scripts/configure-fingerprint-auth.sh disable [login]

Defaults to `enable login`.
This script intentionally targets login only, not sudo or polkit.
EOF
}

main() {
  local action target pam_file auth_line
  local targets=("${@:2}")

  require_root
  load_config "$VIRGINATOR_CONFIG"
  require_command fprintd-enroll

  action=${1:-enable}
  if [[ "$action" != "enable" && "$action" != "disable" ]]; then
    usage
    exit 1
  fi

  if ((${#targets[@]} == 0)); then
    targets=(login)
  fi

  for target in "${targets[@]}"; do
    [[ "$target" == "login" ]] || die "unsupported fingerprint target: $target"
    pam_file=$(ensure_pam_service_file system-local-login)

    if [[ "$action" == "disable" ]]; then
      backup_file_once "$pam_file" >/dev/null
      remove_managed_block "$pam_file" "fingerprint-auth"
      log "removed fingerprint auth block from $pam_file"
      continue
    fi

    auth_line='auth       sufficient   pam_fprintd.so'
    insert_pam_auth_block "$pam_file" "fingerprint-auth" "$auth_line"
    log "enabled fingerprint auth in $pam_file"
  done

  warn "fingerprint auth is restricted to login because using it for sudo or polkit is unsafe"
  warn "keep an existing root shell open while testing new PAM changes"
}

main "$@"
