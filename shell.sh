#!/bin/bash
# One command to get into dev environment
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Build master image if it doesn't exist
if ! docker image inspect dev-env:latest >/dev/null 2>&1; then
    echo "Building master image (first time only)..."
    make -f "$SCRIPT_DIR/Makefile" build-master
fi

# Install dev-init if not already done (check both symlink and .env.local)
if [ ! -L .devcontainer ] || [ ! -f .env.local ]; then
    make -f "$SCRIPT_DIR/Makefile" dev-init
fi

# Enter shell (auto-starts container if needed)
make -f "$SCRIPT_DIR/Makefile" shell
