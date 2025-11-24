# 📦 homelab

Cross-platform setup automation for macOS, Windows, and Synology, plus Docker-based Homelab stack management.

This repository provides a collection of Shell, PowerShell, and Synology scripts, as well as multiple Docker Compose stacks, to automate the setup and administration of your homelab.

## 📁 Repository Structure

```txt
homelab/
├── 📂 .github/
│   ├── 📂 ISSUE_TEMPLATE/
│   │   ├── 📄 bug_report.yml
│   │   └── 📄 feature_request.yml
│   ├── 📂 workflows/
│   │   ├── ⚙️ codeql.yml
│   │   ├── ⚙️ labeler.yml
│   │   ├── ⚙️ release.yml
│   │   ├── ⚙️ setup-labels.yml
│   │   └── ⚙️ stale.yml
│   ├── ⚙️ CODEOWNERS
│   └── ⚙️ dependabot.yml
├── 📂 .vscode/
│   ├── ⚙️ extensions.json
│   └── ⚙️ settings.json
├── 📂 bash/
│   ├── 📂 .config/
│   │   ├── 🧩 p10k.zsh
│   │   ├── 🧩 .zshrc
│   │   └── 🎨 alacritty.toml
│   ├── 🍏 darwin/
│   │   ├── 💻 brew.sh
│   │   ├── 💻 config.sh
│   │   ├── 💻 globaly.sh
│   │   └── 🚀 index.sh
│   ├── 📦 synology/
│   │   ├── 🖥️ cli.sh
│   │   ├── 🔑 import_key.sh
│   │   ├── 🚀 index.sh
│   │   ├── 🔐 login.sh
│   │   ├── 🌐 remote.sh
│   │   └── 🔏 secret.txt
│   ├── 🛠️ utils/
│   │   ├── 🧩 utils.ps1
│   │   └── 🧩 utils.sh
│   ├── 🪟 windows/
│   │   ├── 📦 chocolatey.ps1
│   │   ├── 💻 config.ps1
│   │   ├── 💻 globaly.ps1
│   │   ├── 🚀 index.ps1
│   │   └── 💻 index.sh
│   ├── 🚀 index.sh
│   └── 🚀 index.ps1
├── 🐳 compose/
│   ├── 📊 checkmk.yml
│   ├── 🌐 hosting.yml
│   ├── 🛠️ management.yml
│   └── 🎮 retroassembly.yml
├── 🌱 .env.example
├── 🙈 .gitignore
├── 📜 LICENSE
├── 📝 install.log
└── 📖 README.md
```

## 🚀 Features

### macOS Setup (bash/darwin/)

- ✔ Brew bootstrap
- ✔ macOS system defaults
- ✔ CLI tools installation
- ✔ Development environment setup (zsh, config, utils)

### Windows Setup (windows/)

- ✔ PowerShell-based setup (apps, environment, configs)
- ✔ Chocolatey bootstrapping
- ✔ Utilities for administration

### Synology Scripts (bash/synology/)

- ✔ Key import automation
- ✔ Remote control
- ✔ CLI tools for DSM
- ✔ Login & configuration helpers

### Shared Utilities (bash/utils & windows/utils.ps1)

- ✔ Log handling
- ✔ Validations
- ✔ Helper functions
- ✔ Colorized console output

## Docker-Compose Stacks (compose/)

Each stack is modular and optional:

| File                | Purpose                  |
| ------------------- | ------------------------ |
| `checkmk.yml`       | Monitoring               |
| `hosting.yml`       | Web hosting environment  |
| `management.yml`    | Admin & infra management |
| `retroassembly.yml` | Retro gaming / emu setup |

## 🛠 Installation

### macOS

```bash
git clone https://github.com/munirmardinli/homelab.git
cd homelab/bash/darwin
chmod +x index.sh
./index.sh
```

### Windows

```bash
git clone https://github.com/munirmardinli/homelab.git
cd homelab/windows
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\index.ps1
```
### Synology (DSM SSH Shell)

```bash
git clone https://github.com/munirmardinli/homelab.git
cd homelab/bash/synology
chmod +x index.sh
sh index.sh
```

### 🐳 Docker Compose Stacks

Start a specific stack:

```bash
docker compose -f compose/checkmk.yml up -d
```

## 🔐 Security

- ✔ SECURITY.md
- ✔ GitHub Dependabot
- ✔ CodeQL (Shell + Dockerfile + PowerShell Analyzers)
- ✔ Automated Release Builds

## 📜 License

MIT License — freely usable.
