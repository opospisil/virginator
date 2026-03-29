#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
export VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-$VIRGINATOR_ROOT/config/current.sh}

# shellcheck source=../lib/common.sh
. "$VIRGINATOR_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
Usage: ./scripts/enroll-yubikey.sh [--append]

Creates or extends ~/.config/Yubico/u2f_keys for the configured primary user.
Use --append when adding a second key.
Touch the YubiKey when prompted during enrollment.
EOF
}

load_config "$VIRGINATOR_CONFIG"

[[ $(id -un) == "$PRIMARY_USER_NAME" ]] || die "run this script as $PRIMARY_USER_NAME"
require_command pamu2fcfg

APPEND=0

if [[ ${1:-} == "--append" ]]; then
  APPEND=1
elif [[ $# -gt 0 ]]; then
  usage
  exit 1
fi

ORIGIN="pam://$HOSTNAME"
CONFIG_DIR="$HOME/.config/Yubico"
AUTHFILE="$CONFIG_DIR/u2f_keys"
ENTRY=""

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

if (( APPEND == 0 )) && [[ -f "$AUTHFILE" ]]; then
  backup_file_once "$AUTHFILE" >/dev/null
fi

if (( APPEND == 1 )); then
  [[ -f "$AUTHFILE" ]] || die "cannot append because $AUTHFILE does not exist yet"
  log "append mode: touch the YubiKey when prompted"
  ENTRY=$(pamu2fcfg -i "$ORIGIN" -n | tr -d '\n')
  printf '%s\n' "$(tr -d '\n' < "$AUTHFILE")$ENTRY" > "$AUTHFILE"
else
  log "creating $AUTHFILE for hostname $HOSTNAME"
  log "touch the YubiKey when prompted"
  ENTRY=$(pamu2fcfg -i "$ORIGIN" | tr -d '\n')
  printf '%s\n' "$ENTRY" > "$AUTHFILE"
fi

chmod 600 "$AUTHFILE"
log "YubiKey mapping written to $AUTHFILE"
