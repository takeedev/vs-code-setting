#!/usr/bin/env sh

#echo 
echo "start install extention"

#gitlens
code --force --install-extension eamodio.gitlens

#vscode-eslint
code --force --install-extension dbaeumer.vscode-eslint

#check extension
code --list-extensions

#echo 
echo "install extention complese"