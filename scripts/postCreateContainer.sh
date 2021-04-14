#!/bin/bash

# install docker
apt-get update
apt-get install -y docker.io
# apt-get install -y curl qemu-user-static binfmt-support jq moreutils

# build anything
source ./hooks/.config
source ./hooks/post_checkout
source ./hooks/pre_build
source ./hooks/build

# shell
bash