# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.163.1/containers/python-3/.devcontainer/base.Dockerfile

# [Choice] Python version: 3, 3.9, 3.8, 3.7, 3.6
# ARG VARIANT="3"
# FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT}
ARG ARCH=
FROM ${ARCH}python:3.9-slim-buster


# set ENV for excellent ludeeus's scripts
ENV CONTAINER_TYPE=integration
ENV DEVCONTAINER=True

# open ports
EXPOSE 8123

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
    cython \
    gcc \
    git \
    iputils-ping \
    libatomic1 \
    libavcodec-dev \
    libc-dev \
    libffi-dev \
    libjpeg-dev \
    libpcap-dev \
    libssl-dev \
    make \
    multiarch-support \
    musl-dev \
    nano \
    openssh-client \
    procps rfkill \
    unzip \
    vim \
    wget \
    zlib1g-dev \ 
  && rm -fr /var/lib/apt/lists/* \ 
  && find /usr/local \( -type d -a -name test -o -name tests -o -name '__pycache__' \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \; \ 
  && rm -fr /tmp/* /var/{cache,log}/*

# pip requirements
COPY requirements.txt /tmp/pip-tmp/
RUN pip3 --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
  && rm -rf /tmp/pip-tmp

# Copy files
COPY rootfs/common /

# prepare copied files/folders/execute rights
RUN \
  chmod +x /usr/bin/container \
  && mkdir -p /config/custom_components

# install Home Assistant DEV
RUN \
  /usr/bin/container install

