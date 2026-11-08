#!/usr/bin/env bash
# Firewall, nmap, Docker binds, host listeners, Traefik LAN allowlist.

host_scan() {
  local prefix cidr fw stealth nmap proxy docker_socket mutable_images elevated
  SEC_SCOPE=host
  SEC_RAN_HOST=1
  prefix="$(env_val HOMELAB_IP_PREFIX)"
  if [[ -z "$prefix" ]]; then
    sec_warn "HOMELAB_IP_PREFIX" "missing in Bitwarden — LAN nmap skipped"
    prefix=""
    cidr=""
  else
    cidr="${prefix}.0/24"
  fi
  proxy="$(env_val HOMELAB_PROXY_HOST)"
  proxy="${proxy}"

  sec_log ""
  sec_log "=== Host / LAN ==="

  fw="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>&1 || true)"
  if printf '%s' "$fw" | grep -qiE 'disabled|state = 0'; then
    sec_warn "macOS firewall" "$fw"
  else
    sec_ok "macOS firewall" "$fw"
  fi

  stealth="$(/usr/libexec/ApplicationFirewall/socketfilterfw --getstealthmode 2>&1 || true)"
  if printf '%s' "$stealth" | grep -qiE 'disabled|stealth mode disabled'; then
    sec_warn "macOS stealth mode" "$stealth"
  else
    sec_ok "macOS stealth mode" "$stealth"
  fi

  if [[ -f "$ROOT_DIR/src/docker/traefik.yml" ]] && grep -q 'lan@file' "$ROOT_DIR/src/docker/traefik.yml"; then
    sec_ok "Traefik LAN allowlist" "websecure uses lan@file"
  else
    sec_warn "Traefik LAN allowlist" "lan@file not found"
  fi

  nmap="$(command -v nmap || true)"
  if [[ -z "$prefix" ]]; then
    :
  elif [[ -z "$nmap" ]]; then
    sec_warn "nmap" "not installed (brew install nmap)"
  else
    sec_log "nmap ping $cidr"
    "$nmap" -sn -T4 --max-retries 1 --host-timeout 8s -oG - "$cidr" \
      >"$LOG_DIR/nmap-ping.log" 2>/dev/null || true
    live="$(awk '/Status: Up/{print $2}' "$LOG_DIR/nmap-ping.log" | sort -u | tr '\n' ' ')"
    sec_ok "Live hosts" "${live:-none}"

    sec_log "nmap ports ${prefix}.1 ${prefix}.${proxy}"
    "$nmap" -sT -Pn -T4 --max-retries 1 --host-timeout 20s \
      -p 22,53,80,443,784,853,2222,3000,4015,5050,51826,8000-8100,8443,8888,9090,16686 \
      -oG - "${prefix}.1" "${prefix}.${proxy}" \
      >"$LOG_DIR/nmap-key-ports.log" 2>/dev/null || true
    awk '
      /^Host:/ && /Ports:/ {
        ip=$2
        split($0, a, "Ports: ")
        n=split(a[2], p, ",")
        out=""
        for (i=1;i<=n;i++) {
          split(p[i], f, "/")
          gsub(/^ +/, "", f[1])
          if (f[2]=="open") {
            if (out!="") out=out ", "
            out=out f[1] "/" f[3]
          }
        }
        if (out!="") print ip "\t" out
      }
    ' "$LOG_DIR/nmap-key-ports.log" >"$NMAP_TSV"
    if [[ -s "$NMAP_TSV" ]]; then
      while IFS=$'\t' read -r ip ports; do
        sec_info "Open ports $ip" "$ports"
      done <"$NMAP_TSV"
    else
      sec_ok "Open ports" "none on .1 / .${proxy} scanned set"
    fi
  fi

  if ! command -v docker >/dev/null; then
    sec_warn "Docker" "CLI missing"
  else
    docker ps -a --format '{{.Names}}\t{{.Status}}\t{{.Ports}}' >"$LOG_DIR/docker-ps.log" 2>/dev/null || true
    ids="$(docker ps -q 2>/dev/null || true)"
    if [[ -z "$ids" ]]; then
      sec_ok "Docker" "no running containers"
    else
      # shellcheck disable=SC2086
      docker inspect --format '{{.Name}} {{json .NetworkSettings.Ports}}' $ids \
        >"$LOG_DIR/docker-inspect-ports.json" 2>/dev/null || true
      python3 - "$LOG_DIR/docker-inspect-ports.json" "$DOCKER_TSV" <<'PY'
import json, sys
from pathlib import Path
src, dest = Path(sys.argv[1]), Path(sys.argv[2])
rows = []
for line in src.read_text(encoding="utf-8", errors="replace").splitlines():
    line = line.strip()
    if not line or " " not in line:
        continue
    name, blob = line.split(" ", 1)
    name = name.lstrip("/")
    try:
        ports = json.loads(blob)
    except json.JSONDecodeError:
        continue
    if not ports:
        continue
    for cport, maps in ports.items():
        if not maps:
            continue
        for m in maps:
            hip = (m or {}).get("HostIp") or "*"
            hport = (m or {}).get("HostPort") or "?"
            rows.append(f"{name}\t{cport}\t{hip}:{hport}")
dest.write_text("\n".join(rows) + ("\n" if rows else ""), encoding="utf-8")
PY
      wild=0
      if [[ -s "$DOCKER_TSV" ]]; then
        while IFS=$'\t' read -r name cport bind; do
          case "$bind" in
            0.0.0.0:* | \[::\]:*)
              wild=$((wild + 1))
              sec_hit "Docker 0.0.0.0" "$name $cport -> $bind"
              ;;
            *)
              sec_info "Docker bind" "$name $cport -> $bind"
              ;;
          esac
        done <"$DOCKER_TSV"
      fi
      if [[ "$wild" -eq 0 ]]; then
        sec_ok "Docker publishes" "no 0.0.0.0 on running containers"
      fi
    fi
  fi

  if command -v lsof >/dev/null; then
    lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null >"$LOG_DIR/lsof-listen.log" || true
    wild_l="$(awk '/LISTEN/ && /TCP \*:/{print}' "$LOG_DIR/lsof-listen.log" | awk '{print $1,$9}' | sort -u | tr '\n' '; ')"
    if [[ -n "$wild_l" ]]; then
      sec_warn "Host listen on *" "$wild_l"
    else
      sec_ok "Host listeners" "no * / 0.0.0.0 TCP listens (or none found)"
    fi
  fi

  docker_socket="$(grep -HnE 'source:[[:space:]]*/var/run/docker.sock' "$ROOT_DIR"/src/docker/*.yml 2>/dev/null || true)"
  if [[ -n "$docker_socket" ]]; then
    sec_warn "Docker socket mounts" "$docker_socket — read_only does not restrict Docker API operations"
  else
    sec_ok "Docker socket mounts" "none in Compose files"
  fi

  mutable_images="$(grep -HnE '^[[:space:]]*image:[[:space:]]*[^[:space:]]+:(latest|main|stable)([[:space:]]|$)' "$ROOT_DIR"/src/docker/*.yml 2>/dev/null || true)"
  if [[ -n "$mutable_images" ]]; then
    sec_warn "Mutable Docker image tags" "$mutable_images — pin versions or digests for reproducible updates"
  else
    sec_ok "Mutable Docker image tags" "none found"
  fi

  elevated="$(grep -HnE '^[[:space:]]*(privileged:[[:space:]]*true|network_mode:[[:space:]]*host|pid:[[:space:]]*host)' "$ROOT_DIR"/src/docker/*.yml 2>/dev/null || true)"
  if [[ -n "$elevated" ]]; then
    sec_hit "Elevated Compose privileges" "$elevated"
  else
    sec_ok "Elevated Compose privileges" "no privileged, host-network, or host-PID setting found"
  fi
}

