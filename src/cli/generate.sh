#!/usr/bin/env bash

[[ -n "${GENERATE_SH_LOADED:-}" ]] && return 0
GENERATE_SH_LOADED=1

set -euo pipefail

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ssh.sh
source "$CLI_DIR/ssh.sh"

CONFIG_DIR="$ROOT/src/.config"
DOCKER_DIR="$ROOT/src/docker"

generate_folder() {
  local folder
  folder="$(bw_val DOCKER_FOLDER_PATH)"
  if [[ -z "$folder" ]]; then
    echo "❌ DOCKER_FOLDER_PATH is missing in Bitwarden" >&2
    return 1
  fi
  if [[ "$folder" != /* ]]; then
    folder="${ROOT}/${folder#./}"
  fi
  printf '%s' "$folder"
}

generate_secrets_file() {
  local folder="$1"
  if [[ -n "$folder" && -f "$folder/generated/bw" ]]; then
    printf '%s' "$folder/generated/bw"
    return 0
  fi
  printf '%s' "$BW_FILE"
}

_generate_secret_key() {
  case "$1" in
    *PASSWORD*|*TOKEN*|*SECRET*|*HASH*|*KEY*|*API*) return 0 ;;
    *) return 1 ;;
  esac
}

generate_missing_keys() {
  python3 - "$CONFIG_DIR" "$DOCKER_DIR" "${SECRETS_FILE:-$BW_FILE}" <<'PY'
import re, sys
from pathlib import Path

config, docker, env_path = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
pat = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)")
have = set()
if env_path.is_file():
    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        have.add(line.split("=", 1)[0].strip())
need = []
files = [
    p for p in config.iterdir()
    if p.is_file() and (p.suffix in {".yml", ".yaml", ".rb", ".toml"} or p.name == "http")
] if config.is_dir() else []
if docker.is_dir():
    files.extend(p for p in docker.iterdir() if p.is_file() and p.suffix in {".yml", ".yaml"})
for path in sorted(files):
    for name in pat.findall(path.read_text(encoding="utf-8")):
        if name not in have and name not in need:
            need.append(name)
print("\n".join(need))
PY
}

generate_fill_missing() {
  local key value secret
  [[ -f "${SECRETS_FILE:-$BW_FILE}" ]] || bw_write
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    echo "ℹ️  ${key} fehlt in DOCKER_FOLDER_PATH/generated/bw." >&2
    secret=0
    _generate_secret_key "$key" && secret=1
    if ! _bw_tty; then
      echo "❌ ${key} is missing in Bitwarden" >&2
      return 1
    fi
    value="$(_ssh_prompt "$key" "$secret")" || return 1
    bw_upsert "$key" "$value"
  done < <(generate_missing_keys)
}

generate_render() {
  local stage="$1"
  python3 - "${SECRETS_FILE:-$BW_FILE}" "$CONFIG_DIR" "$stage" <<'PY'
import base64, json, re, sys
from pathlib import Path

env_path, config, stage = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
pat = re.compile(
    r"\$\{([A-Za-z_][A-Za-z0-9_]*)(?:(\?\:|\?|:-|-)([^}]*))?\}"
)

def unquote(val):
    val = val.strip()
    if len(val) >= 2 and val[0] == '"' and val[-1] == '"':
        val = val[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    elif len(val) >= 2 and val[0] == "'" and val[-1] == "'":
        val = val[1:-1]
    return val.replace("$$", "$")

env = {}
for raw in env_path.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    key, _, val = line.partition("=")
    env[key.strip()] = unquote(val)

missing = []

def repl(match):
    name, op, rest = match.group(1), match.group(2), match.group(3)
    if name in env and env[name] != "":
        return env[name]
    if op in (":-", "-"):
        return rest or ""
    missing.append(name)
    return match.group(0)

stage.mkdir(parents=True, exist_ok=True)
template_files = [
    p for p in config.iterdir()
    if p.is_file() and (p.suffix in {".yml", ".yaml", ".rb", ".toml"} or p.name == "http")
]
for src in sorted(template_files):
    text = pat.sub(repl, src.read_text(encoding="utf-8"))
    dest = stage / src.name
    if src.name == "traefik.yml":
        user = env.get("TRAEFIK_DASHBOARD_USER", "").strip()
        password = env.get("TRAEFIK_DASHBOARD_PASSWORD", "")
        if not user or not password:
            missing.extend(name for name in ("TRAEFIK_DASHBOARD_USER", "TRAEFIK_DASHBOARD_PASSWORD") if not env.get(name, "").strip())
        else:
            import subprocess
            hashed = subprocess.check_output(["openssl", "passwd", "-apr1", password], text=True).strip()
            text = text.replace("TRAEFIK_BASIC_AUTH", f"{user}:{hashed}")
    dest.write_text(text, encoding="utf-8")
    dest.chmod(0o600)

devices_file = stage / "devices.yml"
dynamic_file = stage / "traefik.yml"
domain = env.get("PRIVATE_DOMAIN", "").strip()
if devices_file.is_file() and dynamic_file.is_file() and domain:
    devices = []
    current = None
    for raw in devices_file.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if line.startswith("- name:"):
            if current:
                devices.append(current)
            current = {"name": line.split(":", 1)[1].strip()}
        elif current and ":" in line:
            key, value = line.split(":", 1)
            current[key.strip()] = value.strip()
    if current:
        devices.append(current)
    extra = ["  serversTransports:", "    insecure:", "      insecureSkipVerify: true", "  routers:"]
    services = ["  services:"]
    for item in devices:
        name = item.get("name", "")
        ip = item.get("ip", "")
        port = item.get("port", "")
        if not name or not ip or not port:
            continue
        https = item.get("https", "false").lower() == "true"
        scheme = "https" if https else "http"
        extra.extend([
            f"    {name}:",
            f'      rule: "Host(`{name}.{domain}`)"',
            "      entryPoints:",
            "        - websecure",
            "      tls:",
            "        certResolver: le",
            f"      service: {name}",
        ])
        services.extend([
            f"    {name}:",
            "      loadBalancer:",
            "        passHostHeader: false",
        ])
        if https:
            services.append("        serversTransport: insecure")
        services.extend([
            "        servers:",
            f'          - url: "{scheme}://{ip}:{port}"',
        ])
    dynamic_file.write_text(
        dynamic_file.read_text(encoding="utf-8").rstrip() + "\n" + "\n".join(extra + services) + "\n",
        encoding="utf-8",
    )

user = env.get("GHCR_USERNAME", "").strip()
token = env.get("GHCR_TOKEN", "").strip()
if not user or not token:
    missing.extend(name for name in ("GHCR_USERNAME", "GHCR_TOKEN") if not env.get(name, "").strip())
else:
    auth = base64.b64encode(f"{user}:{token}".encode()).decode()
    docker_json = stage / "docker.json"
    docker_json.write_text(json.dumps({"auths": {"ghcr.io": {"auth": auth}}}, indent=2) + "\n", encoding="utf-8")
    docker_json.chmod(0o600)

if missing:
    names = " ".join(dict.fromkeys(missing))
    print(f"❌ missing in DOCKER_FOLDER_PATH/generated/bw: {names}", file=sys.stderr)
    sys.exit(1)
print(str(stage))
PY
}

generate_place() {
  local stage="$1" folder dest local_dest
  ssh_load || return 1
  folder="$(generate_folder)" || return 1
  local_dest="${ROOT}/data/generated"
  if [[ -d "$folder" ]]; then
    local_dest="${folder}/generated"
  elif [[ "$folder" == "$ROOT/"* ]]; then
    local_dest="${folder}/generated"
  elif [[ "$folder" == "$DEPLOY_DIR/"* ]]; then
    local_dest="${ROOT}/${folder#"$DEPLOY_DIR"/}/generated"
  fi
  mkdir -p "$local_dest"
  cp -p "$stage"/* "$local_dest"/
  chmod 700 "$local_dest"
  chmod 600 "$local_dest"/*
  echo "📝 generated → ${local_dest}"
  if [[ -f "$local_dest/gitlab.rb" ]]; then
    echo "📝 gitlab.rb → ${local_dest}/gitlab.rb"
  fi

  dest="${DOCKER_FOLDER_PATH}/generated"
  echo "📁 ${SSH_HOST}:${dest}"
  local config_rb="${DOCKER_FOLDER_PATH}/gitlab/config/gitlab.rb"
  COPYFILE_DISABLE=1 tar -C "$stage" -cf - . | ssh_run "mkdir -p $(printf %q "$dest") && tar -C $(printf %q "$dest") -xf - && chmod 700 $(printf %q "$dest") && chmod 600 $(printf %q "$dest")/* && mkdir -p $(printf %q "${config_rb%/*}") && cat $(printf %q "$dest/gitlab.rb") > $(printf %q "$config_rb")"
}

generate_main() {
  local stage folder
  [[ -f "$BW_FILE" ]] || bw_write
  folder="$(generate_folder)" || return 1
  SECRETS_FILE="$(generate_secrets_file "$folder")"
  export SECRETS_FILE
  generate_fill_missing
  stage="$(mktemp -d "${TMPDIR:-/tmp}/compose-generated.XXXXXX")"
  generate_render "$stage" >/dev/null
  generate_place "$stage"
  rm -rf "$stage"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  generate_main "$@"
fi
