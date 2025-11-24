#!/usr/bin/env pwsh
<#
Windows Index Script
führt chocolatey.ps1 aus (analog zu macOS index.sh)
#>

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$UTILS = Join-Path $SCRIPT_DIR "..\utils\utils.ps1"
$CHOCO_SCRIPT = Join-Path $SCRIPT_DIR "chocolatey.ps1"

# ---------------------------------------------------------
# Utils laden (falls vorhanden)
# ---------------------------------------------------------
if (Test-Path $UTILS) {
    . $UTILS
} else {
    Write-Host "ℹ utils.ps1 nicht gefunden – fahre ohne Logging-Funktionen fort."
}

Function InfoSafe($msg) {
    if (Get-Command Info -ErrorAction SilentlyContinue) { Info $msg }
    else { Write-Host "ℹ $msg" -ForegroundColor Cyan }
}

Function OkSafe($msg) {
    if (Get-Command Ok -ErrorAction SilentlyContinue) { Ok $msg }
    else { Write-Host "✔ $msg" -ForegroundColor Green }
}

Function ErrSafe($msg) {
    if (Get-Command Err -ErrorAction SilentlyContinue) { Err $msg }
    else { Write-Host "❌ $msg" -ForegroundColor Red }
}

# ---------------------------------------------------------
# Startmeldung
# ---------------------------------------------------------
InfoSafe "──────────────────────────────────────────────"
InfoSafe "   🚀 MUNIR – Windows Setup STARTING"
InfoSafe "──────────────────────────────────────────────"

# ---------------------------------------------------------
# Script Runner (wie in index.sh)
# ---------------------------------------------------------
Function Run-Script($path) {
    if (-Not (Test-Path $path)) {
        ErrSafe "Script fehlt: $path"
        exit 1
    }

    InfoSafe "Starting $(Split-Path $path -Leaf)..."

    try {
        & $path
        if ($LASTEXITCODE -ne 0) {
            throw "Exit Code $LASTEXITCODE"
        }
    }
    catch {
        ErrSafe "Fehler beim Ausführen von $path"
        ErrSafe $_
        exit 1
    }
}

# ---------------------------------------------------------
# Chocolatey Setup ausführen
# ---------------------------------------------------------
Run-Script $CHOCO_SCRIPT

# ---------------------------------------------------------
# Abschluss
# ---------------------------------------------------------
InfoSafe "──────────────────────────────────────────────"
OkSafe   "   MUNIR – Windows Setup erfolgreich! 🎉"
InfoSafe "──────────────────────────────────────────────"
