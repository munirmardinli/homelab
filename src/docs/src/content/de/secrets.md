---
nav: Secrets und Generate
order: 3
---

# Secrets und Generate

Compose-Dateien enthalten keine Klartext-Passwörter. Platzhalter wie `${PRIVATE_DOMAIN}` und `${DOCKER_FOLDER_PATH}` kommen aus einem Env-File.

## Bitwarden Secrets Manager

CI setzt `BWS_ACCESS_TOKEN`. `bitwarden.sh` liest das Projekt `HomeLab` (`BWS_PROJECT`) und schreibt Secrets nach `data/generated/bw` und auf dem Host nach `$DOCKER_FOLDER_PATH/generated/bw`.

`DOCKER_FOLDER_PATH` ist ein absoluter Ordner auf dem Host. Fehlt er, bricht `generate.sh` ab. Compose nutzt `${DOCKER_FOLDER_PATH?:Error - DOCKER_FOLDER_PATH is missing in Bitwarden}`.

## Fehlende Schlüssel

`generate_missing_keys` sucht in `src/.config` und `src/docker` nach `${NAME}`. Namen mit `PASSWORD`, `TOKEN`, `SECRET`, `HASH`, `KEY` oder `API` gelten als geheim.

## Auf dem Host

- `$DOCKER_FOLDER_PATH/generated/bw` ist das Env-File für `docker compose --env-file`.
- `$DOCKER_FOLDER_PATH/generated/dashy.yml` wird als `/app/user-data/conf.yml` gemountet.
- Dienstordner wie `$DOCKER_FOLDER_PATH/dashy` halten persistente Daten.

Env-File und Tokens gehören nicht ins Git.
