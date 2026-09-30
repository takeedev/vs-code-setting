#!/usr/bin/env sh

set -eu

command -v code >/dev/null 2>&1 || {
  printf '%s\n' 'Error: VS Code CLI (code) was not found in PATH.' >&2
  exit 1
}

RAW_VSCODE_SETTINGS_URL=${RAW_VSCODE_SETTINGS_URL:-https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main}

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
  VSpaceCode.whichkey \
  vscodevim.vim; do
  code --force --install-extension "$extension"
done

temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/vscode-custom-extensions.XXXXXX")
cleanup() {
  rm -rf "$temp_dir"
}
trap cleanup EXIT
trap 'exit 1' HUP INT TERM

custom_installer="$temp_dir/install-explorer-vim-menu.sh"
curl -fsSL "$RAW_VSCODE_SETTINGS_URL/extensions/explorer-vim-menu/install-extension.sh" -o "$custom_installer"
/usr/bin/env sh "$custom_installer"

printf '%s\n' 'Installed extensions:'
code --list-extensions
