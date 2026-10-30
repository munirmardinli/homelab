---
nav: Repository
order: 2
---

# Repository

| Pfad                        | Rolle                                                                                                        |
| --------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `src/docker/*.yml`          | Compose-Projekte. Der Dateiname ohne Endung ist `--project-name`.                                            |
| `src/.config`               | Quellkonfiguration für `generate.sh`: `dashy.yml`, `traefik.yml`, `gitlab.rb`, `runner.toml`, `devices.yml`. |
| `src/icons`                 | Dashy-Icons, gemountet nach `/app/user-data/item-icons`.                                                     |
| `src/cli`                   | Deploy-Skripte. Sie setzen `ROOT` und laden sich gegenseitig.                                                |
| `src/docs/src/content`      | Diese Seiten als Markdown. `npm run build` kompiliert sie nach `public`.                                     |
| `.gitlab-ci.yml`            | Parent-Pipeline mit Stage `triggers`.                                                                        |
| `.gitlab/homelab.yml`       | Deploy auf den Docker-Host.                                                                                  |
| `.gitlab/documentation.yml` | GitLab Pages für diese Dokumentation.                                                                        |

## CLI

| Skript         | Aufgabe                                                                                                              |
| -------------- | -------------------------------------------------------------------------------------------------------------------- |
| `bitwarden.sh` | Installiert bei Bedarf `bws`, liest das Projekt `HomeLab` und schreibt das Env-File. `get NAME` gibt einen Wert aus. |
| `generate.sh`  | Legt `DOCKER_FOLDER_PATH` an, ergänzt fehlende Variablen und rendert nach `generated`.                               |
| `ssh.sh`       | `ssh_run` führt einen Befehl auf dem Host aus.                                                                       |
| `pull.sh`      | Aktualisiert das Git-Checkout auf dem Host.                                                                          |
| `compose.sh`   | Sammelt geänderte Compose-Dateien, stellt Traefik nach vorn, lädt hoch und listet.                                   |

## Parent-Pipeline

`homelab` startet bei Änderungen an `.gitlab/homelab.yml` oder `src/docker`. `documentation` startet bei `.gitlab/documentation.yml` oder `src/docs`. Beide nutzen `strategy: depend`.
