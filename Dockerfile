ARG BASE_IMAGE_PREFIX
FROM ${BASE_IMAGE_PREFIX}python:3.8-slim-buster

# see hooks/post_checkout
ARG ARCH
COPY qemu-${ARCH}-static /usr/bin

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
    docker.io \
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
RUN pip3 install --upgrade pip \
  && pip3 --no-cache-dir install -r /tmp/pip-tmp/requirements.txt \
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

# install hacs
RUN \
  mkdir -p /src/hacs \
  && cd /src/hacs \
  && mkdir -p /config/custom_components/hacs \
  && wget https://github.com/hacs/integration/releases/latest/download/hacs.zip \
  && unzip hacs.zip -d /config/custom_components/hacs \
  && /bin/rm -rf /src/hacs
