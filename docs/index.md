---
title: Home
tags:
  - Global
categories:
  - Global
authors:
  - Munir
status: true
visibility: true
robots: index, follow
custom_field:
  custom_key: custom_value
comments: true
---

<a href="https://www.buymeacoffee.com/munirmardinli" target="_blank">
  <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=munirmardinli&button_colour=40DCA5&font_colour=ffffff&font_family=Cookie&outline_colour=000000&coffee_colour=FFDD00" />
</a>

This repository contains a Docker Compose environment for a private homelab focused on **security**, **automation**, **authentication**, and **developer productivity**.

## 📦 Included Services

=== "🔐 Authentication"
    **Autentik**: OpenID Connect provider for SSO across all services

=== "🛠 System Services"
    - **Watchtower**: Automatic container updates
    - **Autoheal**: Restarts faulty containers
    - **Dashy**: Homepage with links and status overview
    - **Roundcube**: Webmail client
    - **Guacamole**: Remote desktop gateway (RDP, SSH, etc.)

=== "💻 Development"
    - **Code-Server**: Web-based VS Code
    - **Obsidian Server**: Central knowledge base
    - **GitLab & GitLab-Runner**: Private CI/CD platform

=== "☁️ Cloud & Proxy"
    - **Nextcloud**: File hosting
    - **Pi-hole**: Network-wide ad blocker
    - **Cloudflared**: Secure tunnels
    - **Nginx Proxy Manager**: SSL and reverse proxy

## 🚀 Setup

=== "Prerequisites"
    - Docker & Docker Compose
    - Configured `.env` file
    - Valid domain and DNS setup (Cloudflare recommended)

=== "Starting"
    ```bash
    cd docker
    docker-compose -f <filename>.yml up -d
    ```

=== "Configuration"
    - All environment variables are defined in the `.env` file
    - Secrets like passwords, certificates, and API keys belong in the `secrets/` folder
    - Never commit secrets to the Git repository!
    - HTTPS is managed via Nginx Proxy Manager — ideally combined with Cloudflare as DNS provider

## 🌍 Services Overview

| Service     | Example URL                     | Auth via Autentik |
|------------|---------------------------------|-------------------|
| Dashy      | `https://dashy.deinedomain.tld` | ✅                |
| GitLab     | `https://git.deinedomain.tld`   | ✅                |
| Nextcloud  | `https://cloud.deinedomain.tld` | ✅                |
| Guacamole  | `https://remote.deinedomain.tld`| ✅                |
| Roundcube  | `https://mail.deinedomain.tld`  | ✅                |
