#!/usr/bin/env bash

set -euo pipefail

# shellcheck source=../lib/common.sh
. "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"

require_root
load_config "${VIRGINATOR_CONFIG:-}"

log "configuring lemurs as the default display manager"
install -d -m 755 /etc/lemurs/wms

cat > /etc/lemurs/wms/i3 <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

[[ -f /etc/profile ]] && . /etc/profile
[[ -f "$HOME/.profile" ]] && . "$HOME/.profile"
[[ -f "$HOME/.xprofile" ]] && . "$HOME/.xprofile"

export DESKTOP_SESSION=i3
export XDG_CURRENT_DESKTOP=i3
export XDG_SESSION_DESKTOP=i3
export XDG_SESSION_TYPE=x11

exec dbus-run-session i3
EOF

chmod 755 /etc/lemurs/wms/i3
log "lemurs session launcher ready at /etc/lemurs/wms/i3"
