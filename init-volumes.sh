#!/usr/bin/env bash
set -euo pipefail

# Deploy the standard config values into pi-coding-agent volume and ollama
# volume
#
# Usage: ./init-volumes.sh [-f]

# Resolve script directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "Setting up pi-coding-agent volume"
src_dir_pi="$script_dir/initcontent/pi-agent-defaults"
target_dir_pi="$script_dir/submodule/pi-coding-agent/.pi-data/agent"

# Create target directory
mkdir -p "$target_dir_pi"

# Copy files from src to target only if they don't already exist
for f in "$src_dir_pi"/*.{json,md}; do
  [ -e "$target_dir_pi/$(basename "$f")" ] || cp "$f" "$target_dir_pi/"
done

echo "Setting up ollama volume (FORCE_OLLAMA_INIT = $FORCE_OLLAMA_INIT)"
src_dir_ollama="$script_dir/initcontent/ollama-defaults"
target_dir_ollama="$script_dir/volumes/rw/ollama/"

# Create target directory
mkdir -p "$target_dir_ollama"

# Copy files from src to target only if they don't already exist
if [ -n $FORCE_OLLAMA_INIT ] || [ -e "$target_dir_ollama/modelfiles" ]; then
  echo "Copying modelfiles..."
  cp "$src_dir_ollama/modelfiles" "$target_dir_ollama/" -r
fi
for f in "$src_dir_ollama"/*.sh; do
  if [ -n $FORCE_OLLAMA_INIT ] || [ -e "$target_dir_ollama/$(basename "$f")" ]; then
    echo "Copying '$f'..."
    cp "$f" "$target_dir_ollama/"
  fi
  chmod +x $target_dir_ollama/$(basename "$f")
done

echo "Defaults deployed."