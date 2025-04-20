#!/usr/bin/env  bash

set -euo pipefail

# Defaults
IMAGE_NAME="gensen"
IMAGE_TAG="latest"
FLASK_PORT="8080"
IMAGE_VERSION="1.0.0"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -n | --name)
    IMAGE_NAME="${2:-gensen}"
    shift 2
    ;;
  -p | --port)
    FLASK_PORT="${2:-8080}"
    shift 2
    ;;
  -t | --tag)
    IMAGE_TAG="${2:-latest}"
    shift 2
    ;;
  -v | --version)
    IMAGE_VERSION="${2}"
    shift 2
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"

docker build \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --build-arg VERSION="$IMAGE_VERSION" \
  --build-arg FLASK_PORT="$FLASK_PORT" \
  .
