#!/usr/bin/env bash
set -euo pipefail

# Deploy the standard config values into pi-coding-agent volume (bash)
# Usage: ./deploy-defaults.sh

# Resolve script directory
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

src_dir="$script_dir/pi-agent-defaults"
target_dir="$script_dir/submodule/pi-coding-agent/.pi-data/agent"

# Create target directory
mkdir -p "$target_dir"

# Copy files from src to target only if they don't already exist
for f in "$src_dir"/*.json; do
  [ -e "$target_dir/$(basename "$f")" ] || cp "$f" "$target_dir/"
done

echo "Defaults deployed."