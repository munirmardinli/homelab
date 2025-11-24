#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/utils/utils.sh" ]; then
  source "$SCRIPT_DIR/utils/utils.sh"
else
  source "$(cd "$SCRIPT_DIR/.." && pwd)/utils/utils.sh"
fi

BASE="$SCRIPT_DIR"

run() {
  local script="$1"
  if [ -f "$script" ]; then
    info "Starting $(basename "$script") ..."
    chmod +x "$script"
    "$script"
  else
    err "Script missing: $script"
    exit 1
  fi
}

info "──────────────────────────────────────"
info "   🚀 MUNIR - Synology SETUP STARTING"
info "──────────────────────────────────────"

run "$BASE/remote.sh"

info "──────────────────────────────────────"
ok   "   MUNIR - Setup completed successfully! 🎉"
info "──────────────────────────────────────"
