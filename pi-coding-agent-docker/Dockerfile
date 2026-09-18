# syntax=docker/dockerfile:1

FROM mcr.microsoft.com/dotnet/sdk:10.0.401-resolute AS base

ENV NODE_ENV=production
ENV DEBIAN_FRONTEND=noninteractive
ENV NPM_CONFIG_LOGLEVEL=warn

# create agentclod user
# Rename the user & group 'ubuntu' to 'agentclod'
RUN usermod -l agentclod ubuntu && \
    groupmod -n agentclod ubuntu && \
    usermod -d /home/agentclod -m agentclod

ENV HOME=/home/agentclod

# install apt software
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs \
    npm \
    git \
    curl \
    wget \
    ca-certificates \
    procps \
    build-essential \
    python3 \
    python3-dev \
    openssh-client \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# install github client
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

######################################################################
#region move npm global to userland
#
# move npm modules & the pi agent from the global npm directory to a new
# userland npm directory.  This allows us to run-time install pi plugins.

RUN mkdir -p /home/agentclod/.pi/agent \
    /workspace \
    /home/agentclod/.config \
    /home/agentclod/.npm \
    /workspace \
    /home/agentclod/.config \
    /home/agentclod/.npm \
    /home/agentclod/.npm-global/bin \
    /home/agentclod/.npm-global/lib
    
RUN npm config set prefix=/home/agentclod/.npm-global \
    && echo "export PATH=\"$HOME/.npm-global/bin:\$PATH\"" >> /home/agentclod/.bashrc \
    && chown -R agentclod:agentclod /home/agentclod/.npm-global \
    && chown -R agentclod:agentclod /home/agentclod/.npmrc
#endregion move npm global to userland
######################################################################

# dotnet tools path
ENV PATH="/home/agentclod/.dotnet/tools:${PATH}"

# pi coding agent
RUN npm install -g @earendil-works/pi-coding-agent \
    && ln -s /home/agentclod/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js /usr/bin/pi

WORKDIR /workspace

# tmux config
COPY .tmux.conf /home/agentclod/.tmux.conf
ENV LANG=en_US.UTF-8
ENV TERM=xterm-256color

COPY entrypoint-tmux.sh /
RUN chmod +x /entrypoint-tmux.sh

# final prep of userland
RUN chown -R agentclod:agentclod /home/agentclod

USER agentclod

ENTRYPOINT ["/entrypoint-tmux.sh"]
CMD []