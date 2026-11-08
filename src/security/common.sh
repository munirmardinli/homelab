#!/usr/bin/env bash
# Shared helpers for src/security/*.sh — English logs, no secret values.

[[ -n "${SEC_COMMON_LOADED:-}" ]] && return 0
SEC_COMMON_LOADED=1

SEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SEC_DIR/../.." && pwd)"
# shellcheck source=../cli/bitwarden.sh
source "$SEC_DIR/../cli/bitwarden.sh"
# shellcheck source=../bash/paths.sh
source "$ROOT_DIR/src/bash/paths.sh"
SETUP_PATHS_FILE="$ROOT_DIR/src/.config/bash/paths.json"
SETUP_ROOT="$(setup_root_from_paths)" || return 1
HOMELAB_WORKSPACE="$(setup_path_value HOMELAB_WORKSPACE)" || return 1
export SETUP_ROOT
export HOMELAB_WORKSPACE
LOG_DIR="$SETUP_ROOT/assets/logs/security"
HTML_DIR="$SETUP_ROOT/assets/cli/reports"
HTML_HOST="$HTML_DIR/host.html"
HTML_GITHUB="$HTML_DIR/github.html"
HTML_VIRUS="$HTML_DIR/virus.html"
HTML_GITLEAKS="$HTML_DIR/gitleaks.html"
HOST_CHECKS="$LOG_DIR/host-checks.tsv"
GITHUB_CHECKS="$LOG_DIR/github-checks.tsv"
VIRUS_CHECKS="$LOG_DIR/virus-checks.tsv"
GITLEAKS_CHECKS="$LOG_DIR/gitleaks-checks.tsv"
HITS="$LOG_DIR/virus-hits.tsv"
AGENTS="$LOG_DIR/virus-agents.tsv"
NMAP_TSV="$LOG_DIR/nmap-open.tsv"
DOCKER_TSV="$LOG_DIR/docker-binds.tsv"
GITHUB_TSV="$LOG_DIR/github.tsv"
GITLEAKS_TSV="$LOG_DIR/gitleaks-findings.tsv"
TARGETS_FILE="$LOG_DIR/virus-targets.txt"
TEXT_LOG="$LOG_DIR/security-report.log"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export SETUP_ROOT

sec_init() {
  mkdir -p "$LOG_DIR" "$HTML_DIR"
  : >"$HOST_CHECKS"
  : >"$GITHUB_CHECKS"
  : >"$VIRUS_CHECKS"
  : >"$GITLEAKS_CHECKS"
  : >"$HITS"
  : >"$AGENTS"
  : >"$NMAP_TSV"
  : >"$DOCKER_TSV"
  : >"$GITHUB_TSV"
  : >"$GITLEAKS_TSV"
  : >"$TARGETS_FILE"
  : >"$TEXT_LOG"
  SEC_READY=1
  SEC_OK=0
  SEC_WARN=0
  SEC_HIT=0
  SEC_RAN_HOST=0
  SEC_RAN_GITHUB=0
  SEC_RAN_VIRUS=0
  SEC_RAN_GITLEAKS=0
  SEC_SCOPE=
  if [[ ! -s "$BW_FILE" ]]; then
    if [[ -n "${BWS_ACCESS_TOKEN:-}" ]]; then
      bw_write || echo "⚠️  Bitwarden secrets not loaded." >&2
    else
      echo "⚠️  Bitwarden secrets not loaded." >&2
    fi
  fi
}

env_val() {
  bw_val "$1"
}

sec_log() { printf '%s\n' "$*" | tee -a "$TEXT_LOG"; }

sec_checks_file() {
  case "${SEC_SCOPE:-}" in
    github) printf '%s' "$GITHUB_CHECKS" ;;
    virus) printf '%s' "$VIRUS_CHECKS" ;;
    gitleaks) printf '%s' "$GITLEAKS_CHECKS" ;;
    *) printf '%s' "$HOST_CHECKS" ;;
  esac
}

sec_ok() {
  SEC_OK=$((SEC_OK + 1))
  sec_log "[ok]   $1 — $2"
  printf 'ok\t%s\t%s\n' "$1" "$2" >>"$(sec_checks_file)"
}

sec_warn() {
  SEC_WARN=$((SEC_WARN + 1))
  sec_log "[warn] $1 — $2"
  printf 'warn\t%s\t%s\n' "$1" "$2" >>"$(sec_checks_file)"
}

sec_hit() {
  SEC_HIT=$((SEC_HIT + 1))
  sec_log "[hit]  $1 — $2"
  printf 'danger\t%s\t%s\n' "$1" "$2" >>"$(sec_checks_file)"
}

sec_info() {
  sec_log "[info] $1 — $2"
  printf 'info\t%s\t%s\n' "$1" "$2" >>"$(sec_checks_file)"
}
