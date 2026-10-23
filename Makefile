# Makefile for dirtclod-pi docker

.PHONY: help build-pi-agent build init-volumes force-init-volumes up down clean
.DEFAULT_GOAL := build

# Use this project name for tagging/pushing images
PROJECT_NAME := dirtclod-pi
AGENT_IMAGE := ghcr.io/$(shell whoami)/$(PROJECT_NAME)-pi-agent:local
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
# Load .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

help:
	@echo "usage: make [target]"

init-volumes:
	@bash ./init-volumes.sh

force-init-volumes:
	@bash ./init-volumes.sh -f

build: init-volumes
	docker compose build

# Start the full stack (ensures network and builds agent first)
up: build
	@echo "Starting stack with docker compose"
	@echo ""
	@echo "NOTE: on first run the llama.cpp servers download their models into"
	@echo "      volumes/llama BEFORE the API comes up (agent model is ~14GB)."
	@echo "      'podman ps' will show llama-agent as (health: starting) until"
	@echo "      the download finishes - follow progress with:"
	@echo "        podman logs -f dirtclod-llama-agent"
	@echo ""
	docker compose up -d --remove-orphans
	@bash ./init-pi-ssh.sh

down:
	docker compose down --remove-orphans

clean: down
	@echo "Removing agent local image (if present)"
	-@docker image rm $(AGENT_IMAGE) || true