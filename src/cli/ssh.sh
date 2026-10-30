#!/usr/bin/env bash

[[ -n "${SSH_SH_LOADED:-}" ]] && return 0
SSH_SH_LOADED=1

set -euo pipefail

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bitwarden.sh
source "$CLI_DIR/bitwarden.sh"

_ssh_prompt() {
  local label="$1" secret="${2:-0}" value=""
  if ! _bw_tty; then
    echo "❌ ${label} is missing in DOCKER_FOLDER_PATH/generated/bw." >&2
    return 1
  fi
  printf '%s: ' "$label" >/dev/tty
  if [[ "$secret" == 1 ]]; then
    IFS= read -rs value </dev/tty || return 1
    printf '\n' >/dev/tty
  else
    IFS= read -r value </dev/tty || return 1
  fi
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  if [[ -z "$value" ]]; then
    echo "❌ ${label} is empty" >&2
    return 1
  fi
  printf '%s' "$value"
}

ssh_prepare_local() {
  local key value deploy
  if [[ ! -f "$BW_FILE" ]]; then
    echo "ℹ️  DOCKER_FOLDER_PATH/generated/bw does not exist yet." >&2
    bw_write || return 1
  fi
  for key in HOMELAB_IP_PREFIX HOMELAB_PROXY_HOST HOMELAB_PROXY_SSH_USER HOMELAB_PROXY__SSH_PORT HOMELAB_PROXY_SSH_PASSWORD IMAC_REPO_DIR; do
    value="$(bw_val "$key")"
    [[ -n "$value" ]] && continue
    echo "ℹ️  ${key} is missing in DOCKER_FOLDER_PATH/generated/bw." >&2
    if [[ "$key" == HOMELAB_PROXY_SSH_PASSWORD ]]; then
      value="$(_ssh_prompt "$key" 1)" || return 1
    else
      value="$(_ssh_prompt "$key")" || return 1
    fi
    bw_upsert "$key" "$value"
  done
  deploy="$(bw_val IMAC_REPO_DIR)"
  if [[ "$deploy" != /* ]]; then
    echo "❌ IMAC_REPO_DIR must be an absolute path on the iMac." >&2
    return 1
  fi
}

ssh_load() {
  ssh_prepare_local || return 1

  HOMELAB_IP_PREFIX="$(bw_val HOMELAB_IP_PREFIX)"
  HOMELAB_PROXY_HOST="$(bw_val HOMELAB_PROXY_HOST)"
  HOMELAB_PROXY_SSH_USER="$(bw_val HOMELAB_PROXY_SSH_USER)"
  HOMELAB_PROXY__SSH_PORT="$(bw_val HOMELAB_PROXY__SSH_PORT)"
  HOMELAB_PROXY_SSH_PASSWORD="$(bw_val HOMELAB_PROXY_SSH_PASSWORD)"
  DEPLOY_DIR="$(bw_val IMAC_REPO_DIR)"

  if [[ -z "$HOMELAB_IP_PREFIX" || -z "$HOMELAB_PROXY_HOST" || -z "$HOMELAB_PROXY_SSH_USER" || -z "$HOMELAB_PROXY__SSH_PORT" || -z "$HOMELAB_PROXY_SSH_PASSWORD" || -z "$DEPLOY_DIR" ]]; then
    echo "❌ SSH data in DOCKER_FOLDER_PATH/generated/bw is incomplete." >&2
    return 1
  fi

  SSH_HOST="${HOMELAB_IP_PREFIX}.${HOMELAB_PROXY_HOST}"
  SSH_TARGET="${HOMELAB_PROXY_SSH_USER}@${SSH_HOST}"
  export HOMELAB_IP_PREFIX HOMELAB_PROXY_HOST HOMELAB_PROXY_SSH_USER HOMELAB_PROXY__SSH_PORT HOMELAB_PROXY_SSH_PASSWORD DEPLOY_DIR SSH_HOST SSH_TARGET
  ssh_pin_docker_folder
}

ssh_pin_docker_folder() {
  local folder
  folder="$(bw_val DOCKER_FOLDER_PATH)"
  [[ -n "$folder" ]] || return 0
  if [[ "$folder" != /* ]]; then
    folder="${DEPLOY_DIR}/${folder#./}"
    bw_upsert DOCKER_FOLDER_PATH "$folder"
  fi
}

ssh_exec() {
  if ! command -v sshpass >/dev/null 2>&1; then
    echo "❌ sshpass not found." >&2
    return 1
  fi
  SSHPASS="$HOMELAB_PROXY_SSH_PASSWORD" sshpass -e ssh \
    -o StrictHostKeyChecking=accept-new \
    -o PreferredAuthentications=keyboard-interactive,password \
    -o NumberOfPasswordPrompts=1 \
    -p "$HOMELAB_PROXY__SSH_PORT" \
    "$SSH_TARGET" \
    "$@"
}

ssh_run() {
  local arg script
  ssh_load || return 1
  if [[ $# -eq 0 ]]; then
    echo "Usage: bash src/cli/ssh.sh ssh_run <command> [args...]" >&2
    return 2
  fi
  script="export PATH=/Applications/Docker.app/Contents/Resources/bin:/opt/homebrew/bin:/usr/local/bin:\$PATH"
  script+="; security unlock-keychain -p $(printf %q "$HOMELAB_PROXY_SSH_PASSWORD") \"\$HOME/Library/Keychains/login.keychain-db\" >/dev/null 2>&1 || true"
  script+="; mkdir -p $(printf %q "$DEPLOY_DIR")"
  script+="; cd $(printf %q "$DEPLOY_DIR") || exit 1"
  script+=" &&"
  if [[ $# -eq 1 ]]; then
    script+=" $1"
  else
    for arg in "$@"; do
      script+=" $(printf %q "$arg")"
    done
  fi
  echo "🔌 ${SSH_TARGET} port ${HOMELAB_PROXY__SSH_PORT}"
  ssh_exec "bash -lc $(printf %q "$script")"
}

ssh_main() {
  case "${1:-}" in
    ssh_run)
      shift
      ssh_run "$@"
      ;;
    "")
      ssh_run "echo logged-in && ls -la"
      ;;
    *)
      ssh_run "$@"
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  ssh_main "$@"
fi
