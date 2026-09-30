#!/usr/bin/env sh

set -eu

repo_root=$(CDPATH= cd "$(dirname "$0")/.." && pwd -P)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/vscode-settings-tests.XXXXXX")
cleanup() {
  rm -rf "$test_root"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

passed=0
failed=0

pass() {
  passed=$((passed + 1))
  printf 'ok %s - %s\n' "$passed" "$1"
}

fail() {
  failed=$((failed + 1))
  printf 'not ok %s - %s\n' "$((passed + failed))" "$1" >&2
}

run_test() {
  test_name=$1
  shift
  if "$@"; then
    pass "$test_name"
  else
    fail "$test_name"
  fi
}

assert_same() {
  cmp -s "$1" "$2" || {
    printf 'Files differ: %s %s\n' "$1" "$2" >&2
    return 1
  }
}

make_stubs() {
  stub_dir=$1
  mkdir -p "$stub_dir"

  cat > "$stub_dir/curl" <<'EOF'
#!/usr/bin/env sh
set -eu
url=
destination=
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) destination=$2; shift 2 ;;
    -*) shift ;;
    *) url=$1; shift ;;
  esac
done
[ -n "$url" ] && [ -n "$destination" ]
relative_path=${url#*/config/}
case "$url" in
  */config/*) relative_path="config/$relative_path" ;;
  */install-extensions.sh) relative_path=install-extensions.sh ;;
  *) exit 22 ;;
esac
cp "$CURL_FIXTURE_ROOT/$relative_path" "$destination"
EOF

  cat > "$stub_dir/code" <<'EOF'
#!/usr/bin/env sh
set -eu
printf '%s\n' "$*" >> "$CODE_CALL_LOG"
if [ "${1:-}" = '--list-extensions' ]; then
  printf '%s\n' 'stub.extension'
fi
EOF
  chmod +x "$stub_dir/curl" "$stub_dir/code"
}

test_json_files() {
  python3 - "$repo_root/config/settings.json" "$repo_root/config/keybindings.json" <<'PY'
import json
import sys

def reject_duplicates(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"duplicate JSON key: {key}")
        result[key] = value
    return result

for path in sys.argv[1:]:
    with open(path, encoding="utf-8") as source:
        json.load(source, object_pairs_hook=reject_duplicates)
PY

  python3 - "$repo_root/config/settings.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as source:
    settings = json.load(source)

assert settings["vim.leader"] == "<space>"
assert settings["whichkey.delay"] == 0
assert any(binding.get("commands") == ["whichkey.show"] for binding in settings["vim.normalModeKeyBindingsNonRecursive"])
assert any(binding.get("commands") == ["whichkey.show"] for binding in settings["vim.visualModeKeyBindingsNonRecursive"])
bindings = {binding["key"]: binding for binding in settings["whichkey.bindings"]}
assert bindings.keys() >= {" ", "?", "a", "h", "n", "o", "r"}
assert bindings["n"]["bindings"] == [
    {
        "key": "p",
        "name": "New project window",
        "type": "command",
        "command": "workbench.action.newWindow",
    }
]
open_bindings = {binding["key"]: binding for binding in bindings["o"]["bindings"]}
assert {key: binding["command"] for key, binding in open_bindings.items() if key != "p"} == {
    "e": "workbench.files.action.showActiveFileInExplorer",
    "f": "workbench.action.quickOpen",
    "i": "editor.action.organizeImports",
    "P": "workbench.action.files.openFolder",
    "r": "workbench.action.openRecent",
    "t": "workbench.action.terminal.new",
}
assert open_bindings["p"]["commands"] == [
    "workbench.view.explorer",
    "workbench.files.action.focusFilesExplorer",
]
PY
}

test_install_and_restore() {
  case_root="$test_root/install"
  user_dir="$case_root/User Settings"
  backup_dir="$case_root/backups"
  stub_dir="$case_root/bin"
  mkdir -p "$user_dir"
  printf '{"old":true}\n' > "$user_dir/settings.json"
  printf '[{"key":"old"}]\n' > "$user_dir/keybindings.json"
  cp "$user_dir/settings.json" "$case_root/old-settings.json"
  cp "$user_dir/keybindings.json" "$case_root/old-keybindings.json"
  make_stubs "$stub_dir"

  PATH="$stub_dir:$PATH" \
    CURL_FIXTURE_ROOT="$repo_root" \
    HOME="$case_root/home" \
    VSCODE_USER_DIR="$user_dir" \
    VSCODE_SETTINGS_BACKUP_DIR="$backup_dir" \
    VSCODE_SKIP_EXTENSIONS=1 \
    RAW_VSCODE_SETTINGS_URL=https://fixtures.invalid \
    sh "$repo_root/install.sh" >/dev/null

  assert_same "$repo_root/config/settings.json" "$user_dir/settings.json"
  assert_same "$repo_root/config/keybindings.json" "$user_dir/keybindings.json"

  printf '{"changed":true}\n' > "$user_dir/settings.json"
  HOME="$case_root/home" VSCODE_SETTINGS_BACKUP_DIR="$backup_dir" \
    sh "$repo_root/restore.sh" >/dev/null

  assert_same "$case_root/old-settings.json" "$user_dir/settings.json"
  assert_same "$case_root/old-keybindings.json" "$user_dir/keybindings.json"
}

