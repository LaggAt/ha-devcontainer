#!/bin/bash
source /etc/bash_completion.d/container_completion
source /usr/share/container/tools
git config --global core.autocrlf input > /dev/null 2>&1

#export PS1="container# "
export DEVCONTAINER="True"
export CONTAINER="True"

# Copy SSH keys if they exsist
if test -d "/tmp/.ssh"; then
    cp -R /tmp/.ssh /root/.ssh > /dev/null 2>&1
    chmod 700 /root/.ssh > /dev/null 2>&1
    chmod 644 /root/.ssh/id_rsa.pub > /dev/null 2>&1
    chmod 600 /root/.ssh/id_rsa > /dev/null 2>&1
fi

complete -W "\`grep -oE '^[a-zA-Z0-9_.-]+:([^=]|$)' ?akefile | sed 's/[^a-zA-Z0-9_.-]*$//'\`" make

echo hacs-base-container <https://github.com/LaggAt/hacs-base-container>
echo This is far from finished! Read the README.md for development state.
echo
echo TODO: show usage in a simple example integration, provide launch.json for vscode. 
echo
