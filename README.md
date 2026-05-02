# DirtClod Pie
This is a simple docker stack to create a fully-local secure local coding agent.  It is very WIP and not suitable for any purpose at this time.

## Ollama
The stack uses Ollama for local LLM hosting, and attempts to install Qwen3.5 by default (with mixed success).

## Pi-Agent
Uses [pi-coding-agent-container](https://github.com/gni/pi-coding-agent-container) for secure dockerized pi coding agent.

## ssh-mitm
SSH to github is handled by a proxy that keeps user's keys secret in the proxy server.
This must be configured with the .env var `SSH_MITM_DEST_HOST`.
Keys go in "volumes".  Further documentation details is TODO.

## Open-WebUI
Included just for fun, you can chat with the agent through there.
