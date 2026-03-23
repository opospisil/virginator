#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export VIRGINATOR_ROOT=$(cd -- "$SCRIPT_DIR/.." && pwd)
export VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-/etc/virginator/config.sh}

# shellcheck source=../lib/common.sh
. "$VIRGINATOR_ROOT/lib/common.sh"

load_config "$VIRGINATOR_CONFIG"
PRIMARY_HOME=$(getent passwd "$PRIMARY_USER_NAME" | cut -d: -f6)

check_command() {
  local name
  name=$1

  if command -v "$name" >/dev/null 2>&1; then
    printf '[ok] %s\n' "$name"
  else
    printf '[missing] %s\n' "$name"
  fi
}

check_command fish
check_command i3
check_command alacritty
check_command tmux
check_command podman
check_command openvpn
check_command git-crypt
check_command ykman
check_command pamu2fcfg
check_command fprintd-enroll

if [[ $(id -u) -eq 0 ]]; then
  systemctl is-enabled --quiet NetworkManager.service && printf '[ok] NetworkManager enabled\n' || printf '[missing] NetworkManager enabled\n'
  systemctl is-enabled --quiet bluetooth.service && printf '[ok] bluetooth enabled\n' || printf '[missing] bluetooth enabled\n'
  systemctl is-enabled --quiet pcscd.socket && printf '[ok] pcscd.socket enabled\n' || printf '[missing] pcscd.socket enabled\n'
else
  printf 'service checks skipped because this script is not running as root\n'
fi

if [[ -n ${GO_VERSION:-} && -x "$PRIMARY_HOME/golang/current/bin/go" ]]; then
  printf '[ok] Go active at %s\n' "$PRIMARY_HOME/golang/current/bin/go"
fi

if [[ -x "$PRIMARY_HOME/.local/bin/nvim" ]]; then
  printf '[ok] Neovim nightly active at %s\n' "$PRIMARY_HOME/.local/bin/nvim"
fi

if [[ -n ${NODE_VERSION:-} && -x "$PRIMARY_HOME/node/current/bin/node" ]]; then
  printf '[ok] Node.js active at %s\n' "$PRIMARY_HOME/node/current/bin/node"
fi

if [[ -x "$PRIMARY_HOME/.local/bin/bw" ]]; then
  printf '[ok] Bitwarden CLI active at %s\n' "$PRIMARY_HOME/.local/bin/bw"
fi
