#!/usr/bin/env bash

set -euo pipefail

REPO_URL=${REPO_URL:-https://github.com/opospisil/virginator.git}
REPO_DIR=${REPO_DIR:-virginator}

ensure_iwd_disable_powersave() {
  local config_file tmp_file

  config_file=/etc/iwd/main.conf
  mkdir -p /etc/iwd

  if [[ ! -f "$config_file" ]]; then
    cat > "$config_file" <<'EOF'
[General]
DisablePowerSave=true
EOF
    return 0
  fi

  tmp_file=$(mktemp)
  awk '
    BEGIN {
      in_general = 0
      general_seen = 0
      setting_written = 0
    }
    /^\[General\]$/ {
      if (in_general && !setting_written) {
        print "DisablePowerSave=true"
        setting_written = 1
      }
      print
      in_general = 1
      general_seen = 1
      next
    }
    /^\[/ {
      if (in_general && !setting_written) {
        print "DisablePowerSave=true"
        setting_written = 1
      }
      in_general = 0
    }
    in_general && /^DisablePowerSave=/ {
      if (!setting_written) {
        print "DisablePowerSave=true"
        setting_written = 1
      }
      next
    }
    {
      print
    }
    END {
      if (in_general && !setting_written) {
        print "DisablePowerSave=true"
        setting_written = 1
      }
      if (!general_seen) {
        if (NR > 0) {
          print ""
        }
        print "[General]"
        print "DisablePowerSave=true"
      }
    }
  ' "$config_file" > "$tmp_file"

  mv "$tmp_file" "$config_file"
}

[[ $(id -u) -eq 0 ]] || {
  printf 'run this script as root\n' >&2
  exit 1
}

ensure_iwd_disable_powersave
systemctl restart iwd.service || systemctl start iwd.service || true

echo "giving the iwd service time to start"
sleep 5

timedatectl set-ntp true || true

if command -v iw >/dev/null 2>&1; then
  while read -r key iface _; do
    [[ $key == "Interface" ]] || continue
    iw dev "$iface" set power_save off || true
  done < <(iw dev)
fi

pacman -Sy --needed --noconfirm reflector
cp -n /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

reflector \
  --country CZ \
  --country DE \
  --verbose \
  --latest 20 \
  --protocol https \
  --sort rate \
  --save /etc/pacman.d/mirrorlist

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
