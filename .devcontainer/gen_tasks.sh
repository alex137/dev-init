#!/bin/bash
MAKEFILE="Makefile"
OUTPUT_FILE="../.zed/tasks.json"
GITIGNORE="../.gitignore"
cd "$(dirname "$0")"
mkdir -p "../.zed"
echo "[" > "$OUTPUT_FILE"
awk -F'[:#]' '/^[a-zA-Z0-9_-]+:[[:space:]]*[^#]*#/ {
    target = $1; label = $3;
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", target);
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", label);
    if (count > 0) printf ",\n";
    printf "  {\n    \"label\": \"%s\",\n    \"command\": \"make %s\",\n    \"use_new_terminal\": true\n  }", label, target;
    count++;
} END { printf "\n" }' "$MAKEFILE" >> "$OUTPUT_FILE"
echo "]" >> "$OUTPUT_FILE"
if ! grep -q ".zed/tasks.json" "$GITIGNORE" 2>/dev/null; then
    echo -e "\n.zed/tasks.json" >> "$GITIGNORE"
fi
