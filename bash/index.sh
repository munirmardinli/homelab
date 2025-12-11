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

# -------------------------------------------------------
# Run Darwin and Synology sequentially, remove Windows
# -------------------------------------------------------

info "Running macOS Setup..."
run "$BASE/darwin/index.sh"

info "Running Synology Setup..."
run "$BASE/synology/index.sh"

ok "Setup completed successfully."
