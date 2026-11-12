#!/usr/bin/env bash

[[ -n "${COMPOSE_SH_LOADED:-}" ]] && return 0
COMPOSE_SH_LOADED=1

set -euo pipefail

CLI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ssh.sh
source "$CLI_DIR/ssh.sh"

compose_ignored() {
  case "${1##*/}" in
    compose.yml|compose.yaml|docker-compose.yml|docker-compose.yaml) return 0 ;;
    *) return 1 ;;
  esac
}

collect_compose_files() {
  COMPOSE_FILES=()
  local f base name

  if [[ "${CI_PIPELINE_SOURCE:-}" == "web" && -z "${COMPOSE_STACKS:-}" ]]; then
    for f in "$ROOT"/src/docker/*.yml "$ROOT"/src/docker/*.yaml; do
      [[ -f "$f" ]] || continue
      compose_ignored "$f" && continue
      COMPOSE_FILES+=("${f#"$ROOT"/}")
    done
    return 0
  fi

  if [[ -n "${COMPOSE_STACKS:-}" ]]; then
    for name in $COMPOSE_STACKS; do
      name="${name#./}"
      name="${name##*/}"
      name="${name%.yml}"
      name="${name%.yaml}"
      if compose_ignored "${name}.yml"; then
        echo "❌ Compose file is not a stack: ${name}" >&2
        return 1
      elif [[ -f "$ROOT/src/docker/${name}.yml" ]]; then
        COMPOSE_FILES+=("src/docker/${name}.yml")
      elif [[ -f "$ROOT/src/docker/${name}.yaml" ]]; then
        COMPOSE_FILES+=("src/docker/${name}.yaml")
      else
        echo "❌ Compose file not found: ${name}" >&2
        return 1
      fi
    done
    return 0
  fi

  local before="${CI_COMMIT_BEFORE_SHA:-}"
  local after="${CI_COMMIT_SHA:-HEAD}"
  if [[ -n "$before" && ! "$before" =~ ^0+$ ]]; then
    while IFS= read -r f; do
      [[ -n "$f" ]] || continue
      [[ -f "$ROOT/$f" ]] || continue
      compose_ignored "$f" && continue
      COMPOSE_FILES+=("$f")
    done < <(git -C "$ROOT" diff --name-only --diff-filter=ACMR "$before" "$after" -- 'src/docker/*.yml' 'src/docker/*.yaml')
    return 0
  fi

  if [[ -z "${CI:-}" ]]; then
    if git -C "$ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
      while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        [[ -f "$ROOT/$f" ]] || continue
        compose_ignored "$f" && continue
        COMPOSE_FILES+=("$f")
      done < <(git -C "$ROOT" diff --name-only --diff-filter=ACMR HEAD -- 'src/docker/*.yml' 'src/docker/*.yaml')
    fi
    return 0
  fi

  for f in "$ROOT"/src/docker/*.yml "$ROOT"/src/docker/*.yaml; do
    [[ -f "$f" ]] || continue
    compose_ignored "$f" && continue
    base="${f#"$ROOT"/}"
    COMPOSE_FILES+=("$base")
  done
}

order_compose_files() {
  local f base
  local -a first rest
  first=()
  rest=()
  if ((${#COMPOSE_FILES[@]} == 0)); then
    return 0
  fi
  for f in "${COMPOSE_FILES[@]}"; do
    base="${f##*/}"
    case "$base" in
      traefik.yml|traefik.yaml) first+=("$f") ;;
      *) rest+=("$f") ;;
    esac
  done
  COMPOSE_FILES=("${first[@]}" "${rest[@]}")
}

