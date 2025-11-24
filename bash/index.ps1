#!/usr/bin/env pwsh
<#
Windows root installer
Equivalent to bash/index.sh for macOS/Linux
Launches platform-specific windows setup in bash/windows/
#>

# ---------------------------------------------------------
# Paths & Utils
# ---------------------------------------------------------

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$UTILS = Join-Path $SCRIPT_DIR "utils/utils.ps1"
$WINDOWS_DIR = Join-Path $SCRIPT_DIR "windows"
$ENTRY = Join-Path $WINDOWS_DIR "index.ps1"

# Load utils.ps1
if (Test-Path $UTILS) {
    . $UTILS
} else {
    Write-Host "⚠ utils.ps1 not found. Continuing without extended logging..." -ForegroundColor Yellow
}

# Safe wrappers (if utils not loaded)
function InfoSafe($msg) {
    if (Get-Command Info -ErrorAction SilentlyContinue) { Info $msg }
    else { Write-Host "ℹ $msg" -ForegroundColor Cyan }
}

function OkSafe($msg) {
    if (Get-Command Ok -ErrorAction SilentlyContinue) { Ok $msg }
    else { Write-Host "✔ $msg" -ForegroundColor Green }
}

function ErrSafe($msg) {
    if (Get-Command Err -ErrorAction SilentlyContinue) { Err $msg }
    else { Write-Host "❌ $msg" -ForegroundColor Red }
}

# ---------------------------------------------------------
# Start
# ---------------------------------------------------------

InfoSafe "──────────────────────────────────────────────"
InfoSafe "   🚀 MUNIR – Windows ROOT Setup STARTING"
InfoSafe "──────────────────────────────────────────────"

# ---------------------------------------------------------
# Script Runner (like run() in index.sh)
# ---------------------------------------------------------
function Run-Script($path) {
    if (-not (Test-Path $path)) {
        ErrSafe "Script missing: $path"
        exit 1
    }

    InfoSafe "Starting: $(Split-Path $path -Leaf)"

    try {
        & $path
        if ($LASTEXITCODE -ne 0) {
            throw "Exit Code $LASTEXITCODE"
        }
    } catch {
        ErrSafe "Error running: $path"
        ErrSafe $_
        exit 1
    }
}

# ---------------------------------------------------------
# Run platform-specific windows setup
# ---------------------------------------------------------
Run-Script $ENTRY

# ---------------------------------------------------------
# Finish
# ---------------------------------------------------------
InfoSafe "──────────────────────────────────────────────"
OkSafe   "   MUNIR – Windows ROOT Setup completed! 🎉"
InfoSafe "──────────────────────────────────────────────"
