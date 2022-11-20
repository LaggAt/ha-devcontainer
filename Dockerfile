# [Choice] Python version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.10, 3.9, 3.8, 3.7, 3.6, 3-bullseye, 3.10-bullseye, 3.9-bullseye, 3.8-bullseye, 3.7-bullseye, 3.6-bullseye, 3-buster, 3.10-buster, 3.9-buster, 3.8-buster, 3.7-buster, 3.6-buster
ARG VARIANT="3.10-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT} as build
# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# run as root from now on
USER root

# Environment Variable defaults
ENV DEVCONTAINER=True
ENV DEBIAN_FRONTEND=noninteractive

# open ports
## hass
EXPOSE 8123
## python remote debugger
EXPOSE 5678

# install packages (many more as in default home assistant, to save time later)
RUN \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && apt-get update \
  && apt-get -y install \
    apparmor \
    bash \
    bluetooth \
    bluez \
    bluez-tools \
    build-essential \
    ca-certificates \
    cargo \
    cmake \
    curl \
    cython3 \
    dbus \
    docker.io \
    gcc \
    git \
    iputils-ping \
    ipython3 \
    jq \
    libatomic1 \
    libavcodec-dev \
    libavfilter-dev \
    libavformat-dev \
    libavdevice-dev \
    libavutil-dev \
    libc6-dev \
    libffi-dev \
    libglib2.0-bin \
    libjpeg-dev \
    libpcap-dev \
    libpulse0 \
    libturbojpeg0 \
    libudev-dev \
    libssl-dev \
    libswscale-dev \
    libswresample-dev \
    libxml2 \
    libyaml-dev \
    make \
    musl-dev \
    nano \
    network-manager \
    openssh-client \
    procps \
    python3 \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-venv \
    python3-wheel \
    rfkill \
    systemd-journal-remote \
    udisks2 \
    unzip \
    vim \
    wget \
    xz-utils \
    zlib1g-dev \ 
  && apt-get clean \
  && rm -fr /var/lib/apt/lists/* \ 
  && find /usr/local \( -type d -a -name test -o -name tests -o -name '__pycache__' \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \; \ 
  && rm -fr /tmp/* /var/{cache,log}/*

# deploy ha-devcontainer commands, scripts, home assistant basic config, ...
COPY copy_root/ /
# 'dev' cli
RUN cd /opt/dev \
  && pip install --editable .




#*1) prepare source to copy from for home-assistant/core
WORKDIR /tmp
RUN git clone https://github.com/home-assistant/core.git
# Add Home Assistant wheels repository
#ENV WHEELS_LINKS=https://wheels.home-assistant.io/musllinux/

#*1 from here on, COPY RELATIVE_PATH should get: RUN cp -rf /tmp/core/RELATIVE_PATH
#   used for https://github.com/home-assistant/core/blob/dev/Dockerfile below
WORKDIR /usr/src
RUN mkdir -p homeassistant/homeassistant
#*2 removed this from all pip install commands (without single quotes):
#   ' --no-cache-dir --no-index --only-binary=:all: --find-links "${WHEELS_LINKS}"''
#*3 removed ' home_assistant_frontend-*' from the COPY, as the folder/file is not existant in core git.

##### START dependencies from https://github.com/home-assistant/core/blob/dev/Dockerfile
# Synchronize with homeassistant/core.py:async_stop
ENV \
    S6_SERVICES_GRACETIME=220000

## Setup Home Assistant Core dependencies
RUN cp -rf /tmp/core/requirements.txt homeassistant/
RUN cp -rf /tmp/core/homeassistant/package_constraints.txt homeassistant/homeassistant/
RUN \
    pip3 install \
    -r homeassistant/requirements.txt --use-deprecated=legacy-resolver
RUN cp -rf /tmp/core/requirements_all.txt homeassistant/
RUN \
    if ls homeassistant/home_assistant_frontend*.whl 1> /dev/null 2>&1; then \
        pip3 install --no-cache-dir --no-index homeassistant/home_assistant_frontend-*.whl; \
    fi \
    && pip3 install \
    -r homeassistant/requirements_all.txt --use-deprecated=legacy-resolver

## Setup Home Assistant Core
RUN cp -rf /tmp/core/. homeassistant/
RUN \
    pip3 install \
    -e ./homeassistant --use-deprecated=legacy-resolver \
    && python3 -m compileall homeassistant/homeassistant

# Home Assistant S6-Overlay
RUN cp -rf /tmp/core/rootfs /

##### END dependencies from https://github.com/home-assistant/core/blob/dev/Dockerfile

# #install home assistant itself
# RUN pip install homeassistant

#prepare hacs
RUN cd /config \
  && mkdir -p /config/custom_components \
  && wget -O - https://get.hacs.xyz | bash -

# #create user admin/admin (does not avoid bootstap dialogs)
# RUN /usr/local/bin/hass --config /config --script auth add admin admin
#check config (and download all further necessary packages)
RUN /usr/local/bin/hass --config /config --script check_config

# Run and Stop home assistant when onboading dialog is shown
RUN /usr/local/bin/dev ha start --install-deps-only

#TODO later: also automate/skip onboarding


# Cleanup
RUN \
  rm -rf /root/.cache/* /tmp/* /usr/src/homeassistant 