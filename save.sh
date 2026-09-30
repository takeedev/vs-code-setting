#!/usr/bin/env sh

set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd -P)

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
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
    fail 'python3, jq, or node is required to validate JSON'
  fi
}

if [ -n "${VSCODE_USER_DIR:-}" ]; then
  user_dir=$VSCODE_USER_DIR
else
  case "$(uname -s 2>/dev/null || printf unknown)" in
    Darwin) user_dir="$HOME/Library/Application Support/Code/User" ;;
    MINGW*|MSYS*|CYGWIN*) user_dir="${APPDATA:-$HOME/AppData/Roaming}/Code/User" ;;
    *) user_dir="${XDG_CONFIG_HOME:-$HOME/.config}/Code/User" ;;
  esac
fi

for config_file in settings.json keybindings.json; do
  if [ ! -f "$user_dir/$config_file" ]; then
    printf 'Error: source file not found: %s\n' "$user_dir/$config_file" >&2
    exit 1
  fi
done

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/vscode-settings-save.XXXXXX") || fail 'cannot create temporary directory'
cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

for config_file in settings.json keybindings.json; do
  cp "$user_dir/$config_file" "$temp_dir/$config_file"
  validate_json "$temp_dir/$config_file" || fail "$config_file is invalid JSON"
done
for config_file in settings.json keybindings.json; do
  mv "$temp_dir/$config_file" "$script_dir/config/$config_file"
done
printf 'Saved VS Code settings from: %s\n' "$user_dir"
