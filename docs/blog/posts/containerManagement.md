---
title: Container Management
authors:
  - Munir
tags:
  - Monitoring
  - Maintenance
categories:
  - Infrastructure
status: true
visibility: true
robots: index, follow
slug: management
comments: true
---

# Container Management Tools

Production-grade container monitoring, auto-healing and dashboard solutions.

## 🛠️ Service Configuration

- Logging (`default-logging`)
- Labels (`default-labels`)
- Resource limits (`resource-limits`)

### Core Services

=== "Watchtower"
    ```yaml hl_lines="13-37" linenums="1"
    watchtower:
      image: containrrr/watchtower
      container_name: watchtower
      hostname: watchtower
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=watchtower
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
        WATCHTOWER_CLEANUP: true # (3)
        WATCHTOWER_LABEL_ENABLE: true # (4)
        WATCHTOWER_DEBUG: true # (5)
        WATCHTOWER_ROLLING_RESTART: true # (6)
        WATCHTOWER_INCLUDE_STOPPED: true # (7)
        NO_COLOR: 1 # (8)
        WATCHTOWER_NO_SETUP_MESSAGE: true # (9)
        WATCHTOWER_TIMEOUT: 30s # (10)
        WATCHTOWER_NO_RESTART: false # (11)
        WATCHTOWER_POLL_INTERVAL: 30 # (12)
        WATCHTOWER_HTTP_API_UPDATE: true # (13)
        WATCHTOWER_HTTP_API_METRICS: true # (14)
        WATCHTOWER_HTTP_API_PERIODIC_POLLS: true # (15)
        DOCKER_TLS_VERIFY: true # (16)
        WATCHTOWER_LOG_LEVEL: info # (17)
        DOCKER_API_VERSION: 1.41 # (18)
        WATCHTOWER_REMOVE_VOLUMES: false # (19)
        WATCHTOWER_TRACE: true # (20)
        WATCHTOWER_HTTP_API_TOKEN: ${WATCHTOWER_HTTP_API_TOKEN:? Token is missing} # (21)
        WATCHTOWER_NOTIFICATIONS: gotify # (22)
        WATCHTOWER_NOTIFICATIONS_LEVEL: info # (23)
        WATCHTOWER_NOTIFICATION_GOTIFY_URL: https://gotify.${SYNOLOGY_BASIC_URL} # (24)
        WATCHTOWER_NOTIFICATION_GOTIFY_TOKEN: ${WATCHTOWER_NOTIFICATION_GOTIFY_TOKEN:?Token is Required} # (25)
      ports:
        - "8080:8080"
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
          source: /root/.docker/config.json
          target: /root/.docker/config.json
          read_only: true
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: watchtower
    ```

    1. → User ID for permissions (default: 1026)
    2. → Group ID for permissions (default: 100)
    3. → Automatically clean up old images
    4. → Enable container monitoring by label
    5. → Enable debug mode
    6. → Enable rolling restarts
    7. → Monitor stopped containers
    8. → Disable colored output
    9. → Disable setup message
    10. → Container stop timeout (30s)
    11. → Disable container restarts (false)
    12. → Check interval in seconds (30)
    13. → Enable HTTP API updates
    14. → Enable metrics endpoint
    15. → Enable periodic polls via API
    16. → Enable TLS verification
    17. → Log level (info)
    18. → Docker API version (1.41)
    19. → Remove volumes with containers (false)
    20. → Enable trace logging
    21. → Required API token
    22. → Notification service (gotify)
    23. → Notification level (info)
    24. → Gotify server URL
    25. → Gotify access token

=== "Autoheal"
    ```yaml hl_lines="13-19" linenums="1"
    autoheal:
      image: willfarrell/autoheal
      container_name: autoheal
      hostname: autoheal
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=autoheal
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
        AUTOHEAL_INTERVAL: 60s # (3)
        AUTOHEAL_CONTAINER_LABEL: recreat.container # (4)
        DOCKER_HOST: unix:///var/run/docker.sock # (5)
        WEBHOOK_URL: https://gotify.${SYNOLOGY_BASIC_URL}/message?token=${WATCHTOWER_NOTIFICATION_GOTIFY_TOKEN} # (6)
        AUTOHEAL_ONLY_MONITOR_RUNNING: false # (7)
      volumes:
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
        monitoring: autoheal
    ```

    1. → User ID for permissions (default: 1026)
    2. → Group ID for permissions (default: 100)
    3. → Health check interval (60s)
    4. → Label to identify containers to monitor
    5. → Docker socket path
    6. → Gotify webhook URL for notifications
    7. → Monitor only running containers (false)

