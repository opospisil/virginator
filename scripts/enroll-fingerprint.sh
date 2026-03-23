#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
export VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-$VIRGINATOR_ROOT/config/current.sh}

# shellcheck source=../lib/common.sh
. "$VIRGINATOR_ROOT/lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/enroll-fingerprint.sh [finger-name]
  ./scripts/enroll-fingerprint.sh --all

Examples:
  ./scripts/enroll-fingerprint.sh right-index-finger
  ./scripts/enroll-fingerprint.sh --all
EOF
}

load_config "$VIRGINATOR_CONFIG"
require_command fprintd-delete fprintd-enroll

if [[ $(id -u) -eq 0 ]]; then
  TARGET_USER=${SUDO_USER:-$PRIMARY_USER_NAME}
else
  TARGET_USER=$(id -un)
fi

if [[ ${1:-} == "--all" ]]; then
  log "removing existing fingerprints for $TARGET_USER"
  fprintd-delete "$TARGET_USER" || true
  for finger in \
    left-thumb left-index-finger left-middle-finger left-ring-finger left-little-finger \
    right-thumb right-index-finger right-middle-finger right-ring-finger right-little-finger
  do
    log "enrolling $finger for $TARGET_USER"
    fprintd-enroll -f "$finger" "$TARGET_USER"
  done
  exit 0
fi

if [[ $# -gt 1 ]]; then
  usage
  exit 1
fi

if [[ $# -eq 1 ]]; then
  log "enrolling $1 for $TARGET_USER"
  exec fprintd-enroll -f "$1" "$TARGET_USER"
fi

log "enrolling the default finger for $TARGET_USER"
exec fprintd-enroll "$TARGET_USER"
