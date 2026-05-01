# Makefile for pxtl-clod-docker

.PHONY: help init-submodules build-agent build init-agent compose-up compose-down clean
.DEFAULT_GOAL := build

# Use this project name for tagging/pushing images
PROJECT_NAME := pxtl-clod-docker
AGENT_IMAGE := ghcr.io/$(shell whoami)/$(PROJECT_NAME)-pi-agent:local
ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

help:
	@echo "usage: make [target]"

init-submodules:
	git submodule update --init --recursive

build-agent: init-submodules
	@echo "Building pi-coding-agent from submodule/pi-coding-agent"
	@cd submodule/pi-coding-agent \
	&& make setup \
	&& docker compose --env-file $(ROOT_DIR)/.env build 

init-agent: build-agent
	@bash ./init-agent-settings.sh

build: init-agent
	docker compose build

# Start the full stack (ensures network and builds agent first)
compose-up: init-agent
	@echo "Starting stack with docker compose"
	docker compose up -d

compose-down:
	docker compose down

clean: compose-down
	@echo "Removing agent local image (if present)"
	-@docker image rm $(AGENT_IMAGE) || true