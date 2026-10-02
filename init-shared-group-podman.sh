#!/usr/bin/env bash
set -euo pipefail

# Host setup for shared-file access between you (the host user) and the agent
# container, under rootless Podman.
#
# Creates a group whose gid matches what the agent's in-container gid maps to
# on the host (per your subgid range), adds you to it, and fixes ownership and
# setgid bits on volumes so both you and the agent can edit everything there.
#
# Safe to re-run at any time (idempotent): every step checks before it changes
# anything. Re-running is also the way to pick up new files — anything created
# under volumes after the last run (or new bind-mounted paths added to the
# compose file) won't carry the shared ownership/permissions until you do.
#
# Rootful-Docker users: skip this script entirely. With Docker, container
# uid/gid are the host uid/gid, so `user: "1000:1000"` matches your own files
# and no group is needed.
#
# Usage: ./init-shared-group.sh [group-name]
#   group-name defaults to "agentshare"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GROUP_NAME="${1:-agentshare}"
AGENT_GID="${AGENT_GID:-1000}"   # the gid used by `user:` in docker-compose.yaml
SHARED_DIR="$script_dir/volumes"

# 1. Find the host gid that the agent's container gid maps to.
host_gid="$(podman unshare awk -v g="$AGENT_GID" \
  '$1 <= g && g < $1+$3 { print $2 + g - $1; exit }' /proc/self/gid_map)"

if [ -z "$host_gid" ]; then
  echo "Could not find a host gid for container gid $AGENT_GID in your subgid map." >&2
  exit 1
fi
echo "Container gid $AGENT_GID maps to host gid $host_gid"

# 2. Create the group at that gid (or reuse it if it already exists).
if getent group "$host_gid" >/dev/null; then
  existing_name="$(getent group "$host_gid" | cut -d: -f1)"
  if [ "$existing_name" = "$GROUP_NAME" ]; then
    echo "Group '$GROUP_NAME' (gid $host_gid) already exists."
  else
    echo "A group '$existing_name' already uses gid $host_gid; reusing it." >&2
    GROUP_NAME="$existing_name"
  fi
else
  sudo groupadd -g "$host_gid" "$GROUP_NAME"
  echo "Created group '$GROUP_NAME' (gid $host_gid)."
fi

# 3. Add yourself to it (idempotent).
if id -nG "$USER" | grep -qw "$GROUP_NAME"; then
  echo "You are already in '$GROUP_NAME'."
else
  sudo usermod -aG "$GROUP_NAME" "$USER"
  echo "Added $USER to '$GROUP_NAME'."
fi

# 4. Tell the user what's left.
echo
echo "Done. Remaining manual steps:"
echo "  1. Log out and back in (or 'newgrp $GROUP_NAME') for group membership to take effect."
echo "  2. Set AGENT_UID=$AGENT_GID and AGENT_GID=$AGENT_GID in .env if not already set."
echo "     (compose uses user: \"\${AGENT_UID:-0}:\${AGENT_GID:-0}\")"
echo "  3. Ensure the agent's shell uses umask 002 so new files stay group-writable"
echo "     (add UMASK=002 to the service's environment: in docker-compose.yaml)."
echo "  4. Re-create the container: docker compose up -d --force-recreate pi-coding-agent"
