#!/bin/bash

# install docker
#apt-get update
#apt-get install -y docker.io
# apt-get install -y curl qemu-user-static binfmt-support jq moreutils

# build anything
chmod +x ./hooks/.config
chmod +x ./hooks/post_checkout
chmod +x ./hooks/pre_build
chmod +x ./hooks/build
./hooks/.config
./hooks/post_checkout
./hooks/pre_build
./hooks/build

# shell
bash