#!/usr/bin/env bash
set -euo pipefail

# Deploy the standard config values into pi-coding-agent volume and ollama
# volume.  Use -f to force ollama init.  Pi init must be done manually because
# that's more destructive.
#
# Usage: ./init-volumes.sh [-f]

# Resolve script directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

AGENT_GID="${AGENT_GID:-1000}"   # the gid used by `user:` in docker-compose.yaml

print_usage() {
  printf "Usage: ./init-volumes.sh [-f]"
}

FORCE_OLLAMA_INIT=''
while getopts 'f' flag; do
  case "${flag}" in
    f) FORCE_OLLAMA_INIT='true' ;;
    *) print_usage
       exit 1 ;;
  esac
done

# check if we're running an unsupported configuration.
if ls /run/user/*/docker.sock >/dev/null 2>&1; then
  echo "DirtClod Pie does not support rootless docker, use podman or rooted docker" >&2
  exit 1
fi

echo "Setting up pi-coding-agent volume"
src_dir_pi="$script_dir/initcontent/pi-agent-defaults"
target_dir_pi="$script_dir/volumes/pi-coding-agent/.pi-data/agent"

# Create target directory
mkdir -p "$target_dir_pi"

# Copy files from src to target only if they don't already exist
for f in "$src_dir_pi"/*.{json,md}; do
  [ -e "$target_dir_pi/$(basename "$f")" ] || cp "$f" "$target_dir_pi/"
done

# Assign ownership of copied files to rootless podman user if necessary
if docker info 2>/dev/null | grep -q 'run/user/.*/podman/podman.sock'; then
  echo "Rootless Podman detected — aligning volume ownership with agent identity"

  echo "Fixing ownership and permissions under pi_coding_agent ..."
  podman unshare chown -R "$AGENT_GID:$AGENT_GID" "$script_dir/volumes/pi-coding-agent/.config"
  podman unshare chown -R "$AGENT_GID:$AGENT_GID" "$script_dir/volumes/pi-coding-agent/.npm"
  podman unshare chown -R "$AGENT_GID:$AGENT_GID" "$script_dir/volumes/pi-coding-agent/.pi-data"
  podman unshare chown -R "$AGENT_GID:$AGENT_GID" "$script_dir/volumes/pi-coding-agent/.secrets"
  #not .ssh
  podman unshare chmod -R g+rwX "$script_dir/volumes/pi-coding-agent"
  podman unshare find "$script_dir/volumes/pi-coding-agent" -type d -exec chmod g+s {} +

  echo "Fixing ownership and permissions under workspace ..."
  podman unshare chown -R "$AGENT_GID:$AGENT_GID" "$script_dir/volumes/workspace"
  podman unshare chmod -R g+rwX "$script_dir/volumes/workspace"
  podman unshare find "$script_dir/volumes/workspace" -type d -exec chmod g+s {} +
else
  echo "Not rootless Podman — skipping uid-mapping fix (not needed on Docker)"
fi

echo "Setting up ollama volume (FORCE_OLLAMA_INIT = $FORCE_OLLAMA_INIT)"
src_dir_ollama="$script_dir/initcontent/ollama-defaults"
target_dir_ollama="$script_dir/volumes/ollama/"

# Create target directory
mkdir -p "$target_dir_ollama"

# Copy files from src to target only if they don't already exist
if [ -n "$FORCE_OLLAMA_INIT" ] || [ -e "$target_dir_ollama/modelfiles" ]; then
  echo "Copying modelfiles..."
  cp "$src_dir_ollama/modelfiles" "$target_dir_ollama/" -r
fi
for f in "$src_dir_ollama"/*.sh; do
  if [ -n "$FORCE_OLLAMA_INIT" ] || [ -e "$target_dir_ollama/$(basename "$f")" ]; then
    echo "Copying '$f'..."
    cp "$f" "$target_dir_ollama/"
  fi
  chmod +x "$target_dir_ollama/$(basename "$f")"
done

echo "Defaults deployed."