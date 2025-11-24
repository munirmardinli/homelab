#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$BASH_DIR/utils/utils.sh"

ENV_FILE=".env"

### 📌 Load .env if available
if [ -f "$ENV_FILE" ]; then
  info "Loading configuration from .env ..."
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  warn ".env not found — using fallback values or input."
fi

### 📌 Defaults + Environment Override
SYNO_USER="${SYNO_USER}"
SYNO_HOST="${SYNO_HOST}"
SYNO_PORT="${SYNO_PORT}"

### 📌 Load password or prompt for input (skip if SSH-Key Modus aktiv)
PROMPT_FOR_PASSWORD="true"
if [ -n "${SYNOLOGY_USE_SSH_KEY:-}" ]; then
  PROMPT_FOR_PASSWORD="false"
fi

if [ -z "$SYNO_PASS" ] && [ "$PROMPT_FOR_PASSWORD" = "true" ]; then
  read -s "SYNO_PASS?🔑 Password: "
  echo ""
fi

if [ -n "${SYNOLOGY_LOGIN_SOURCE_ONLY:-}" ]; then
  return 0 2>/dev/null
fi

info "🔐 Synology SSH Login"
echo "👤 Username: $SYNO_USER"
echo "🌐 Hostname or IP: $SYNO_HOST"
echo "🔌 SSH Port: $SYNO_PORT"
echo "🔑 Password: ******"

SSH_CMD="ssh $SYNO_USER@$SYNO_HOST -p $SYNO_PORT"

info "Connecting to Synology: $SSH_CMD ..."

if command -v sshpass >/dev/null 2>&1 && [ -n "${SYNO_PASS:-}" ]; then
  info "Using sshpass with password authentication."
  sshpass -p "$SYNO_PASS" ssh \
    -o StrictHostKeyChecking=no \
    -p "$SYNO_PORT" "$SYNO_USER@$SYNO_HOST"
  ssh_status=$?
else
  info "Falling back to SSH key authentication (password not supplied or sshpass missing)."
  ssh \
    -o StrictHostKeyChecking=no \
    -p "$SYNO_PORT" "$SYNO_USER@$SYNO_HOST"
  ssh_status=$?
fi

if [ $ssh_status -eq 0 ]; then
  ok "SSH connection successful!"
else
  err "SSH connection failed."
fi
