---
title: Development Services Configuration
tags:
  - IDE
  - Version Control
  - Note Taking
categories:
  - Development
status: true
robots: index, follow
visibility: true
slug: development-services
comments: true
authors:
  - Munir
---

# Development Environment Stack

Integrated development environment with code editor, version control, and knowledge management.

## 🛠️ Service Configuration

- This setup uses the [shared Docker Compose anchors](../../global/sharedConfig.md) for:
- Logging (`default-logging`)
- Labels (`default-labels`)
- Resource limits (`resource-limits`)

### Development Services

=== "Code Server"
    ```yaml hl_lines="13-17"
    codeserver:
      container_name: codeserver
      hostname: codeserver
      image: ghcr.io/linuxserver/code-server
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=codeserver
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
        PASSWORD: ${SUDO_PASSWORD_VSCODE} # (3)
        PROXY_DOMAIN: codeserver.${SYNOLOGY_BASIC_URL} # (4)
        SUDO_PASSWORD: ${SUDO_PASSWORD_VSCODE} # (5)
      volumes:
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT:?path required}/obsidian
          target: /config
      ports:
        - ${CODE_SERVER:-82}:8443
      networks:
        - dockerization
      labels:
        <<: *default-labels
        monitoring: codeserver
    ```

    1. → User ID for volume permissions (default: 1026)
    2. → Group ID for volume permissions (default: 100)
    3. → Web interface password (must be set in `.env`)
    4. → Proxy domain for the service
    5. → Sudo password for terminal operations

=== "Obsidian"
    ```yaml hl_lines="32-35"
    obsidian:
      container_name: obsidian
      hostname: obsidian
      image: ghcr.io/linuxserver/obsidian:latest
      restart: always
      shm_size: "5gb"
      security_opt:
        - no-new-privileges:false
        - seccomp:unconfined
      healthcheck:
        test: timeout 10s bash -c ':> /dev/tcp/127.0.0.1/3000' || exit 1
        interval: 10s
        timeout: 5s
        retries: 3
        start_period: 90s
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=obsidian
      ports:
        - '${OBSIDIAN_PORT:-3421}:3000'
      volumes:
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/obsidian
          target: /config
      environment:
        CUSTOM_USER: ${EMAIL} # (1)
        PASSWORD: ${OBSIDIAN_PASSWORD} # (2)
        UID: ${UID_NAS_ADMIN:-1026} # (3)
        GID: ${GID_NAS_ADMIN:-100} # (4)
      networks:
        - dockerization
      labels:
        <<: *default-labels
        monitoring: obsidian
    ```

    1. → Login email address
    2. → Web interface password (must be set in `.env`)
    3. → User ID for volume permissions (default: 1026)
    4. → Group ID for volume permissions (default: 100)

=== "GitLab CE"
    ```yaml hl_lines="12-39"
    gitlab:
      container_name: gitlab
      hostname: "gitlab.${SYNOLOGY_BASIC_URL:?Synology URL required}"
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=gitlab
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
        GITLAB_OMNIBUS_CONFIG: | # (3)
          external_url 'https://gitlab.${SYNOLOGY_BASIC_URL}'
          gitlab_rails['gitlab_shell_ssh_port'] = 22
          gitlab_rails['gitlab_shell_git_timeout'] = 800
          gitlab_rails['gitlab_email_enabled'] = true
          gitlab_rails['gitlab_email_from'] = '${MAIL_RECEIVER}'
          gitlab_rails['gitlab_email_display_name'] = 'Synology Gitlab'
          gitlab_rails['gitlab_email_reply_to'] = '${MAIL_RECEIVER}'
          gitlab_rails['smtp_enable'] = true
          gitlab_rails['smtp_address'] = '${SMTP_HOST:-smtp.mail.me.com}'
          gitlab_rails['smtp_port'] = '${SMTP_PORT:-587}'
          gitlab_rails['smtp_user_name'] = '${EMAIL}'
          gitlab_rails['smtp_password'] = '${SMTP_PASSWORD}'
          gitlab_rails['smtp_domain'] = 'icloud.com'
          gitlab_rails['smtp_authentication'] = 'login'
          gitlab_rails['smtp_enable_starttls_auto'] = true
          gitlab_rails['gitlab_root_email'] = '${EMAIL}'
          gitlab_rails['lfs_enabled'] = true
          nginx['proxy_connect_timeout'] = 300
          nginx['proxy_read_timeout'] = 3600
          registry['enable'] = true
          registry_external_url 'https://gitlab.${SYNOLOGY_BASIC_URL}:${GITLAB_REGISTRY:-5005}'
      ports:
        - "${GITLAB_HTTPS:-5100}:443" # (4)
        - "${GITLAB_REGISTRY:-5101}:5005" # (5)
        - "${GITLAB_SSH:-5102}:22" # (6)
      volumes:
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/gitlab/config
          target: /etc/gitlab
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/logs/gitlab
          target: /var/log/gitlab
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/gitlab/data
          target: /var/opt/gitlab
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: gitlab
    ```

    1. → User ID for volume permissions (default: 1026)
    2. → Group ID for volume permissions (default: 100)
    3. → Base URL for GitLab instance
			 → SSH port for Git operations
		 	 → Git operation timeout (seconds)
			 → Enable email notifications
    	 → Sender email address
       → Email display name
       → Reply-to email address
       → Enable SMTP service
       → SMTP server address
       → SMTP server port
       → SMTP username
       → SMTP password (must be set in `.env`)
       → SMTP domain
       → SMTP auth method
       → Enable STARTTLS
       → Admin email address
       → Enable Git LFS support
       → Nginx connect timeout
       → Nginx read timeout
       → Enable container registry
       → Registry external URL
    4. → Web UI port (default: 5100)
    5. → Container registry port (default: 5101)
    6. → Git SSH port (default: 5102)

