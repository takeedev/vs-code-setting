# VS Code settings

Personal VS Code settings, IntelliJ-style keybindings, Vim mappings, and extension
installers. Setup supports macOS, Linux, and Windows environments such as Git Bash.
In VSCodeVim Normal or Visual mode, press `Space` to open a Which Key menu showing
the available leader-key commands and their descriptions.

Useful leader groups include `Space a` for tool views, `Space o` for opening files,
Explorer, recent workspaces, imports, and terminals, and `Space r` for run/refactor.
Use `Space o P` to open a project/folder and `Space n p` to start a new project
window.

## Setup

The installer validates both JSON files, backs up the current configuration, then
installs settings, keybindings, and shared extensions.

```sh
curl -fsSL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/install.sh | /usr/bin/env sh
```

Set `VSCODE_USER_DIR` to install into a nonstandard VS Code profile directory. Set
`VSCODE_SKIP_EXTENSIONS=1` when only the configuration files should be installed.

## Restore

Restore the most recent automatic backup:

```sh
curl -fsSL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/restore.sh | /usr/bin/env sh
```

From a cloned repository, a specific backup can also be selected:

```sh
./restore.sh "$HOME/.vscode-settings-backups/20260929-120000"
```

## Save current settings

From a cloned repository:

```sh
./save.sh
```

This copies the active `settings.json` and `keybindings.json` into `config/`.

## Language extensions

```sh
curl -fsSL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/extensions/java/install-extension-java.sh | /usr/bin/env sh
curl -fsSL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/extensions/javascript/install-extension-javascript.sh | /usr/bin/env sh
```

## Tests

Tests use temporary HOME and VS Code directories plus stubbed `curl` and `code`
commands, so they do not change the machine's real editor configuration.

```sh
./tests/run.sh
```
