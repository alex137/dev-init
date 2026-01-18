#!/bin/bash
# Run this from a project root. It looks for a Makefile.

MAKEFILE="Makefile"
OUTPUT_DIR=".zed"
OUTPUT_FILE="$OUTPUT_DIR/tasks.json"
GITIGNORE=".gitignore"

mkdir -p "$OUTPUT_DIR"
echo "🔍 Syncing Zed tasks..."

# Start JSON
echo "[" > "$OUTPUT_FILE"

# 1. Add Local Tasks from the Makefile
awk -F'[:#]' '
/^[a-zA-Z0-9_-]+:[[:space:]]*[^#]*#/ {
    target = $1; label = $3;
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", target);
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", label);
    if (count > 0) printf ",\n";
    printf "  {\n    \"label\": \"%s\",\n    \"command\": \"make %s\",\n    \"use_new_terminal\": true\n  }", label, target;
    count++;
}
END { printf "\n" }' "$MAKEFILE" >> "$OUTPUT_FILE"

# 2. Add the "Global" Master Update Task
# This reaches back into the dev-init folder to rebuild the base image
printf ",\n  {\n    \"label\": \"🛠️  GLOBAL: Rebuild Master Environment\",\n" >> "$OUTPUT_FILE"
printf "    \"command\": \"make -C ../dev-init build-master\",\n" >> "$OUTPUT_FILE"
printf "    \"use_new_terminal\": true\n  }" >> "$OUTPUT_FILE"

echo "]" >> "$OUTPUT_FILE"

# 3. .gitignore cleanup
if ! grep -q ".zed/tasks.json" "$GITIGNORE" 2>/dev/null; then
    echo -e "\n.zed/tasks.json" >> "$GITIGNORE"
fi
