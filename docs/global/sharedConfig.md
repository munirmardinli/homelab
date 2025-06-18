---
title: Shared Config
authors:
  - Munir
tags:
  - Globaly
categories:
  - Globaly
hide:
  - toc
status: true
visibility: true
robots: index, follow
comments: true
custom_field:
  custom_key: custom_value
---

## Shared Docker Compose Anchors

The following shared anchors are used across services in your docker-compose.yml file to ensure consistent configuration for logging, labeling, and resource limits.

=== "Logging"
    **Standardized Logging for Docker services**

    The following shared anchors are used across services in your docker-compose.yml file to ensure consistent configuration for logging, labeling, and resource limits.

    ```yaml hl_lines="2-11" linenums="1"
    x-logging: &default-logging
      driver: "loki" # (1)
      options: &default-logging-options
        loki-url: https://loki.${SYNOLOGY_BASIC_URL}/loki/api/v1/push # (2)
        loki-retries: 5 # (3)
        loki-batch-size: 400 # (4)
        loki-batch-wait: 2s # (5)
        loki-timeout: 10s # (6)
        loki-max-backoff: 5s # (7)
        loki-min-backoff: 1s # (8)
        loki-tenant-id: default # (9)
    ```

    1. → Uses Grafana Loki for log aggregation
    2. → Dynamic URL using environment variable
    3. → Maximum 5 retries on failure
    4. → 400 log lines per batch maximum
    5. → 2 second wait for partial batches
    6. → 10 second request timeout
    7. → 5 seconds maximum between retries
    8. → 1 second minimum between retries
    9. → Default tenant identifier

    !!! info "Remember"
        - The `SYNOLOGY_BASIC_URL` must be set in your environment or replaced with your direct Loki URL
        - These settings can be adjusted as needed, but the shown values are recommended by Loki docs for:
          - Balanced performance (batch size 400)
          - Reliable delivery (retries 5)
          - Network resilience (timeout 10s)
        - For production environments, consider:
          - Increasing batch size if high log volume
          - Adjusting timeouts based on network latency

=== "Labels"
    **Standardized labels for Docker services**

    The following shared anchors ensure consistent behavior across your `docker-compose.yml`:

    ```yaml hl_lines="2-4" linenums="1"
    x-labels: &default-labels
      com.centurylinklabs.watchtower.enable: true  # (1)
      recreat.container: true                      # (2)
      container.label.group: setup                 # (3)
    ```

    1. → Enables [Watchtower](https://containrrr.dev/watchtower/) to auto-update this container
    2. → Custom marker for deployment-triggered recreation
    3. → Categorizes containers (e.g., `proxy`, `db`, `monitoring`)

    !!! info "Remember"
        - Update `container.label.group` per service
        - Groups enable bulk operations via:
        ```bash
        docker ps --filter "label=container.label.group=setup"
        ```

=== "Resource Limits"
    **Standardized Resource Limits for Docker services**

    The following shared anchors ensure consistent behavior across your `docker-compose.yml`:

    ```yaml hl_lines="4-9" linenums="1"
    x-resource-limits: &default-resource-limits
      deploy:
        resources:
          limits:
            cpus: '0.50'  # (1)
            memory: 512M  # (2)
          reservations:
            cpus: '0.25'  # (3)
            memory: 256M  # (4)
    ```

    1. → Container won't exceed 50% of a CPU core
    2. → Hard memory cap of 512MB (OOM kill if exceeded)
    3. → Guaranteed 25% of a CPU core
    4. → Always allocated 256MB memory buffer

    !!! info "Remember"
        - Adjust values based on your host machine capacity
        - Monitor usage with
        ```bash
        docker stats --format "table {% raw %}{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}{% endraw %}"
        ```

## Example Usage

Here's how to implement these shared anchors in a service definition:

```yaml linenums="1"
version: '3.8'

services:
  nginx:
    image: nginx:latest
    <<: *default-labels
    <<: *default-resource-limits
    logging: *default-logging
    ports:
      - "80:80"
    environment:
      - SYNOLOGY_BASIC_URL=yourdomain.com  # Required for Loki URL

  postgres:
    image: postgres:15
    <<: *default-labels
    <<: *default-resource-limits
    logging: *default-logging
    environment:
      POSTGRES_PASSWORD: example
      - SYNOLOGY_BASIC_URL=yourdomain.com
    volumes:
      - pgdata:/var/lib/postgresql/data

x-logging: &default-logging
  driver: "loki"
  options: &default-logging-options
    loki-url: https://loki.${SYNOLOGY_BASIC_URL}/loki/api/v1/push
    loki-retries: 5
    loki-batch-size: 400
    loki-batch-wait: 2s
    loki-timeout: 10s
    loki-max-backoff: 5s
    loki-min-backoff: 1s
    loki-tenant-id: default

x-labels: &default-labels
  com.centurylinklabs.watchtower.enable: true
  recreat.container: true
  container.label.group: setup

x-resource-limits: &default-resource-limits
  deploy:
    resources:
      limits:
        cpus: '0.50'
        memory: 512M
      reservations:
        cpus: '0.25'
        memory: 256M

volumes:
  pgdata:
```
