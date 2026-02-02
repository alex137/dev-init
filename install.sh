#!/bin/bash
# Install dev-init in the current working directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
make -f "$SCRIPT_DIR/Makefile" dev-init
