#!/usr/bin/env sh

#echo 
echo "start install extention"

#gitlens
code --force --install-extension eamodio.gitlens

#vscode-eslint
code --force --install-extension dbaeumer.vscode-eslint

#echo 
echo "++++++++++++++++++++++++++++++++++++++++"

#check extension
code --list-extensions