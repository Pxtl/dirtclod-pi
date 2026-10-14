#!/usr/bin/env bash
# set -euo pipefail

modelfiles_dir="$HOME/.ollama/modelfiles"

for d in $(ls $modelfiles_dir); do
    # Skip if it isn't actually a directory
    [ -d "$modelfiles_dir/$d" ] || continue

    echo "creating model '$d'..."
    modelname=$(sed -nE 's/^FROM[[:space:]]+(.+)/\1/p' "$modelfiles_dir/$d/Modelfile")
    ollama pull $modelname
    ollama create $d -f "$modelfiles_dir/$d/Modelfile"
done
