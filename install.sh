#!/usr/bin/env sh
config_path_last_version=$(ls -d $HOME/AppData/Roaming/Code* | sort -V | tail -n 1)
echo "Latest version: $config_path_last_version"