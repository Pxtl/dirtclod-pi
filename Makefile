# Makefile for dirtclod-pi docker

.PHONY: help init-submodules build-pi-agent build init-volumes force-init-volumes compose-up compose-down clean
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

init-volumes: build-pi-agent
	@bash ./init-volumes.sh

force-init-volumes: build-pi-agent
	@bash ./init-volumes.sh -f

build: init-volumes
	docker compose build

# Start the full stack (ensures network and builds agent first)
compose-up: build
	@echo "Starting stack with docker compose"
	docker compose up -d --remove-orphans

compose-down:
	docker compose down --remove-orphans

clean: compose-down
	@echo "Removing agent local image (if present)"
	-@docker image rm $(AGENT_IMAGE) || true