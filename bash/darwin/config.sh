#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/utils/utils.sh" ]; then
  source "$SCRIPT_DIR/utils/utils.sh"
else
  source "$(cd "$SCRIPT_DIR/.." && pwd)/utils/utils.sh"
fi

REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COPY_DIRECTORY="$HOME"

info "Transferring iMac setup files..."

cp "$REPO_ROOT/.config/.p10k.zsh" "$COPY_DIRECTORY/.p10k.zsh"
cp "$REPO_ROOT/.config/.zshrc" "$COPY_DIRECTORY/.zshrc"

if [ ! -d "$COPY_DIRECTORY/.config/alacritty" ]; then
  mkdir -p "$COPY_DIRECTORY/.config/alacritty"
fi

cp "$REPO_ROOT/.config/alacritty.toml" "$COPY_DIRECTORY/.config/alacritty/alacritty.toml"

THEMES_DIR="$COPY_DIRECTORY/.config/alacritty/themes"
THEMES_REPO="https://github.com/alacritty/alacritty-theme"

if [ ! -d "$THEMES_DIR" ]; then
  git clone "$THEMES_REPO" "$THEMES_DIR"
elif [ -z "$(ls -A "$THEMES_DIR" 2>/dev/null)" ]; then
  rm -rf "$THEMES_DIR"
  git clone "$THEMES_REPO" "$THEMES_DIR"
fi

ok "iMac setup refreshed."
