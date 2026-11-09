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

ssh_dir_host="$script_dir/volumes/pi-coding-agent/.ssh"
ssh_dir_incontainer="/home/agentclod/.ssh"

if [[ $is_rootless_podman == "true" ]]; then
  # we can use 'podman' commands because docker is not supported here.
  if [[ -n "$force_ssh_init" ]] || [[ ! -f "$ssh_dir_host/id_ed25519" ]]; then
    echo "deleting old .ssh files from pi-coding-agent..."
    podman exec -it --user root dirtclod-pi rm -f \
      $ssh_dir_incontainer/config \
      $ssh_dir_incontainer/id_ed25519 \
      $ssh_dir_incontainer/id_ed25519.pub \
      $ssh_dir_incontainer/known_hosts

    echo "copying ssh-client files from sshitmaids to pi-coding-agent..."
    mkdir -p "$ssh_dir_host"
    cp "$script_dir/volumes/ssh-client"/* "$ssh_dir_host"
  fi

  echo "transferring ownership to agent clod..."
  podman unshare chown -R "1000:1000" "$ssh_dir_host"

  # Normalize on every run: rebuilds can leave group bits behind, and ssh
  # hard-fails on group/other-writable private keys. The source volume may
  # have been created under umask 002, so normalize modes explicitly.
  echo "restricting ssh key permissions (ssh rejects group-writable keys)..."
  # explicit g-s because this fs keeps dir setgid even
  podman exec -it --user root dirtclod-pi chmod ug=rwx,g-s "$ssh_dir_incontainer"
  podman exec -it --user root dirtclod-pi chmod u=rw,go-rwx "$ssh_dir_incontainer/id_ed25519"
  podman exec -it --user root dirtclod-pi chmod ug=rw "$ssh_dir_incontainer/id_ed25519.pub" \
    "$ssh_dir_incontainer/known_hosts" \
    "$ssh_dir_incontainer/config"
  echo "done."
fi