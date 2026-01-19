#!/bin/bash
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

printf ",\n  {\n    \"label\": \"🛠️  GLOBAL: Rebuild Master\",\n    \"command\": \"make -C ../dev-init build-master\",\n    \"use_new_terminal\": true\n  }\n" >> "$OUTPUT_FILE"
echo "]" >> "$OUTPUT_FILE"
