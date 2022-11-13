# ARG BASE_IMAGE_PREFIX
# FROM ${BASE_IMAGE_PREFIX}debian:stable-slim AS build

# [Choice] Python version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.10, 3.9, 3.8, 3.7, 3.6, 3-bullseye, 3.10-bullseye, 3.9-bullseye, 3.8-bullseye, 3.7-bullseye, 3.6-bullseye, 3-buster, 3.10-buster, 3.9-buster, 3.8-buster, 3.7-buster, 3.6-buster
ARG VARIANT="3.10-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT} as build
# FROM mcr.microsoft.com/vscode/devcontainers/base:debian as build
# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# see hooks/post_checkout
#ARG ARCH
#COPY qemu-${ARCH}-static /usr/bin

# configurations for this container
#ENV PREFER_RESOLVER=IPv4

# set ENV for excellent ludeeus's scripts
#ENV CONTAINER_TYPE=integration
ENV DEVCONTAINER=True
ENV DEBIAN_FRONTEND=noninteractive

# open ports
EXPOSE 8123

# prefer IPv4 over IPv6 name resolution
# works after restart only, doesn't allow cloning from github :/
#RUN if [ "$PREFER_IPv6_RESOLVER"=="IPv4" ] ; then sed -e 's/\#\(precedence ::ffff:0:0\/96  100\)/\1/g' -i /etc/gai.conf ; fi

# install additional OS packages.
RUN \
  apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends \
    apparmor \
    bash \
    bluetooth \
    bluez \
    bluez-tools \
    build-essential \
    ca-certificates \
    curl \
    cython3 \
    dbus \
    docker.io \
    gcc \
    git \
    iputils-ping \
    jq \
    libatomic1 \
    libavcodec-dev \
    libc-dev \
    libffi-dev \
    libglib2.0-bin \
    libjpeg-dev \
    libpcap-dev \
    libpulse0 \
    libssl-dev \
    make \
    musl-dev \
    nano \
    network-manager \
    openssh-client \
    procps rfkill \
    python3-dev \
    python3-pip \
    python3-venv \
    python3-wheel \
    systemd-journal-remote \
    udisks2 \
    unzip \
    vim \
    wget \
    xz-utils \
    zlib1g-dev \ 
  && rm -fr /var/lib/apt/lists/* \ 
  && find /usr/local \( -type d -a -name test -o -name tests -o -name '__pycache__' \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \; \ 
  && rm -fr /tmp/* /var/{cache,log}/*

# taken from devcontainer image: https://github.com/home-assistant/devcontainer/blob/main/addons/Dockerfile
RUN git clone https://github.com/home-assistant/devcontainer.git /tmp/devcontainer
# set execute right on executables (files in bin folders)
RUN find /tmp/devcontainer/ -iname bin | xargs chmod -R +x

# COPY ./common/rootfs /
# COPY ./common/rootfs_supervisor /
# COPY ./common/install /tmp/common/install
RUN cp -R /tmp/devcontainer/common/rootfs/* / \
  && cp -R /tmp/devcontainer/common/rootfs_supervisor/* / \
  && mkdir -p /tmp/common/install \
  && cp -R /tmp/devcontainer/common/install/* /tmp/common/install

# Install common
RUN \
    bash devcontainer_init \
    && common_install_packages \
        docker \
        shellcheck \
        cas \
        os-agent

# COPY ./addons/rootfs /
RUN cp -R /tmp/devcontainer/addons/rootfs/* /


#### from here on some scripts I have been fiddling with before. Kept until we have something working.

### Superviced installer (Add-On Menu)
# # install docker-ce
# RUN curl -fsSL get.docker.com | sh
# # # install OS agent
# RUN service dbus start \
#   && export ARCH=$(dpkg --print-architecture | sed 's/^amd64$/x86_64/g') \
#   && wget https://github.com/home-assistant/os-agent/releases/download/1.4.1/os-agent_1.4.1_linux_$ARCH.deb \
#   && sudo dpkg -i os-agent_1.4.1_linux_$ARCH.deb
# # install home assistant supervised package 
# RUN wget https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb \
#   && dpkg -i homeassistant-supervised.deb

# # pip requirements
# COPY requirements.txt /tmp/pip-tmp/
# RUN pip install --upgrade pip \
#   && pip --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
#   && rm -rf /tmp/pip-tmp
# # # Copy files
# COPY rootfs/common /
# ##TODO: add my own scripts!

# # # prepare copied files/folders/execute rights
# # RUN \
# #   chmod +x /usr/bin/container \
# #   && mkdir -p /config/custom_components
# # install Home Assistant and install requirements
# RUN \
#   pip3 install homeassistant homeassistant-cli
# # create config and install prequisites
# RUN \
#   hass -c /config --script ensure_config \
#   && hass -c /config --script ensure_config

# # install hacs
# # RUN \
# #   mkdir -p /src/hacs \
# #   && cd /src/hacs \
# #   && mkdir -p /config/custom_components/hacs \
# #   && wget https://github.com/hacs/integration/releases/latest/download/hacs.zip \
# #   && unzip hacs.zip -d /config/custom_components/hacs \
# #   && /bin/rm -rf /src/hacs
# RUN cd /config \
#   && mkdir -p /config/custom_components \
#   && wget -O - https://get.hacs.xyz | bash -
