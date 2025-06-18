# 🛡 SECURITY.md

## 🔐 Authentication

- **Autentik** is the central Identity Provider (IdP) for all services.  
- SSO via OpenID Connect is enabled for Dashy, GitLab, Nextcloud, Guacamole, Roundcube, etc.  
- Multi-factor authentication (MFA) is strongly recommended and can be enforced per user group.  
- Role-based access control (RBAC) is managed through Autentik.  

## ♻️ Updates & Automation

- **Watchtower** automatically updates containers when new image versions are available.  
- **Autoheal** monitors container healthchecks and restarts faulty containers.  
- Regular manual checks and version reviews are still recommended.  

## 🌐 Network & Proxy Security

- **Nginx Proxy Manager** manages SSL certificates, redirects, and HTTPS access.  
- **Cloudflared** provides secure tunnels to Cloudflare—no port forwarding needed.  
- **Pi-hole** blocks tracking, ads, and known malware domains via DNS filtering.  
- Host firewall settings (e.g., ufw) should restrict Docker access to localhost only.  

## 🗝️ Secrets & Credentials

- All credentials and tokens are stored **locally in the `secrets/` directory**.  
- The `.env` file contains no sensitive data, only service configuration.  
- The `secrets/` folder is listed in `.gitignore` and must **never be committed**.  

## 🔐 Certificates

- Certificates are automatically issued via **Let's Encrypt** through Nginx Proxy Manager.  
- Alternatively, a Cloudflare API key can be used for DNS-01 challenges.  
- Custom certificates can also be placed in the `secrets/` folder and used.  

## 💾 Backup & Recovery

- Services with persistent data (e.g., GitLab, Nextcloud, Obsidian) write to named volumes or dedicated mounts.  
- Backups of these volumes should be automated regularly using tools like:  
  - `borg`, `restic`, `duplicati` or simple `rsync` cron jobs.  
- At least one external, encrypted offsite backup is recommended.  

## 🧩 Container Hardening

- Only **official or vetted** Docker images are used.  
- Rootless mode or restricted user permissions are configured where possible.  
- Security updates are applied automatically via Watchtower and manual review.  

## 📋 Logging & Audit

- Logs of all services are accessible via `docker logs` or can be forwarded externally to syslog, Grafana Loki, etc.  
- Optional: integration with monitoring tools like Prometheus, Grafana, Loki, Uptime Kuma.  

---

## 📌 Recommendations

- Use **SSH access only with key pairs**, no password logins.  
- Employ `fail2ban` or similar tools for host hardening.  
- Use VLANs, dedicated networks, or firewalls to segment sensitive services.  
- Keep the system, Docker engine, and all dependencies up to date.  
