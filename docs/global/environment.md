---
title: Environment
authors:
  - Munir
tags:
  - Globaly
categories:
  - Globaly
status: true
robots: index, follow
visibility: true
comments: true
hide:
  - toc
---

# ⚙️ Environment Variables

These environment variables configure all Homelab services. Store sensitive values in your `.env` file and reference them in Docker Compose.

=== "🔧 Core Configuration"
    | Variable | Description | Example |
    |----------|-------------|---------|
    | 📡 `SYNOLOGY_BASIC_URL` | Base URL for Synology services | `https://synology.yourdomain.com` |
    | 📂 `MOUNT_PATH_DOCKER_ROOT` | Docker volumes root path | `/mnt/docker` |
    | 📧 `EMAIL` | Primary contact email | `your@email.com` |

=== "🔐 Authentication Secrets"
    | Variable | Description | Security |
    |----------|-------------|----------|
    | 🔑 `PG_PASS` | PostgreSQL database password | 🔒 Sensitive |
    | 🔐 `AUTHENTIK_SECRET_KEY` | Autentik cryptographic key | 🔒 Sensitive |
    | 🛠️ `SUDO_PASSWORD_VSCODE` | VS Code container sudo password | 🔒 Sensitive |

=== "📨 Email Configuration"
    | Variable | Description | Required |
    |----------|-------------|----------|
    | 📩 `MAIL_RECEIVER` | Alert notifications recipient | `alerts@yourdomain.com` |
    | 📤 `SMTP_PASSWORD` | Outbound mail server password | 🔒 Yes |

=== "🌐 Networking"
    | Variable | Description | Service |
    |----------|-------------|---------|
    | 🌐 `CLOUDFLARE_TOKEN` | Cloudflare API token | 🔒 Tunnel/DNS |
    | 🚫 `PI_HOLE_PASSWORD` | Pi-hole admin interface | 🔒 DNS |

=== "🛡️ Security"
    | Variable | Description | Scope |
    |----------|-------------|-------|
    | 🔑 `INITIAL_ADMIN_PASSWORD` | Default admin password | Multiple services |
    | 🕵️‍♂️ `WATCHTOWER_HTTP_API_TOKEN` | Container update auth | 🔒 Watchtower |


!!! success "Best Practices"
    - **Always** use `.env` files for sensitive variables
    - Rotate credentials quarterly
    - Restrict permissions to `600`
    - Never commit to version control

!!! example "Sample .env File"
    ```bash
    # Core
    SYNOLOGY_BASIC_URL=synology.yourdomain.com
    MOUNT_PATH_DOCKER_ROOT=/mnt/docker

    # Secrets
    PG_PASS=strongpassword123
    AUTENTIK_SECRET_KEY=changeme
    ```