host_harden() {
  local firewall="/usr/libexec/ApplicationFirewall/socketfilterfw"
  local answer state stealth
  SEC_SCOPE=host

  if [[ ! -x "$firewall" ]]; then
    echo "❌ macOS Application Firewall utility not found." >&2
    return 1
  fi
  if [[ ! -t 0 ]]; then
    echo "❌ Host hardening requires an interactive terminal for confirmation." >&2
    return 1
  fi

  sec_log "=== macOS firewall hardening ==="
  echo "This will enable the macOS Application Firewall and stealth mode."
  echo "It will not change per-app rules or block all incoming connections."
  printf 'Type ENABLE to continue: '
  read -r answer </dev/tty
  if [[ "$answer" != ENABLE ]]; then
    echo "Cancelled."
    sec_warn "macOS firewall hardening" "cancelled by user"
    return 1
  fi

  sudo "$firewall" --setglobalstate on || {
    sec_hit "macOS firewall hardening" "could not enable the firewall"
    return 1
  }
  sudo "$firewall" --setstealthmode on || {
    sec_hit "macOS firewall hardening" "could not enable stealth mode"
    return 1
  }

  state="$("$firewall" --getglobalstate 2>&1)" || return 1
  stealth="$("$firewall" --getstealthmode 2>&1)" || return 1
  if printf '%s' "$state" | grep -qiE 'disabled|state = 0'; then
    echo "❌ Firewall verification failed: $state" >&2
    sec_hit "macOS firewall hardening" "verification failed: $state"
    return 1
  fi
  if printf '%s' "$stealth" | grep -qiE 'disabled|stealth mode disabled'; then
    echo "❌ Stealth-mode verification failed: $stealth" >&2
    sec_hit "macOS firewall hardening" "verification failed: $stealth"
    return 1
  fi
  sec_ok "macOS firewall hardening" "$state; $stealth"
  echo "✅ macOS firewall and stealth mode are enabled."
}
