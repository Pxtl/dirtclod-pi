# DirtClod Pie
This is a simple docker stack to create a fully-local secure coding agent.
It is very WIP and not suitable for any purpose at this time.

# WARNING
Take the [MIT license](LICENSE) seriously: This is hacking by a docker/LLM
novice.  While this is a best-effort at securing the LLM agent, I make no
guarantees.

## Usage

The intent is that you can pull down this project and `make compose-up` it and
get a working coding agent.  Connect to the agent with:

`docker exec -it pi-agent pi`

While `dirtclod-pi` initializes the agent and ollama server with expected
startup config (see `./initcontent`), you are free to customize those afterwards.
Use the `make force-init-volumes` to re-import the default settings.  Note that
this will not delete any custom things you have added, just re-copy the files
into the volumes.

## Components

### Ollama
The stack uses Ollama for local LLM hosting, and attempts to install Qwen3.5 by
default.

#### Configuration
Models can be customized in the Ollama volume in
`./volumes/rw/ollama/modelfiles`.  The entrypoint script will automatically name
the model after the directory containing the `Modelfile`.

Within the `dirtclod-net` network, Ollama is hosted on 11434.  But on your host's port it is bound to the .env var `OLLAMA_PUBLIC_PORT`, defaulting to 11434.

### pi-coding-agent
Uses
[pi-coding-agent-container](https://github.com/gni/pi-coding-agent-container)
for secure dockerized pi coding agent.

#### Configuration
Pi agent configuration is unfortunately stored deep in a submodule's volumes:
`./submodule/pi-coding-agent/.pi-data/agent`.  There you'll find the system
prompt and **Pi coding agent** settings and system prompt.  Getting this to a
more user-friendly path is TODO.

### ssh-mitm
SSH to github is handled by a proxy that keeps user's keys secret in the proxy
server. This must be configured with the .env var `SSH_MITM_DEST_HOST`. Keys go
in "volumes".  Further documentation details is TODO.

### Open-WebUI
Included just for fun, you can chat with the agent through there. 

**WARNING: CONFIG OPTIONS AND WEIGHTS CHANGES IN GUI DO NOT APPEAR TO WORK FOR
PI CODING AGENT.**

To set custom config options and weights, you will have to make a custom model.