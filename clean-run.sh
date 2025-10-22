#!/usr/bin/env bash
# ------------------------------------------------------------
# clean-run.sh
# Completely reset Docker and run a fresh container
# from an image specified as the first argument.
# ------------------------------------------------------------
# Usage:
#   ./clean-run.sh ghcr.io/garetd/cloudcomputing:latest
#
# This will:
#   1. Stop and remove all containers
#   2. Remove all Docker images, volumes, and networks
#   3. Pull the image you specify
#   4. Run it on port 8080:80
# ------------------------------------------------------------

set -e

IMAGE="$1"

if [ -z "$IMAGE" ]; then
  echo "ERROR: No image provided."
  echo "Usage: $0 <image-name:tag>"
  echo "Example: $0 ghcr.io/garetd/cloudcomputing:latest"
  exit 1
fi

echo "Stopping all running containers..."
docker stop $(docker ps -q) 2>/dev/null || true

echo "Removing all containers..."
docker rm $(docker ps -aq) 2>/dev/null || true

echo "Removing all images..."
docker rmi -f $(docker images -q) 2>/dev/null || true

echo "Pruning volumes and networks..."
docker volume prune -f
docker network prune -f

echo "Docker cleanup complete."
echo

echo "⬇Pulling clean image: $IMAGE ..."
docker pull "$IMAGE"

echo "Running new container..."
docker run -d --name cloudcomputing \
  -p 8080:80 \
  "$IMAGE"

echo
echo "Container started successfully!"
echo "   → http://localhost:8080"
echo
docker ps --filter "name=cloudcomputing"

