if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if [[ ! -f "$HOME/.oh-my-zsh/themes/powerlevel10k.zsh-theme" ]] && command -v brew >/dev/null; then
  ln -sf "$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme" \
    "$HOME/.oh-my-zsh/themes/powerlevel10k.zsh-theme" 2>/dev/null
fi

brewSetup() {
  local formulae=(
    git gh gitleaks clamav nmap
    zsh-autosuggestions zsh-history-substring-search
    powerlevel10k zsh-syntax-highlighting
  )

  local casks=(
    font-meslo-lg-nerd-font visual-studio-code
  )

  local selection="${1:-all}"
  local missing_formulae=()
  local missing_casks=()
  local pkg clean_name cask
  local -a selected_formulae selected_casks

  case "$selection" in
    --list)
      printf 'Formulae: %s\nCasks: %s\n' "${formulae[*]}" "${casks[*]}"
      return 0
      ;;
    all|formulae|casks) ;;
    *)
      echo "Usage: brewSetup [--list|formulae|casks]" >&2
      return 2
      ;;
  esac

  if [[ "$selection" == formulae && $# -gt 1 ]]; then
    shift
    selected_formulae=("$@")
    for pkg in "${selected_formulae[@]}"; do
      if [[ ! " ${formulae[*]} " == *" $pkg "* ]]; then
        echo "❌ Unknown formula: $pkg" >&2
        return 2
      fi
    done
  elif [[ "$selection" == formulae ]]; then
    selected_formulae=("${formulae[@]}")
  fi

  if [[ "$selection" == casks && $# -gt 1 ]]; then
    shift
    selected_casks=("$@")
    for cask in "${selected_casks[@]}"; do
      if [[ ! " ${casks[*]} " == *" $cask "* ]]; then
        echo "❌ Unknown cask: $cask" >&2
        return 2
      fi
    done
  elif [[ "$selection" == casks ]]; then
    selected_casks=("${casks[@]}")
  fi

  if ! command -v brew >/dev/null; then
    local answer
    echo "Homebrew is missing. The official installer will be downloaded from brew.sh."
    printf 'Install Homebrew now? [y/N] '
    read -r answer
    [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]] || {
      echo "Cancelled."
      return 1
    }
    if ! command -v curl >/dev/null; then
      echo "❌ curl is required to install Homebrew." >&2
      return 1
    fi
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || return 1
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      echo "❌ Homebrew installer finished, but brew was not found in a standard location." >&2
      return 1
    fi
  fi

  if [[ "$selection" == all || "$selection" == formulae ]]; then
    [[ "$selection" == all ]] && selected_formulae=("${formulae[@]}")
    for pkg in "${selected_formulae[@]}"; do
      clean_name="${pkg##*/}"
      if ! brew list --formula "$clean_name" &>/dev/null; then
        missing_formulae+=("$pkg")
      fi
    done
  fi

  if [[ "$selection" == all || "$selection" == casks ]]; then
    [[ "$selection" == all ]] && selected_casks=("${casks[@]}")
    for cask in "${selected_casks[@]}"; do
      if ! brew list --cask "$cask" &>/dev/null; then
        missing_casks+=("$cask")
      fi
    done
  fi

  printf 'Homebrew will install:\n'
  printf '  Formulae: %s\n' "${missing_formulae[*]:-none}"
  printf '  Casks:    %s\n' "${missing_casks[*]:-none}"
  printf 'Continue? [y/N] '
  local answer
  read -r answer
  [[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]] || {
    echo "Cancelled."
    return 0
  }

  if ((${#missing_formulae[@]} > 0)); then
    brew install "${missing_formulae[@]}"
  fi
  if ((${#missing_casks[@]} > 0)); then
    brew install --cask "${missing_casks[@]}"
  fi

  echo "✅ Requested Homebrew packages are installed."
}
