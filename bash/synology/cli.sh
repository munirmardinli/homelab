#!/bin/zsh

set -e
set -u
set -o pipefail

# export PATH="/opt/bin:/opt/sbin:/usr/local/bin:/usr/local/sbin:/usr/syno/bin:/usr/syno/sbin:$PATH"

export PATH="/var/packages/ContainerManager/target/usr/bin:/var/packages/ContainerManager/target/tool:/usr/local/bin:$PATH"

ROOT_DOCKER="/volume1/docker"
COMPOSE_DIR="/volume1/docker/compose/deployment"
PROJECT_DIR="/volume1/docker/projects"
PRODUCTION_DIR="/volume1/docker/production"

DOCKER_PRIV="/var/packages/ContainerManager/target/tool/docker"

echo "=== Synology CLI Task ==="
echo "Hostname: $(hostname)"
echo "Aktuelle Zeit: $(date)"

cd $ROOT_DOCKER
pwd

cd $COMPOSE_DIR
pwd
ls -la

which docker-compose || echo "docker-compose nicht gefunden"
which docker || echo "docker nicht gefunden"

docker image prune -f || true
docker volume prune -f || true

docker-compose -f "$COMPOSE_DIR"/dashboard.yml pull || true
