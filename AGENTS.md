# Repository guidance

## Purpose and layout

This repository distributes personal VS Code settings, keybindings, and shell
scripts for installing extensions. It has no application build or package manager;
tests run directly with POSIX shell and Python 3.

- `config/settings.json`: editor preferences, Vim mappings, language settings,
  and local database connection configuration.
- `config/keybindings.json`: keyboard shortcuts and removals of default bindings.
- `install.sh`: validates and installs configuration after creating a backup.
- `save.sh` and `restore.sh`: capture the current configuration and restore an
  installer backup.
- `install-extensions.sh`: shared extensions installed through the `code` CLI.
- `extensions/java/install-extension-java.sh`: Java and Spring extensions.
- `extensions/javascript/install-extension-javascript.sh`: JavaScript,
  TypeScript, Angular, and CSS extensions.
- `tests/run.sh`: isolated shell integration tests with stubbed external commands.
- `README.md`: setup, rollback, save, and extension installation commands.

## Editing conventions

- Keep changes focused on the requested configuration or installation behavior.
- Preserve the JSON files' two-space indentation and strict JSON syntax.
- Preserve keybinding order and `when` conditions. Commands beginning with `-`
  remove default bindings; repeated keys may serve different contexts.
- Check Vim mappings in settings when changing related keyboard shortcuts.
- Follow the existing extension scripts' `code --force --install-extension
  publisher.extension` pattern and short grouping comments. Keep language-specific
  additions in the corresponding language installer.
- Do not enable commented-out extensions merely because settings reference them.
- Keep README installation commands and download URLs aligned with script changes.
- Never add credentials or populated database passwords to tracked settings.

## Validation

Run these non-mutating checks from the repository root as relevant to a change:

```sh
python3 -m json.tool config/settings.json > /dev/null
python3 -m json.tool config/keybindings.json > /dev/null
sh -n install.sh
sh -n install-extensions.sh
sh -n extensions/java/install-extension-java.sh
sh -n extensions/javascript/install-extension-javascript.sh
sh -n save.sh
sh -n restore.sh
sh -n tests/run.sh
./tests/run.sh
git diff --check
```

Syntax checks do not verify extension IDs, CLI flags, or shortcut behavior. Review
those explicitly, and report any manual checks that were not performed.

Do not run installers directly as routine validation: they overwrite user
configuration or install extensions. The integration tests exercise installers
with isolated destinations and stubbed external commands.

The shell scripts target POSIX `sh`. Preserve support for paths containing spaces
and use the documented environment overrides in tests instead of real editor paths.
