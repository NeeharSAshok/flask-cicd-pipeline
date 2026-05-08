#!/usr/bin/env bash
# =============================================================================
# Manual Deployment Script
# Run on EC2 server to deploy/update the app manually.
# Usage: bash scripts/deploy.sh [IMAGE_TAG]
# =============================================================================

set -euo pipefail

IMAGE_TAG="${1:-latest}"
DOCKER_HUB_USERNAME="${DOCKER_HUB_USERNAME:-your_dockerhub_username}"
IMAGE="${DOCKER_HUB_USERNAME}/flask-cicd-app:${IMAGE_TAG}"

echo "🚀 Deploying: $IMAGE"

# Pull the new image
docker pull "$IMAGE"

# Navigate to project directory
cd ~/flask-cicd-pipeline

# Bring down old stack gracefully
echo "🛑 Stopping current containers..."
docker compose down --remove-orphans || true

# Export version tag so docker-compose can use it
export APP_VERSION="$IMAGE_TAG"

# Start new stack
echo "📦 Starting new containers..."
docker compose up -d

# Wait and verify health
echo "⏳ Waiting for app to be healthy..."
for i in {1..12}; do
  if curl -sf http://localhost/health > /dev/null; then
    echo "✅ App is healthy!"
    break
  fi
  echo "  Attempt $i/12 — retrying in 5s..."
  sleep 5
  if [ "$i" -eq 12 ]; then
    echo "❌ Health check failed after 60s"
    docker compose logs app
    exit 1
  fi
done

echo ""
echo "════════════════════════════════════"
echo "  Deployment complete! 🎉"
echo "  Image: $IMAGE"
echo "  URL:   http://$(curl -s ifconfig.me)"
echo "════════════════════════════════════"
