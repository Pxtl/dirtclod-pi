#!/usr/bin/env bash
# set -euo pipefail

echo "1. Starting Ollama server..."
ollama serve > /var/log/ollama-serve.log 2>&1 &

# HACK: don't know how to wait until ollama is serving.
sleep 2

echo "Ollama is ready!"

echo "2. Pulling qwen3.5 as default image if not done already..."
ollama pull qwen3.5

echo "2a. Pulling qwen3.8 as possible upgrade image if not done already..."
ollama pull batiai/qwen3.8-27b:iq3

echo "2b. Pulling qwen2.5-coder as autocomplete..."
ollama pull qwen2.5-coder:1.5b

echo "3. Creating dirtclod models...."
modelfiles_dir="$HOME/.ollama/modelfiles"

for d in $(ls $modelfiles_dir); do
    echo "creating model '$d'..."
    ollama create $d -f $modelfiles_dir/$d/Modelfile
done

echo "4. Entering idle mode."
sleep infinity
