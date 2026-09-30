# VS Code settings

## Setup

The installer validates both JSON files, backs up the current configuration, then
installs settings, keybindings, shared extensions, and the bundled Explorer Vim
Menu extension.

```sh
curl -fsSL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/install.sh | /usr/bin/env sh
```

## Restore

```sh
curl -fsSL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/restore.sh | /usr/bin/env sh
```

From a cloned repository, a specific backup can also be selected:

```sh
./restore.sh "$HOME/.vscode-settings-backups/20260929-120000"
```

## Language extensions

```sh
curl -fsSL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/extensions/java/install-extension-java.sh | /usr/bin/env sh
curl -fsSL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/extensions/javascript/install-extension-javascript.sh | /usr/bin/env sh
```
