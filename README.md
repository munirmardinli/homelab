# 🐝 Honelab Docker Infrastructure

This repository contains a Docker Compose environment for a private homelab focused on security, automation, authentication, and developer productivity.

## 📦 Included Services

### 🔐 Authentication
- **Autentik**: OpenID Connect provider for SSO across all services

### 🛠 System Services
- **Watchtower**: Automatic container updates
- **Autoheal**: Restarts faulty containers
- **Dashy**: Homepage with links and status overview
- **Roundcube**: Webmail client for managing the internal mail server
- **Guacamole**: Remote desktop gateway for RDP, SSH, and more

### 💻 Development Environment
- **Code-Server**:  Web-based VS Code
- **Obsidian Server**: Central knowledge base
- **GitLab & GitLab-Runner**: Private CI/CD platform

### ☁️ Private Cloud & Proxy
- **Nextcloud**: File hosting and groupware
- **Pi-hole**: Network-wide ad blocker
- **Cloudflared**: Secure tunnels to Cloudflare
- **Nginx Proxy Manager**: SSL certificate and reverse proxy management

## 🚀 Setup

### Prerequisites
- Docker & Docker Compose
- Configured `.env` Datei (see example `.env.example`)
- Domain(s) + DNS access (recommended: Cloudflare)

## 🚀 Starting

1. Change to the Docker folder:

```bash
cd docker
```

2. Start the desired compose stack:

```bash
docker-compose -f <Datei-Name>.yml up -d
```

## 🔧 Configuration

- All environment variables are defined in the .env file
- Secrets like passwords, certificates, and API keys belong in the secrets/ folder (never commit these to the Git repository!)
- HTTPS is managed via Nginx Proxy Manager — ideally combined with Cloudflare as DNS provider

---

## 🌍 Services Overview

| Service     | Example URL                     | Auth via Autentik |
|------------|-----------------------------------|-------------------|
| Dashy      | `https://dashy.deinedomain.tld`   | ✅                |
| GitLab     | `https://git.deinedomain.tld`     | ✅                |
| Nextcloud  | `https://cloud.deinedomain.tld`   | ✅                |
| Guacamole  | `https://remote.deinedomain.tld`  | ✅                |
| Roundcube  | `https://mail.deinedomain.tld`    | ✅                |

## 🛡 Security

See [SECURITY.md](./SECURITY.md) for detailed notes on:

- Authentication (SSO via Autentik)
- Automatic updates and container healing
- Network hardening (e.g. proxy, DNS, tunnels)
- Backup strategies for persistent data

---

## 📜 License

MIT License – see [LICENSE](./LICENSE)
