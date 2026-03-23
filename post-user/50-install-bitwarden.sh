#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

load_config "${VIRGINATOR_CONFIG:-}"

exec "$VIRGINATOR_ROOT/scripts/install-bitwarden-cli.sh" "$BITWARDEN_CLI_VERSION"
