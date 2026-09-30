'use strict';

const assert = require('assert');
const Module = require('module');

const executed = [];
let registeredCommand;
let picker;

function disposable() {
  return { dispose() {} };
}

const vscode = {
  commands: {
    registerCommand(command, callback) {
      assert.strictEqual(command, 'takeedev.explorerVimMenu.show');
      registeredCommand = callback;
      return disposable();
    },
    async executeCommand(...args) {
      executed.push(args);
    }
  },
  window: {
    createQuickPick() {
      const listeners = {};
      picker = {
        items: [],
        selectedItems: [],
        shown: false,
        onDidAccept(callback) {
          listeners.accept = callback;
          return disposable();
        },
        onDidHide(callback) {
          listeners.hide = callback;
          return disposable();
        },
        show() {
          this.shown = true;
        },
        hide() {
          listeners.hide();
        },
        dispose() {},
        accept() {
          listeners.accept();
        }
      };
      return picker;
    },
    showErrorMessage(message) {
      throw new Error(message);
    }
  }
};

const originalLoad = Module._load;
Module._load = function load(request, parent, isMain) {
  if (request === 'vscode') {
    return vscode;
  }
  return originalLoad(request, parent, isMain);
};

const extension = require('./extension');
Module._load = originalLoad;

async function main() {
  const subscriptions = [];
  extension.activate({ subscriptions });
  assert.strictEqual(subscriptions.length, 1);
  assert.strictEqual(typeof registeredCommand, 'function');

  await registeredCommand();
  assert.strictEqual(picker.shown, true);
  assert.strictEqual(picker.title, 'Explorer Actions');
  assert.ok(picker.items.length >= 10);
  assert.deepStrictEqual(executed[0], ['setContext', 'takeedev.explorerVimMenuVisible', true]);

  picker.selectedItems = [picker.items.find((item) => item.command === 'renameFile')];
  picker.accept();
  await new Promise((resolve) => setTimeout(resolve, 10));

  assert.ok(executed.some((call) => call[0] === 'setContext' && call[2] === false));
  const focusIndex = executed.findIndex((call) => call[0] === 'workbench.files.action.focusFilesExplorer');
  const renameIndex = executed.findIndex((call) => call[0] === 'renameFile');
  assert.ok(focusIndex > 0);
  assert.ok(renameIndex > focusIndex);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
