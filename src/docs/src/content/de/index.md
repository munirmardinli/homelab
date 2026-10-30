---
nav: Übersicht
order: 1
---

# Homelab Docker

Dieses Repository betreibt den Homelab als Docker-Compose-Stacks. GitLab CI liest Secrets aus Bitwarden Secrets Manager, erzeugt Laufzeitdateien, kopiert Compose-Dateien per SSH auf den Host und startet nur geänderte Stacks neu.

## Was das Repo leistet

- Ein Compose-File pro Dienst unter `src/docker`.
- Statische Konfiguration unter `src/.config` (Dashy, Traefik, GitLab Runner).
- Shell-CLI unter `src/cli` für Secrets, Generierung, SSH und Compose.
- Zwei Kind-Pipelines: Homelab-Deploy und diese Dokumentation auf GitLab Pages.

## Typischer Ablauf

1. Eine Compose-Datei auf dem Default-Branch ändern.
2. Die Parent-Pipeline startet `.gitlab/homelab.yml`, weil Dateien unter `src/docker` geändert wurden.
3. `bitwarden.sh` schreibt das Env-File, `generate.sh` füllt fehlende Schlüssel und rendert Konfiguration.
4. `pull.sh` aktualisiert das Checkout auf dem Host, `compose.sh upload` legt die Dateien ab.
5. Pro geänderter Datei: `docker compose stop`, `pull`, `up -d`.

## Sprache

Deutsch ist die Voreinstellung. DE und EN speichern die Wahl in `localStorage` unter `docs-lang`. Ohne gespeicherte Wahl bleibt Deutsch aktiv.
