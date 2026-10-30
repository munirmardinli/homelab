#!/usr/bin/env bash

[[ -n "${BW_SH_LOADED:-}" ]] && return 0
BW_SH_LOADED=1

set -euo pipefail

if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
else
  ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fi

BW_FILE="${BW_FILE:-$ROOT/data/generated/bw}"
if [[ ! -f "$BW_FILE" ]]; then
  mkdir -p "$(dirname "$BW_FILE")"
  if [[ -f "$ROOT/data/bw" ]]; then
    mv "$ROOT/data/bw" "$BW_FILE"
  elif [[ -f "$ROOT/assets/bw" ]]; then
    mv "$ROOT/assets/bw" "$BW_FILE"
  fi
fi
BWS_PROJECT="${BWS_PROJECT:-HomeLab}"
export PATH="${HOME}/.local/bin:${PATH:-/usr/bin:/bin}"
export ROOT BW_FILE

if [[ -n "${BWS_ACCESS_TOKEN:-}" ]]; then
  export BWS_ACCESS_TOKEN
fi

_bws_install() {
  local tag ver asset url tmp dest bin os arch asset_prefix
  dest="${HOME}/.local/bin"
  mkdir -p "$dest"

  os="$(uname -s)"
  arch="$(uname -m)"
  case "$os:$arch" in
    Darwin:arm64) asset_prefix="bws-aarch64-apple-darwin" ;;
    Darwin:x86_64) asset_prefix="bws-x86_64-apple-darwin" ;;
    Linux:x86_64|Linux:amd64) asset_prefix="bws-x86_64-unknown-linux-gnu" ;;
    Linux:aarch64|Linux:arm64) asset_prefix="bws-aarch64-unknown-linux-gnu" ;;
    *)
      echo "❌ unsupported platform for bws: ${os} ${arch}" >&2
      return 1
      ;;
  esac

  tag="$(curl -fsSL "https://api.github.com/repos/bitwarden/sdk-sm/releases" | python3 -c '
import json, sys
rels = json.load(sys.stdin)
for rel in rels:
    t = rel.get("tag_name") or ""
    if t.startswith("bws-v"):
        print(t)
        raise SystemExit(0)
raise SystemExit(1)
')"
  ver="${tag#bws-v}"
  asset="${asset_prefix}-${ver}.zip"
  url="https://github.com/bitwarden/sdk-sm/releases/download/${tag}/${asset}"

  echo "⚙️  Installing bws ${ver}" >&2
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/bws.XXXXXX")"
  curl -fsSL -o "$tmp/bws.zip" "$url"
  unzip -qo "$tmp/bws.zip" -d "$tmp"
  bin="$(find "$tmp" -type f -name bws | head -n 1)"
  if [[ -z "$bin" ]]; then
    rm -rf "$tmp"
    echo "❌ bws binary missing in zip." >&2
    return 1
  fi
  install -m 755 "$bin" "$dest/bws"
  rm -rf "$tmp"
  export PATH="${dest}:${PATH}"
  hash -r 2>/dev/null || true
}

_bw_tty() {
  [[ -r /dev/tty && -t 1 ]]
}

bw_ensure() {
  if ! command -v bws >/dev/null 2>&1; then
    _bws_install || return 1
  fi
  if [[ -z "${BWS_ACCESS_TOKEN:-}" ]]; then
    if ! _bw_tty; then
      echo "❌ BWS_ACCESS_TOKEN missing." >&2
      echo '   export BWS_ACCESS_TOKEN="..."' >&2
      return 1
    fi
    local token=""
    printf 'BWS_ACCESS_TOKEN: ' >/dev/tty
    IFS= read -rs token </dev/tty || return 1
    printf '\n' >/dev/tty
    token="${token#"${token%%[![:space:]]*}"}"
    token="${token%"${token##*[![:space:]]}"}"
    if [[ -z "$token" ]]; then
      echo "❌ BWS_ACCESS_TOKEN empty" >&2
      return 1
    fi
    export BWS_ACCESS_TOKEN="$token"
  fi
  BWS_ACCESS_TOKEN="$(python3 - "$BWS_ACCESS_TOKEN" <<'PY'
import sys
token = (sys.argv[1] or "").strip()
for ch in "“”„«»\"'":
    token = token.replace(ch, "")
print(token)
PY
)"
  export BWS_ACCESS_TOKEN
  if [[ -z "$BWS_ACCESS_TOKEN" ]]; then
    echo "❌ BWS_ACCESS_TOKEN is empty after cleanup." >&2
    return 1
  fi
}

