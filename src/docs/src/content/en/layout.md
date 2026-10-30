---
nav: Repository
order: 2
---

# Repository

| Path                        | Role                                                                                                           |
| --------------------------- | -------------------------------------------------------------------------------------------------------------- |
| `src/docker/*.yml`          | Compose projects. The file stem is `--project-name`.                                                           |
| `src/.config`               | Source configuration for `generate.sh`: `dashy.yml`, `traefik.yml`, `gitlab.rb`, `runner.toml`, `devices.yml`. |
| `src/icons`                 | Dashy icons, mounted at `/app/user-data/item-icons`.                                                           |
| `src/cli`                   | Deploy scripts. They set `ROOT` and source each other.                                                         |
| `src/docs/src/content`      | These pages as Markdown. `npm run build` compiles them into `public`.                                          |
| `.gitlab-ci.yml`            | Parent pipeline with the `triggers` stage.                                                                     |
| `.gitlab/homelab.yml`       | Deploy onto the Docker host.                                                                                   |
| `.gitlab/documentation.yml` | GitLab Pages for this documentation.                                                                           |

## CLI

| Script         | Job                                                                                                            |
| -------------- | -------------------------------------------------------------------------------------------------------------- |
| `bitwarden.sh` | Installs `bws` when needed, reads the `HomeLab` project, and writes the env file. `get NAME` prints one value. |
| `generate.sh`  | Creates `DOCKER_FOLDER_PATH`, fills missing variables, and renders into `generated`.                           |
| `ssh.sh`       | `ssh_run` runs a command on the host.                                                                          |
| `pull.sh`      | Updates the git checkout on the host.                                                                          |
| `compose.sh`   | Collects changed Compose files, orders Traefik first, uploads, and lists them.                                 |

## Parent pipeline

`homelab` starts when `.gitlab/homelab.yml` or `src/docker` changes. `documentation` starts when `.gitlab/documentation.yml` or `src/docs` changes. Both use `strategy: depend`.
