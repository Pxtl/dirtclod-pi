# syntax=docker/dockerfile:1

FROM local/pi-coding-agent:latest AS base

######################################################################
#region move npm global to userland
USER root

# move npm modules & the pi agent from the global npm directory to a new
# userland npm directory.  This allows us to run-time install pi plugins.
RUN mkdir -p /home/node/.npm-global/bin \
    && mkdir -p /home/node/.npm-global/lib \
    && npm config set prefix=/home/node/.npm-global \
    && mkdir -p /home/node/.npm-global/lib/node_modules/@earendil-works \
    && mv /usr/local/lib/node_modules/@earendil-works/pi-coding-agent /home/node/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent \
    && chown -R node:node /home/node/.npm-global \
    && chown -R node:node /home/node/.npmrc \
    && ln -s /home/node/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js /home/node/.npm-global/bin/pi \
    && ln -s /home/node/.npm-global/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js /usr/bin/pi

USER node

# set the user's node global to the new node-global, add it to PATH
RUN npm config set prefix=/home/node/.npm-global
RUN echo "export PATH=\"$HOME/.npm-global/bin:\$PATH\"" >> /home/node/.bashrc
#endregion move npm global to userland
######################################################################

USER root

# need OpenSSH to do git operations over SSH via the MITM server, need tmux to
# run pi in background
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client \
    tmux

COPY .tmux.conf /home/node/.tmux.conf

COPY entrypoint-tmux.sh /
RUN chmod +x /entrypoint-tmux.sh

######################################################################
#region install development dependencies needed to work on my projects

# dotnet
RUN wget https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-10.0 \
    && dotnet workload update \
    && echo "DOTNET_ROOT=/usr/lib/dotnet" >> /etc/environment

#endregion install development dependencies needed to work on my projects
######################################################################

# final prep of userland
RUN chown -R node:node /home/node

USER node

ENTRYPOINT ["/entrypoint-tmux.sh"]
CMD []