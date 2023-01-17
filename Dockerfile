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

WORKDIR /tmp

# install ZSH Shell
RUN \
	wget https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O oh-my-zsh-install.sh \
	&& rm -rf /root/.oh-my-zsh \
	&& chmod +x ./oh-my-zsh-install.sh \
	&& ./oh-my-zsh-install.sh --unattended \
	&& rm -f ./oh-my-zsh-install.sh

# deploy ha-devcontainer commands, scripts, home assistant basic config, default shell, ...
COPY copy_root/ /

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

## Setup Home Assistant Core and dependencies
RUN mkdir -p homeassistant/homeassistant \
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
	&& pip3 install \
    	-e ./homeassistant --use-deprecated=legacy-resolver \
    && python3 -m compileall homeassistant/homeassistant \ 
    #prepare hacs \
    && cd /config \
    && mkdir -p /config/custom_components \
    && wget -O - https://get.hacs.xyz | bash - \
    #install 'dev' cli \
    && cd /opt/dev \
    && pip install --editable . \
    #run and Stop home assistant when onboading dialog is shown \
    && /usr/local/bin/dev ha start --install-deps-only \
    #cleanup \
	&& cp -rf /tmp/core/rootfs / \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* \ 
    && find /usr/local \( -type d -a -name test -o -name tests -o -name '__pycache__' \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \; \ 
    && rm -fr /tmp/* /var/{cache,log}/* /root/.cache
