#!/usr/bin/env bash
# GitHub visibility + secret-scanning alerts. Never prints secret values.

github_scan() {
  local user status vis full
  SEC_SCOPE=github
  SEC_RAN_GITHUB=1

  sec_log ""
  sec_log "=== GitHub ==="

  user="$(env_val GHCR_USERNAME)"
  if [[ -z "$user" ]]; then
    sec_warn "GitHub" "GHCR_USERNAME is missing in Bitwarden"
    return 0
  fi
  if [[ ! "$user" =~ ^[A-Za-z0-9-]+$ ]]; then
    sec_warn "GitHub" "GHCR_USERNAME in Bitwarden is invalid"
    return 0
  fi

  if ! command -v gh >/dev/null; then
    sec_warn "GitHub" "gh CLI missing"
    return 0
  fi
  if ! gh auth status -h github.com >/dev/null 2>&1; then
    sec_warn "GitHub" "not logged in (gh auth login)"
    return 0
  fi

  gh api user --jq '{login,public_repos}' >"$LOG_DIR/github-user.json" 2>/dev/null || true
  gh api --paginate "users/${user}/repos?type=owner&per_page=100" \
    --jq '.[] | [.full_name, (.private|tostring), .visibility, .html_url] | @tsv' \
    >"$GITHUB_TSV" 2>/dev/null || true

  if [[ ! -s "$GITHUB_TSV" ]]; then
    sec_warn "GitHub" "could not list owned repos"
    return 0
  fi

  while IFS=$'\t' read -r full priv vis url; do
    if [[ "$priv" == "true" ]]; then
      status="$(curl -sS -o /dev/null -w '%{http_code}' \
        -H 'Accept: application/vnd.github+json' \
        -H 'User-Agent: homelab-security-scan' \
        "https://api.github.com/repos/${full}" || echo 000)"
      if [[ "$status" == "200" ]]; then
        sec_hit "Private repo public" "$full unauthenticated HTTP 200"
      else
        sec_ok "Private repo" "$full not reachable without login (HTTP $status)"
      fi
    else
      sec_info "Public repo" "$full $url"
    fi
    sec="$(gh api "repos/${full}/secret-scanning/alerts?state=open&per_page=5" --jq 'length' 2>/dev/null || echo x)"
    if [[ "$sec" == "0" ]]; then
      sec_ok "Secret scanning $full" "0 open alerts"
    elif [[ "$sec" =~ ^[0-9]+$ ]]; then
      sec_hit "Secret scanning $full" "$sec open alert(s) — rotate, values not printed"
    fi
  done <"$GITHUB_TSV"
}
