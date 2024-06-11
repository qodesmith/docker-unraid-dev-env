# VS Code in the browser!
FROM gitpod/openvscode-server:latest as base

# Set the user to root so we don't have permission errors to do the things.
USER root

# Update / install system dependencies
RUN apt-get update && \
    apt-get install -y \
    zip \
    unzip \
    git \
    ssh

# This directory will contain the VS Code plugins we build for installation.
ARG VSIX="/vsix"
RUN mkdir $VSIX

ARG TEMP_REPOS="/temp-repos"
RUN mkdir $TEMP_REPOS

# Bun
ENV BUN_INSTALL=/usr/local
RUN curl -o- -fsSL https://bun.sh/install | bash

# Node
# The only reason we include Node is because the @vscode/vsce package that
# builds the VS Code extension is hardcoded to use yarn or npm 🫠
RUN curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
    apt-get install nodejs -y

# outrun-meets-synthwave (theme)
WORKDIR $TEMP_REPOS
RUN git clone https://github.com/qodesmith/outrun-meets-synthwave.git
WORKDIR $TEMP_REPOS/outrun-meets-synthwave
RUN bun install && \
    bunx @vscode/vsce package --skip-license && \
    mv $(ls *.vsix | head -n 1) $VSIX

# vscode-copy-filename (extension)
WORKDIR $TEMP_REPOS
RUN git clone https://github.com/qodesmith/vscode-copy-filename.git
WORKDIR $TEMP_REPOS/vscode-copy-filename
RUN bun install && \
    bunx @vscode/vsce package --skip-license && \
    mv $(ls *.vsix | head -n 1) $VSIX

# openvscode-server-settings (extension) - THIS MUST BE THE LAST EXTENSION!
WORKDIR $TEMP_REPOS
RUN git clone https://github.com/qodesmith/openvscode-server-settings.git
WORKDIR $TEMP_REPOS/openvscode-server-settings
RUN bun install && \
    bun run package && \
    mv $(ls *.vsix | head -n 1) $VSIX

################################################################################
################################################################################
################################################################################

FROM gitpod/openvscode-server:latest

# Set the user to root so we don't have permission errors to do the things.
USER root

RUN apt-get update && \
    apt-get install -y \
    zsh \
    zip \
    unzip \
    git \
    ssh

ENV GIT_CONFIG_GLOBAL="/user/dev_setup/.gitconfig"
ARG OPENVSCODE="/home/.openvscode-server/bin/openvscode-server"
ARG VSIX="/vsix"

RUN mkdir $VSIX
COPY --from=base $VSIX/* $VSIX

# Bun
ENV BUN_INSTALL=/usr/local
RUN curl -o- -fsSL https://bun.sh/install | bash

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_DISABLE_COMPFIX="true"
SHELL ["/bin/zsh", "-c"]

# Delta for git - https://github.com/dandavison/delta/releases
ARG TEMP_DELTA_DIR="/tmp-delta"
ARG DELTA_DEB="git-delta_0.17.0_amd64.deb"
RUN mkdir $TEMP_DELTA_DIR
WORKDIR $TEMP_DELTA_DIR
RUN curl -O -fsSL https://github.com/dandavison/delta/releases/download/0.17.0/$DELTA_DEB && \
    dpkg -i $DELTA_DEB

# Extensions available publicly
RUN $OPENVSCODE --install-extension esbenp.prettier-vscode && \
    $OPENVSCODE --install-extension eamodio.gitlens && \
    $OPENVSCODE --install-extension wix.vscode-import-cost && \
    $OPENVSCODE --install-extension yoavbls.pretty-ts-errors && \
    $OPENVSCODE --install-extension alefragnani.project-manager && \
    $OPENVSCODE --install-extension gruntfuggly.todo-tree && \
    $OPENVSCODE --install-extension mikestead.dotenv && \
    $OPENVSCODE --install-extension tobermory.es6-string-html && \
    $OPENVSCODE --install-extension dbaeumer.vscode-eslint && \
    $OPENVSCODE --install-extension techer.open-in-browser && \
    $OPENVSCODE --install-extension christian-kohler.path-intellisense && \
    $OPENVSCODE --install-extension $VSIX/outrun-meets-synthwave-0.0.1.vsix && \
    $OPENVSCODE --install-extension $VSIX/vscode-copy-filename-0.1.1.vsix && \
    $OPENVSCODE --install-extension $VSIX/openvscode-server-settings-1.0.0.vsix
