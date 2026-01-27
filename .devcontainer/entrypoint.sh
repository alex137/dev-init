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

# Fix permissions on .claude volume mount (created by docker-compose)
if [ -d /home/user/.claude ]; then
    chown -R user:user /home/user/.claude
fi

# Fix permissions on .config/claude-code volume mount
if [ -d /home/user/.config/claude-code ]; then
    chown -R user:user /home/user/.config/claude-code
fi

# NOTE: Credentials are protected by the claude-secure wrapper, which nukes them
# immediately after Claude reads them. This allows OAuth credentials to persist
# in the volume while preventing malicious packages from accessing them.

# Ensure npm global directory exists and is configured
mkdir -p /home/user/.npm-global
chown -R user:user /home/user/.npm-global
# Add npm global bin to PATH if not already present
if ! grep -q 'npm-global' /home/user/.bashrc 2>/dev/null; then
    echo 'export PATH="/home/user/.npm-global/bin:$PATH"' >> /home/user/.bashrc
    chown user:user /home/user/.bashrc
fi

exec "$@"
