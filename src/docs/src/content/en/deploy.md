---
nav: Deploy
order: 4
---

# Deploy

`deploy:compose` in `.gitlab/homelab.yml` runs on `debian:bookworm-slim` with `resource_group: compose-deploy` and a 45-minute timeout. `GIT_DEPTH` is 0 so the diff selects the changed Compose files.

## When the job runs

- On the default branch when Compose files changed.
- On a manual run (`CI_PIPELINE_SOURCE == web`). Without `COMPOSE_STACKS`, `compose.sh` takes every file under `src/docker`.

## Steps

1. Install packages: bash, curl, git, openssh-client, python3, sshpass.
2. `bitwarden.sh` and `generate.sh`.
3. Read `DOCKER_FOLDER_PATH` with `bitwarden.sh get`.
4. `ssh.sh ssh_run` starts `pull.sh` on the host.
5. `compose.sh upload` and `compose.sh list`.
6. For each file: `stop`, `pull`, `up -d` with `--env-file "$DOCKER_FOLDER_PATH/generated/bw"`.

## Order and selection

Traefik comes first because the `frontend` network is external. `COMPOSE_STACKS` limits a web run, for example `dashy traefik`.

## Pages

Changes under `src/docs` start `.gitlab/documentation.yml`. The `pages` job runs `npm run build` and publishes `src/docs/public`.
