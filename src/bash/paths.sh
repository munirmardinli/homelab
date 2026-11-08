#!/usr/bin/env bash

if [[ -n "${ZSH_VERSION:-}" ]]; then
  _SETUP_PATHS_SOURCE_ROOT="$(cd "$(dirname "${(%):-%x}")/../.." && pwd)"
else
  _SETUP_PATHS_SOURCE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

setup_paths_file() {
  local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
  if [[ -n "${SETUP_PATHS_FILE:-}" && -r "$SETUP_PATHS_FILE" ]]; then
    printf '%s\n' "$SETUP_PATHS_FILE"
  elif [[ -r "$config_home/homelab/paths.json" ]]; then
    printf '%s\n' "$config_home/homelab/paths.json"
  elif [[ -r "$_SETUP_PATHS_SOURCE_ROOT/src/.config/bash/paths.json" ]]; then
    printf '%s\n' "$_SETUP_PATHS_SOURCE_ROOT/src/.config/bash/paths.json"
  else
    echo "❌ paths.json not found; run 'make zsh-install' or set SETUP_PATHS_FILE." >&2
    return 1
  fi
}

setup_path_value() {
  local file env_name
  file="$(setup_paths_file)" || return 1
  env_name="$1"
  python3 - "$file" "$env_name" <<'PY'
import json
import sys
from pathlib import Path

config_path, env_name = sys.argv[1:]
try:
    config = json.loads(Path(config_path).read_text(encoding="utf-8"))
    home_value = str(config["home"])
    home = Path(home_value.replace("~", str(Path.home()), 1) if home_value.startswith("~") else home_value).expanduser()
    matches = [
        item for item in config["directories"]
        if isinstance(item, dict) and item.get("environmentVariable") == env_name
    ]
    if len(matches) != 1:
        raise ValueError(f"expected exactly one directory for {env_name}, found {len(matches)}")
    value = Path(str(matches[0]["path"]))
    if not value.is_absolute():
        value = home / value
    print(value)
except (KeyError, OSError, TypeError, ValueError, json.JSONDecodeError) as error:
    print(f"❌ cannot resolve {env_name} from {config_path}: {error}", file=sys.stderr)
    raise SystemExit(1)
PY
}

setup_root_from_paths() {
  local root
  root="$(setup_path_value SETUP_ROOT)" || return 1
  if [[ ! -d "$root" ]]; then
    echo "❌ SETUP_ROOT from paths.json does not exist: $root" >&2
    return 1
  fi
  printf '%s\n' "$root"
}

setup_paths_list() {
  local file
  file="$(setup_paths_file)" || return 1
  python3 - "$file" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
try:
    config = json.loads(config_path.read_text(encoding="utf-8"))
    home_value = str(config["home"])
    home = Path(home_value.replace("~", str(Path.home()), 1) if home_value.startswith("~") else home_value).expanduser()
    for item in config["directories"]:
        value = Path(str(item["path"]))
        if not value.is_absolute():
            value = home / value
        variable = item.get("environmentVariable", "")
        print(f'{variable or "-"}\t{value}\t{item.get("description", "")}')
except (KeyError, OSError, TypeError, ValueError, json.JSONDecodeError) as error:
    print(f"❌ cannot read {config_path}: {error}", file=sys.stderr)
    raise SystemExit(1)
PY
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-root}" in
    root)
      setup_root_from_paths
      ;;
    list)
      setup_paths_list
      ;;
    *)
      echo "Usage: $0 [root|list]" >&2
      exit 2
      ;;
  esac
fi
