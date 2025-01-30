#!/usr/bin/env sh
config_path_last_version=$(ls -d $HOME/AppData/Roaming/Code* | sort -V | tail -n 1)
echo "Latest version: $config_path_last_version"

# config
curl -k https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/config/settings.json -o "$config_path_last_version/User/settings.json"
curl -k https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/config/keybindings.json -o "$config_path_last_version/User/keybindings.json"

# execute install extendtion
bash <(curl -sL https://raw.githubusercontent.com/takeedev/vs-code-setting/refs/heads/main/install-extensions.sh)