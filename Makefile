ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SHELL := /bin/bash
.DEFAULT_GOAL := help

export ROOT
export COMMAND
export BREW_ARGS
export ACTION
export SECURITY_COMMAND
export SECRET_KEY
export COMPOSE_STACKS
export IMAC_REPO_DIR
export DOCKER_STACK
export DOCKER_ARGS

.PHONY: help check paths zsh-install zsh-oh-my-zsh \
	bitwarden bitwarden-get generate ssh ssh-run ssh-key-setup \
	compose compose-list compose-upload docker deploy pull \
	settings settings-brew settings-git settings-tailscale settings-pull-schedule \
	security security-host security-host-harden security-github security-virus security-gitleaks

help:
	@printf '%s\n' \
	  'Homelab Make targets:' \
	  '  check                       Check shell syntax and JSON files' \
	  '  paths                       Print directories configured in paths.json' \
	  '  zsh-install                 Sync zsh, p10k and path config to your home directory' \
	  '  zsh-oh-my-zsh               Install Oh My Zsh (asks for confirmation)' \
	  '  bitwarden                   Fetch Bitwarden secrets into the local generated file' \
	  '  bitwarden-get SECRET_KEY=x  Print one value from the generated secrets file' \
	  '  generate                    Render and deploy generated configuration' \
	  '  ssh                         Connect and show the remote deployment directory' \
	  '  ssh-run COMMAND="..."       Run a command remotely via src/cli/ssh.sh ssh_run' \
	  '  ssh-key-setup               Reset known_hosts and create/show the local SSH key' \
	  '  compose [COMPOSE_STACKS=x]  SSH-deploy changed stacks, or the selected stack(s)' \
	  '  compose-list                List Compose stacks selected for deployment' \
	  '  compose-upload              Upload Compose/config files without deploying' \
	  '  docker DOCKER_STACK=x DOCKER_ARGS="up -d"  Run a Compose command for one stack' \
	  '  deploy                      Run the full CLI deployment sequence' \
	  '  pull                        Run pull.sh (may commit and push repository changes)' \
	  '  settings                    List settings targets' \
	  '  settings-brew [BREW_ARGS=...]  brewSetup: all, formulae, casks, or --list' \
	  '  settings-git                Set global Git identity from Bitwarden' \
	  '  settings-tailscale          Enable forwarding and advertise the configured routes' \
	  '  settings-pull-schedule [ACTION=status|install|remove|run]' \
	  '  security [SECURITY_COMMAND=all|virus|host|host-harden|github|gitleaks]' \
	  '  security-host|security-host-harden|security-github|security-virus|security-gitleaks'

check:
	@find . -type f -name '*.sh' -not -path './.git/*' -print | while IFS= read -r file; do bash -n "$$file" || exit; done
	@python3 -m json.tool src/.config/bash/paths.json >/dev/null
	@if command -v zsh >/dev/null 2>&1; then \
	  zsh -n src/.config/zsh && zsh -n src/.config/.p10k.zsh; \
	else \
	  echo 'zsh not installed; skipped Zsh syntax checks'; \
	fi
	@echo 'Shell and JSON checks passed.'

paths:
	@SETUP_PATHS_FILE="$$ROOT/src/.config/bash/paths.json" bash src/bash/paths.sh list

zsh-install:
	@bash -c 'source "$$ROOT/src/bash/setup.sh"; configSync zsh p10k paths'

zsh-oh-my-zsh:
	@command -v zsh >/dev/null 2>&1 || { echo 'zsh is required.' >&2; exit 127; }
	@zsh -c 'source "$$1"; ohMyZshSetup' zsh "$$ROOT/src/.config/zsh"

bitwarden:
	@bash src/cli/bitwarden.sh

bitwarden-get:
	@test -n "$$SECRET_KEY" || { echo 'Set SECRET_KEY, e.g. make bitwarden-get SECRET_KEY=EMAIL' >&2; exit 2; }
	@bash src/cli/bitwarden.sh get "$$SECRET_KEY"

generate:
	@bash src/cli/generate.sh

ssh:
	@bash src/cli/ssh.sh

ssh-run:
	@test -n "$$COMMAND" || { echo 'Set COMMAND, e.g. make ssh-run COMMAND="docker ps"' >&2; exit 2; }
	@bash src/cli/ssh.sh ssh_run "$$COMMAND"

ssh-key-setup:
	@bash src/cli/generateSSH.sh

compose:
	@bash src/cli/ssh.sh compose

compose-list:
	@bash src/cli/compose.sh list

compose-upload:
	@bash src/cli/ssh.sh compose upload

docker:
	@test -n "$$DOCKER_STACK" || { echo 'Set DOCKER_STACK, e.g. make docker DOCKER_STACK=dashboard DOCKER_ARGS="up -d"' >&2; exit 2; }
	@test -n "$$DOCKER_ARGS" || { echo 'Set DOCKER_ARGS, e.g. DOCKER_ARGS="up -d"' >&2; exit 2; }
	@bash src/cli/compose.sh docker

deploy:
	@bash src/cli/deploy.sh

pull:
	@bash pull.sh run

settings:
	@printf '%s\n' 'Settings targets: settings-brew settings-git settings-tailscale settings-pull-schedule'

settings-brew:
	@bash -c 'source "$$ROOT/src/settings/homebrew.sh"; brewSetup $${BREW_ARGS:-all}'

settings-git:
	@bash -c 'source "$$ROOT/src/bash/setup.sh"; source "$$ROOT/src/settings/git.sh"; gitSetup'

settings-tailscale:
	@bash src/settings/tailscale.sh

settings-pull-schedule:
	@bash src/settings/pullSchedule.sh "$${ACTION:-status}"

security:
	@bash src/security/index.sh "$${SECURITY_COMMAND:-all}"

security-host:
	@bash src/security/index.sh host

security-host-harden:
	@bash src/security/index.sh host-harden

security-github:
	@bash src/security/index.sh github

security-virus:
	@bash src/security/index.sh virus

security-gitleaks:
	@bash src/security/index.sh gitleaks
