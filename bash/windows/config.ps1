# config.ps1
# Windows version of config.sh (iMac setup)

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$UTILS = Join-Path $SCRIPT_DIR "..\utils\utils.ps1"

if (Test-Path $UTILS) { . $UTILS }

# ---------------------------------------------------------
# Paths
# ---------------------------------------------------------
$REPO_ROOT = (Resolve-Path "$SCRIPT_DIR\..").Path
$HOME_DIR  = $env:USERPROFILE

Info "Transferring Windows setup files..."

# ---------------------------------------------------------
# oh-my-posh Theme Setup (p10k replacement)
# ---------------------------------------------------------
$poshDir = Join-Path $HOME_DIR "AppData\Local\oh-my-posh"
$poshTheme = Join-Path $poshDir "p10k.omp.json"
$poshSource = Join-Path $REPO_ROOT ".config\p10k.omp.json"

if (-not (Test-Path $poshDir)) {
    New-Item -ItemType Directory -Path $poshDir | Out-Null
}

if (Test-Path $poshSource) {
    Copy-Item $poshSource $poshTheme -Force
    Ok "oh-my-posh theme transferred."
} else {
    Warn "p10k.omp.json not found in repo."
}

# ---------------------------------------------------------
# PowerShell Profile (analog zu .zshrc)
# ---------------------------------------------------------
$profileDir = Split-Path -Parent $PROFILE

if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir | Out-Null
}

$profileSrc = Join-Path $REPO_ROOT ".config\powershell_profile.ps1"

if (Test-Path $profileSrc) {
    Copy-Item $profileSrc $PROFILE -Force
    Ok "PowerShell profile updated."
} else {
    Warn "powershell_profile.ps1 missing in repo."
}

# ---------------------------------------------------------
# Alacritty Config
# ---------------------------------------------------------
$alacrittyDir = Join-Path $HOME_DIR ".config\alacritty"

if (-not (Test-Path $alacrittyDir)) {
    New-Item -ItemType Directory -Path $alacrittyDir | Out-Null
}

$alacrittyTomlSrc = Join-Path $REPO_ROOT ".config\alacritty.toml"
$alacrittyTomlDst = Join-Path $alacrittyDir "alacritty.toml"

Copy-Item $alacrittyTomlSrc $alacrittyTomlDst -Force
Ok "Alacritty config transferred."

# ---------------------------------------------------------
# Alacritty Themes
# ---------------------------------------------------------
$themesDir = Join-Path $alacrittyDir "themes"
$themesRepo = "https://github.com/alacritty/alacritty-theme"

if (-not (Test-Path $themesDir)) {
    git clone $themesRepo $themesDir | Out-Null
    Ok "Alacritty themes repository cloned."
}
elseif (-not (Get-ChildItem $themesDir)) {
    Remove-Item $themesDir -Recurse -Force
    git clone $themesRepo $themesDir | Out-Null
    Ok "Alacritty themes repository refreshed."
}
else {
    Info "Themes already exist — skipping clone."
}

Ok "Windows setup refreshed."
