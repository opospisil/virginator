#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

load_config "${VIRGINATOR_CONFIG:-}"

if [[ -x "$HOME/.cargo/bin/rustup" ]]; then
  log "rustup is already installed"
  exit 0
fi

require_command curl sh

log "installing rustup from the official bootstrap script"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
