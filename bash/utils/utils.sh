#!/bin/zsh

LOGFILE="install.log"

# Colors
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

timestamp() {
  date +"%Y-%m-%d %H:%M:%S"
}

# --- Logging with simultaneous logfile output -------------------------------

log_write() {
  echo "[$(timestamp)] $1" >> "$LOGFILE"
}

ok() {
  echo -e "${GREEN}✔ $1${NC}"
  log_write "OK: $1"
}

info() {
  echo -e "${BLUE}ℹ $1${NC}"
  log_write "INFO: $1"
}

warn() {
  echo -e "${YELLOW}⚠ $1${NC}"
  log_write "WARN: $1"
}

err() {
  echo -e "${RED}❌ $1${NC}"
  log_write "ERROR: $1"
}

# --- Visual section header ---------------------------------------------------

section() {
  echo -e "${CYAN}${BOLD}"
  echo "──────────────────────────────────────────────"
  echo "  $1"
  echo "──────────────────────────────────────────────"
  echo -e "${NC}"
  log_write "SECTION: $1"
}

# --- Run-safe with error logging ---------------------------------------------

run_safe() {
  log_write "RUN: $1"
  if ! eval "$1"; then
    err "Error executing command: $1"
    exit 1
  fi
}

# --- Email validation --------------------------------------------------------

is_valid_email() {
  local email="$1"

  # Very good regex for standard emails
  if [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    return 0
  else
    return 1
  fi
}

ask_email() {
  while true; do
    read "email?Please enter your Git email address: "
    if is_valid_email "$email"; then
      ok "Email accepted: $email"
      log_write "VALID_EMAIL: $email"
      echo "$email"
      return 0
    else
      warn "Invalid email. Example: user@example.com"
    fi
  done
}
