#!/bin/zsh

set -e
set -u
set -o pipefail

export PATH="/var/packages/ContainerManager/target/usr/bin:/var/packages/ContainerManager/target/tool:/usr/local/bin:$PATH"

ROOT_DOCKER="/volume1/docker"
COMPOSE_DIR="/volume1/docker/compose/deployment"

echo "=== Synology CLI Task ==="
echo "Hostname: $(hostname)"
echo "Aktuelle Zeit: $(date)"

cd $COMPOSE_DIR

which docker-compose || echo "docker-compose nicht gefunden"
which docker || echo "docker nicht gefunden"

docker image prune -f || true
docker volume prune -f || true
