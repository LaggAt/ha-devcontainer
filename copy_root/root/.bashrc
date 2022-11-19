#!/bin/bash

git config --global core.autocrlf input > /dev/null 2>&1

export DEVCONTAINER="True"
export CONTAINER="True"

#'dev' cli autocompletion for bash
eval "$(_DEV_COMPLETE=bash_source dev)"

echo https://github.com/LaggAt/ha-devcontainer
echo This is far from finished! Read the README.md for development state.
echo
echo Start by typing: dev --help
echo