test_invalid_download_is_safe() {
  case_root="$test_root/invalid"
  user_dir="$case_root/user"
  fixture_dir="$case_root/fixtures"
  stub_dir="$case_root/bin"
  mkdir -p "$user_dir" "$fixture_dir/config"
  printf '{"original":true}\n' > "$user_dir/settings.json"
  cp "$user_dir/settings.json" "$case_root/original.json"
  printf '{ invalid json\n' > "$fixture_dir/config/settings.json"
  cp "$repo_root/config/keybindings.json" "$fixture_dir/config/keybindings.json"
  cp "$repo_root/install-extensions.sh" "$fixture_dir/install-extensions.sh"
  make_stubs "$stub_dir"

  if PATH="$stub_dir:$PATH" \
    CURL_FIXTURE_ROOT="$fixture_dir" \
    HOME="$case_root/home" \
    VSCODE_USER_DIR="$user_dir" \
    VSCODE_SETTINGS_BACKUP_DIR="$case_root/backups" \
    VSCODE_SKIP_EXTENSIONS=1 \
    RAW_VSCODE_SETTINGS_URL=https://fixtures.invalid \
    sh "$repo_root/install.sh" >/dev/null 2>&1; then
    printf '%s\n' 'Installer unexpectedly accepted invalid JSON' >&2
    return 1
  fi

  assert_same "$case_root/original.json" "$user_dir/settings.json"
  [ ! -e "$case_root/backups" ]
}

test_extension_installers() {
  case_root="$test_root/extensions"
  stub_dir="$case_root/bin"
  call_log="$case_root/code.log"
  make_stubs "$stub_dir"
  : > "$call_log"

  for installer in \
    "$repo_root/install-extensions.sh" \
    "$repo_root/extensions/java/install-extension-java.sh" \
    "$repo_root/extensions/javascript/install-extension-javascript.sh"; do
    PATH="$stub_dir:$PATH" CODE_CALL_LOG="$call_log" sh "$installer" >/dev/null
  done

  [ "$(grep -c '^--force --install-extension ' "$call_log")" -eq 20 ]
  [ "$(grep -c 'bradlc.vscode-tailwindcss' "$call_log")" -eq 1 ]
  [ "$(grep -c 'vscodevim.vim' "$call_log")" -eq 1 ]
  [ "$(grep -c 'ms-azuretools.vscode-containers' "$call_log")" -eq 1 ]
  [ "$(grep -c 'MarcoGoedert.JavaScriptSnippetsUpdated' "$call_log")" -eq 1 ]
  [ "$(grep -c 'dsznajder.es7-react-js-snippets' "$call_log")" -eq 1 ]
  [ "$(grep -c 'VSpaceCode.whichkey' "$call_log")" -eq 1 ]
  ! grep -q 'ms-azuretools.vscode-docker' "$call_log"
  ! grep -q 'xabikos.javascriptsnip' "$call_log"
  ! grep -q -- '--intsall-extension' "$call_log"
}

test_save() {
  case_root="$test_root/save"
  repo_copy="$case_root/repo"
  user_dir="$case_root/user"
  mkdir -p "$case_root" "$user_dir"
  cp -R "$repo_root" "$repo_copy"
  printf '{"saved":true}\n' > "$user_dir/settings.json"
  printf '[{"key":"saved"}]\n' > "$user_dir/keybindings.json"

  VSCODE_USER_DIR="$user_dir" sh "$repo_copy/save.sh" >/dev/null
  assert_same "$user_dir/settings.json" "$repo_copy/config/settings.json"
  assert_same "$user_dir/keybindings.json" "$repo_copy/config/keybindings.json"
}

test_restore_removes_files_that_did_not_exist() {
  case_root="$test_root/restore-absent"
  user_dir="$case_root/user"
  backup_dir="$case_root/backups"
  stub_dir="$case_root/bin"
  make_stubs "$stub_dir"

  PATH="$stub_dir:$PATH" \
    CURL_FIXTURE_ROOT="$repo_root" \
    HOME="$case_root/home" \
    VSCODE_USER_DIR="$user_dir" \
    VSCODE_SETTINGS_BACKUP_DIR="$backup_dir" \
    VSCODE_SKIP_EXTENSIONS=1 \
    RAW_VSCODE_SETTINGS_URL=https://fixtures.invalid \
    sh "$repo_root/install.sh" >/dev/null

  [ -f "$user_dir/settings.json" ]
  [ -f "$user_dir/keybindings.json" ]
  HOME="$case_root/home" VSCODE_SETTINGS_BACKUP_DIR="$backup_dir" \
    sh "$repo_root/restore.sh" >/dev/null
  [ ! -e "$user_dir/settings.json" ]
  [ ! -e "$user_dir/keybindings.json" ]
}

test_invalid_save_is_safe() {
  case_root="$test_root/invalid-save"
  repo_copy="$case_root/repo"
  user_dir="$case_root/user"
  mkdir -p "$case_root" "$user_dir"
  cp -R "$repo_root" "$repo_copy"
  cp "$repo_copy/config/settings.json" "$case_root/original-settings.json"
  printf '{ invalid json\n' > "$user_dir/settings.json"
  printf '[]\n' > "$user_dir/keybindings.json"

  if VSCODE_USER_DIR="$user_dir" sh "$repo_copy/save.sh" >/dev/null 2>&1; then
    printf '%s\n' 'Save unexpectedly accepted invalid JSON' >&2
    return 1
  fi
  assert_same "$case_root/original-settings.json" "$repo_copy/config/settings.json"
}

printf '1..7\n'
run_test 'configuration files are strict JSON without duplicate keys' test_json_files
run_test 'installer backs up and restore recovers files with space-safe paths' test_install_and_restore
run_test 'invalid downloads never overwrite current settings' test_invalid_download_is_safe
run_test 'extension installers issue the expected CLI commands' test_extension_installers
run_test 'save copies both user configuration files into the repository' test_save
run_test 'restore removes files that were absent before installation' test_restore_removes_files_that_did_not_exist
run_test 'invalid saved JSON never overwrites repository configuration' test_invalid_save_is_safe

if [ "$failed" -ne 0 ]; then
  exit 1
fi
