---
title: Nextcloud Configuration
tags:
  - File Sharing
  - Collaboration
categories:
  - Productivity
status: true
robots: index, follow
visibility: true
slug: nextcloud
comments: true
authors:
  - Munir
---

# Nextcloud Setup

Self-hosted productivity platform with file sync & share, calendars, contacts and more.

## 🛠️ Service Configuration

- This setup uses the [shared Docker Compose anchors](../../global/sharedConfig.md) for
- Logging (`default-logging`)
- Labels (`default-labels`)
- Resource limits (`resource-limits`)

### Core Services

=== "PostgreSQL"
    ```yaml hl_lines="18-22"
    nextcloud-postgres:
      image: postgres:latest
      container_name: nextcloud-postgres
      hostname: nextcloud-postgres
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=nextcloud-postgres
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
        interval: 10s
        timeout: 5s
        retries: 5
      environment:
        POSTGRES_USER: ${POSTGRES_USER:-nextcloud} # (1)
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-nextcloud} # (2)
        POSTGRES_DB: ${POSTGRES_DB:-nextcloud} # (3)
        UID: ${UID_NAS_ADMIN:-1026} # optional (4)
        GID: ${GID_NAS_ADMIN:-100} # optional (5)
      volumes:
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT:?path required}/nextcloud/db
          target: /var/lib/postgresql/data
      labels:
        <<: *default-labels
        monitoring: nextcloud-postgress
      networks:
        dockerization:
    ```

    1. → Database username (default: `nextcloud`)
    2. → Database password (default: `nextcloud`)
    3. → Database name (default: `nextcloud`)
    4. → Optional user ID for volume permissions (default: 1026)
    5. → Optional group ID for volume permissions (default: 100)

=== "Redis"
    ```yaml hl_lines="20-21"
    nextcloud-redis:
      image: redis:alpine
      container_name: nextcloud-redis
      hostname: nextcloud-redis
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=nextcloud-redis
      healthcheck:
        test: ["CMD", "redis-cli", "ping"]
        interval: 10s
        timeout: 5s
        retries: 5
      networks:
        dockerization:
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # optional (1)
        GID: ${GID_NAS_ADMIN:-100} # optional (2)
      volumes:
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      labels:
        <<: *default-labels
        monitoring: nextcloud-redis
    ```

    1. → Optional user ID for volume permissions (default: 1026)
    2. → Optional group ID for volume permissions (default: 100)

=== "Nextcloud"
    ```yaml hl_lines="29-43"
    nextcloud:
      image: nextcloud:latest
      container_name: nextcloud
      hostname: nextcloud
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=nextcloud
      healthcheck:
        test: ["CMD-SHELL", "curl --fail http://localhost:80 || exit 1"]
        interval: 60s
        retries: 5
        start_period: 20s
        timeout: 10s
      ports:
        - "${NEXT_CLOUD_PORT:-81}:80"
      volumes:
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/nextcloud/app
          target: /var/www/html
      environment:
        POSTGRES_USER: ${POSTGRES_USER:-nextcloud} # (1)
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-nextcloud} # (2)
        POSTGRES_DB: ${POSTGRES_DB:-nextcloud} # (3)
        POSTGRES_HOST: ${POSTGRES_HOST:-nextcloud-postgres} # (4)
        NEXTCLOUD_DATADIR: /mnt/ncdata # (5)
        NEXTCLOUD_UPLOAD_LIMIT: 10G # (6)
        NEXTCLOUD_MEMORY_LIMIT: 512M # (7)
        TRUSTED_DOMAINS: nextcloud.${SYNOLOGY_BASIC_URL:?Synology URL required} # (8)
        SMTP_HOST: ${SMTP_HOST:-smtp.mail.me.com} # (9)
        SMTP_SECURE_MODE: tls # (10)
        SMTP_PORT: ${SMTP_PORT:-587} # (11)
        SMTP_NAME: ${EMAIL} # (12)
        SMTP_PASSWORD: ${SMTP_PASSWORD} # (13)
        UID: ${UID_NAS_ADMIN:-1026} # optional (14)
        GID: ${GID_NAS_ADMIN:-100} # optional (15)
      depends_on:
        nextcloud-postgres:
          condition: service_healthy
        nextcloud-redis:
          condition: service_healthy
      labels:
        <<: *default-labels
        monitoring: nextcloud
      networks:
        dockerization:
    ```

    1. → PostgreSQL username (matches database service)
    2. → PostgreSQL password (matches database service)
    3. → Database name (matches database service)
    4. → Database hostname (using Docker service name)
    5. → Data storage path inside container
    6. → Max upload size (10GB)
    7. → PHP memory limit (512MB)
    8. → Trusted domain (required)
    9. → SMTP server for email
    10. → SMTP encryption (TLS)
    11. → SMTP port (587)
    12. → Email address for SMTP auth
    13. → SMTP password (must be set in `.env`)
    14. → User ID for volume permissions (default: 1026)
    15. → Group ID for volume permissions (default: 100)

## 🔐 Required Environment Variables

Refer to [Environment Variables](../../global/index.md) documentation for:

| Variable | Description | Required |
|----------|-------------|----------|
| `MOUNT_PATH_DOCKER_ROOT` | Storage path | ✅ |
| `SYNOLOGY_BASIC_URL` | Domain for trusted hosts | ✅ |
| `EMAIL` | Admin email for SMTP | ✅ |
| `SMTP_PASSWORD` | SMTP auth password | ✅ |
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
mkdir -p ${MOUNT_PATH_DOCKER_ROOT}/nextcloud/{db,app}
chown -R ${UID_NAS_ADMIN:-1026}:${GID_NAS_ADMIN:-100} ${MOUNT_PATH_DOCKER_ROOT}/nextcloud
```
3. Start services
```bash
docker-compose up -d
```
4. Access web UI at `http://yourdomain.com:81`
### 🔄 Maintenance

- **Backups**
	- Regularly backup both the PostgreSQL and app volumes
- **Updates**
```bash
docker-compose pull && docker-compose up -d
```
- **Logs**
```bash
docker-compose logs -f
```
