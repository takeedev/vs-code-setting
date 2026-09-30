#!/usr/bin/env sh

set -eu

command -v code >/dev/null 2>&1 || {
  printf '%s\n' 'Error: VS Code CLI (code) was not found in PATH.' >&2
  exit 1
}

printf '%s\n' 'Installing Java extensions'

for extension in \
  vscjava.vscode-java-pack \
  vmware.vscode-spring-boot; do
  code --force --install-extension "$extension"
done
