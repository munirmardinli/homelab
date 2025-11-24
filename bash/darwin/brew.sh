#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/utils/utils.sh" ]; then
  source "$SCRIPT_DIR/utils/utils.sh"
else
  source "$(cd "$SCRIPT_DIR/.." && pwd)/utils/utils.sh"
fi

###############################################################################
# --- Check operating system & install Homebrew ------------------------------
###############################################################################

OS="$(uname -s)"
info "Checking operating system: $OS"

if [ "$OS" = "Darwin" ]; then
  BREW_PATH="/opt/homebrew/bin/brew"
  PROFILE="$HOME/.zprofile"

elif [ "$OS" = "Linux" ]; then
  BREW_PATH="/home/linuxbrew/.linuxbrew/bin/brew"
  PROFILE="$HOME/.profile"

else
  err "Unsupported operating system: $OS"
  exit 1
fi

# Homebrew Installation
if ! command -v brew >/dev/null 2>&1; then
  info "Homebrew not found. Installing..."
  export HOMEBREW_NO_INSTALL_FROM_API=1
  run_safe '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

  echo "" >> $PROFILE
  echo "eval \"\$($BREW_PATH shellenv)\"" >> $PROFILE
  eval "$($BREW_PATH shellenv)"

  ok "Homebrew installed successfully."
else
  ok "Homebrew is already installed."
  eval "$($BREW_PATH shellenv)"
fi

###############################################################################
# --- Homebrew Update & Install Packages + Casks -----------------------------
###############################################################################

info "Updating Homebrew..."
brew update
brew upgrade

packages=(
  wget
  node
  git
  mas
  sshpass
  powerlevel10k
  zsh-syntax-highlighting
  zsh-autosuggestions
  zsh-completions
  bat
  neovim
  eza
  zsh
  fzf
  fontconfig
  diff-so-fancy
  zoxide
)

casks=(
  font-fira-code-nerd-font
  font-jetbrains-mono-nerd-font
  font-meslo-lg-nerd-font
  google-chrome
  cursor
  chatgpt-atlas
  antigravity
  alacritty
)

install_items() {
  local type=$1
  shift
  for item in "$@"; do
    if brew list $type "$item" >/dev/null 2>&1; then
      ok "$item is already installed."
    else
      info "Installing $item..."
      run_safe "brew install $type $item"
    fi
  done
}

info "Installing Brew Packages..."
install_items "" $packages

info "Installing Brew Casks..."
install_items "--cask" $casks

ok "Brew list completed."

###############################################################################
# --- MAS: mas Installation, Login Check & Install masApps -------------------
###############################################################################

if [ "$OS" != "Darwin" ]; then
  warn "MAS is only available on macOS – Skipping MAS section."
  exit 0
fi

info "Checking mas installation..."
if ! command -v mas >/dev/null 2>&1; then
  warn "mas not installed – installing via Brew..."
  brew install mas
fi

info "Checking App Store login..."
if mas list 2>&1 | grep -q "not signed in"; then
  err "Not signed in to App Store!"
  exit 1
fi
ok "App Store Login OK."

declare -A masApps=(
  ["Goodnotes"]=1444383602
  ["HP Smart"]=1474276998
  ["Pages"]=409201541
  ["Presentify"]=1507246666
  ["PrettyJSON"]=1445328303
  ["Windows App"]=1295203466
  ["Xcode"]=497799835
  ["WhatsApp"]=310633997
)

attempt_install() {
  local id="$1"
  local tries=0

  until [ $tries -ge 3 ]; do
    mas install "$id" && return 0
    tries=$((tries+1))
    warn "Installation error (ID: $id), attempt $tries/3..."
    sleep 2
  done

  err "Installation of ID $id failed."
  return 1
}

info "Checking installed apps..."

for app in "${(@k)masApps}"; do
  id="${masApps[$app]}"

  if mas list | grep -q "$id"; then
    ok "$app is already installed."
  else
    info "Installing $app..."
    attempt_install "$id"
  fi
done

ok "MAS: Installation completed (no updates performed)."
