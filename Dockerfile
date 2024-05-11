# VS Code in the browser!
FROM gitpod/openvscode-server:latest

# Set the user to root so we don't have permission errors to do the things.
USER root

# Git
ENV GIT_CONFIG_GLOBAL="/user/dev_setup/.gitconfig"

# Update / install system dependencies
RUN apt-get update && \
    apt-get install -y \
    zip \
    unzip \
    zsh \
    sudo \
    git \
    ssh

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
ARG VSCODE_SETTINGS_DIR="/vscode-settings"
ARG SETTINGS_PLUGIN_URL="https://github.com/qodesmith/openvscode-server-settings.git"
ARG SETTINGS_PLUGIN_DIR="openvscode-server-settings"
ARG OUTRUN_URL="https://github.com/qodesmith/outrun-meets-synthwave.git"
ARG OUTRUN_DIR="outrun-meets-synthwave"
ARG OPENVSCODE_SERVER_ROOT="/home/.openvscode-server"
ARG OPENVSCODE="${OPENVSCODE_SERVER_ROOT}/bin/openvscode-server"

# outrun-meets-synthwave (theme)
RUN mkdir $VSCODE_SETTINGS_DIR
WORKDIR $VSCODE_SETTINGS_DIR
RUN git clone $OUTRUN_URL
WORKDIR $VSCODE_SETTINGS_DIR/$OUTRUN_DIR
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
WORKDIR $VSCODE_SETTINGS_DIR
RUN git clone $SETTINGS_PLUGIN_URL
WORKDIR $VSCODE_SETTINGS_DIR/$SETTINGS_PLUGIN_DIR
RUN bun install && bun run package
RUN $OPENVSCODE --install-extension $(ls *.vsix | head -n 1)

# Delta for git - https://github.com/dandavison/delta/releases
ARG TEMP_DELTA_DIR="/tmp-delta"
ARG DELTA_DEB="git-delta_0.17.0_amd64.deb"
RUN mkdir $TEMP_DELTA_DIR
WORKDIR $TEMP_DELTA_DIR
RUN curl -O -fsSL https://github.com/dandavison/delta/releases/download/0.17.0/$DELTA_DEB
RUN dpkg -i $DELTA_DEB

# Final setup
COPY src/settings.json $VSCODE_SETTINGS_DIR
RUN chsh -s $(which zsh)
WORKDIR /user

# Cleanup
RUN apt-get remove nodejs -y
RUN rm -rf $TEMP_DELTA_DIR
