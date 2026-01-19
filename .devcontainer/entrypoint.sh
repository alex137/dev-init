#!/bin/bash
set -e

# Ensure persistent user directory exists
mkdir -p /workspaces/repo/user

# Seed dotfiles if missing
[ -f /workspaces/repo/user/.bashrc ] || cp /etc/skel/.bashrc /workspaces/repo/user/
[ -f /workspaces/repo/user/.profile ] || cp /etc/skel/.profile /workspaces/repo/user/

# Remove existing home and symlink to persistent location
rm -rf /home/user
ln -sf /workspaces/repo/user /home/user

# Fix ownership
chown -R user:user /workspaces/repo/user

exec "$@"