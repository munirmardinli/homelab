---
title: Core Services Configuration
tags:
  - Networking
  - DNS
  - Proxy
authors:
  - Munir
categories:
  - Infrastructure
status: true
robots: index, follow
visibility: true
slug: CoreServices
comments: true
---

# Core Infrastructure Services

Essential networking stack including DNS resolution, reverse proxy, and cloud tunneling.

## 🛠️ Service Configuration

- This setup uses the [shared Docker Compose anchors](../../global/sharedConfig.md) for:
- Logging (`default-logging`)
- Labels (`default-labels`)
- Resource limits (`resource-limits`)

### Core Services

=== "Cloudflare Tunnel"
    ```yaml hl_lines="14-16"
    cloudflared:
      container_name: cloudflared
      hostname: cloudflared
      image: cloudflare/cloudflared:latest
      command: tunnel --no-autoupdate run --token ${CLOUDFLARE_TOKEN:?CLOUDFLARE_TOKEN required}
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=cloudflared
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
        TUNNEL_METRICS: ${TUNNEL_METRICS:-0.0.0.0:8080} # (3)
      volumes:
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: cloudflared
    ```

    1. → User ID for volume permissions (default: 1026)
    2. → Group ID for volume permissions (default: 100)
    3. → Metrics endpoint (default: 0.0.0.0:8080)

=== "Pi-hole DNS"
    ```yaml hl_lines="30-45"
    pihole:
      container_name: pihole
      hostname: pihole
      image: pihole/pihole
      restart: always
      cap_add:
        - NET_ADMIN
      security_opt:
        - no-new-privileges=false
      deploy:
        resources:
          limits:
            memory: 512MB
      ulimits:
        nofile:
          soft: 65536
          hard: 65536
      healthcheck:
        test: ["CMD", "dig", "@127.0.0.1", "-p53", "pi.hole"]
        interval: 1m
        timeout: 10s
        retries: 3
        start_period: 30s
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=pihole
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
        FTLCONF_LOCAL_IPV4: ${FTLCONF_LOCAL_IPV4:-0.0.0.0} # (3)
        FTLCONF_LOCAL_IPV6: ${FTLCONF_LOCAL_IPV6:-::} # (4)
        PIHOLE_UID: ${PIHOLE_UID:-1000} # (5)
        PIHOLE_GID: ${PIHOLE_GID:-1000} # (6)
        DNSMASQ_USER: ${DNSMASQ_USER:-pihole} # (7)
        FTLCONF_dns_listeningMode: ${FTLCONF_dns_listeningMode:-all} # (8)
        FTLCONF_webserver_port: ${FTLCONF_webserver_port:-80} # (9)
        FTLCONF_webserver_api_password: ${PI_HOLE_PASSWORD:?Password is Missing} # (10)
        WEBTHEME: ${WEBTHEME:-dark} # (11)
        FTLCONF_dns_upstreams: ${FTLCONF_dns_upstreams:-1.1.1.1;1.0.0.1;8.8.8.8;8.8.4.4} # (12)
        FTLCONF_QUERY_LOGGING: ${FTLCONF_QUERY_LOGGING:-true} # (13)
        FTLCONF_MAXDBDAYS: ${FTLCONF_MAXDBDAYS:-30} # (14)
        FTLCONF_PRIVACYLEVEL: ${FTLCONF_PRIVACYLEVEL:-0} # (15)
        VIRTUAL_HOST: pihole.${SYNOLOGY_BASIC_URL} # (16)
      ports:
        - "53:53/tcp"
        - "53:53/udp"
        - "81:80/tcp"
      volumes:
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT:?path required}/config/dnsmasq.d
          target: /etc/dnsmasq.d
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/pihole
          target: /etc/pihole
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/logs/pihole
          target: /var/log/pihole
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: pihole
    ```

    1. → User ID for permissions (default: 1026)
    2. → Group ID for permissions (default: 100)
    3. → IPv4 listening address (default: 0.0.0.0)
    4. → IPv6 listening address (default: ::)
    5. → Pi-hole user ID (default: 1000)
    6. → Pi-hole group ID (default: 1000)
    7. → DNSMasq user (default: pihole)
    8. → DNS listening mode (default: all)
    9. → Web interface port (default: 80)
    10. → Required admin password
    11. → Web UI theme (default: dark)
    12. → Upstream DNS servers
    13. → Query logging (default: true)
    14. → Log retention (default: 30 days)
    15. → Privacy level (default: 0)
    16. → Virtual host URL

=== "Nginx Proxy Manager"
    ```yaml hl_lines="25-28"
    npm-proxy:
      container_name: npm-proxy
      hostname: npm-proxy
      image: jc21/nginx-proxy-manager:latest
      restart: always
      healthcheck:
        test:
          - CMD
          - curl
          - -f
          - http://localhost:81/ping
        interval: 30s
        timeout: 10s
        retries: 3
        start_period: 20s
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=npm-proxy
      ports:
        - ${NGNIX_PROXY_MANAGER_PORT:-84}:81
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
        INITIAL_ADMIN_EMAIL: ${EMAIL} # (3)
        INITIAL_ADMIN_PASSWORD: ${INITIAL_ADMIN_PASSWORD:?Password is missing} # (4)
      volumes:
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/ngx/data
          target: /data
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/development/config/ngx.json
          target: /app/config/production.json
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/ngx/letsencrypt
          target: /etc/letsencrypt
        - type: bind
          source: /var/run/docker.sock
          target: /var/run/docker.sock
          read_only: true
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: npm-proxy
    ```

    1. → User ID for permissions (default: 1026)
    2. → Group ID for permissions (default: 100)
    3. → Admin email address
    4. → Required admin password

## 🔐 Required Environment Variables

Refer to [Environment Variables](../../global/index.md) documentation for:

| Variable | Description | Required |
|----------|-------------|----------|
| `CLOUDFLARE_TOKEN` | Cloudflare Tunnel token | ✅ |
| `PI_HOLE_PASSWORD` | Pi-hole admin password | ✅ |
| `INITIAL_ADMIN_PASSWORD` | NPM admin password | ✅ |
| `MOUNT_PATH_DOCKER_ROOT` | Storage path | ✅ |
| `SYNOLOGY_BASIC_URL` | Base domain for services | ✅ |
| `UID_NAS_ADMIN` | User ID for volume permissions | ⚠️ Recommended |
| `GID_NAS_ADMIN` | Group ID for volume permissions | ⚠️ Recommended |

!!! warning "Security Notice"
    - Be stored in `.env` files
    - Have restricted permissions (`chmod 600`)
    - Never be committed to version control
    - Be rotated periodically

## 🚀 Deployment

1. Create `.env` file with required variables
2. *Initialize volumes*
```bash
mkdir -p ${MOUNT_PATH_DOCKER_ROOT}/{config/dnsmasq.d,pihole,logs/pihole,ngx/data,ngx/letsencrypt}
chown -R ${UID_NAS_ADMIN:-1026}:${GID_NAS_ADMIN:-100} ${MOUNT_PATH_DOCKER_ROOT}
```
3. **Start services**
```bash
docker-compose up -d
```

### 🔄 Maintenance

- **Backups**
	- Regularly backup volume directories
- **Updates**
```bash
docker-compose pull
docker-compose up -d
```
- **Logs**
```bash
docker-compose logs -f
```
