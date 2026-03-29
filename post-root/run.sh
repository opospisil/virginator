#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
export VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-$VIRGINATOR_ROOT/config/current.sh}

# shellcheck source=../lib/common.sh
. "$VIRGINATOR_ROOT/lib/common.sh"

require_root
load_config "$VIRGINATOR_CONFIG"

for script in \
  "$SCRIPT_DIR/10-install-packages.sh" \
  "$SCRIPT_DIR/20-configure-lemurs.sh" \
  "$SCRIPT_DIR/25-configure-touchpad.sh" \
  "$SCRIPT_DIR/30-enable-services.sh"
do
  log "executing ${script##*/}"
  bash "$script"
done

log "post-root setup complete"
printf 'reboot or switch to lemurs, log in as %s, and run %s/post-user/run.sh\n' "$PRIMARY_USER_NAME" "$REPO_INSTALL_DIR"
