---
title: Authentik Configuration
tags:
  - Authentication
  - SSO
categories:
  - Security
authors:
  - Munir
status: true
robots: index, follow
visibility: true
slug: authentik
comments: true
---

# Authentik Identity Provider

Production-ready identity and access management solution with SSO, user directories, and multi-factor authentication.

## 🛠️ Service Configuration

- This setup uses the [shared Docker Compose anchors](../../global/sharedConfig.md) for:
- Logging (`default-logging`)
- Labels (`default-labels`)
- Resource limits (`resource-limits`)

### Core Services

=== "PostgreSQL"
    ```yaml hl_lines="27-31"
    postgresql:
      container_name: authentik-postgresql
      hostname: authentik-postgresql
      image: docker.io/library/postgres:16-alpine
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=authentik-postgresql
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -d $${POSTGRES_DB} -U $${POSTGRES_USER}"]
        start_period: 20s
        interval: 30s
        retries: 5
        timeout: 5s
      volumes:
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT:?path required}/authentik/database
          target: /var/lib/postgresql/data
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      environment:
        POSTGRES_PASSWORD: ${PG_PASS:?database password required} # (1)
        POSTGRES_USER: ${PG_USER:-authentik} # (2)
        POSTGRES_DB: ${PG_DB:-authentik} # (3)
        UID: ${UID_NAS_ADMIN:-1026} # optional (4)
        GID: ${GID_NAS_ADMIN:-100} # optional (5)
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: authentik-postgresql
    ```

    1. **POSTGRES_PASSWORD**
       → Required database password (must be set in `.env`)
    2. **POSTGRES_USER**
       → Database username (default: `authentik`)
    3. **POSTGRES_DB**
       → Database name (default: `authentik`)
    4. **UID**
       → Optional user ID for volume permissions (default: 1026)
    5. **GID**
       → Optional group ID for volume permissions (default: 100)

=== "Redis"
    ```yaml hl_lines="28-29"
    redis:
      container_name: authentik-redis
      hostname: authentik-redis
      image: docker.io/library/redis:alpine
      command: --save 60 1 --loglevel warning
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=authentik-redis
      healthcheck:
        test: ["CMD-SHELL", "redis-cli ping | grep PONG"]
        start_period: 20s
        interval: 30s
        retries: 5
        timeout: 3s
      volumes:
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/authentik/redis
          target: /data
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # optional (1)
        GID: ${GID_NAS_ADMIN:-100} # optional (2)
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: authentik-redis
    ```

    1. → Optional user ID for volume permissions (default: 1026)
    2. → Optional group ID for volume permissions (default: 100)

=== "Authentik Server"
    ```yaml hl_lines="14-23"
    authentik:
      container_name: authentik
      hostname: authentik
      image: ${AUTHENTIK_IMAGE:-ghcr.io/goauthentik/server}:${AUTHENTIK_TAG:-2025.2.1}
      restart: always
      command: server
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=authentik
      environment:
        AUTHENTIK_REDIS__HOST: redis # (1)
        AUTHENTIK_POSTGRESQL__HOST: postgresql # (2)
        AUTHENTIK_POSTGRESQL__USER: ${PG_USER:-authentik} # (3)
        AUTHENTIK_POSTGRESQL__NAME: ${PG_DB:-authentik} # (4)
        AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS} # (5)
        AUTHENTIK_BOOTSTRAP_EMAIL: ${EMAIL} # (6)
        AUTHENTIK_BOOTSTRAP_PASSWORD: ${AUTHENTIK_BOOTSTRAP_PASSWORD} # (7)
        AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY} # (8)
        UID: ${UID_NAS_ADMIN:-1026} # optional (9)
        GID: ${GID_NAS_ADMIN:-100} # optional (10)
      volumes:
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/authentik/media
          target: /media
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/authentik/templates
          target: /templates
      ports:
        - "${COMPOSE_PORT_HTTP:-9001}:9000"
        - "${COMPOSE_PORT_HTTPS:-9443}:9443"
      depends_on:
        postgresql:
          condition: service_healthy
        redis:
          condition: service_healthy
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: authentik
    ```

    1. → Redis hostname (using Docker service name)
    2. → PostgreSQL hostname (using Docker service name)
    3. → PostgreSQL username (matches `POSTGRES_USER`)
    4. → Database name (matches `POSTGRES_DB`)
    5. → Must match `POSTGRES_PASSWORD`
    6. → Initial admin email (must be set in `.env`)
    7. → Initial admin password (must be set in `.env`)
    8. → Encryption key (must be set in `.env`)
    9. → User ID for volume permissions (default: 1026)
    10. → Group ID for volume permissions (default: 100)