compose_env_file() {
  local folder="${DOCKER_FOLDER_PATH:-}"
  [[ -n "$folder" ]] || folder="$(bw_val DOCKER_FOLDER_PATH)"
  if [[ -z "$folder" ]]; then
    echo "❌ DOCKER_FOLDER_PATH is missing in Bitwarden" >&2
    return 1
  fi
  if [[ "$folder" != /* ]]; then
    folder="${DEPLOY_DIR}/${folder#./}"
  fi
  printf '%s' "${folder}/generated/bw"
}

compose_upload() {
  local remote_bw folder
  remote_bw="$(compose_env_file)" || return 1
  folder="$(dirname "$remote_bw")"

  echo "📁 ${DEPLOY_DIR}"
  ssh_run "mkdir -p $(printf %q "$folder")"

  local -a payload=(src/docker)
  [[ -d "$ROOT/src/.config" ]] && payload+=(src/.config)
  [[ -d "$ROOT/.config" ]] && payload+=(.config)
  [[ -f "$BW_FILE" ]] && payload+=("${BW_FILE#"$ROOT"/}")

  COPYFILE_DISABLE=1 tar -C "$ROOT" -cf - "${payload[@]}" | ssh_run "tar -C $(printf %q "$DEPLOY_DIR") -xf - && chmod 700 $(printf %q "$folder") && chmod 600 $(printf %q "$remote_bw")"
}

compose_project() {
  local name="${1##*/}"
  name="${name%.yml}"
  name="${name%.yaml}"
  printf '%s' "$name"
}

compose_run_stack() {
  local name="$1" file env_file
  shift
  local -a args=("$@")

  if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
    echo "❌ Invalid Compose stack name: ${name:-<empty>}" >&2
    return 2
  fi
  if [[ -f "$ROOT/src/docker/${name}.yml" ]]; then
    file="src/docker/${name}.yml"
  elif [[ -f "$ROOT/src/docker/${name}.yaml" ]]; then
    file="src/docker/${name}.yaml"
  else
    echo "❌ Compose stack not found: ${name}" >&2
    return 1
  fi
  if ((${#args[@]} == 0)); then
    echo 'Usage: make docker DOCKER_STACK=<name> DOCKER_ARGS="up -d"' >&2
    return 2
  fi

  ssh_load || return 1
  compose_upload || return 1
  env_file="$(compose_env_file)" || return 1
  ssh_run docker compose --env-file "$env_file" --project-name "$name" -f "$file" "${args[@]}"
}

compose_cli_docker() {
  local -a args=()
  if (($# > 0)); then
    compose_run_stack "$@"
  else
    read -r -a args <<<"${DOCKER_ARGS:-}"
    compose_run_stack "${DOCKER_STACK:-}" "${args[@]}"
  fi
}

compose_apply() {
  local f project env_file
  echo "▶️  stop → pull → up -d: ${COMPOSE_FILES[*]}"
  ssh_run docker network inspect frontend >/dev/null 2>&1 || ssh_run docker network create frontend
  if ((${#COMPOSE_FILES[@]} == 0)); then
    return 0
  fi
  for f in "${COMPOSE_FILES[@]}"; do
    project="$(compose_project "$f")"
    echo ""
    echo "——— ${f} ———"
    env_file="$(compose_env_file)" || return 1
    ssh_run docker compose --env-file "$env_file" --project-name "$project" -f "$f" stop || echo "ℹ️  stop: ${project} was not running"
    ssh_run docker compose --env-file "$env_file" --project-name "$project" -f "$f" pull
    ssh_run docker compose --env-file "$env_file" --project-name "$project" -f "$f" up -d
  done
  echo ""
  echo "✅ Docker update done."
}

compose_main() {
  collect_compose_files
  if ((${#COMPOSE_FILES[@]} == 0)); then
    echo "ℹ️  No compose changes. Nothing to deploy."
    return 0
  fi
  order_compose_files
  echo "📦 ${COMPOSE_FILES[*]}"
  ssh_load || return 1
  compose_upload
  compose_apply
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-}" in
    list)
      collect_compose_files
      order_compose_files
      if ((${#COMPOSE_FILES[@]})); then
        printf '%s\n' "${COMPOSE_FILES[@]}"
      fi
      ;;
    upload)
      ssh_load || exit 1
      compose_upload
      ;;
    docker)
      shift
      compose_cli_docker "$@"
      ;;
    *)
      compose_main "$@"
      ;;
  esac
fi
