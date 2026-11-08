#!/usr/bin/env bash
# Security module: host + github + virus + gitleaks → separate html/*.html files

SEC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_source_sec() {
  local file="$SEC_DIR/$1"
  if [[ ! -r "$file" ]]; then
    echo "missing: $file" >&2
    return 1
  fi
  # shellcheck disable=SC1090
  source "$file"
}

_source_sec common.sh
_source_sec host.sh
_source_sec github.sh
_source_sec virus.sh
_source_sec gitleaks.sh
_source_sec report.sh
unset -f _source_sec

security_usage() {
  cat <<'EOF'
Usage: bash src/security/index.sh [virus|host|host-harden|github|gitleaks]
       make security [SECURITY_COMMAND=virus|host|host-harden|github|gitleaks]
       make security-virus SCAN_ROOT=/path/to/scan

  (default)  host + github + virus + gitleaks → assets/cli/reports/*.html
  virus      ClamAV / LoveLetter / Trojans → assets/cli/reports/virus.html
  host       firewall, nmap, Docker → assets/cli/reports/host.html
  host-harden  enable macOS firewall and stealth mode (asks for confirmation)
  github     repo visibility → assets/cli/reports/github.html
  gitleaks   secret scan (no values) → assets/cli/reports/gitleaks.html

Opens the matching file(s) in assets/cli/reports/ when done.
EOF
}

security_main() {
  local cmd="${1:-all}"
  shift || true
  set +e

  case "$cmd" in
    -h|--help|help)
      security_usage
      return 0
      ;;
  esac

  sec_init
  sec_log "=== Security ==="
  sec_log "Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"

  case "$cmd" in
    all|"")
      host_scan
      github_scan
      virus_main "$@"
      gitleaks_scan
      ;;
    virus)
      virus_main "$@"
      ;;
    host)
      host_scan
      ;;
    host-harden)
      host_harden || return $?
      ;;
    github)
      github_scan
      ;;
    gitleaks)
      gitleaks_scan
      ;;
    *)
      echo "unknown security command: $cmd" >&2
      security_usage
      return 1
      ;;
  esac

  sec_write_reports
  sec_log "OK=$SEC_OK  WARN=$SEC_WARN  HITS=$SEC_HIT"
  if [[ "${SEC_HIT:-0}" -gt 0 ]]; then
    return 1
  fi
  return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  security_main "$@"
fi
