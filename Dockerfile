# [Choice] Python version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.10, 3.9, 3.8, 3.7, 3.6, 3-bullseye, 3.10-bullseye, 3.9-bullseye, 3.8-bullseye, 3.7-bullseye, 3.6-bullseye, 3-buster, 3.10-buster, 3.9-buster, 3.8-buster, 3.7-buster, 3.6-buster
ARG VARIANT="3.9-bullseye"
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
EXPOSE 8123

# ################## homeassistant core https://github.com/home-assistant/core/blob/dev/Dockerfile.dev
# - extended by useful packages and tools

# install packages (many more as in default home assistant, to save time later)
RUN \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && apt-get update \
  && apt-get -y install --no-install-recommends \
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

# get and install hass-release
RUN \
  cd /usr/src \
  && git clone --depth 1 https://github.com/home-assistant/hass-release \
  && pip3 install -e hass-release/

# Install Python dependencies from requirements
#COPY requirements.txt ./
#COPY homeassistant/package_constraints.txt homeassistant/package_constraints.txt
#COPY requirements_test.txt requirements_test_pre_commit.txt ./
RUN \
  mkdir -p /tmp/requirements/homeassistant \
  && cd /tmp/requirements/homeassistant \
  && /usr/bin/wget \
    https://raw.githubusercontent.com/home-assistant/core/dev/homeassistant/package_constraints.txt \
  && cd /tmp/requirements \
  && /usr/bin/wget \
    https://raw.githubusercontent.com/home-assistant/core/dev/requirements.txt \
    https://raw.githubusercontent.com/home-assistant/core/dev/requirements_test.txt \
    https://raw.githubusercontent.com/home-assistant/core/dev/requirements_test_pre_commit.txt \
  && pip3 install -r requirements.txt --use-deprecated=legacy-resolver \
  && pip3 install -r requirements_test.txt --use-deprecated=legacy-resolver \
  && rm -rf /tmp/requirements

# ################## END homeassistant core https://github.com/home-assistant/core/blob/dev/Dockerfile.dev




# # taken from devcontainer image: https://github.com/home-assistant/devcontainer/blob/main/addons/Dockerfile
# RUN git clone https://github.com/home-assistant/devcontainer.git /tmp/devcontainer
# # set execute right on executables (files in bin folders)
# RUN find /tmp/devcontainer/ -type d -iname bin | xargs chmod -R +x
# # use SUPERVISOR_NAME env variable:
# RUN find /tmp/devcontainer/ -type f -print0 | xargs -0 sed -i 's/hassio_supervisor/$SUPERVISOR_NAME/g'

# # COPY ./common/rootfs /
# # COPY ./common/rootfs_supervisor /
# # COPY ./common/install /tmp/common/install
# RUN cp -R /tmp/devcontainer/common/rootfs/* / \
#   && cp -R /tmp/devcontainer/common/rootfs_supervisor/* / \
#   && mkdir -p /tmp/common/install \
#   && cp -R /tmp/devcontainer/common/install/* /tmp/common/install

# # Install common
# RUN \
#     bash devcontainer_init \
#     && common_install_packages \
#         docker \
#         shellcheck \
#         cas \
#         os-agent

# # COPY ./addons/rootfs /
# RUN cp -R /tmp/devcontainer/addons/rootfs/* /


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
