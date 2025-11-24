#!/bin/zsh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/utils/utils.sh" ]; then
  source "$SCRIPT_DIR/utils/utils.sh"
else
  source "$(cd "$SCRIPT_DIR/.." && pwd)/utils/utils.sh"
fi

GITCONFIG="$HOME/.gitconfig"

if [ -f "$GITCONFIG" ]; then
  EXISTING_USER=$(git config --file "$GITCONFIG" --get user.name 2>/dev/null)
  EXISTING_EMAIL=$(git config --file "$GITCONFIG" --get user.email 2>/dev/null)
else
  EXISTING_USER=""
  EXISTING_EMAIL=""
fi

if [ -n "$EXISTING_USER" ] && [ -n "$EXISTING_EMAIL" ]; then
  GIT_USER="$EXISTING_USER"
  GIT_EMAIL="$EXISTING_EMAIL"
else
  warn "Git User or Email not found in .gitconfig. Please enter."

  read "GIT_USER?Please enter your Git username: "
  read "GIT_EMAIL?Please enter your Git email address: "
  
  git config --global user.name "$GIT_USER"
  git config --global user.email "$GIT_EMAIL"
fi

info "Configure Git global..."

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global core.pager "diff-so-fancy | less --tabs=4 -RF"
git config --global interactive.diffFilter "diff-so-fancy --patch"
git config --global color.ui true

git config --global color.diff-highlight.oldNormal     "red bold"
git config --global color.diff-highlight.oldHighlight  "red bold 52"
git config --global color.diff-highlight.newNormal     "green bold"
git config --global color.diff-highlight.newHighlight  "green bold 22"

git config --global color.diff.meta    "11"
git config --global color.diff.frag    "magenta bold"
git config --global color.diff.func    "146 bold"
git config --global color.diff.commit  "yellow bold"
git config --global color.diff.old     "red bold"
git config --global color.diff.new     "green bold"
git config --global color.diff.whitespace "red reverse"

ok "Git global configuration completed."


###############################################################################
# Transfer Cursor SETTINGS
###############################################################################

CURSOR_SETTINGS_DIR="$HOME/Library/Application Support/Cursor/User"
CURSOR_SETTINGS_FILE="$CURSOR_SETTINGS_DIR/settings.json"
SOURCE_SETTINGS=".vscode/settings.json"

info "Transferring Cursor Editor Settings..."

mkdir -p "$CURSOR_SETTINGS_DIR"

cp "$SOURCE_SETTINGS" "$CURSOR_SETTINGS_FILE"

ok "Cursor settings.json updated successfully."
