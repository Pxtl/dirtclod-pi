#!/usr/bin/env bash

# Install recommended pi extension modules. Idempotent: a module is only
# installed when its node_modules directory is missing, so already-installed
# modules (persisted in the volume) are not reinstalled.
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
PI_MODULES=(
    "@tmustier/pi-ralph-wiggum"
    "@pinet/model-aware-compaction"
)
for pkg in "${PI_MODULES[@]}"; do
    if [ ! -d "$PI_AGENT_DIR/npm/node_modules/$pkg" ]; then
        pi install "npm:$pkg" || echo "warning: failed to install $pkg" >&2
    fi
done

tmux new-session -d -s bash /bin/bash
tmux new-session -s pi pi
