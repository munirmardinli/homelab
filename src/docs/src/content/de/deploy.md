---
nav: Deploy
order: 4
---

# Deploy

`deploy:compose` in `.gitlab/homelab.yml` läuft auf `debian:bookworm-slim` mit `resource_group: compose-deploy` und 45 Minuten Timeout. `GIT_DEPTH` ist 0, damit der Diff die geänderten Compose-Dateien bestimmt.

## Wann der Job startet

- Auf dem Default-Branch, wenn Compose-Dateien geändert wurden.
- Bei einem manuellen Lauf (`CI_PIPELINE_SOURCE == web`). Ohne `COMPOSE_STACKS` nimmt `compose.sh` alle Dateien unter `src/docker`.

## Schritte

1. Pakete installieren: bash, curl, git, openssh-client, python3, sshpass.
2. `bitwarden.sh` und `generate.sh`.
3. `DOCKER_FOLDER_PATH` per `bitwarden.sh get` lesen.
4. `ssh.sh ssh_run` startet `pull.sh` auf dem Host.
5. `compose.sh upload` und `compose.sh list`.
6. Pro Datei: `stop`, `pull`, `up -d` mit `--env-file "$DOCKER_FOLDER_PATH/generated/bw"`.

## Reihenfolge und Auswahl

Traefik kommt zuerst, weil das Netz `frontend` extern ist. `COMPOSE_STACKS` begrenzt einen Web-Lauf, zum Beispiel `dashy traefik`.

## Pages

Änderungen unter `src/docs` starten `.gitlab/documentation.yml`. Der Job `pages` führt `npm run build` aus und veröffentlicht `src/docs/public`.
