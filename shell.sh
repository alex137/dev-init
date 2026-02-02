#!/bin/bash
# One command to get into dev environment
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Capture image ID before build
OLD_IMAGE_ID=$(docker images -q dev-env:latest 2>/dev/null)

# Always build master image from dev-init directory (Docker caching makes it fast if unchanged)
make -C "$SCRIPT_DIR" build-master

# Check if image changed
NEW_IMAGE_ID=$(docker images -q dev-env:latest 2>/dev/null)

# Install dev-init if not already done (check both symlink and .env.local)
if [ ! -L .devcontainer ] || [ ! -f .env.local ]; then
    make -f "$SCRIPT_DIR/Makefile" dev-init
fi

# If image changed, remove old container so it gets recreated
if [ "$OLD_IMAGE_ID" != "$NEW_IMAGE_ID" ] && [ -n "$OLD_IMAGE_ID" ]; then
    echo "🔄 Image updated, recreating container..."
    PROJ_NAME=$(basename "$(pwd)" | tr '.' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
    docker rm -f "${PROJ_NAME}-app" 2>/dev/null || true
fi

# Enter shell (auto-starts container if needed)
make -f "$SCRIPT_DIR/Makefile" shell
