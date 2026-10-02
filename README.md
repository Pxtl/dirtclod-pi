# DirtClod Pie

This is a simple docker stack to create a fully-local secure coding agent.
It is very WIP and not suitable for any purpose at this time.

## WARNING

Take the [MIT license](LICENSE) seriously: This is hacking by a docker/LLM
novice.  While this is a best-effort at securing the LLM agent, I make no
guarantees.

## Usage & Preconditions

The intent is that you can pull down this project, configure your .env file,
then use `make up` to get a working local-hosted coding agent running in a
secured container under podman or docker.  The agent starts on docker start, and
is available in a tmux session so you can tmux disconnect (ctrl+b -> d) and it
will continue to run.

In order to connect to github (or any other ssh-based git foundry) you'll need
the ssh public keys from sshitmaids' mitm server.  If you let dirtclod and
sshitmaids generate the ssh files, the one you need to give to github is here:

```
volumes/sshitmaids/id_ed25519_upstream.pub
```

Alternately, you can provide your own id_ed22519_upstream.pub into the volume.

Note that for any changes to files: In many cases the actual final copies of the
files like keys and the like are located in tempfs, with the copy operation
occurring in entrypoint.sh.  So you should probably restart your containers
after making that kind of change.

### The .env file

The file `.env.example` can be copied to `.env` file.  The settings are
documented within this file.  The bare minimum you'll want to change is the
section that controls the git username and emai

```
# Git identity - this is a part you must override
GIT_NAME=user-name-goes-here
GIT_EMAIL=1234567890+user-name-goes-here@users.noreply.github.com
```

### Podman and Docker

If running under rootless podman (recommended), it is recommended to run
`init-shared-group-podman.sh`.  This will create a user-group and grant your
current user access to that group, so you can conveniently access the
`workspace` files created and owned by the agent user.  Without that change
there will be the problem that your normal user will not have permission to the
agent's workspace or config files.

Under rootful docker or podman, this step is not necessary. Rootless docker is
not a supported configuration.

### Using the Agent

Connect to the agent with:

`docker exec -it dirtclod-pi tmux attach -t pi`

Note that tmux will shut down the agent if you `exit`

While `dirtclod-pi` initializes the agent and Ollama server with expected
startup config (see `./initcontent`), you are free to customize those afterwards.
Use the `make force-init-volumes` to re-import the default settings.  Note that
this will not delete any custom things you have added, just re-copy the files
into the volumes.

## Components

### Ollama
Runs as container "dirtclod-ollama" for service "ollama".

The stack uses Ollama for local LLM hosting, and attempts to install Qwen3.5 by
default.

#### Configuration
Models can be customized in the Ollama volume in
`./volumes/ollama/modelfiles`.  The entrypoint script will automatically name
the model after the directory containing the `Modelfile`.

Within the `dirtclod-net` network, Ollama is hosted on 11434.  But on your
host's port it is bound to the .env var `OLLAMA_PUBLIC_PORT`, defaulting to
11434. If you change this port in .env you will need to update your pi agent
settings.json.

### pi-coding-agent
Runs container "dirtclod-pi" for service "pi-coding-agent"

#### Configuration
Pi agent configuration is stored in `./volumes/pi-coding-agent/.pi-data/agent`.
There you'll find the system prompt and **Pi coding agent** settings and system prompt.

### sshitmaids
Runs container "dirtclod-sshitmaids" for service "sshitmaids".

"sshitmaids" is an ssh mitm server that keeps the user's ssh keys secret in the
server and forwards the ssh traffic from dirtclod to github. See
[sshitmaids](https://github.com/pxtl/sshitmaids)

### Open-WebUI
Runs container "dirtclod-ollama-webui" for service "ollama-webui".

Included just for fun, you can chat with the ollama LLMs through there.

**WARNING: CONFIG OPTIONS AND WEIGHTS CHANGES IN GUI DO NOT APPEAR TO WORK FOR OLLAMA.**

To set custom config options and weights, you will have to make a custom model.
