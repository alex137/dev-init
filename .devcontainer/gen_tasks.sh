#!/bin/bash

# Get the directory where THIS script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# 1. Setup paths - Use the script's location to find the registry reliably
# This assumes the registry is one level up from the .devcontainer folder
REGISTRY_FILE="$SCRIPT_DIR/../projects.reg"
PROJ_NAME=$(basename "$(pwd)")
ENV_FILE=".devcontainer/.env"
START_PORT=2222

# Ensure registry exists
touch "$REGISTRY_FILE"

# 2. Newline Safety: Ensure we aren't appending to a line that lacks a newline
# This prevents "dev-init:2221state-transfer-protocol:2222" corruption
if [ -s "$REGISTRY_FILE" ] && [ "$(tail -c 1 "$REGISTRY_FILE" | wc -l)" -eq 0 ]; then
    echo "" >> "$REGISTRY_FILE"
fi

# 3. Check registry for existing port or assign new one
if grep -q "^$PROJ_NAME :" "$REGISTRY_FILE"; then
    PORT=$(grep "^$PROJ_NAME :" "$REGISTRY_FILE" | cut -d: -f2 | xargs)
    echo "♻️  Existing project found. Using port $PORT"
else
    # Find the maximum port currently assigned
    # We grep for numbers only to avoid mixing in text or comments
    MAX_PORT=$(cut -d: -f2 "$REGISTRY_FILE" | grep -oE '[0-9]+' | sort -n | tail -n 1)

    if [ -z "$MAX_PORT" ]; then
        PORT=$START_PORT
    else
        # Force 10# base to prevent bash from interpreting ports as octal (e.g. 08, 09)
        PORT=$((10#$MAX_PORT + 1))
    fi

    echo "$PROJ_NAME : $PORT" >> "$REGISTRY_FILE"
    echo "✨ New project registered. Assigning port $PORT"
fi

# 4. Generate the .env file
cat <<EOF > "$ENV_FILE"
COMPOSE_PROJECT_NAME=$PROJ_NAME
HOST_PORT_SSH=$PORT
EOF

echo "✅ Created $ENV_FILE with Name: $PROJ_NAME and Port: $PORT"

# 5. Zed Tasks
MAKEFILE="Makefile"
OUTPUT_DIR=".zed"
OUTPUT_FILE="$OUTPUT_DIR/tasks.json"
mkdir -p "$OUTPUT_DIR"

echo "[" > "$OUTPUT_FILE"
awk -F'[:#]' '/^[a-zA-Z0-9_-]+:[[:space:]]*[^#]*#/ {
    target = $1; label = $3;
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", target);
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", label);
    if (count > 0) printf ",\n";
    printf "  {\n    \"label\": \"%s\",\n    \"command\": \"make %s\",\n    \"use_new_terminal\": true\n  }", label, target;
    count++;
}' "$MAKEFILE" >> "$OUTPUT_FILE"

# Add the Global Rebuild task
printf ",\n  {\n    \"label\": \"🛠️  GLOBAL: Rebuild Master\",\n    \"command\": \"make -C ../dev-init build-master\",\n    \"use_new_terminal\": true\n  }\n" >> "$OUTPUT_FILE"
echo "]" >> "$OUTPUT_FILE"
