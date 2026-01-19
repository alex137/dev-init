#!/bin/bash
set -e

if [ -d /workspaces/repo ]; then
    mkdir -p /workspaces/repo/user

    # Seed dotfiles in persistent storage if missing
    [ -f /workspaces/repo/user/.bashrc ] || cp /etc/skel/.bashrc /workspaces/repo/user/
    [ -f /workspaces/repo/user/.profile ] || cp /etc/skel/.profile /workspaces/repo/user/

    # Symlink individual dotfiles from /home/user to persistent storage
    # (Don't replace /home/user itself - it may have volume mounts like .claude)
    for f in .bashrc .profile; do
        if [ -f /workspaces/repo/user/$f ] && [ ! -L /home/user/$f ]; then
            rm -f /home/user/$f 2>/dev/null || true
            ln -sf /workspaces/repo/user/$f /home/user/$f
        fi
    done

    chown -R user:user /workspaces/repo/user
    chown -h user:user /home/user/.bashrc /home/user/.profile 2>/dev/null || true
fi

# Set up SSH authorized_keys from environment variable if provided
if [ -n "$SSH_AUTHORIZED_KEYS" ]; then
    mkdir -p /home/user/.ssh
    echo "$SSH_AUTHORIZED_KEYS" > /home/user/.ssh/authorized_keys
    chmod 700 /home/user/.ssh
    chmod 600 /home/user/.ssh/authorized_keys
    chown -R user:user /home/user/.ssh
fi

exec "$@"
