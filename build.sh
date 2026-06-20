#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e

# Configuration
GH_USER="${1:-cjkihl}"
DATE_TAG=$(date +%Y%m%d)
IMAGE_NAME="ghcr.io/${GH_USER}/applio-runpod"

# 1. Validation Check
if [ ! -f "start.sh" ]; then
    echo "❌ Error: start.sh not found in the current directory!"
    echo "Make sure your persistent start.sh script is in this folder before building."
    exit 1
fi

if [ ! -f "Dockerfile.runpod" ]; then
    echo "❌ Error: Dockerfile.runpod not found!"
    exit 1
fi

# 2. Build the Image
echo "🚀 Building ${IMAGE_NAME}:latest..."
docker build -f Dockerfile.runpod -t "${IMAGE_NAME}:latest" .

# 3. Tag the Image with the Date
echo "🏷️ Tagging image as ${IMAGE_NAME}:${DATE_TAG}..."
docker tag "${IMAGE_NAME}:latest" "${IMAGE_NAME}:${DATE_TAG}"

# 4. Push to GHCR
echo ""
echo "📤 Pushing to GitHub Container Registry..."
docker push "${IMAGE_NAME}:latest"
docker push "${IMAGE_NAME}:${DATE_TAG}"

echo ""
echo "✅ Success! Deployed:"
echo "   - ${IMAGE_NAME}:latest"
echo "   - ${IMAGE_NAME}:${DATE_TAG}"