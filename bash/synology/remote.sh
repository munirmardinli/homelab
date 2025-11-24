#!/bin/zsh

set -e
set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$BASH_DIR/utils/utils.sh"

REMOTE_SCRIPT_PATH="${1:-}"
DEFAULT_REMOTE_SCRIPT="$SCRIPT_DIR/cli.sh"
DEFAULT_KEY_PATH="$HOME/.ssh/id_ed25519_synology"
SSH_KEY_PATH="${SYNOLOGY_SSH_KEY_PATH:-$DEFAULT_KEY_PATH}"
USE_SSH_KEY=false

# -----------------------------------------------------------------------------
# SSH Key Check
# -----------------------------------------------------------------------------
if [ -f "$SSH_KEY_PATH" ]; then
  USE_SSH_KEY=true
  info "🔑 SSH-Key gefunden – Passwort wird nicht benötigt."
else
  info "🔑 Kein SSH-Key – verwende sshpass + Passwort."
  if ! command -v sshpass >/dev/null 2>&1; then
    err "sshpass fehlt. Installiere es: brew install hudochenkov/sshpass/sshpass"
    exit 1
  fi
fi

# -----------------------------------------------------------------------------
# Login-Daten laden
# -----------------------------------------------------------------------------
info "🔐 Lade Logindaten ..."
export SYNOLOGY_LOGIN_SOURCE_ONLY=1
source "$SCRIPT_DIR/login.sh"
unset SYNOLOGY_LOGIN_SOURCE_ONLY

SSH_TARGET="$SYNO_USER@$SYNO_HOST"
SSH_BASE_ARGS=(-o StrictHostKeyChecking=no -p "$SYNO_PORT" "$SSH_TARGET")

# -----------------------------------------------------------------------------
# Script-Pfad normalisieren
# -----------------------------------------------------------------------------
if [ -z "$REMOTE_SCRIPT_PATH" ]; then
  REMOTE_SCRIPT_PATH="$DEFAULT_REMOTE_SCRIPT"
fi

if [[ "$REMOTE_SCRIPT_PATH" != /* ]]; then
  REMOTE_SCRIPT_PATH="$(cd "$(dirname "$REMOTE_SCRIPT_PATH")" && pwd)/$(basename "$REMOTE_SCRIPT_PATH")"
fi

# -----------------------------------------------------------------------------
# Upload + Sudo Execution
# -----------------------------------------------------------------------------
info "📄 Sende $(basename "$REMOTE_SCRIPT_PATH") zur Ausführung (mit sudo -i nach Login) ..."

if [ "$USE_SSH_KEY" = true ]; then

  ssh -i "$SSH_KEY_PATH" "${SSH_BASE_ARGS[@]}" "sudo -i bash -s" < "$REMOTE_SCRIPT_PATH"
  remote_exit=$?

else

  sshpass -p "$SYNO_PASS" ssh "${SSH_BASE_ARGS[@]}" \
    "sudo -S -i bash -s" <<< "$SYNO_PASS" < "$REMOTE_SCRIPT_PATH"

  remote_exit=$?
fi

# -----------------------------------------------------------------------------
# Rückmeldung
# -----------------------------------------------------------------------------
if [ "$remote_exit" -eq 0 ]; then
  ok "Remote-Skript erfolgreich ausgeführt (als root)."
else
  err "Remote-Skript fehlgeschlagen (Exit $remote_exit)."
  exit "$remote_exit"
fi