bw_write() {
  local projects list proj n
  bw_ensure || return 1

  projects="$(mktemp "${TMPDIR:-/tmp}/bws-proj.XXXXXX")"
  list="$(mktemp "${TMPDIR:-/tmp}/bws-list.XXXXXX")"
  umask 077
  chmod 600 "$projects" "$list"

  bws project list >"$projects"
  proj="$(python3 - "$projects" "$BWS_PROJECT" <<'PY'
import json, sys
from pathlib import Path

projects_path, fallback = Path(sys.argv[1]), sys.argv[2]
want = (fallback or "HomeLab").strip().lower()
try:
    data = json.loads(projects_path.read_text(encoding="utf-8") or "[]")
except Exception:
    raise SystemExit(0)
if isinstance(data, dict):
    data = data.get("data") or [data]
if not isinstance(data, list):
    raise SystemExit(0)
for item in data:
    if not isinstance(item, dict):
        continue
    name = str(item.get("name") or "").strip().lower()
    ident = str(item.get("id") or "").strip()
    if name == want and ident:
        print(ident)
        raise SystemExit(0)
PY
)"

  if [[ -n "$proj" ]]; then
    bws secret list "$proj" >"$list"
  else
    bws secret list >"$list"
  fi
  if [[ ! -s "$list" ]]; then
    rm -f "$projects" "$list"
    echo "❌ bws secret list failed. Check BWS_ACCESS_TOKEN and project ${BWS_PROJECT}." >&2
    return 1
  fi

  if [[ -d "$BW_FILE" ]]; then
    rm -rf "$BW_FILE"
  fi
  mkdir -p "$(dirname "$BW_FILE")"
  n="$(python3 - "$list" "$BW_FILE" <<'PY'
import json, re, sys
from pathlib import Path

list_path, dest = Path(sys.argv[1]), Path(sys.argv[2])
key_re = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

def as_list(raw):
    try:
        data = json.loads(raw or "[]")
    except Exception:
        return []
    if isinstance(data, dict):
        if isinstance(data.get("data"), list):
            return data["data"]
        return [data]
    return data if isinstance(data, list) else []

def quote(val):
    val = val.replace("\\", "\\\\").replace('"', '\\"').replace("$", "$$")
    return '"' + val + '"'

env = {}
for item in as_list(list_path.read_text(encoding="utf-8")):
    if not isinstance(item, dict) or item.get("value") is None:
        continue
    key = str(item.get("key") or item.get("name") or "").strip()
    if not key_re.match(key):
        continue
    env[key] = str(item["value"]).replace("\r", "").replace("\n", " ")

if not env:
    sys.exit("❌ no secrets written")

lines = [f"{key}={quote(env[key])}" for key in sorted(env)]
dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
dest.chmod(0o600)
print(len(lines))
PY
)"
  rm -f "$projects" "$list"
  echo "🔐 Bitwarden: ${n} secrets → ${BW_FILE#"$ROOT"/}" >&2
}

bw_upsert() {
  local key="$1" value="$2"
  [[ -n "$key" ]] || return 1
  if [[ -d "$BW_FILE" ]]; then
    rm -rf "$BW_FILE"
  fi
  mkdir -p "$(dirname "$BW_FILE")"
  umask 077
  python3 - "$BW_FILE" "$key" "$value" <<'PY'
import sys
from pathlib import Path

path, key, value = Path(sys.argv[1]), sys.argv[2], sys.argv[3]

def quote(val):
    val = val.replace("\\", "\\\\").replace('"', '\\"').replace("$", "$$")
    return '"' + val + '"'

lines = []
if path.is_file():
    lines = path.read_text(encoding="utf-8").splitlines()
found = False
out = []
prefix = key + "="
for raw in lines:
    if raw.startswith(prefix):
        out.append(prefix + quote(value))
        found = True
    else:
        out.append(raw)
if not found:
    out.append(prefix + quote(value))
text = "\n".join(out)
if text and not text.endswith("\n"):
    text += "\n"
path.write_text(text, encoding="utf-8")
path.chmod(0o600)
PY
}

bw_val() {
  python3 - "$BW_FILE" "$1" <<'PY'
from pathlib import Path
import sys

def unquote(val):
    val = val.strip()
    if len(val) >= 2 and val[0] == '"' and val[-1] == '"':
        val = val[1:-1].replace('\\"', '"').replace("\\\\", "\\")
    elif len(val) >= 2 and val[0] == "'" and val[-1] == "'":
        val = val[1:-1]
    return val.replace("$$", "$")

path, key = Path(sys.argv[1]), sys.argv[2]
if not path.is_file():
    raise SystemExit(0)
for raw in path.read_text(encoding="utf-8").splitlines():
    line = raw.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    k, _, val = line.partition("=")
    if k.strip() != key:
        continue
    print(unquote(val), end="")
    break
PY
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-}" in
    get)
      bw_val "${2:-}"
      ;;
    *)
      bw_write
      ;;
  esac
fi
