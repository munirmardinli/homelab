if [[ -n "${ZSH_VERSION:-}" ]]; then
  _CONFIG_ROOT="$(cd "$(dirname "${(%):-%x}")/../.." && pwd)"
else
  _CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
_config_sync_file() {
  local src="$1" dest="$2" only_missing="${3:-}"
  if [[ ! -r "$src" ]]; then
    echo "❌ Config source not found: $src" >&2
    return 1
  fi
  mkdir -p "$(dirname "$dest")"
  if [[ -n "$only_missing" && -e "$dest" ]]; then
    return 0
  fi
  cmp -s "$src" "$dest" 2>/dev/null && return 0
  cp "$src" "$dest"
}

configSync() {
  local root="$_CONFIG_ROOT" item tmp
  local -a items=("$@")

  if ((${#items[@]} == 0)); then
    items=(zsh p10k)
  fi

  for item in "${items[@]}"; do
    case "$item" in
      zsh)
        tmp="$(mktemp "${TMPDIR:-/tmp}/homelab-zshrc.XXXXXX")" || return 1
        if ! python3 - "$root/src/.config/zsh" "$root" >"$tmp" <<'PY'
import shlex
import sys
from pathlib import Path

source, root = Path(sys.argv[1]), sys.argv[2]
try:
    content = source.read_text(encoding="utf-8")
except OSError as error:
    print(f"❌ Cannot read Zsh config {source}: {error}", file=sys.stderr)
    raise SystemExit(1)

marker = "__HOMELAB_ROOT__"
if content.count(marker) != 1:
    print(f"❌ Expected exactly one {marker} marker in {source}.", file=sys.stderr)
    raise SystemExit(1)
sys.stdout.write(content.replace(marker, shlex.quote(root)))
PY
        then
          rm -f "$tmp"
          return 1
        fi
        chmod 644 "$tmp" || { rm -f "$tmp"; return 1; }
        if ! _config_sync_file "$tmp" "$HOME/.zshrc"; then
          rm -f "$tmp"
          return 1
        fi
        rm -f "$tmp"
        ;;
      p10k)
        _config_sync_file "$root/src/.config/.p10k.zsh" "${XDG_CONFIG_HOME:-$HOME/.config}/.p10k.zsh"
        ;;
      *)
        echo "❌ unknown config: $item" >&2
        return 1
        ;;
    esac
  done
}

configSetup() {
  configSync "$@"
  echo "✅ Config: ${*:-zsh, p10k}"
}

alias zshconfig="nano \"$_CONFIG_ROOT/src/.config/zsh\""
alias p10kconfig="nano \"$_CONFIG_ROOT/src/.config/.p10k.zsh\""
