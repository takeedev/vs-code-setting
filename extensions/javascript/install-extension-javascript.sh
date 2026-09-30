#!/usr/bin/env sh

set -eu

command -v code >/dev/null 2>&1 || {
  printf '%s\n' 'Error: VS Code CLI (code) was not found in PATH.' >&2
  exit 1
}

printf '%s\n' 'Installing JavaScript and TypeScript extensions'

for extension in \
  Angular.ng-template \
  vitest.explorer \
  ms-vscode.vscode-typescript-next \
  MarcoGoedert.JavaScriptSnippetsUpdated \
  bradlc.vscode-tailwindcss \
  ecmel.vscode-html-css; do
  code --force --install-extension "$extension"
done
