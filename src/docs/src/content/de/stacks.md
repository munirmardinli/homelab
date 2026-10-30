---
nav: Stacks
order: 5
---

# Stacks

Jede Datei in `src/docker` ist ein Stack. Die meisten joinen das Netz `frontend`, setzen `restart` und das Label `com.centurylinklabs.watchtower.enable: true`. Hostnamen nutzen `${PRIVATE_DOMAIN}`.

| Datei               | Dienst                                              | Gruppe     |
| ------------------- | --------------------------------------------------- | ---------- |
| `traefik.yml`       | Reverse Proxy. Wird vor den anderen Stacks deployt. | management |
| `adguard.yml`       | AdGuard Home, DNS.                                  | dns        |
| `dashy.yml`         | Startseite, Icons und generierte `dashy.yml`.       | management |
| `dashboard.yml`     | Zweites Dashboard.                                  | management |
| `gitlab.yml`        | GitLab, Config aus `gitlab.rb`.                     | management |
| `runner.yml`        | GitLab Runner, Config aus `runner.toml`.            | management |
| `watchtower.yml`    | Image-Updates für opt-in Container.                 | monitoring |
| `uptime.yml`        | Uptime Kuma.                                        | monitoring |
| `homeassistant.yml` | Home Assistant, Hinweise in `devices.yml`.          | monitoring |
| `artcraft.yml`      | ArtCraft.                                           | monitoring |
| `openwebui.yml`     | Open WebUI.                                         | webui      |
| `codeserver.yml`    | code-server.                                        | writing    |
| `obsidian.yml`      | Obsidian.                                           | writing    |
| `renovate.yml`      | Renovate.                                           | homelab    |

## Neuen Stack anlegen

1. `src/docker/<name>.yml` mit `name`, Service, Netz `frontend` und den gemeinsamen Labels.
2. Neue `${VARIABLEN}` im Bitwarden-Projekt `HomeLab` hinterlegen.
3. Daten unter `$DOCKER_FOLDER_PATH/<name>` mounten.
4. Commit auf den Default-Branch. Deploy betrifft nur diese Datei, außer der Lauf ist manuell ohne `COMPOSE_STACKS`.

## Dashy-Inhalte

Die Startseite kommt aus `src/.config/dashy.yml`. Ein neuer Link braucht einen Eintrag dort und optional ein Bild unter `src/icons`. Die gerenderte Datei liegt nach dem nächsten Generate- und Dashy-Deploy auf dem Host.
