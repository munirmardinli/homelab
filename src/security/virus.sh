#!/usr/bin/env bash

virus_main() {
  local scan_root user_agents n f path sig kind rc err target
  local love=0 trojan=0 worm=0 virus=0 ransom=0 pua=0 name_hits=0 agent_n=0 found=0
  local -a targets excludes

  [[ "${SEC_READY:-}" == 1 ]] || sec_init
  SEC_SCOPE=virus
  SEC_RAN_VIRUS=1

  scan_root="${IMAC_REPO_DIR:-$(env_val IMAC_REPO_DIR)}"
  scan_root="${scan_root:-$ROOT_DIR}"
  scan_root="${scan_root/#\~/$HOME}"

  targets=()
  if [[ $# -gt 0 ]]; then
    targets=("$@")
  else
    for d in "$scan_root" "$HOME/Downloads" "$HOME/Desktop" "$HOME/Documents" "$HOME/Applications"; do
      [[ -d "$d" ]] && targets+=("$d")
    done
  fi
  printf '%s ' "${targets[@]:-none}" >"$TARGETS_FILE"

  sec_log ""
  sec_log "=== Virus / Trojan / worm ==="
  sec_log "Targets: ${targets[*]:-none}"

  if command -v spctl >/dev/null; then
    gk="$(spctl --status 2>&1 || true)"
    if printf '%s' "$gk" | grep -qi disabled; then
      sec_warn "Gatekeeper" "$gk"
    else
      sec_ok "Gatekeeper" "$gk"
    fi
  fi
  if command -v csrutil >/dev/null; then
    sip="$(csrutil status 2>&1 || true)"
    if printf '%s' "$sip" | grep -qi disabled; then
      sec_warn "SIP" "$sip"
    else
      sec_ok "SIP" "$sip"
    fi
  fi
  if command -v fdesetup >/dev/null; then
    fv="$(fdesetup status 2>&1 || true)"
    if printf '%s' "$fv" | grep -qi 'off'; then
      sec_warn "FileVault" "$fv"
    else
      sec_ok "FileVault" "$fv"
    fi
  fi
  xp="/Library/Apple/System/Library/CoreServices/XProtect.bundle/Contents/version.plist"
  if [[ -f "$xp" ]]; then
    ver="$(defaults read "$xp" CFBundleShortVersionString 2>/dev/null || echo '?')"
    sec_ok "XProtect" "signature set $ver"
  fi

  name_hits=0
  if [[ ${#targets[@]} -gt 0 ]]; then
    while IFS= read -r -d '' f; do
      name_hits=$((name_hits + 1))
      sec_warn "Suspicious filename" "$f"
    done < <(
      find "${targets[@]}" \( \
        -iname '*iloveyou*' -o -iname '*loveletter*' -o \
        -iname '*love-letter*' -o -iname 'LOVE-LETTER-FOR-YOU*' \
      \) -type f -print0 2>/dev/null || true
    )
  fi
  if [[ "$name_hits" -eq 0 ]]; then
    sec_ok "LoveLetter filenames" "none"
  fi

  user_agents="$HOME/Library/LaunchAgents"
  : >"$AGENTS"
  if [[ -d "$user_agents" ]]; then
    while IFS= read -r -d '' p; do
      agent_n=$((agent_n + 1))
      printf '%s\n' "$p" >>"$AGENTS"
      sec_log "  LaunchAgent: $p"
    done < <(find "$user_agents" -maxdepth 1 -name '*.plist' -print0 2>/dev/null || true)
    if [[ "$agent_n" -eq 0 ]]; then
      sec_ok "LaunchAgents" "none"
    else
      sec_ok "LaunchAgents" "$agent_n user plist(s) — unknown ones: System Settings → Login Items"
    fi
  else
    sec_ok "LaunchAgents" "folder missing"
  fi

  if ! command -v clamscan >/dev/null; then
    sec_hit "ClamAV" "not installed (brew install clamav)"
    return 2
  fi

  local etc conf sample name
  for etc in /opt/homebrew/etc/clamav /usr/local/etc/clamav; do
    [[ -d "$etc" ]] || continue
    for name in freshclam.conf clamd.conf; do
      conf="$etc/$name"
      sample="$etc/${name}.sample"
      if [[ -f "$conf" ]]; then
        grep -q '^Example$' "$conf" 2>/dev/null && sed -i.bak 's/^Example$/# Example/' "$conf"
      elif [[ -f "$sample" ]]; then
        sed 's/^Example$/# Example/' "$sample" >"$conf"
      fi
    done
    break
  done

  if command -v freshclam >/dev/null; then
    if freshclam --quiet >>"$LOG_DIR/freshclam.log" 2>&1; then
      sec_ok "ClamAV signatures" "updated (viruses, Trojans, worms, LoveLetter, PUA)"
    else
      fc=$?
      if [[ "$fc" -eq 1 ]]; then
        sec_ok "ClamAV signatures" "already current"
      else
        sec_warn "freshclam" "exit $fc — using local DB"
      fi
    fi
  else
    sec_warn "freshclam" "not installed"
  fi

  if [[ ${#targets[@]} -eq 0 ]]; then
    sec_warn "Virus targets" "none — pass paths or set IMAC_REPO_DIR"
    return 0
  fi

  excludes=(
    --exclude-dir=node_modules --exclude-dir='\.git' --exclude-dir='\.next'
    --exclude-dir='\.obsidian' --exclude-dir='\.cache' --exclude-dir='\.cursor'
    --exclude-dir=dist --exclude-dir=build --exclude-dir=data
    --exclude-dir=__pycache__ --exclude-dir=vendor --exclude-dir=coverage
  )

  classify_hit() {
    local sig="$1" low
    low="$(printf '%s' "$sig" | tr '[:upper:]' '[:lower:]')"
    case "$low" in
      *loveletter* | *iloveyou* | *love-letter* | *vbs.love*) printf 'LoveLetter' ;;
      *trojan* | *backdoor* | *rat.*) printf 'Trojan' ;;
      *worm*) printf 'Worm' ;;
      *ransom*) printf 'Ransomware' ;;
      *adware* | *pup.* | *pua.*) printf 'PUA' ;;
      *virus*) printf 'Virus' ;;
      *) printf 'Malware' ;;
    esac
  }

  : >"$HITS"
  : >"$LOG_DIR/virus-clamscan.log"
  for target in "${targets[@]}"; do
    [[ -e "$target" ]] || { sec_warn "Missing path" "$target"; continue; }
    sec_log "Scan: $target"
    set +e
    clamscan -r --stdout --detect-pua=yes \
      --max-filesize=20M --max-scansize=40M --max-files=80000 \
      "${excludes[@]}" \
      "$target" >"$LOG_DIR/virus-clamscan.tmp" 2>&1
    rc=$?
    set -uo pipefail
    cat "$LOG_DIR/virus-clamscan.tmp" >>"$LOG_DIR/virus-clamscan.log"
    if [[ "$rc" -eq 2 ]]; then
      err="$(grep -E '^(LibClamAV|ERROR:|Warning:)' "$LOG_DIR/virus-clamscan.tmp" | tail -3 | tr '\n' ' ')"
      err="${err:-macOS may block this folder (Privacy / iCloud)}"
      sec_warn "ClamAV skip" "$target — $err"
    fi
    while IFS= read -r line; do
      [[ "$line" == *' FOUND' ]] || continue
      path="${line%:*}"
      sig="${line##*: }"
      sig="${sig% FOUND}"
      kind="$(classify_hit "$sig")"
      found=$((found + 1))
      printf '%s\t%s\t%s\n' "$kind" "$sig" "$path" >>"$HITS"
      case "$kind" in
        LoveLetter) love=$((love + 1)) ;;
        Trojan) trojan=$((trojan + 1)) ;;
        Worm) worm=$((worm + 1)) ;;
        Virus) virus=$((virus + 1)) ;;
        Ransomware) ransom=$((ransom + 1)) ;;
        PUA) pua=$((pua + 1)) ;;
      esac
      sec_hit "$kind" "$sig $path"
    done <"$LOG_DIR/virus-clamscan.tmp"
  done

  if [[ "$found" -eq 0 ]]; then
    sec_ok "ClamAV" "no virus, Trojan, worm, LoveLetter, or PUA in scanned paths"
  else
    sec_hit "ClamAV detections" "$found (LoveLetter=$love Trojan=$trojan Worm=$worm Virus=$virus Ransom=$ransom PUA=$pua)"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  # shellcheck source=common.sh
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
  sec_init
  virus_main "$@"
  # shellcheck source=report.sh
  source "$SEC_DIR/report.sh"
  sec_write_reports
  if [[ "${SEC_HIT:-0}" -gt 0 ]]; then
    exit 1
  fi
  exit 0
fi
