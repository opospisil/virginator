#!/usr/bin/env bash

set -euo pipefail

GO_VERSION=${1:-}
GO_ARCH=${GO_ARCH:-linux-amd64}
GO_ROOT_BASE=${GO_ROOT_BASE:-$HOME/golang}

if [[ -z "$GO_VERSION" ]]; then
  printf 'usage: %s <go-version>\n' "$0" >&2
  exit 1
fi

VERSION_DIR="$GO_ROOT_BASE/$GO_VERSION"
CURRENT_SYMLINK="$GO_ROOT_BASE/current"
TARBALL_NAME="go${GO_VERSION}.${GO_ARCH}.tar.gz"
DOWNLOAD_URL="https://go.dev/dl/${TARBALL_NAME}"

mkdir -p "$GO_ROOT_BASE" "$VERSION_DIR" "$HOME/go"

if [[ -x "$VERSION_DIR/bin/go" ]]; then
  printf 'Go %s is already present at %s\n' "$GO_VERSION" "$VERSION_DIR"
else
  rm -rf "$VERSION_DIR"
  mkdir -p "$VERSION_DIR"
  curl -fsSL "$DOWNLOAD_URL" -o "$GO_ROOT_BASE/$TARBALL_NAME"
  tar -C "$VERSION_DIR" -xzf "$GO_ROOT_BASE/$TARBALL_NAME" --strip-components=1
  rm -f "$GO_ROOT_BASE/$TARBALL_NAME"
fi

ln -sfn "$VERSION_DIR" "$CURRENT_SYMLINK"
printf 'Go %s is now active via %s\n' "$GO_VERSION" "$CURRENT_SYMLINK"
