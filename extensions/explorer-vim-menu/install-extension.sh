#!/usr/bin/env sh

set -eu

RAW_VSCODE_SETTINGS_URL=${RAW_VSCODE_SETTINGS_URL:-https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main}
extension_id=takeedev.explorer-vim-menu
extension_version=0.1.0
extensions_dir=${VSCODE_EXTENSIONS_DIR:-"$HOME/.vscode/extensions"}
target_dir="$extensions_dir/$extension_id-$extension_version"

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

download() {
  source_url=$1
  destination=$2
  curl -fsSL "$source_url" -o "$destination" || fail "download failed: $source_url"
}

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/explorer-vim-menu.XXXXXX") || fail 'cannot create temporary directory'
cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

download "$RAW_VSCODE_SETTINGS_URL/extensions/explorer-vim-menu/package.json" "$temp_dir/package.json"
download "$RAW_VSCODE_SETTINGS_URL/extensions/explorer-vim-menu/extension.js" "$temp_dir/extension.js"

if command -v python3 >/dev/null 2>&1; then
  python3 -m json.tool "$temp_dir/package.json" >/dev/null
elif command -v node >/dev/null 2>&1; then
  node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$temp_dir/package.json"
else
  fail 'python3 or node is required to validate the extension manifest'
fi

mkdir -p "$extensions_dir" "$target_dir" || fail "cannot create extension directory: $target_dir"
cp "$temp_dir/package.json" "$target_dir/package.json.new"
cp "$temp_dir/extension.js" "$target_dir/extension.js.new"
mv "$target_dir/package.json.new" "$target_dir/package.json"
mv "$target_dir/extension.js.new" "$target_dir/extension.js"

printf 'Installed Explorer Vim Menu extension in: %s\n' "$target_dir"
