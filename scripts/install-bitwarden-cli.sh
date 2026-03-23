#!/usr/bin/env bash

set -euo pipefail

VERSION=${1:-latest}
NPM_PREFIX=${NPM_PREFIX:-$HOME/.local/npm-global}
PACKAGE='@bitwarden/cli'

if [[ -d "$HOME/node/current/bin" ]]; then
  PATH="$HOME/node/current/bin:$PATH"
fi

command -v node >/dev/null 2>&1 || {
  printf 'Node.js is not available in PATH\n' >&2
  exit 1
}

command -v npm >/dev/null 2>&1 || {
  printf 'npm is not available in PATH\n' >&2
  exit 1
}

if [[ "$VERSION" != "latest" ]]; then
  PACKAGE="${PACKAGE}@${VERSION}"
fi

mkdir -p "$NPM_PREFIX" "$HOME/.local/bin"
npm install --global --prefix "$NPM_PREFIX" "$PACKAGE"
ln -sfn "$NPM_PREFIX/bin/bw" "$HOME/.local/bin/bw"

printf 'Bitwarden CLI installed at %s/bin/bw\n' "$NPM_PREFIX"
