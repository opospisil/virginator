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
  sudo ./scripts/configure-fingerprint-auth.sh enable [lemurs] [login]
  sudo ./scripts/configure-fingerprint-auth.sh disable [lemurs] [login]

Defaults to `enable lemurs`.
This script intentionally targets lemurs or console login only, not sudo or polkit.
EOF
}

pam_service_name() {
  case "$1" in
    lemurs) printf 'lemurs\n' ;;
    login) printf 'system-local-login\n' ;;
    *) die "unsupported fingerprint target: $1" ;;
  esac
}

main() {
  local action target pam_file auth_line service_name
  local targets=("${@:2}")
  local saw_lemurs=0
  local saw_login=0

  require_root
  load_config "$VIRGINATOR_CONFIG"
  require_command fprintd-enroll

  action=${1:-enable}
  if [[ "$action" != "enable" && "$action" != "disable" ]]; then
    usage
    exit 1
  fi

  if ((${#targets[@]} == 0)); then
    targets=(lemurs)
  fi

  for target in "${targets[@]}"; do
    [[ "$target" == "lemurs" ]] && saw_lemurs=1
    [[ "$target" == "login" ]] && saw_login=1

    service_name=$(pam_service_name "$target")
    pam_file=$(ensure_pam_service_file "$service_name")

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

  if (( saw_lemurs == 1 && saw_login == 1 )); then
    warn "lemurs usually includes the login PAM stack, so enabling both lemurs and login may cause duplicate prompts"
  fi

  warn "fingerprint auth is restricted to lemurs or console login because using it for sudo or polkit is unsafe"
  warn "keep an existing root shell open while testing new PAM changes"
}

main "$@"