=== "GitLab Runner"
    ```yaml hl_lines="12-13"
    gitlab-runner:
      container_name: gitlab-runner
      hostname: gitlab-runner
      restart: always
      <<: *resource-limits
      logging:
        <<: *default-logging
        options:
          <<: *default-logging-options
          loki-external-labels: job=gitlab-runner
      environment:
        UID: ${UID_NAS_ADMIN:-1026} # (1)
        GID: ${GID_NAS_ADMIN:-100} # (2)
      volumes:
        - type: bind
          source: /etc/localtime
          target: /etc/localtime
          read_only: true
        - type: bind
          source: /var/run/docker.sock
          target: /var/run/docker.sock
          read_only: true
        - type: bind
          source: ${MOUNT_PATH_DOCKER_ROOT}/gitlab/runner
          target: /etc/gitlab-runner
      networks:
        dockerization:
      labels:
        <<: *default-labels
        monitoring: gitlab-runner
    ```

    1. → User ID for volume permissions (default: 1026)
    2. → Group ID for volume permissions (default: 100)

## 🔐 Required Environment Variables

Refer to [Environment Variables](../../global/index.md) documentation for:

| Variable | Description | Required |
|----------|-------------|----------|
| `SUDO_PASSWORD_VSCODE` | Code Server password | ✅ |
| `OBSIDIAN_PASSWORD` | Obsidian web interface password | ✅ |
| `SMTP_PASSWORD` | GitLab email password | ✅ |
| `MOUNT_PATH_DOCKER_ROOT` | Storage path | ✅ |
| `SYNOLOGY_BASIC_URL` | Base domain for services | ✅ |
| `UID_NAS_ADMIN` | User ID for volume permissions | ⚠️ Recommended |
| `GID_NAS_ADMIN` | Group ID for volume permissions | ⚠️ Recommended |

!!! warning "Security Notice"
    All sensitive credentials should:
    - Be stored in `.env` files
    - Have restricted permissions (`chmod 600`)
    - Never be committed to version control
    - Be rotated periodically

## 🚀 Deployment

1. Create `.env` file with required variables
2. **Initialize volumes**
```bash
mkdir -p ${MOUNT_PATH_DOCKER_ROOT}/{obsidian,gitlab/config,gitlab/data,gitlab/runner,logs/gitlab}
chown -R ${UID_NAS_ADMIN:-1026}:${GID_NAS_ADMIN:-100} ${MOUNT_PATH_DOCKER_ROOT}
```
3. **Start services**
```bash
docker-compose up -d
```
4. **Access services**
- Code Server: `https://codeserver.yourdomain.com:${CODE_SERVER:-82}`
- Obsidian: `https://yourdomain.com:${OBSIDIAN_PORT:-3421}`
- GitLab: `https://gitlab.yourdomain.com:${GITLAB_HTTPS:-5100}`

### 🔄 Maintenance

- **Backups**
	- Regularly backup all volume directories
- **Updates**
```bash
docker-compose pull && docker-compose up -d --force-recreate
```
- **Logs**
```bash
docker-compose logs -f
```