=== "Authentik Worker"
    ```yaml hl_lines="14-23"
    worker:
      container_name: authentik-worker
      hostname: authentik-worker
      image: ${AUTHENTIK_IMAGE:-ghcr.io/goauthentik/server}:${AUTHENTIK_TAG:-2025.2.1}
      restart: always
      command: worker
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=authentik-worker
      environment:
        AUTHENTIK_REDIS__HOST: redis # (1)
        AUTHENTIK_POSTGRESQL__HOST: postgresql # (2)
        AUTHENTIK_POSTGRESQL__USER: ${PG_USER:-authentik} # (3)
        AUTHENTIK_POSTGRESQL__NAME: ${PG_DB:-authentik} # (4)
        AUTHENTIK_POSTGRESQL__PASSWORD: ${PG_PASS} # (5)
        AUTHENTIK_BOOTSTRAP_EMAIL: ${EMAIL} # (6)
        AUTHENTIK_BOOTSTRAP_PASSWORD: ${AUTHENTIK_BOOTSTRAP_PASSWORD} # (7)
        AUTHENTIK_SECRET_KEY: ${AUTHENTIK_SECRET_KEY} # (8)
        UID: ${UID_NAS_ADMIN:-1026} # optional (9)
        GID: ${GID_NAS_ADMIN:-100} # optional (10)
      user: root
      volumes:
        - type: bind
          source: /var/run/docker.sock
          target: /var/run/docker.sock
          read_only: true
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/authentik/media
          target: /media
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/authentik/certs
          target: /certs
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/authentik/templates
          target: /templates
      depends_on:
        postgresql:
          condition: service_healthy
        redis:
          condition: service_healthy
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: authentik
    ```

    1. → Redis hostname (using Docker service name)
    2. → PostgreSQL hostname (using Docker service name)
    3. → PostgreSQL username (matches `POSTGRES_USER`)
    4. → Database name (matches `POSTGRES_DB`)
    5. → Must match `POSTGRES_PASSWORD`
    6. → Initial admin email (must be set in `.env`)
    7. → Initial admin password (must be set in `.env`)
    8. → Encryption key (must be set in `.env`)
    9. → User ID for volume permissions (default: 1026)
    10. → Group ID for volume permissions (default: 100)

## 🔐 Required Environment Variables

Refer to [Environment Variables](../../global/index.md) documentation for:

| Variable | Description | Required |
|----------|-------------|----------|
| `PG_PASS` | PostgreSQL password | ✅ |
| `AUTHENTIK_BOOTSTRAP_PASSWORD` | Initial admin password | ✅ |
| `AUTHENTIK_SECRET_KEY` | Encryption key | ✅ |
| `MOUNT_PATH_DOCKER_ROOT` | Storage path | ✅ |
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
mkdir -p ${MOUNT_PATH_DOCKER_ROOT}/authentik/{database,redis,media,certs,templates}
chown -R ${UID_NAS_ADMIN:-1026}:${GID_NAS_ADMIN:-100} ${MOUNT_PATH_DOCKER_ROOT}/authentik
```
3. **Start services**
```bash
docker-compose up -d
```
4. Access web UI at `https://yourdomain.com:9443`

### 🔄 Maintenance

- **Backups**
	- Regularly backup the PostgreSQL volume
- **Updates**
```bash
docker-compose pull
docker-compose up -d
```
- **Logs**
```bash
docker-compose logs -f
```
