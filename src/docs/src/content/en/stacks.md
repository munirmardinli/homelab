---
nav: Stacks
order: 5
---

# Stacks

Each file in `src/docker` is a stack. Most services join the `frontend` network, set `restart`, and carry `com.centurylinklabs.watchtower.enable: true`. Hostnames use `${PRIVATE_DOMAIN}`.

| File                | Service                                           | Group      |
| ------------------- | ------------------------------------------------- | ---------- |
| `traefik.yml`       | Reverse proxy. Deployed before the other stacks.  | management |
| `adguard.yml`       | AdGuard Home for DNS.                             | dns        |
| `dashy.yml`         | Start page, icons, and the generated `dashy.yml`. | management |
| `dashboard.yml`     | Second dashboard.                                 | management |
| `gitlab.yml`        | GitLab, config from `gitlab.rb`.                  | management |
| `runner.yml`        | GitLab Runner, config from `runner.toml`.         | management |
| `watchtower.yml`    | Image updates for containers that opt in.         | monitoring |
| `uptime.yml`        | Uptime Kuma.                                      | monitoring |
| `homeassistant.yml` | Home Assistant, notes in `devices.yml`.           | monitoring |
| `artcraft.yml`      | ArtCraft.                                         | monitoring |
| `openwebui.yml`     | Open WebUI.                                       | webui      |
| `codeserver.yml`    | code-server.                                      | writing    |
| `obsidian.yml`      | Obsidian.                                         | writing    |
| `renovate.yml`      | Renovate.                                         | homelab    |

## Add a stack

1. Add `src/docker/<name>.yml` with `name`, the service, the `frontend` network, and the shared labels.
2. Store new `${VARIABLES}` in the Bitwarden project `HomeLab`.
3. Mount data under `$DOCKER_FOLDER_PATH/<name>`.
4. Commit on the default branch. Deploy covers only that file, unless the run is manual and `COMPOSE_STACKS` is empty.

## Dashy content

The start page comes from `src/.config/dashy.yml`. A new link needs an entry there and, optionally, an image under `src/icons`. The rendered file reaches the host on the next generate and Dashy deploy.
