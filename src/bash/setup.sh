if [[ -n "${ZSH_VERSION:-}" ]]; then
  _CONFIG_ROOT="$(cd "$(dirname "${(%):-%x}")/../.." && pwd)"
else
  _CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
# shellcheck source=paths.sh
source "$_CONFIG_ROOT/src/bash/paths.sh"

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
  local root
  local SETUP_PATHS_FILE="$_CONFIG_ROOT/src/.config/bash/paths.json"
  root="$(setup_root_from_paths)" || return 1
  local -a items=("$@")
  local item

  if ((${#items[@]} == 0)); then
    items=(zsh p10k paths)
  fi

  for item in "${items[@]}"; do
    case "$item" in
      zsh)
        _config_sync_file "$root/src/.config/zsh" "$HOME/.zshrc"
        ;;
      p10k)
        _config_sync_file "$root/src/.config/.p10k.zsh" "${XDG_CONFIG_HOME:-$HOME/.config}/.p10k.zsh"
        ;;
      paths)
        local config_home="${XDG_CONFIG_HOME:-$HOME/.config}/homelab"
        _config_sync_file "$root/src/bash/paths.sh" "$config_home/paths.sh"
        _config_sync_file "$root/src/.config/bash/paths.json" "$config_home/paths.json"
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
  echo "✅ Config: ${*:-zsh, p10k, paths}"
}

alias zshconfig="nano \"$_CONFIG_ROOT/src/.config/zsh\""
alias p10kconfig="nano \"$_CONFIG_ROOT/src/.config/.p10k.zsh\""
