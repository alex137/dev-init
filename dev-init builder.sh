mkdir -p dev-init/.devcontainer

# 1. Create the Proxy Makefile (Root)
cat << 'EOF' > dev-init/Makefile
# Root Proxy Makefile
%:
	@$(MAKE) -i -C .devcontainer $@

all:
	@$(MAKE) -i -C .devcontainer up
EOF

# 2. Create the Dockerfile
cat << 'EOF' > dev-init/.devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/python:1-3.12-bookworm

USER root
RUN apt-get update && apt-get install -y \
    curl git openssh-server gnupg build-essential \
    clang llvm gdb nasm cmake unzip zip \
    verilator yosys ghdl iverilog gtkwave graphviz \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Elide (JS, TS, Python, Kotlin)
RUN curl -sSL --tlsv1.2 https://elide.sh | bash -s -
ENV PATH="/root/.elide/bin:${PATH}"

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Elixir & Gleam
RUN apt-get update && apt-get install -y elixir erlang-dev \
    && curl -fsSL https://github.com/gleam-lang/gleam/releases/latest/download/gleam-nightly-x86_64-unknown-linux-musl.tar.gz | tar -xzC /usr/local/bin \
    && rm -rf /var/lib/apt/lists/*

# Haskell & Claude
RUN apt-get update && apt-get install -y ghc cabal-install && rm -rf /var/lib/apt/lists/*
RUN npm install -g @anthropic-ai/claude-code

# SSH for Zed
RUN mkdir -p /var/run/sshd && \
    echo "vscode:zed" | chpasswd && \
    sed -i "s/#PasswordAuthentication yes/PasswordAuthentication yes/" /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
EOF

# 3. Create the docker-compose.yml
cat << 'EOF' > dev-init/.devcontainer/docker-compose.yml
services:
  app:
    build:
      context: ..
      dockerfile: .devcontainer/Dockerfile
    volumes:
      - ..:/workspaces/repo
    tty: true
EOF

# 4. Create the Engine Makefile
cat << 'EOF' > dev-init/.devcontainer/Makefile
PLUMBING_VERSION = 1.0.2
MASTER_PATH = ../../dev-init/.devcontainer/Makefile
COMPOSE = docker compose -f docker-compose.yml
PS_FORMAT = --format '{{.Service}}: {{.Ports}}'

HAS_CARGO  := $(shell [ -f ../Cargo.toml ] && echo "yes")
HAS_MIX    := $(shell [ -f ../mix.exs ] && echo "yes")
HAS_KOTLIN := $(shell find ../src -name "*.kt" 2>/dev/null | grep -q . && echo "yes")
HAS_GLEAM  := $(shell [ -f ../gleam.toml ] && echo "yes")

.PHONY: up status down clean logs setup-zed dev-init check-version test help

up: #Docker Up
	@$(MAKE) check-version
	@$(COMPOSE) up -d
	@$(MAKE) status

status: #Docker Status
	@$(COMPOSE) ps $(PS_FORMAT)

down: #Docker Down
	@$(COMPOSE) down

logs: #Docker Logs
	@$(COMPOSE) logs -f

clean: #Git Clean (untracked)
	@cd .. && git clean -fd

test: #Run Polyglot Tests
	@if [ "$(HAS_CARGO)" = "yes" ]; then cargo test; \
	elif [ "$(HAS_MIX)" = "yes" ]; then mix test; \
	elif [ "$(HAS_GLEAM)" = "yes" ]; then gleam test; \
	elif [ "$(HAS_KOTLIN)" = "yes" ]; then elide test; \
	else echo "❌ No test suite found."; fi

check-version: #Check Plumbing Version
	@if [ -f $(MASTER_PATH) ]; then \
		MASTER_VER=$$(grep "PLUMBING_VERSION =" $(MASTER_PATH) | cut -d" " -f3); \
		if [ "$(PLUMBING_VERSION)" != "$$MASTER_VER" ]; then \
			echo "⚠️ Update Available! Master: $$MASTER_VER"; \
		fi \
	fi

dev-init: #Initialize/Upgrade Project
	@cp -r ../../dev-init/.devcontainer ../
	@cp ../../dev-init/Makefile ../
	@$(MAKE) setup-zed

setup-zed: #Update Zed Tasks
	@chmod +x gen_tasks.sh
	@./gen_tasks.sh

help: #Show Commands
	@grep -E '^[a-zA-Z0-9_-]+:.*?#.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
EOF

# 5. Create the Task Generator
cat << 'EOF' > dev-init/.devcontainer/gen_tasks.sh
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
EOF

chmod +x dev-init/.devcontainer/gen_tasks.sh
tar -czf dev-init-plumbing.tar.gz dev-init
echo "📦 Done! Your tarball is ready: dev-init-plumbing.tar.gz"
