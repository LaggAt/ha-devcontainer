#!/bin/bash

git config --global core.autocrlf input > /dev/null 2>&1

export DEVCONTAINER="True"
export CONTAINER="True"

# Copy SSH keys if they exsist
if test -d "/tmp/.ssh"; then
    cp -R /tmp/.ssh /root/.ssh > /dev/null 2>&1
    chmod 700 /root/.ssh > /dev/null 2>&1
    chmod 644 /root/.ssh/id_rsa.pub > /dev/null 2>&1
    chmod 600 /root/.ssh/id_rsa > /dev/null 2>&1
fi

#'dev' cli autocompletion for bash
eval "$(_FOO_BAR_COMPLETE=source_bash dev)"

complete -W "\`grep -oE '^[a-zA-Z0-9_.-]+:([^=]|$)' ?akefile | sed 's/[^a-zA-Z0-9_.-]*$//'\`" make

echo ha-devcontainer <https://github.com/LaggAt/ha-devcontainer>
echo This is far from finished! Read the README.md for development state.
echo
echo TODO: show usage in a simple example integration, provide launch.json for vscode.
echo
