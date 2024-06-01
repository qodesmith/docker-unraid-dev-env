# VS Code in the browser!
FROM gitpod/openvscode-server:latest
# Size - 536.39MB

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
# Size - 724.92MB

# Bun
ENV BUN_INSTALL=/usr/local
RUN curl -o- -fsSL https://bun.sh/install | bash
# Size - 822.25MB

# Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
ENV ZSH_DISABLE_COMPFIX="true"
SHELL ["/bin/zsh", "-c"]
# Size - 832.59MB

# Node
# The only reason we include Node is because the @vscode/vsce package that
# builds the VS Code extension is hardcoded to use yarn or npm 🫠
RUN curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash - && \
    apt-get install nodejs -y

# Variables needed to manually build vsix extension files.
ARG TEMP_REPOS="/temp-repos"
ARG OPENVSCODE="/home/.openvscode-server/bin/openvscode-server"

# Create a directory to manually clone repos for extensions.
RUN mkdir $TEMP_REPOS
# Size - 996.27MB

# outrun-meets-synthwave (theme)
WORKDIR $TEMP_REPOS
RUN git clone https://github.com/qodesmith/outrun-meets-synthwave.git
WORKDIR $TEMP_REPOS/outrun-meets-synthwave
RUN bun install && \
    bunx @vscode/vsce package --skip-license && \
    $OPENVSCODE --install-extension $(ls *.vsix | head -n 1)
# Size - 1.02GB

# vscode-copy-filename (extension)
WORKDIR $TEMP_REPOS
RUN git clone https://github.com/qodesmith/vscode-copy-filename.git
WORKDIR $TEMP_REPOS/vscode-copy-filename
RUN bun install && \
    bunx @vscode/vsce package --skip-license && \
    $OPENVSCODE --install-extension $(ls *.vsix | head -n 1)
# Size - 1.19GB

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
    $OPENVSCODE --install-extension christian-kohler.path-intellisense
# Size - 1.32GB

# openvscode-server-settings (extension) - THIS MUST BE THE LAST EXTENSION!
WORKDIR $TEMP_REPOS
RUN git clone https://github.com/qodesmith/openvscode-server-settings.git
WORKDIR $TEMP_REPOS/openvscode-server-settings
RUN bun install && bun run package && \
    $OPENVSCODE --install-extension $(ls *.vsix | head -n 1)
# Size - 1.4GB

# Delta for git - https://github.com/dandavison/delta/releases
ARG TEMP_DELTA_DIR="/tmp-delta"
ARG DELTA_DEB="git-delta_0.17.0_amd64.deb"
RUN mkdir $TEMP_DELTA_DIR
WORKDIR $TEMP_DELTA_DIR
RUN curl -O -fsSL https://github.com/dandavison/delta/releases/download/0.17.0/$DELTA_DEB && \
    dpkg -i $DELTA_DEB
# Size - 1.41GB

# Final setup
RUN mkdir /vscode-settings
COPY src/settings.json /vscode-settings
RUN chsh -s $(which zsh)
WORKDIR /user

# Cleanup
RUN apt-get remove nodejs -y && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf $TEMP_DELTA_DIR && \
    rm -rf $TEMP_REPOS
# Size - 1.41GB
