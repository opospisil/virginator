#!/usr/bin/env bash

set -euo pipefail

REPO_URL=${REPO_URL:-https://github.com/opospisil/virginator.git}
REPO_DIR=${REPO_DIR:-virginator}
DEFAULT_MIRROR_COUNT=${DEFAULT_MIRROR_COUNT:-20}

prompt_yes_no() {
  local prompt default answer

  prompt=$1
  default=${2:-N}

  if [[ $default == Y ]]; then
    printf '%s [Y/n] ' "$prompt" >&2
  else
    printf '%s [y/N] ' "$prompt" >&2
  fi

  read -r answer
  answer=${answer:-$default}
  [[ $answer =~ ^[Yy]([Ee][Ss])?$ ]]
}

prompt_mirror_count() {
  local answer

  printf 'How many mirrors should reflector keep? [%s] ' "$DEFAULT_MIRROR_COUNT" >&2
  read -r answer
  answer=${answer:-$DEFAULT_MIRROR_COUNT}

  [[ $answer =~ ^[0-9]+$ ]] || {
    printf 'invalid mirror count: %s\n' "$answer" >&2
    exit 1
  }

  printf '%s\n' "$answer"
}

[[ $(id -u) -eq 0 ]] || {
  printf 'run this script as root\n' >&2
  exit 1
}


timedatectl set-ntp true || true

if prompt_yes_no 'Rank mirrors with reflector?' Y; then
  MIRROR_COUNT=$(prompt_mirror_count)
  cp -n /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

  reflector \
    --country CZ \
    --country DE \
    --verbose \
    --latest "$MIRROR_COUNT" \
    --protocol https \
    --sort rate \
    --save /etc/pacman.d/mirrorlist
fi

pacman -Sy --needed --noconfirm git skim

if [[ -d "$REPO_DIR/.git" ]]; then
  printf 'repo already exists at %s\n' "$REPO_DIR"
elif [[ -e "$REPO_DIR" ]]; then
  printf 'path exists and is not a git clone: %s\n' "$REPO_DIR" >&2
  exit 1
else
  git clone --depth=1 "$REPO_URL" "$REPO_DIR"
fi

cat <<EOF
Next:
  cd $REPO_DIR
  ./scripts/select-partitions.sh
  cp config/machines/example.sh config/machines/my-machine.sh
  ./bootstrap.sh config/machines/my-machine.sh
EOF
