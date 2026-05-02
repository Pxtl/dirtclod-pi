# Makefile for dirtclod-pi docker

.PHONY: help init-submodules init-ssh-mitm build-pi-agent build init-pi-agent compose-up compose-down clean
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

init-submodules:
	git submodule update --init --recursive

build-pi-agent: init-submodules
	@echo "Building pi-coding-agent from submodule/pi-coding-agent"
	@cd submodule/pi-coding-agent \
	&& make setup \
	&& docker compose --env-file $(ROOT_DIR)/.env build

init-pi-agent: build-pi-agent
	@bash ./init-pi-agent-settings.sh

init-ssh-mitm:
	@bash ./ssh-mitm-docker/init-ssh-mitm-volumes.sh $(SSH_MITM_DEST_HOST)

build: init-pi-agent init-ssh-mitm
	docker compose build

# Start the full stack (ensures network and builds agent first)
compose-up: build
	@echo "Starting stack with docker compose"
	docker compose up -d

compose-down:
	docker compose down

clean: compose-down
	@echo "Removing agent local image (if present)"
	-@docker image rm $(AGENT_IMAGE) || true