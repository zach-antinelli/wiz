#!/usr/bin/env bash

set -uo pipefail

# Defaults
ENV_FILE=".env"
IMAGE="688567300039.dkr.ecr.us-west-2.amazonaws.com/gensen"
PORT="80"
TAG="94c335b054bfa2000762411a0a7cbe91cbeef610"

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
    PORT="${2:-80}"
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

if docker ps -a --format '{{.Names}}' | grep -q "^${IMAGE}$"; then
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
  -p "${PORT}:8080" \
  "${IMAGE}:${TAG}"

DOCKER_EXIT_CODE=$?
if [ $DOCKER_EXIT_CODE -ne 0 ]; then
  echo "Failed to start the container. Review logs for details."
  exit 1
fi

echo "Container started successfully"
echo "Access the application: http://localhost:${PORT}"
echo "View logs: docker logs ${IMAGE}"
