---
nav: Secrets and generate
order: 3
---

# Secrets and generate

Compose files do not store plaintext passwords. Placeholders such as `${PRIVATE_DOMAIN}` and `${DOCKER_FOLDER_PATH}` come from an env file at runtime.

## Bitwarden Secrets Manager

CI sets `BWS_ACCESS_TOKEN`. `bitwarden.sh` reads the `HomeLab` project (`BWS_PROJECT`) and writes secrets to `data/generated/bw`, then to `$DOCKER_FOLDER_PATH/generated/bw` on the host.

`DOCKER_FOLDER_PATH` may be relative to `IMAC_REPO_DIR` or already be an absolute host directory. The scripts resolve relative values at runtime without changing the Bitwarden value. If it is missing, `generate.sh` stops. Compose uses `${DOCKER_FOLDER_PATH?:Error - DOCKER_FOLDER_PATH is missing in Bitwarden}`.

## Missing keys

`generate_missing_keys` scans rendered templates in `src/.config` and Compose files in `src/docker` for `${NAME}`. Shell and editor configuration files are not treated as templates. Names containing `PASSWORD`, `TOKEN`, `SECRET`, `HASH`, `KEY`, or `API` are treated as secrets.

## On the host

- `$DOCKER_FOLDER_PATH/generated/bw` is the env file for `docker compose --env-file`.
- `$DOCKER_FOLDER_PATH/generated/dashy.yml` is mounted as `/app/user-data/conf.yml`.
- Service directories such as `$DOCKER_FOLDER_PATH/dashy` hold persistent data.

The env file and tokens do not belong in git.
