#!/usr/bin/env bash

set -uo pipefail

# Defaults
ENV_FILE=".env"
IMAGE="gensen"
PORT="8080"
TAG="latest"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -e | --env)
    ENV_FILE="${2:-.env}"
    shift 2
    ;;
  -i | --image)
    IMAGE="${2:-gensen}"
    shift 2
    ;;
  -p | --port)
    PORT="${2:-8080}"
    shift 2
    ;;
  -t | --tag)
    TAG="${2:-latest}"
    shift 2
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

if docker ps -a --format '{{.Names}}' | grep -q "^gensen$"; then
  echo "Stopping existing container..."
  docker rm -f gensen || true
fi

echo "Starting container..."
docker run \
  --detach \
  --name "gensen" \
  --env-file "$ENV_FILE" \
  --restart unless-stopped \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  -p "${PORT}:${PORT}" \
  "${IMAGE}:${TAG}"

DOCKER_EXIT_CODE=$?
if [ $DOCKER_EXIT_CODE -ne 0 ]; then
  echo "Failed to start the container. Review logs for details."
  exit 1
fi

echo "Container started successfully"
echo "Access the application: http://localhost:${PORT}"
echo "View logs: docker logs ${IMAGE}"
