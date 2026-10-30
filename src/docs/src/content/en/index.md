---
nav: Overview
order: 1
---

# Homelab Docker

This repository runs the homelab as Docker Compose stacks. GitLab CI reads secrets from Bitwarden Secrets Manager, renders runtime files, copies Compose files over SSH, and recreates only the stacks that changed.

## What the repo does

- One Compose file per service under `src/docker`.
- Static configuration under `src/.config` (Dashy, Traefik, GitLab Runner).
- A shell CLI under `src/cli` for secrets, generation, SSH, and Compose.
- Two child pipelines: homelab deploy, and this documentation on GitLab Pages.

## Typical flow

1. Change a Compose file on the default branch.
2. The parent pipeline starts `.gitlab/homelab.yml` because files under `src/docker` changed.
3. `bitwarden.sh` writes the env file, and `generate.sh` fills missing keys and renders configuration.
4. `pull.sh` updates the checkout on the host, and `compose.sh upload` copies the files.
5. For each changed file: `docker compose stop`, `pull`, then `up -d`.

## Language

German is the default. DE and EN store the choice in `localStorage` under `docs-lang`. With no stored choice, German stays active.
