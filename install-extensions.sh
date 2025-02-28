#!/usr/bin/env sh

#echo 
echo "start install extention"

#gitlens
#code --force --install-extension eamodio.gitlens

#vscode-eslint
code --force --install-extension dbaeumer.vscode-eslint

#icon-theme
code --force --install-extension PKief.material-icon-theme

#remote explorer
code --force --install-extension ms-vscode.remote-explorer

#remote ssh
code --force --install-extension ms-vscode-remote.remote-ssh

#yaml
code --force --install-extension redhat.vscode-yaml

#create doc
code --force --install-extension mintlify.document

#scansonar
code --force --install-extension sonarsource.sonarlint-vscode

#format xml
code --force --install-extension redhat.vscode-xml

#format yaml
code --force --install-extension redhat.vscode-yaml

#Docker
code --force --install-extension ms-azuretools.vscode-docker

#vim
#code --force --install-extension vscodevim.vim

#mermadAid
#code --force --install-extension ms-vscode.copilot-mermaid-diagram

#echo 
echo "++++++++++++++++++++++++++++++++++++++++"

#check extension
code --list-extensions