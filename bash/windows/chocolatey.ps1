# chocolatey.ps1
# Windows Setup basierend auf macOS brew.sh
# ---------------------------------------------------------------

Write-Host "──────────────────────────────────────────────"
Write-Host "   🚀 Windows Setup via Chocolatey gestartet"
Write-Host "──────────────────────────────────────────────"

# ===============================================================
# Logging
# ===============================================================

$LogFile = "install.log"

Function LogWrite($type, $msg) {
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Add-Content $LogFile "[$timestamp] $type: $msg"
}

Function Info($msg) {
    Write-Host "ℹ $msg" -ForegroundColor Cyan
    LogWrite "INFO" $msg
}

Function Ok($msg) {
    Write-Host "✔ $msg" -ForegroundColor Green
    LogWrite "OK" $msg
}

Function Warn($msg) {
    Write-Host "⚠ $msg" -ForegroundColor Yellow
    LogWrite "WARN" $msg
}

Function Err($msg) {
    Write-Host "❌ $msg" -ForegroundColor Red
    LogWrite "ERROR" $msg
}

# ===============================================================
# Chocolatey Installation
# ===============================================================

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Info "Chocolatey nicht gefunden – Installation gestartet…"
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    if ($LASTEXITCODE -ne 0) {
        Err "Chocolatey Installation fehlgeschlagen."
        exit 1
    }
    Ok "Chocolatey erfolgreich installiert."
} else {
    Ok "Chocolatey bereits installiert."
}

choco feature enable -n allowGlobalConfirmation | Out-Null

# ===============================================================
# Brew → Chocolatey Package Mapping
# ===============================================================

$brewPackages = @(
    "wget",
    "node",
    "git",
    "mas",                      # macOS-only → SKIP
    "sshpass",                  # Windows alternative
    "powerlevel10k",            # oh-my-posh
    "zsh-syntax-highlighting",  # irrelevant on Windows
    "zsh-autosuggestions",      # irrelevant
    "zsh-completions",          # irrelevant
    "bat",
    "neovim",
    "eza",
    "zsh",                      # Windows optional
    "fzf",
    "fontconfig",               # irrelevant
    "diff-so-fancy",
    "zoxide"
)

# Chocolatey mapping
$chocoMap = @{
    "wget"                      = "wget"
    "node"                      = "nodejs"
    "git"                       = "git"
    "sshpass"                   = "sshpass"       # exists in community
    "powerlevel10k"             = "oh-my-posh"
    "bat"                       = "bat"
    "neovim"                    = "neovim"
    "eza"                       = "eza"
    "zsh"                       = "zsh"           # optional
    "fzf"                       = "fzf"
    "diff-so-fancy"             = "diff-so-fancy"
    "zoxide"                    = "zoxide"
}

# Pakete überspringen, die Windows nicht braucht
$skip = @("mas", "fontconfig", "zsh-syntax-highlighting", "zsh-autosuggestions", "zsh-completions")

# ===============================================================
# Installation der Packages
# ===============================================================

Function Install-Package-Safely($pkg) {
    for ($i = 1; $i -le 3; $i++) {
        Try {
            choco install $pkg -y --ignore-checksums
            Ok "$pkg erfolgreich installiert."
            return
        }
        Catch {
            Warn "Fehler beim Installieren von $pkg (Versuch $i/3)."
            Start-Sleep -Seconds 2
        }
    }
    Err "Installation von $pkg nach 3 Versuchen fehlgeschlagen."
}

Info "Installing Chocolatey Packages..."

foreach ($pkg in $brewPackages) {

    if ($skip -contains $pkg) {
        Warn "Überspringe macOS-only Paket: $pkg"
        continue
    }

    if (-not $chocoMap.ContainsKey($pkg)) {
        Warn "Kein Chocolatey-Equivalent für: $pkg"
        continue
    }

    $target = $chocoMap[$pkg]

    if (choco list --local-only | Select-String -Pattern "^$target") {
        Ok "$target ist bereits installiert."
    } else {
        Info "Installiere $target..."
        Install-Package-Safely $target
    }
}

# ===============================================================
# Casks (macOS) ➜ Windows Apps Mapping
# ===============================================================

Info "Installing Windows Apps..."

$casks = @(
    "font-fira-code-nerd-font",
    "font-jetbrains-mono-nerd-font",
    "font-meslo-lg-nerd-font",
    "google-chrome",
    "cursor",
    "chatgpt-atlas",
    "antigravity",
    "alacritty"
)

$chocoCaskMap = @{
    "font-fira-code-nerd-font"   = "firacode"
    "font-jetbrains-mono-nerd-font" = "jetbrainmono"
    "font-meslo-lg-nerd-font"    = "nerd-fonts-meslo"
    "google-chrome"              = "googlechrome"
    "cursor"                     = "cursor"          # falls eigenes Paket
    "chatgpt-atlas"              = "chatgpt"         # Beispiel, falls verfügbar
    "antigravity"                = ""                # optional
    "alacritty"                  = "alacritty"
}

foreach ($c in $casks) {

    if (-not $chocoCaskMap[$c]) {
        Warn "Kein Windows-Equivalent gefunden für: $c"
        continue
    }

    $mapped = $chocoCaskMap[$c]

    if (choco list --local-only | Select-String -Pattern "^$mapped") {
        Ok "$mapped bereits installiert."
    } else {
        Info "Installiere Windows App: $mapped"
        Install-Package-Safely $mapped
    }
}

Ok "Windows Chocolatey Setup abgeschlossen! 🎉"
