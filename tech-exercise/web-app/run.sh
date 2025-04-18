#!/usr/bin/env bash

set -uo pipefail

ENV_FILE=".env"
PORT="8080"
CONTAINER_NAME="gensen"
IMAGE_NAME="gensen:latest"
HEALTH_CHECK_INTERVAL="30"
HEALTH_CHECK_TIMEOUT="10"
HEALTH_CHECK_RETRIES="3"

if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping existing container..."
  docker stop "${CONTAINER_NAME}" || true
  docker rm "${CONTAINER_NAME}" || true
fi

echo "Starting container..."
docker run \
  --detach \
  --name "${CONTAINER_NAME}" \
  --env-file "$ENV_FILE" \
  --restart unless-stopped \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  --health-cmd="wget --no-verbose --tries=1 --spider http://localhost:${PORT} || exit 1" \
  --health-interval="${HEALTH_CHECK_INTERVAL}s" \
  --health-timeout="${HEALTH_CHECK_TIMEOUT}s" \
  --health-retries="${HEALTH_CHECK_RETRIES}" \
  -p "${PORT}:${PORT}" \
  "${IMAGE_NAME}"

DOCKER_EXIT_CODE=$?
if [ $DOCKER_EXIT_CODE -ne 0 ]; then
  echo "Failed to start the container. Review logs for details."
  exit 1
fi

echo "Container started successfully"
echo "Access the application: http://localhost:${PORT}"
echo "View logs: docker logs ${CONTAINER_NAME}"