=== "Dashy"
    ```yaml hl_lines="21-22" linenums="1"
    dashy:
      container_name: dashy
      hostname: dashy
      image: lissy93/dashy:latest
      restart: always
      cap_drop:
        - ALL
      cap_add:
        - CHOWN
        - SETGID
        - SETUID
        - DAC_OVERRIDE
        - NET_BIND_SERVICE
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=dashy
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
      ports:
        - "${DASHY_PORT:-90}:8080"
      volumes:
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/development/config/dashy.yml
          target: /app/user-data/conf.yml
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      networks:
        - dockerization
      labels:
        <<: *default-labels
        monitoring: dashy
    ```

    1. → User ID for permissions (default: 1026)
    2. → Group ID for permissions (default: 100)

=== "Roundcube"
    ```yaml linenums="1"
    roundcube:
      image: roundcube/roundcubemail:latest
      container_name: roundcube
      hostname: roundcube
      restart: always
      ports:
        - "${ROUNDCUBE_PORT:-9002}:8080"
      volumes:
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/www:/var/www/html
          target: /var/roundcube/db
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/config
          target: /var/roundcube/config
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/db
          target: /var/www/html
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: roundcube
    ```

=== "Guacamole"
    ```yaml hl_lines="15-18" linenums="1"
    guacamole:
      image: ${image_guacamole:-jwetzell/guacamole}
      container_name: guacamole
      hostname: guacamole
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=guacamole
      ports:
        - "${GUACMOLE_PORT:-8348}:8080"
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
        GUACD_LOG_LEVEL: info # (3)
        GUACD_PORT: 80 # (4)
      volumes:
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/guacamole
          target: /config
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/logs/guacamole
          target: /var/log/
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: guacamole
    ```

    1. → User ID for permissions (default: 1026)
    2. → Group ID for permissions (default: 100)
    3. → Log level (info)
    4. → Guacamole daemon port (80)

## 🔐 Required Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `UID_NAS_ADMIN` | User ID for volume permissions | ⚠️ Recommended |
| `GID_NAS_ADMIN` | Group ID for volume permissions | ⚠️ Recommended |
| `WATCHTOWER_HTTP_API_TOKEN` | Watchtower API token | ✅ |
| `WATCHTOWER_NOTIFICATION_GOTIFY_TOKEN` | Gotify notification token | ✅ |
| `MOUNT_PATH_DOCKER_ROOT` | Base storage path | ✅ |
| `SYNOLOGY_BASIC_URL` | Base domain for services | ✅ |
| `DASHY_PORT` | Dashy web interface port | ⚠️ Recommended |
| `ROUNDCUBE_PORT` | Roundcube web interface port | ⚠️ Recommended |
| `GUACMOLE_PORT` | Guacamole web interface port | ⚠️ Recommended |
| `image_guacamole` | Guacamole image override | ⚠️ Optional |

!!! warning "Security Notice"
    - Be stored in `.env` files
    - Have restricted permissions (`chmod 600`)
    - Never be committed to version control
    - Be rotated periodically

## 🚀 Deployment

1. Create `.env` file with required variables
2. *Initialize volumes*
```bash
mkdir -p ${MOUNT_PATH_DOCKER_ROOT}/{guacamole,logs/guacamole,development/config,www,config,db}
chown -R ${UID_NAS_ADMIN:-1026}:${GID_NAS_ADMIN:-100} ${MOUNT_PATH_DOCKER_ROOT}
```
3. **Start services**
```bash
docker-compose up -d
```

### 🔄 Maintenance

- **Updates**
```bash
docker-compose pull && docker-compose up -d
```
- **Logs**
```bash
docker-compose logs -f
```
