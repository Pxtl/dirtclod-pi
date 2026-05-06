# syntax=docker/dockerfile:1

FROM local/pi-coding-agent:latest AS base

USER root

# need OpenSSH to do git operations over SSH via the MITM server
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-client

# install development dependencies needed to work on my projects

# dotnet
RUN wget https://packages.microsoft.com/config/debian/12/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y dotnet-sdk-10.0

# move npm modules & the pi agent from the global npm directory to a new
# userland npm directory
RUN mkdir -p /home/node/.npm-global/bin \
    && mkdir -p /home/node/.npm-global/lib \
    && npm config set prefix=/home/node/.npm-global \
    && mkdir -p /home/node/.npm-global/lib/node_modules/@mariozechner \
    && mv /usr/local/lib/node_modules/@mariozechner/pi-coding-agent /home/node/.npm-global/lib/node_modules/@mariozechner/pi-coding-agent \
    && chown -R node:node /home/node/.npm-global \
    && ln -s /home/node/.npm-global/lib/node_modules/@mariozechner/pi-coding-agent/dist/cli.js /home/node/.npm-global/bin/pi

USER node

# set the user's node global to the new node-global, add it to PATH
RUN npm config set prefix=/home/node/.npm-global
RUN echo "export PATH=\"$HOME/.npm-global/bin:\$PATH\"" >> /home/node/.bashrc

ENTRYPOINT ["/bin/bash"]

CMD []