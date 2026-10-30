#!/usr/bin/env bash

[[ -n "${GENERATE_SSH_SH_LOADED:-}" ]] && return 0
GENERATE_SSH_SH_LOADED=1

set -euo pipefail

SSH_DIR="${HOME}/.ssh"
SSH_KEY="${SSH_DIR}/id_ed25519"
SSH_PUB="${SSH_KEY}.pub"

generate_ssh_reset_known_hosts() {
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"
  rm -f "$SSH_DIR/known_hosts" "$SSH_DIR/known_hosts.old"
  : > "$SSH_DIR/known_hosts"
  chmod 644 "$SSH_DIR/known_hosts"
  echo "ℹ️  ${SSH_DIR}/known_hosts reset (empty, newest entries stay on top)."
}

generate_ssh_key() {
  if [[ -f "$SSH_KEY" && -f "$SSH_PUB" ]]; then
    echo "ℹ️  SSH key already exists: ${SSH_KEY}"
    return 0
  fi
  echo "ℹ️  Creating SSH key without a password: ${SSH_KEY}"
  ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "${USER}@$(hostname -s 2>/dev/null || hostname)"
  chmod 600 "$SSH_KEY"
  chmod 644 "$SSH_PUB"
}

generate_ssh_show() {
  echo
  echo "----- ${SSH_PUB} -----"
  cat "$SSH_PUB"
  echo
  echo "----- ${SSH_DIR}/known_hosts -----"
  if [[ -s "$SSH_DIR/known_hosts" ]]; then
    cat "$SSH_DIR/known_hosts"
  else
    echo "(empty)"
  fi
  echo
  echo "----- ${SSH_DIR} -----"
  ls -la "$SSH_DIR"
}

generate_ssh_main() {
  generate_ssh_reset_known_hosts
  generate_ssh_key
  generate_ssh_show
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  generate_ssh_main "$@"
fi
