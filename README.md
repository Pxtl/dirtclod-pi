# DirtClod Pie

This is a simple docker stack to create a fully-local secure coding agent.
It is very WIP and not suitable for any purpose at this time.

## WARNING

Take the [MIT license](LICENSE) seriously: This is hacking by a docker/LLM
novice.  While this is a best-effort at securing the LLM agent, I make no
guarantees.

## Usage & Preconditions

The intent is that you can pull down this project, configure your `.env` file,
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
section that controls the git username and email, and setting the size of your
VRAM.

```
# Git identity - this is a part you must override
GIT_NAME=user-name-goes-here
GIT_EMAIL=1234567890+user-name-goes-here@users.noreply.github.com

# Agent model per your VRAM, see .env.example
LLM_AGENT_HF_REPO=VladimirGav/qwen3.8-27B-14GB-IQ4:IQ4
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

While `dirtclod-pi` initializes the agent and llama.cpp router with expected
startup config (see `./initcontent`), you are free to customize those afterwards.
`make init-volumes` re-imports any default settings files that are still missing
(it never overwrites files you already have - edit your volume copies directly).

## Components

### llama.cpp router
Runs as container "dirtclod-llama" (service "llama") - a single
`llama-server` in router mode serving all models on one port, loading and
unloading model instances on demand.  Models idle for 5 minutes sleep
(unloaded from VRAM/RAM) and auto-reload on the next request.

Originally this stack used Ollama, but Ollama 0.40.x had agentic bugs with
Qwen thinking models - garbled tool schemas from Modelfile `{{ .Function }}`,
early turn-ending on think+tools requests, and silently ignored thinking
kwargs - so it was replaced with `llama-server`, which uses each GGUF's
embedded chat template.

#### Configuration
Models are defined in the router preset `./volumes/llama/models.ini`
(seeded from `initcontent/llama-defaults/`).  Each section names a model
(and its id as served on `/v1/models`), HF repo/file, and per-model args.
Edit and restart to swap quants or add models.  Default trio, sized for a
19GB-VRAM budget:

- `dirtclod-agent-qwen`: Qwen3.8-27B UD-IQ4_XS (14.3GB, full GPU)
- `dirtclod-north-mini-code`: North-Mini-Code-1.0 UD-Q5_K_M (MoE - expert
  weights stay in system RAM via `n-cpu-moe`; ~5GB VRAM-resident)
- `dirtclod-autocomplete-qwen`: Qwen2.5-Coder-1.5B (always resident)

Within the `dirtclod-net` network the router is on `llama:9931`
(llama-server's default port); on the host it binds to `LLAMA_PUBLIC_PORT`
(default 9931, matching the server default).

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
Runs container "dirtclod-webui" for service "webui".

Included just for fun, you can chat with the local LLMs through there.  It
talks to the agent llama-server via its OpenAI-compatible API.
