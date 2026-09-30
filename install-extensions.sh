#!/usr/bin/env sh

set -eu

command -v code >/dev/null 2>&1 || {
  printf '%s\n' 'Error: VS Code CLI (code) was not found in PATH.' >&2
  exit 1
}

printf '%s\n' 'Installing shared VS Code extensions'

for extension in \
  dbaeumer.vscode-eslint \
  PKief.material-icon-theme \
  ms-vscode.remote-explorer \
  ms-vscode-remote.remote-ssh \
  redhat.vscode-yaml \
  mintlify.document \
  sonarsource.sonarlint-vscode \
  redhat.vscode-xml \
  ms-azuretools.vscode-containers \
  vscodevim.vim; do
  code --force --install-extension "$extension"
done

printf '%s\n' 'Installed extensions:'
code --list-extensions
