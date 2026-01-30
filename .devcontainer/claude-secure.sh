#!/bin/bash
# claude-secure: Wrapper that provides credentials only long enough for Claude to authenticate
#
# Security model:
# 1. After first OAuth login, credential is stored in ~/.config/claude-code/
# 2. On container startup, we move it to a backup location (.auth.json.bak)
# 3. Each `claude` invocation: copy backup to expected location
# 4. inotifywait monitors for first read, then immediately deletes the copy
# 5. Claude continues from memory; malicious packages find no credential file
#
# First-time setup: just run `claude` and complete the OAuth flow manually.
# The credential will be automatically protected on subsequent runs.

set -e

CONFIG_DIR="/home/user/.config/claude-code"
AUTH_FILE="$CONFIG_DIR/auth.json"
BACKUP_FILE="$CONFIG_DIR/.auth.json.bak"

# Find the real claude binary
for path in /usr/bin/claude.real /usr/local/bin/claude.real /home/user/.npm-global/bin/claude.real; do
    if [ -x "$path" ]; then
        REAL_CLAUDE="$path"
        break
    fi
done

if [ -z "$REAL_CLAUDE" ]; then
    echo "Error: claude.real not found. Is Claude Code installed?" >&2
    exit 1
fi

mkdir -p "$CONFIG_DIR"

# If auth file exists but backup doesn't, this is first run after login - create backup
if [ -f "$AUTH_FILE" ] && [ ! -f "$BACKUP_FILE" ]; then
    cp "$AUTH_FILE" "$BACKUP_FILE"
    chmod 600 "$BACKUP_FILE"
fi

# If we have a backup, set up the copy-and-nuke flow
if [ -f "$BACKUP_FILE" ]; then
    # Copy backup to expected location
    cp "$BACKUP_FILE" "$AUTH_FILE"
    chmod 600 "$AUTH_FILE"

    # Background process: wait for file access, then nuke it
    (
        inotifywait -qq -e access "$AUTH_FILE" 2>/dev/null
        rm -f "$AUTH_FILE"
    ) &
    WATCHER_PID=$!

    # Cleanup on exit: kill watcher, remove temp credential, but preserve backup
    cleanup() {
        kill $WATCHER_PID 2>/dev/null || true
        rm -f "$AUTH_FILE"
    }
    trap cleanup EXIT
fi

# Run the real claude
exec "$REAL_CLAUDE" "$@"
