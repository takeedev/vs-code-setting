#!/usr/bin/env sh

#echo 
echo "start install extention"

#gitlens
code --force --install-extension eamodio.gitlens

#vscode-eslint
code --force --install-extension dbaeumer.vscode-eslint

#icon-theme
code --force --install-extension PKief.material-icon-theme

#vim
#code --force --install-extension vscodevim.vim

#mermadAid
#code --force --install-extension ms-vscode.copilot-mermaid-diagram

#echo 
echo "++++++++++++++++++++++++++++++++++++++++"

#check extension
code --list-extensions