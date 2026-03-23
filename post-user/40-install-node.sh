#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

load_config "${VIRGINATOR_CONFIG:-}"

if [[ -z "$NODE_VERSION" ]]; then
  warn "NODE_VERSION is empty; skipping Node.js installation"
  exit 0
fi

exec "$VIRGINATOR_ROOT/scripts/node-version-manager.sh" "$NODE_VERSION"
