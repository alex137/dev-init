#!/bin/bash
# One command to get into dev environment
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Always build master image (Docker caching makes it fast if unchanged)
make -f "$SCRIPT_DIR/Makefile" build-master

# Install dev-init if not already done (check both symlink and .env.local)
if [ ! -L .devcontainer ] || [ ! -f .env.local ]; then
    make -f "$SCRIPT_DIR/Makefile" dev-init
fi

# Enter shell (auto-starts container if needed)
make -f "$SCRIPT_DIR/Makefile" shell
