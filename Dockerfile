# ARG BASE_IMAGE_PREFIX
# FROM ${BASE_IMAGE_PREFIX}debian:stable-slim AS dev

# [Choice] Python version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.10, 3.9, 3.8, 3.7, 3.6, 3-bullseye, 3.10-bullseye, 3.9-bullseye, 3.8-bullseye, 3.7-bullseye, 3.6-bullseye, 3-buster, 3.10-buster, 3.9-buster, 3.8-buster, 3.7-buster, 3.6-buster
ARG VARIANT="3.10-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT} as build
# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi


# see hooks/post_checkout
#ARG ARCH
#COPY qemu-${ARCH}-static /usr/bin

# configurations for this container
#ENV PREFER_RESOLVER=IPv4

# set ENV for excellent ludeeus's scripts
ENV CONTAINER_TYPE=integration
ENV DEVCONTAINER=True

# open ports
EXPOSE 8123

# prefer IPv4 over IPv6 name resolution
# works after restart only, doesn't allow cloning from github :/
#RUN if [ "$PREFER_IPv6_RESOLVER"=="IPv4" ] ; then sed -e 's/\#\(precedence ::ffff:0:0\/96  100\)/\1/g' -i /etc/gai.conf ; fi

# install additional OS packages.
RUN \
  apt-get update && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends \
    bash \
    bluetooth \
    bluez \
    bluez-tools \
    build-essential \
    ca-certificates \
    cython3 \
    docker.io \
    gcc \
    git \
    iputils-ping \
    jq \
    libatomic1 \
    libavcodec-dev \
    libc-dev \
    libffi-dev \
    libjpeg-dev \
    libpcap-dev \
    libssl-dev \
    make \
    musl-dev \
    nano \
    openssh-client \
    procps rfkill \
    python3-dev \
    python3-pip \
    python3-venv \
    python3-wheel \
    unzip \
    vim \
    wget \
    zlib1g-dev \ 
  && rm -fr /var/lib/apt/lists/* \ 
  && find /usr/local \( -type d -a -name test -o -name tests -o -name '__pycache__' \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \; \ 
  && rm -fr /tmp/* /var/{cache,log}/*


# pip requirements
COPY requirements.txt /tmp/pip-tmp/
RUN pip install --upgrade pip \
  && pip --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
  && rm -rf /tmp/pip-tmp

# # Copy files
COPY rootfs/common /
##TODO: add my own scripts!

# # prepare copied files/folders/execute rights
# RUN \
#   chmod +x /usr/bin/container \
#   && mkdir -p /config/custom_components

# install Home Assistant and install requirements
RUN \
  pip3 install homeassistant homeassistant-cli
# create config and install prequisites
RUN \
  hass -c /config --script ensure_config \
  && hass -c /config --script ensure_config

# install hacs
# RUN \
#   mkdir -p /src/hacs \
#   && cd /src/hacs \
#   && mkdir -p /config/custom_components/hacs \
#   && wget https://github.com/hacs/integration/releases/latest/download/hacs.zip \
#   && unzip hacs.zip -d /config/custom_components/hacs \
#   && /bin/rm -rf /src/hacs
RUN cd /config \
  && mkdir -p /config/custom_components \
  && wget -O - https://get.hacs.xyz | bash -
