# globaly.ps1
# Windows version of globaly.sh

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$UTILS = Join-Path $SCRIPT_DIR "..\utils\utils.ps1"

if (Test-Path $UTILS) { . $UTILS }

Info "Checking existing Git configuration..."

$gitUser  = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null

if (-not $gitUser -or -not $gitEmail) {
    Warn "Git user.name or email not set. Asking user..."

    $gitUser = Read-Host "Please enter your Git username"
    $gitEmail = Ask-Email

    git config --global user.name "$gitUser"
    git config --global user.email "$gitEmail"
}

Info "Applying Git global configuration..."

git config --global user.name "$gitUser"
git config --global user.email "$gitEmail"

# diff-so-fancy must be installed via choco
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

Ok "Git global configuration completed."

# ---------------------------------------------------------
# Cursor Editor Settings (Windows path)
# ---------------------------------------------------------

Info "Transferring Cursor Editor Settings..."

$cursorSettingsDir = "$env:APPDATA\Cursor\User"
$cursorSettingsFile = Join-Path $cursorSettingsDir "settings.json"
$sourceSettings = Join-Path $SCRIPT_DIR "..\..\.vscode\settings.json"

if (-not (Test-Path $cursorSettingsDir)) {
    New-Item -ItemType Directory -Path $cursorSettingsDir | Out-Null
}

Copy-Item -Path $sourceSettings -Destination $cursorSettingsFile -Force

Ok "Cursor settings.json updated successfully."
