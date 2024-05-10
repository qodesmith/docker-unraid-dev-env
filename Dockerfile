# VS Code in the browser!
FROM gitpod/openvscode-server:latest

# Set the user to root so we don't have permission errors to do the things.
USER root

# Git
ENV GIT_CONFIG_GLOBAL="/user/dev_setup/.gitconfig"

# Update / install system dependencies
RUN apt-get update && \
    apt-get install -y \
    unzip \
    zsh \
    sudo \
    git \
    git-delta

# Bun
ENV BUN_INSTALL=/usr/local
RUN curl -o- -fsSL https://bun.sh/install | bash

# Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_DISABLE_COMPFIX="true"
SHELL ["/bin/zsh", "-c"]

# Node
# The only reason we include Node is because the @vscode/vsce package that
# builds the VS Code extension is hardcoded to use yarn or npm 🫠
RUN curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
RUN apt-get install nodejs -y

# Variables needed to manually build vsix extension files.
ARG TEMP_VSCODE_DIR="/vscode-settings"
ARG SETTINGS_PLUGIN_URL="https://github.com/qodesmith/openvscode-server-settings.git"
ARG SETTINGS_PLUGIN_DIR="openvscode-server-settings"
ARG OUTRUN_URL="https://github.com/qodesmith/outrun-meets-synthwave.git"
ARG OUTRUN_DIR="outrun-meets-synthwave"
ARG OPENVSCODE_SERVER_ROOT="/home/.openvscode-server"
ARG OPENVSCODE="${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server"

RUN mkdir $TEMP_VSCODE_DIR

# outrun-meets-synthwave (theme)
WORKDIR $TEMP_VSCODE_DIR
RUN git clone $OUTRUN_URL
WORKDIR $TEMP_VSCODE_DIR/$OUTRUN_DIR
RUN bun install
RUN bunx @vscode/vsce package --skip-license
RUN $OPENVSCODE --install-extension $(ls *.vsix | head -n 1)

# Extensions available publicly
RUN $OPENVSCODE --install-extension esbenp.prettier-vscode
RUN $OPENVSCODE --install-extension eamodio.gitlens
RUN $OPENVSCODE --install-extension wix.vscode-import-cost
RUN $OPENVSCODE --install-extension yoavbls.pretty-ts-errors
RUN $OPENVSCODE --install-extension alefragnani.project-manager
RUN $OPENVSCODE --install-extension gruntfuggly.todo-tree
RUN $OPENVSCODE --install-extension mikestead.dotenv
RUN $OPENVSCODE --install-extension tobermory.es6-string-html
RUN $OPENVSCODE --install-extension dbaeumer.vscode-eslint
RUN $OPENVSCODE --install-extension techer.open-in-browser
RUN $OPENVSCODE --install-extension christian-kohler.path-intellisense

# openvscode-server-settings (extension) - THIS MUST BE THE LAST EXTENSION!
WORKDIR $TEMP_VSCODE_DIR
RUN git clone $SETTINGS_PLUGIN_URL
WORKDIR $TEMP_VSCODE_DIR/$SETTINGS_PLUGIN_DIR
RUN bun install && bun run package
RUN $OPENVSCODE --install-extension $(ls *.vsix | head -n 1)

# Cleanup
RUN apt-get remove nodejs -y
RUN rm -rf $TEMP_VSCODE_DIR/*

# Final setup
COPY src/settings.json $TEMP_VSCODE_DIR
