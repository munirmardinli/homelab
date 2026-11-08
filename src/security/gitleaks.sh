#!/usr/bin/env bash
# gitleaks on SCAN_ROOT git repos. Writes repo/file/rule/line only — never secret values.

gitleaks_scan() {
  local scan_root cfg label n repos

  [[ "${SEC_READY:-}" == 1 ]] || sec_init
  SEC_SCOPE=gitleaks
  SEC_RAN_GITLEAKS=1

  sec_log ""
  sec_log "=== gitleaks ==="

  : >"$GITLEAKS_TSV"
  scan_root="${SCAN_ROOT:-$(env_val SCAN_ROOT)}"
  scan_root="${scan_root:-$HOMELAB_WORKSPACE}"
  scan_root="${scan_root/#\~/$HOME}"

  if ! command -v gitleaks >/dev/null; then
    sec_warn "gitleaks" "not installed (brew install gitleaks)"
    return 0
  fi
  if [[ ! -d "$scan_root" ]]; then
    sec_warn "SCAN_ROOT" "missing: $scan_root"
    return 0
  fi

  cfg="$SEC_DIR/gitleaks.toml"
  repos=0
  for repo in "$scan_root" "$scan_root"/*; do
    [[ -d "$repo/.git" ]] || continue
    repos=$((repos + 1))
    label="$(basename "$repo")"
    sec_log "gitleaks: $label"
    if [[ -f "$cfg" ]]; then
      gitleaks detect --source "$repo" --config "$cfg" --report-format json \
        --report-path "$LOG_DIR/gitleaks-${label}.json" --no-banner --exit-code 0 \
        >/dev/null 2>"$LOG_DIR/gitleaks-${label}.stderr.log" || true
    else
      gitleaks detect --source "$repo" --report-format json \
        --report-path "$LOG_DIR/gitleaks-${label}.json" --no-banner --exit-code 0 \
        >/dev/null 2>"$LOG_DIR/gitleaks-${label}.stderr.log" || true
    fi
    n="$(python3 - "$LOG_DIR/gitleaks-${label}.json" "$label" "$GITLEAKS_TSV" <<'PY'
import json, sys
from pathlib import Path

src, repo, dest = Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3])
try:
    data = json.loads(src.read_text(encoding="utf-8") or "[]")
except Exception:
    data = []
if not isinstance(data, list):
    data = []
lines = []
for item in data:
    if not isinstance(item, dict):
        continue
    path = item.get("File") or item.get("file") or "?"
    line = item.get("StartLine") or item.get("line") or "?"
    rule = item.get("RuleID") or "leak"
    lines.append(f"{repo}\t{path}\t{rule}\t{line}")
if lines:
    with dest.open("a", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
print(len(lines))
PY
    )"
    n="${n:-0}"
    if [[ "$n" -gt 0 ]]; then
      sec_hit "gitleaks $label" "$n finding(s) — values redacted, rotate secrets"
    else
      sec_ok "gitleaks $label" "clean"
    fi
  done

  if [[ "$repos" -eq 0 ]]; then
    sec_warn "gitleaks" "no git repos under $scan_root"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # shellcheck source=common.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
  sec_init
  gitleaks_scan
  # shellcheck source=report.sh
  source "$SEC_DIR/report.sh"
  sec_write_reports
  if [[ "${SEC_HIT:-0}" -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi
