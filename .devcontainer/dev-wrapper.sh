#!/bin/bash
# Container management wrapper for child repos

if [ $# -eq 0 ]; then
    echo "Usage: ./dev <command>"
    echo ""
    echo "Commands:"
    echo "  up       Start the dev container"
    echo "  down     Stop and remove the container"
    echo "  shell    Enter the container terminal"
    echo "  restart  Restart container (preserves Claude auth)"
    echo "  fresh    Reset container (may lose Claude auth)"
    exit 0
fi

make -f ../dev-init/Makefile "$@"
