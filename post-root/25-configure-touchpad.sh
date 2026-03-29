#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

require_root
load_config "${VIRGINATOR_CONFIG:-}"

log "configuring touchpad tap-to-click defaults"
install -d -m 755 /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/30-touchpad.conf <<'EOF'
Section "InputClass"
    Identifier "touchpad defaults"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "on"
    Option "DisableWhileTyping" "true"
EndSection
EOF
