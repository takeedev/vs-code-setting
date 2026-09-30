#!/usr/bin/env sh

set -eu

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

find_latest_backup() {
  latest=
  for candidate in "$backup_base"/*; do
    [ -f "$candidate/user-dir" ] || continue
    [ -d "$candidate/files" ] || continue
    latest=$candidate
  done
  printf '%s\n' "$latest"
}

[ "$#" -le 1 ] || fail "usage: $0 [backup-directory]"
backup_base=${VSCODE_SETTINGS_BACKUP_DIR:-"$HOME/.vscode-settings-backups"}

if [ "$#" -eq 1 ]; then
  backup_root=$1
else
  backup_root=$(find_latest_backup)
  [ -n "$backup_root" ] || fail "no valid backups found under: $backup_base"
fi

[ -f "$backup_root/user-dir" ] || fail "invalid backup directory: $backup_root"
[ -d "$backup_root/files" ] || fail "invalid backup directory: $backup_root"
IFS= read -r user_dir < "$backup_root/user-dir"
[ -n "$user_dir" ] || fail 'backup contains an empty VS Code user directory'
mkdir -p "$user_dir"

for config_file in settings.json keybindings.json; do
  if [ -f "$backup_root/files/$config_file.present" ]; then
    [ -f "$backup_root/files/$config_file" ] || fail "backup is missing $config_file"
    cp -p "$backup_root/files/$config_file" "$user_dir/$config_file.new"
    mv "$user_dir/$config_file.new" "$user_dir/$config_file"
  else
    rm -f "$user_dir/$config_file"
  fi
done

printf 'Restored VS Code settings in: %s\n' "$user_dir"
printf 'Restore completed from: %s\n' "$backup_root"
