#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

load_config "${VIRGINATOR_CONFIG:-}"

[[ $(id -un) == "$PRIMARY_USER_NAME" ]] || die "run this script as $PRIMARY_USER_NAME"

mkdir -p "$HOME/.local/bin" "$HOME/.local/npm-global"
cp -an "$VIRGINATOR_ROOT/skel/user/." "$HOME/"
chmod +x "$HOME/.xinitrc"

log "copied default user skeleton into $HOME without overwriting existing files"
