# -----------------------------------------------------
# Powerlevel10k Instant Prompt
# -----------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# -----------------------------------------------------
# macOS Nerd Font / MesloLGS NF Check (ohne fc-list)
# -----------------------------------------------------
if ! mdfind -name "MesloLGS NF" >/dev/null 2>&1; then
  echo "⚠️  MesloLGS NF Nerd Font fehlt!"
  echo "💡 Installieren: brew install --cask font-meslo-lg-nerd-font"
fi

# -----------------------------------------------------
# Oh My Zsh
# -----------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git
  docker
  npm
  vscode
  web-search
  extract
  sudo
  node
  copyfile
  jsontools
  colored-man-pages
  history-substring-search
  z
  dirhistory
  jsonTools
  copybuffer
  macos
)

# -----------------------------------------------------
# Brew Plugins
# -----------------------------------------------------
source "$(brew --prefix zsh-autosuggestions)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$(brew --prefix zsh-syntax-highlighting)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ZSH completions
fpath=("$(brew --prefix)/share/zsh-completions" $fpath)

# -----------------------------------------------------
# FZF Integration
# -----------------------------------------------------
source "$(brew --prefix fzf)/shell/key-bindings.zsh"
source "$(brew --prefix fzf)/shell/completion.zsh"

# -----------------------------------------------------
# Start Oh My Zsh
# -----------------------------------------------------
source $ZSH/oh-my-zsh.sh

# -----------------------------------------------------
# Keybindings
# -----------------------------------------------------
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

# -----------------------------------------------------
# Powerlevel10k Theme (Homebrew Fix)
# -----------------------------------------------------
P10K_THEME="/opt/homebrew/opt/powerlevel10k/share/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f "$P10K_THEME" ]] && source "$P10K_THEME"

# -----------------------------------------------------
# Powerlevel10k Config
# -----------------------------------------------------
if [[ -f ~/.p10k.zsh ]]; then
  source ~/.p10k.zsh
else
  p10k configure
fi

# -----------------------------------------------------
# FZF Directory Navigator
# -----------------------------------------------------
fad() {
  local dir
  dir=$(find "${1:-.}" -type d -not -path '*/.*' 2>/dev/null \
    | fzf --preview 'tree -L 2 --noreport {} 2>/dev/null' +m)
  [[ -n "$dir" ]] || return
  cd "$dir" && ls
}

# -----------------------------------------------------
# BAT Integration
# -----------------------------------------------------
alias cat="bat"
alias catn="command cat"

man() {
  env \
  LESSOPEN="| $(brew --prefix)/bin/bat --color=always --style=plain --paging=always --language=man %s" \
  MANROFFOPT="-c" \
  LESS=" -R " \
  man "$@"
}

export GIT_PAGER="bat --paging=always"

# -----------------------------------------------------
# eza Integration
# -----------------------------------------------------
alias ls="eza --icons=always --long --no-filesize --no-time --no-user --no-permissions --color=always"

# -----------------------------------------------------
# History Settings
# -----------------------------------------------------
HISTSIZE=5000
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
HISTDUP=erase

setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups
setopt hist_verify
setopt share_history
setopt hist_expire_dups_first


# -----------------------------------------------------
# Completion Tweaks
# -----------------------------------------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# -----------------------------------------------------
# zoxide
# -----------------------------------------------------
alias cd="z"
eval "$(zoxide init zsh)"

alias reload="source ~/.zshrc"


export TERM="xterm-256color"
