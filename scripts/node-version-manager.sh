#!/usr/bin/env bash

set -euo pipefail

NODE_VERSION=${1:-}
NODE_DISTRO_ARCH=${NODE_DISTRO_ARCH:-linux-x64}
NODE_ROOT_BASE=${NODE_ROOT_BASE:-$HOME/node}

if [[ -z "$NODE_VERSION" ]]; then
  printf 'usage: %s <node-version>\n' "$0" >&2
  exit 1
fi

VERSION_DIR="$NODE_ROOT_BASE/$NODE_VERSION"
CURRENT_SYMLINK="$NODE_ROOT_BASE/current"
ARCHIVE_NAME="node-v${NODE_VERSION}-${NODE_DISTRO_ARCH}.tar.xz"
DOWNLOAD_URL="https://nodejs.org/dist/v${NODE_VERSION}/${ARCHIVE_NAME}"

mkdir -p "$NODE_ROOT_BASE"

if [[ -x "$VERSION_DIR/bin/node" ]]; then
  printf 'Node.js %s is already present at %s\n' "$NODE_VERSION" "$VERSION_DIR"
else
  rm -rf "$VERSION_DIR"
  mkdir -p "$VERSION_DIR"
  curl -fsSL "$DOWNLOAD_URL" -o "$NODE_ROOT_BASE/$ARCHIVE_NAME"
  tar -C "$VERSION_DIR" -xJf "$NODE_ROOT_BASE/$ARCHIVE_NAME" --strip-components=1
  rm -f "$NODE_ROOT_BASE/$ARCHIVE_NAME"
fi

ln -sfn "$VERSION_DIR" "$CURRENT_SYMLINK"
printf 'Node.js %s is now active via %s\n' "$NODE_VERSION" "$CURRENT_SYMLINK"
