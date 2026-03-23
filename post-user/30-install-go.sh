#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

load_config "${VIRGINATOR_CONFIG:-}"

if [[ -z "$GO_VERSION" ]]; then
  warn "GO_VERSION is empty; skipping Go installation"
  exit 0
fi

exec "$VIRGINATOR_ROOT/scripts/go-version-manager.sh" "$GO_VERSION"
