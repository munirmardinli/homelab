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
# Detect OS
# -------------------------------------------------------

OS="$(uname -s)"
info "Detected OS: $OS"

case "$OS" in
  Darwin)
    info "Running macOS Setup..."
    run "$BASE/darwin/index.sh"
    ;;

  Linux)
    # Synology detected?
    if uname -a | grep -qi synology; then
      info "Running Synology Setup..."
      run "$BASE/synology/index.sh"
    else
      warn "Linux detected but no linux setup implemented."
    fi
    ;;

  MINGW*|MSYS*|CYGWIN*|Windows_NT)
    info "Running Windows Setup (PowerShell)..."
    pwsh "$BASE/index.ps1"
    ;;

  *)
    err "Unsupported OS: $OS"
    exit 1
    ;;
esac
