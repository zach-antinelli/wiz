#!/usr/bin/env  bash

set -euo pipefail

IMAGE_NAME="gensen"
IMAGE_TAG="latest"
IMAGE_VERSION="1.0.0"
FLASK_PORT="8080"

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"

docker build \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --build-arg VERSION="$IMAGE_VERSION" \
  --build-arg FLASK_PORT="$FLASK_PORT" \
  .
