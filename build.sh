#!/bin/bash
set -e

GH_USER="${1:-cjkihl}"
DATE_TAG=$(date +%Y%m%d)
IMAGE_NAME="ghcr.io/${GH_USER}/applio-runpod"

echo "Building ${IMAGE_NAME}:latest..."
docker build -f Dockerfile.runpod -t "${IMAGE_NAME}:latest" .
docker tag "${IMAGE_NAME}:latest" "${IMAGE_NAME}:${DATE_TAG}"

echo ""
echo "Pushing to GitHub Container Registry..."
docker push "${IMAGE_NAME}:latest"
docker push "${IMAGE_NAME}:${DATE_TAG}"

echo ""
echo "Done: ${IMAGE_NAME}:latest and ${IMAGE_NAME}:${DATE_TAG}"
