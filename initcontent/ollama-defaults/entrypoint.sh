#!/usr/bin/env bash
# set -euo pipefail

echo "0. Archiving the log..."
logpath=/var/log/ollama-serve.log
mv $logpath $logpath.$(date +%F).bak

echo "1. Starting Ollama server..."
ollama serve > $logpath 2>&1 &

# HACK: don't know how to wait until ollama is serving.
sleep 2

echo "Ollama is ready!"

echo "2. Pulling qwen3.5 as default image if not done already..."
ollama pull qwen3.5

echo "3. Creating dirtclod models...."
./create-models.sh

echo "4. Entering idle mode."
sleep infinity
