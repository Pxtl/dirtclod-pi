#!/bin/sh

# Force HOME to the git user's home directory
HOME=/home/git
export HOME

# Force SSH to use the git user's config file
exec ssh -F /home/git/.ssh/config -T dest "$@"