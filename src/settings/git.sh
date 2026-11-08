_GITSETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
_GITSETUP_BW="$_GITSETUP_ROOT/src/cli/bitwarden.sh"

gitSetup() {
  local full_name="" mail=""

  # shellcheck disable=SC1090
  source "$_GITSETUP_BW"
  [[ -s "$BW_FILE" ]] || bw_write || return 1

  full_name="$(bw_val DEVIECE_FULL_NAME)"
  mail="$(bw_val EMAIL)"

  if [[ -z "$full_name" || -z "$mail" ]]; then
    echo "❌ DEVIECE_FULL_NAME / EMAIL missing in Bitwarden"
    return 1
  fi

  git config --global user.name "$full_name"
  git config --global user.email "$mail"
  git config --global pull.rebase true
  git config core.fileMode false
  if typeset -f configSync >/dev/null 2>&1; then
    configSync zsh p10k paths
  fi
  echo "✅ Git: $full_name <$mail> + pull.rebase"
}
