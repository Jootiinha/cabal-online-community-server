SHELL := /bin/bash

DOCKER_SCRIPT := scripts/docker-local.sh
DOCKER_ACTIONS := init build up down status logs logs-follow smoke-test create-local-account backup migrate test
LOCAL_ACTIONS := check-prerequisites db-init start-local stop-local integration-test restore-test
CLIENT_EXECUTABLE ?= .client/CabalMain.exe

.DEFAULT_GOAL := help

.PHONY: help start start-logs start-client build-local clean $(DOCKER_ACTIONS) $(LOCAL_ACTIONS)

help:
	@printf '%s\n' \
	  'Uso: make <alvo>' \
	  '' \
	  'Docker: init build up down status logs logs-follow smoke-test create-local-account backup migrate test' \
	  'Atalhos: start (up + smoke-test), start-logs, start-client' \
	  'WSL/nativo: check-prerequisites build-local db-init start-local stop-local integration-test restore-test clean' \
	  '' \
	  'start-client usa .client/CabalMain.exe; sobrescreva com CLIENT_EXECUTABLE=/caminho/para/CabalMain.exe.'

$(DOCKER_ACTIONS):
	bash $(DOCKER_SCRIPT) $@

start: up smoke-test

start-logs: start logs-follow

start-client: start create-local-account
	@test -f "$(CLIENT_EXECUTABLE)" || { echo "Cliente nao encontrado: $(CLIENT_EXECUTABLE)" >&2; exit 2; }
	@"$(CLIENT_EXECUTABLE)" >/dev/null 2>&1 &
	@echo "Cliente aberto: $(CLIENT_EXECUTABLE)"

build-local:
	bash scripts/build.sh

clean:
	@bash scripts/stop-local.sh 2>/dev/null || true
	@rm -rf backend/bin .runtime/bin .runtime/logs
	@rm -f .runtime/*.pid
	@echo 'Artefatos locais de build, logs e PIDs removidos.'

$(LOCAL_ACTIONS):
	bash scripts/$@.sh
