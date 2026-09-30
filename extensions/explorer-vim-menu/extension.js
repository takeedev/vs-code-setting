'use strict';

const vscode = require('vscode');

const MENU_VISIBLE_CONTEXT = 'takeedev.explorerVimMenuVisible';
const SHOW_MENU_COMMAND = 'takeedev.explorerVimMenu.show';
const EXPLORER_FOCUS_COMMAND = 'workbench.files.action.focusFilesExplorer';

const actions = [
  { label: '$(go-to-file) Open', command: 'list.select' },
  { label: '$(split-horizontal) Open to the Side', command: 'explorer.openToSide' },
  { label: '$(new-file) New File', command: 'explorer.newFile' },
  { label: '$(new-folder) New Folder', command: 'explorer.newFolder' },
  { label: '$(cut) Cut', command: 'filesExplorer.cut' },
  { label: '$(copy) Copy', command: 'filesExplorer.copy' },
  { label: '$(clippy) Paste', command: 'filesExplorer.paste' },
  { label: '$(edit) Rename', command: 'renameFile' },
  { label: '$(trash) Delete', command: 'deleteFile' },
  { label: '$(files) Copy Path', command: 'copyFilePath' },
  { label: '$(symbol-file) Copy Relative Path', command: 'copyRelativeFilePath' },
  { label: '$(folder-opened) Reveal in Finder / Explorer', command: 'revealFileInOS' },
  { label: '$(terminal) Open in Integrated Terminal', command: 'openInIntegratedTerminal' },
  { label: '$(search) Find in Folder', command: 'filesExplorer.findInFolder' }
];

async function runExplorerAction(command) {
  await vscode.commands.executeCommand(EXPLORER_FOCUS_COMMAND);
  await vscode.commands.executeCommand(command);
}

async function showExplorerVimMenu() {
  const picker = vscode.window.createQuickPick();
  const disposables = [];
  let accepted = false;

  picker.title = 'Explorer Actions';
  picker.placeholder = 'j/k: move  •  Enter: select  •  Esc: close';
  picker.items = actions;
  picker.matchOnDescription = true;
  picker.matchOnDetail = true;

  await vscode.commands.executeCommand('setContext', MENU_VISIBLE_CONTEXT, true);

  disposables.push(
    picker.onDidAccept(() => {
      const selected = picker.selectedItems[0];
      if (!selected || accepted) {
        return;
      }

      accepted = true;
      picker.hide();
      setTimeout(() => {
        runExplorerAction(selected.command).catch((error) => {
          vscode.window.showErrorMessage(`Explorer action failed: ${error.message}`);
        });
      }, 0);
    }),
    picker.onDidHide(() => {
      vscode.commands.executeCommand('setContext', MENU_VISIBLE_CONTEXT, false);
      for (const disposable of disposables) {
        disposable.dispose();
      }
      picker.dispose();
    })
  );

  picker.show();
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand(SHOW_MENU_COMMAND, showExplorerVimMenu)
  );
}

function deactivate() {
  return vscode.commands.executeCommand('setContext', MENU_VISIBLE_CONTEXT, false);
}

module.exports = {
  activate,
  deactivate
};
