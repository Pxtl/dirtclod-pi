#!/usr/bin/env bash
set -euo pipefail

# After sshitmaids is up, copy and chown the client files from sshitmaids to
# dirtclod.
#
# Usage: ./init-pi-ssh.sh [-f]

# Resolve script directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
docker info 2>/dev/null | grep -q 'run/user/.*/podman/podman.sock' && is_rootless_podman="true" || is_rootless_podman="false"

print_usage() {
  printf "Usage: ./init-volumes.sh [-f]"
}

force_ssh_init=''
while getopts 'f' flag; do
  case "${flag}" in
    f) force_ssh_init='true' ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [[ $is_rootless_podman == "true" ]] && { [[ -n "$force_ssh_init" ]] || [[ ! -f "$script_dir/volumes/pi-coding-agent/.ssh/id_ed25519" ]]; }; then
    echo "deleting old .ssh files from pi-coding-agent..."
    podman exec -it --user root dirtclod-pi rm -f \
      /home/agentclod/.ssh/config \
      /home/agentclod/.ssh/id_ed25519 \
      /home/agentclod/.ssh/id_ed25519.pub \
      /home/agentclod/.ssh/known_hosts

    echo "copying ssh-client files from sshitmaids to pi-coding-agent..."
    cp "$script_dir/volumes/ssh-client"/* "$script_dir/volumes/pi-coding-agent/.ssh"
    echo "restricting ssh key permissions (ssh rejects group-writable keys)..."
    # ssh hard-fails on group/other-writable private keys; the source volume may
    # have been created under umask 002, so normalize modes explicitly.
    chmod 600 "$script_dir/volumes/pi-coding-agent/.ssh/id_ed25519"
    chmod 644 "$script_dir/volumes/pi-coding-agent/.ssh/id_ed25519.pub" \
              "$script_dir/volumes/pi-coding-agent/.ssh/known_hosts" \
              "$script_dir/volumes/pi-coding-agent/.ssh/config"
    echo "transferring ownership to agent clod..."
    podman unshare chown -R "1000:1000" "$script_dir/volumes/pi-coding-agent/.ssh"/*
    echo "done."
fi