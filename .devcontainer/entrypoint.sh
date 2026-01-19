#!/bin/bash
set -e

if [ -d /workspaces/repo ]; then
    mkdir -p /workspaces/repo/user

    # Seed dotfiles if missing
    [ -f /workspaces/repo/user/.bashrc ] || cp /etc/skel/.bashrc /workspaces/repo/user/
    [ -f /workspaces/repo/user/.profile ] || cp /etc/skel/.profile /workspaces/repo/user/

    # Only setup symlink if not already done
    if [ ! -L /home/user ]; then
        # Preserve any existing content from the image
        if [ -d /home/user ]; then
            cp -rn /home/user/. /workspaces/repo/user/ 2>/dev/null || true
            rm -rf /home/user
        fi
        ln -sf /workspaces/repo/user /home/user
    fi

    chown -R user:user /workspaces/repo/user
fi

exec "$@"
