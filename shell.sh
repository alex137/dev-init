#!/bin/bash
# One command to get into dev environment
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Install dev-init if not already done (check both symlink and .env.local)
if [ ! -L .devcontainer ] || [ ! -f .env.local ]; then
    make -f "$SCRIPT_DIR/Makefile" dev-init
fi

# Start container and enter shell
make -f "$SCRIPT_DIR/Makefile" shell
