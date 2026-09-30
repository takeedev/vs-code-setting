#!/usr/bin/env sh

set -eu

RAW_VSCODE_SETTINGS_URL=${RAW_VSCODE_SETTINGS_URL:-https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

find_user_dir() {
  if [ -n "${VSCODE_USER_DIR:-}" ]; then
    printf '%s\n' "$VSCODE_USER_DIR"
    return
  fi

  case "$(uname -s 2>/dev/null || printf unknown)" in
    Darwin) printf '%s\n' "$HOME/Library/Application Support/Code/User" ;;
    MINGW*|MSYS*|CYGWIN*) printf '%s\n' "${APPDATA:-$HOME/AppData/Roaming}/Code/User" ;;
    *) printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User" ;;
  esac
}

validate_json() {
  json_file=$1
  if command -v python3 >/dev/null 2>&1; then
    python3 -m json.tool "$json_file" >/dev/null
  elif command -v jq >/dev/null 2>&1; then
    jq empty "$json_file" >/dev/null
  elif command -v node >/dev/null 2>&1; then
    node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$json_file"
  else
    fail 'python3, jq, or node is required to validate downloaded JSON'
  fi
}

download() {
  source_url=$1
  destination=$2
  curl -fsSL "$source_url" -o "$destination" || fail "download failed: $source_url"
}

user_dir=$(find_user_dir)
backup_base=${VSCODE_SETTINGS_BACKUP_DIR:-"$HOME/.vscode-settings-backups"}
backup_timestamp=$(date '+%Y%m%d-%H%M%S')
backup_root="$backup_base/$backup_timestamp"
[ ! -e "$backup_root" ] || backup_root="$backup_root-$$"

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/vscode-settings.XXXXXX") || fail 'cannot create temporary directory'
cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

download "$RAW_VSCODE_SETTINGS_URL/config/settings.json" "$temp_dir/settings.json"
download "$RAW_VSCODE_SETTINGS_URL/config/keybindings.json" "$temp_dir/keybindings.json"
validate_json "$temp_dir/settings.json" || fail 'downloaded settings.json is invalid JSON'
validate_json "$temp_dir/keybindings.json" || fail 'downloaded keybindings.json is invalid JSON'

(umask 077 && mkdir -p "$backup_root/files") || fail 'cannot create backup directory'
printf '%s\n' "$user_dir" > "$backup_root/user-dir"
for config_file in settings.json keybindings.json; do
  if [ -f "$user_dir/$config_file" ]; then
    cp -p "$user_dir/$config_file" "$backup_root/files/$config_file" || fail "cannot back up $config_file"
    : > "$backup_root/files/$config_file.present"
  fi
done

mkdir -p "$user_dir" || fail "cannot create VS Code user directory: $user_dir"
for config_file in settings.json keybindings.json; do
  cp "$temp_dir/$config_file" "$user_dir/$config_file.new" || fail "cannot stage $config_file"
done
for config_file in settings.json keybindings.json; do
  mv "$user_dir/$config_file.new" "$user_dir/$config_file" || fail "cannot install $config_file"
done

printf 'Installed VS Code settings in: %s\n' "$user_dir"
printf 'Backup directory: %s\n' "$backup_root"

if [ "${VSCODE_SKIP_EXTENSIONS:-0}" != 1 ]; then
  download "$RAW_VSCODE_SETTINGS_URL/install-extensions.sh" "$temp_dir/install-extensions.sh"
  /usr/bin/env sh "$temp_dir/install-extensions.sh"
fi
