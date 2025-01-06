# [Choice] https://hub.docker.com/r/microsoft/devcontainers-python
FROM mcr.microsoft.com/devcontainers/python:1-3.13 AS build
# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "BUILDPLATFORM: $BUILDPLATFORM, TARGETPLATFORM: $TARGETPLATFORM" > /log

# run as root from now on
USER root

# Environment Variable defaults
ENV DEVCONTAINER=True
ENV DEBIAN_FRONTEND=noninteractive
ENV ZSH=~/.oh-my-zsh

# open ports
## hass
EXPOSE 8123
## python remote debugger
EXPOSE 5678

WORKDIR /tmp

# deploy ha-devcontainer commands, scripts, home assistant basic config, default shell, ...
COPY copy_root/ /

# install ZSH Shell
RUN \
	wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O oh-my-zsh-install.sh \
	&& rm -rf /root/.oh-my-zsh \
	&& chmod +x ./oh-my-zsh-install.sh \
	&& sudo ./oh-my-zsh-install.sh --unattended \
	&& rm -f ./oh-my-zsh-install.sh

#*1) prepare source to copy from for home-assistant/core
RUN git clone https://github.com/home-assistant/core.git
# Add Home Assistant wheels repository
#ENV WHEELS_LINKS=https://wheels.home-assistant.io/musllinux/

#*1 from here on, COPY RELATIVE_PATH should get: RUN cp -rf /tmp/core/RELATIVE_PATH
#   used for https://github.com/home-assistant/core/blob/dev/Dockerfile below
WORKDIR /usr/src
#*2 removed this from all pip install commands (without single quotes):
#   ' --no-cache-dir --no-index --only-binary=:all: --find-links "${WHEELS_LINKS}"''
#*3 removed ' home_assistant_frontend-*' from the COPY, as the folder/file is not existant in core git.

##### START dependencies from https://github.com/home-assistant/core/blob/dev/Dockerfile
# Synchronize with homeassistant/core.py:async_stop
ENV \
    S6_SERVICES_GRACETIME=220000

# Get go2rtc binary
COPY --from=ghcr.io/alexxit/go2rtc:latest /usr/local/bin/go2rtc /bin/go2rtc
    
RUN \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
	&& apt-get update \
    && apt-get -y install --no-install-recommends build-essential cmake libturbojpeg0 libpcap-dev \
    # Setup Home Assistant Core and dependencies \
	&& mkdir -p homeassistant/homeassistant \
    && cp -rf /tmp/core/requirements.txt homeassistant/ \
    && cp -rf /tmp/core/homeassistant/package_constraints.txt homeassistant/homeassistant/ \
    && pip3 install \
    -r homeassistant/requirements.txt --use-deprecated=legacy-resolver \
    && cp -rf /tmp/core/requirements_all.txt homeassistant/ \
    && if ls homeassistant/home_assistant_frontend*.whl 1> /dev/null 2>&1; then \
        pip3 install --no-cache-dir --no-index homeassistant/home_assistant_frontend-*.whl; \
    fi \
    && pip3 install \
	    -r homeassistant/requirements_all.txt --use-deprecated=legacy-resolver \
	&& cp -rf /tmp/core/. homeassistant/ \
    && cd homeassistant/ \
    && python -m script.translations develop --all \
    && cd .. \
	&& pip3 install \
    	-e ./homeassistant --use-deprecated=legacy-resolver \
    && python3 -m compileall homeassistant/homeassistant \ 
    #install 'dev' cli \
    && cd /opt/dev \
    && pip install --editable . \
    #run and Stop home assistant when onboading dialog is shown \
    && /usr/local/bin/dev ha start --install-deps-only \
    #prepare hacs \
    && cd /config \
    && mkdir -p /config/custom_components \
    && wget https://get.hacs.xyz -O hacs-install.sh \
	&& chmod +x ./hacs-install.sh  \
	&& touch home-assistant.log \
    && ./hacs-install.sh \
	&& rm -f ./hacs-install.sh \
    #cleanup \
	&& cp -rf /tmp/core/rootfs / \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* \ 
    && find /usr/local \( -type d -a -name test -o -name tests -o -name '__pycache__' \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \; \ 
    && rm -fr /tmp/* /var/{cache,log}/* /root/.cache
