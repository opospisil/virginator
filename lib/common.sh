#!/usr/bin/env bash

VIRGINATOR_ROOT=${VIRGINATOR_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}
VIRGINATOR_CONFIG=${VIRGINATOR_CONFIG:-/etc/virginator/config.sh}

log() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_root() {
  [[ $(id -u) -eq 0 ]] || die "run this script as root"
}

require_command() {
  local command_name
  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 || die "missing required command: $command_name"
  done
}

require_vars() {
  local variable_name
  for variable_name in "$@"; do
    [[ -n ${!variable_name:-} ]] || die "missing required configuration variable: $variable_name"
  done
}

trim() {
  local value
  value=$1
  value=${value#"${value%%[![:space:]]*}"}
  value=${value%"${value##*[![:space:]]}"}
  printf '%s' "$value"
}

flag_enabled() {
  case ${1:-} in
    1|[Yy]|[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]|[Oo][Nn]) return 0 ;;
    0|[Nn]|[Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]|[Oo][Ff][Ff]|"") return 1 ;;
    *) die "invalid boolean flag value: ${1:-}" ;;
  esac
}

vault_enabled() {
  flag_enabled "${VAULT_ENABLED:-yes}"
}

load_config() {
  local config_path
  config_path=${1:-$VIRGINATOR_CONFIG}

  [[ -f "$VIRGINATOR_ROOT/config/defaults.sh" ]] || die "defaults file not found under $VIRGINATOR_ROOT/config/defaults.sh"
  [[ -f "$config_path" ]] || die "config file not found: $config_path"

  # shellcheck source=/dev/null
  . "$VIRGINATOR_ROOT/config/defaults.sh"
  # shellcheck source=/dev/null
  . "$config_path"

  VIRGINATOR_CONFIG=$(realpath "$config_path")
  export VIRGINATOR_ROOT VIRGINATOR_CONFIG

  require_vars HOSTNAME TIMEZONE LOCALE KEYMAP PRIMARY_USER_NAME BOOT_PARTITION ROOT_PARTITION HOME_PARTITION

  if vault_enabled; then
    require_vars VAULT_PARTITION
  fi
}

resolve_block_device() {
  local token
  local matches=()

  token=$1
  mapfile -t matches < <(blkid -o device -t "$token")

  case ${#matches[@]} in
    1) printf '%s\n' "${matches[0]}" ;;
    0) die "no block device matched token: $token" ;;
    *) die "multiple block devices matched token: $token" ;;
  esac
}

read_packages_from_file() {
  local file_path line

  file_path=$1
  [[ -f "$file_path" ]] || die "package list not found: $file_path"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line=${line%%#*}
    line=$(trim "$line")
    [[ -n "$line" ]] && printf '%s\n' "$line"
  done < "$file_path"
}

install_packages_from_files() {
  local file_path package_name
  local packages=()

  for file_path in "$@"; do
    while IFS= read -r package_name; do
      packages+=("$package_name")
    done < <(read_packages_from_file "$file_path")
  done

  if ((${#packages[@]} == 0)); then
    warn "no packages were collected from the provided bundle files"
    return 0
  fi

  pacman -S --needed --noconfirm "${packages[@]}"
}

copy_repo_to_target() {
  local target_root

  target_root=$1

  mkdir -p "$target_root$REPO_INSTALL_DIR"
  cp -a "$VIRGINATOR_ROOT/." "$target_root$REPO_INSTALL_DIR/"

  mkdir -p "$target_root$CONFIG_INSTALL_DIR"
  install -m 600 "$VIRGINATOR_CONFIG" "$target_root$CONFIG_INSTALL_DIR/config.sh"
}

ensure_line_in_file() {
  local line file_path

  line=$1
  file_path=$2

  touch "$file_path"
  grep -Fqx "$line" "$file_path" || printf '%s\n' "$line" >> "$file_path"
}

ensure_subid_entries() {
  local user_name

  user_name=$1

  if grep -q "^${user_name}:" /etc/subuid && grep -q "^${user_name}:" /etc/subgid; then
    return 0
  fi

  if usermod --help 2>&1 | grep -q -- '--add-subuids'; then
    usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$user_name"
    return 0
  fi

  warn "unable to add subuid/subgid ranges automatically; rootless podman may need manual setup"
}

backup_file_once() {
  local file_path backup_path

  file_path=$1
  backup_path="${file_path}.virginator.bak"

  [[ -e "$file_path" ]] || die "cannot back up missing file: $file_path"

  if [[ ! -e "$backup_path" ]]; then
    cp -a "$file_path" "$backup_path"
  fi

  printf '%s\n' "$backup_path"
}

ensure_pam_service_file() {
  local service_name etc_path vendor_path

  service_name=$1
  etc_path="/etc/pam.d/$service_name"
  vendor_path="/usr/lib/pam.d/$service_name"

  if [[ -f "$etc_path" ]]; then
    printf '%s\n' "$etc_path"
    return 0
  fi

  [[ -f "$vendor_path" ]] || die "no PAM service file found for $service_name"

  install -D -m 644 "$vendor_path" "$etc_path"
  printf '%s\n' "$etc_path"
}

remove_managed_block() {
  local file_path block_id begin_marker end_marker tmp_file

  file_path=$1
  block_id=$2
  begin_marker="# virginator-begin:${block_id}"
  end_marker="# virginator-end:${block_id}"
  tmp_file=$(mktemp)

  awk -v begin_marker="$begin_marker" -v end_marker="$end_marker" '
    $0 == begin_marker { skip=1; next }
    $0 == end_marker { skip=0; next }
    !skip { print }
  ' "$file_path" > "$tmp_file"

  mv "$tmp_file" "$file_path"
}

insert_pam_auth_block() {
  local file_path block_id auth_line begin_marker end_marker tmp_file

  file_path=$1
  block_id=$2
  auth_line=$3
  begin_marker="# virginator-begin:${block_id}"
  end_marker="# virginator-end:${block_id}"

  backup_file_once "$file_path" >/dev/null
  remove_managed_block "$file_path" "$block_id"

  tmp_file=$(mktemp)

  awk -v begin_marker="$begin_marker" -v auth_line="$auth_line" -v end_marker="$end_marker" '
    BEGIN { inserted=0 }
    !inserted && /^auth[[:space:]]/ {
      print begin_marker
      print auth_line
      print end_marker
      inserted=1
    }
    { print }
    END {
      if (!inserted) {
        print begin_marker
        print auth_line
        print end_marker
      }
    }
  ' "$file_path" > "$tmp_file"

  mv "$tmp_file" "$file_path"
}
