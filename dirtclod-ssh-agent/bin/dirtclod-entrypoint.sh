#!/usr/bin/env bash

set -euo pipefail

# call the original entrypoint.
docker-entrypoint.sh $1

ssh-add ~/.ssh/id_ed25519
