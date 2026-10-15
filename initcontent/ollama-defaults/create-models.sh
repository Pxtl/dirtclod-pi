#!/usr/bin/env bash
# set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <vram>" >&2
    exit 2
fi

ollama_vram="$1"
common_modelfiles_dir="$HOME/.ollama/modelfiles/common"
sized_modelfiles_dir="$HOME/.ollama/modelfiles/$ollama_vram"

if [[ ! -d "$common_modelfiles_dir" ]]; then
    echo "Common models directory does not exist: $common_modelfiles_dir" >&2
    exit 1
fi

if [[ ! -d "$sized_modelfiles_dir" ]]; then
    echo "Sized models directory does not exist: $sized_modelfiles_dir" >&2
    exit 1
fi

for model_dir_path in $(ls -d $common_modelfiles_dir/* $sized_modelfiles_dir/*); do
    model_dir_name="$(basename $model_dir_path)"
    echo "creating model '$model_dir_name' ($ollama_vram)..."
    base_model_name=$(sed -nE 's/^FROM[[:space:]]+(.+)/\1/p' "$model_dir_path/Modelfile")
    ollama pull $base_model_name
    ollama create $model_dir_name -f "$model_dir_path/Modelfile"
done
