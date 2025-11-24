#!/bin/zsh

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$BASH_DIR/utils/utils.sh"

SECRET_FILE="$SCRIPT_DIR/secret.txt"
TARGET_KEY_PATH="${SYNOLOGY_SSH_KEY_PATH:-$HOME/.ssh/id_ed25519_synology}"
TARGET_DIR="$(dirname "$TARGET_KEY_PATH")"
FORCE_REIMPORT="${FORCE_SSH_KEY_IMPORT:-false}"

info "🔑 Importiere Synology-SSH-Key nach $TARGET_KEY_PATH ..."
info "Verwende Quelle: $SECRET_FILE"

if [ ! -f "$SECRET_FILE" ]; then
  err "secret.txt fehlt. Bitte füge deinen privaten Schlüssel unter $SECRET_FILE ein."
  exit 1
fi

if ! grep -q "BEGIN OPENSSH PRIVATE KEY" "$SECRET_FILE"; then
  err "secret.txt scheint keinen gültigen OpenSSH-Schlüssel zu enthalten."
  exit 1
fi

if [ -f "$TARGET_KEY_PATH" ] && [ "$FORCE_REIMPORT" != "true" ]; then
  ok "SSH-Key existiert bereits unter $TARGET_KEY_PATH (Setze FORCE_SSH_KEY_IMPORT=true um zu überschreiben)."
  exit 0
fi

mkdir -p "$TARGET_DIR"

umask 177
cp "$SECRET_FILE" "$TARGET_KEY_PATH"
chmod 600 "$TARGET_KEY_PATH"

PUBLIC_KEY_PATH="${TARGET_KEY_PATH}.pub"
if command -v ssh-keygen >/dev/null 2>&1; then
  ssh-keygen -y -f "$TARGET_KEY_PATH" > "$PUBLIC_KEY_PATH"
  chmod 644 "$PUBLIC_KEY_PATH"
  ok "Öffentlicher Schlüssel gespeichert unter $PUBLIC_KEY_PATH"
else
  warn "ssh-keygen nicht gefunden – öffentlicher Schlüssel wurde nicht generiert."
fi

if command -v ssh-add >/dev/null 2>&1; then
  if ssh-add -l | grep -q "$TARGET_KEY_PATH" 2>/dev/null; then
    info "Schlüssel ist bereits im SSH-Agenten geladen."
  else
    ssh-add "$TARGET_KEY_PATH" && ok "Schlüssel in SSH-Agent geladen."
  fi
else
  warn "ssh-add nicht gefunden – Schlüssel wurde nicht in den Agent geladen."
fi

ok "SSH-Key-Import abgeschlossen."
