# utils.ps1
# PowerShell Utilities (Windows equivalent to utils.sh)

$Global:LOGFILE = "install.log"

# ----------------------------------------------------------
# Timestamp
# ----------------------------------------------------------
function Timestamp {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

# ----------------------------------------------------------
# Logging Core
# ----------------------------------------------------------
function LogWrite($type, $msg) {
    Add-Content -Path $LOGFILE -Value "[$(Timestamp)] $type: $msg"
}

# ----------------------------------------------------------
# Styled Output
# ----------------------------------------------------------
function Ok($msg) {
    Write-Host "✔ $msg" -ForegroundColor Green
    LogWrite "OK" $msg
}

function Info($msg) {
    Write-Host "ℹ $msg" -ForegroundColor Cyan
    LogWrite "INFO" $msg
}

function Warn($msg) {
    Write-Host "⚠ $msg" -ForegroundColor Yellow
    LogWrite "WARN" $msg
}

function Err($msg) {
    Write-Host "❌ $msg" -ForegroundColor Red
    LogWrite "ERROR" $msg
}

# ----------------------------------------------------------
# run-safe (eval wrapper)
# ----------------------------------------------------------
function Run-Safe($command) {
    Info "RUN: $command"
    try {
        Invoke-Expression $command
        if ($LASTEXITCODE -ne 0) {
            throw "Exit Code $LASTEXITCODE"
        }
    } catch {
        Err "Error executing: $command"
        Err $_
        exit 1
    }
}

# ----------------------------------------------------------
# Email Validation
# ----------------------------------------------------------
function Is-ValidEmail($email) {
    return $email -match '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
}

function Ask-Email {
    while ($true) {
        $email = Read-Host "Please enter your Git email address"

        if (Is-ValidEmail $email) {
            Ok "Email accepted: $email"
            return $email
        } else {
            Warn "Invalid email format. Example: user@example.com"
        }
    }
}
