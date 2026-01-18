# --- Versioning ---
PLUMBING_VERSION = 1.0.3
MASTER_PATH = ../dev-init/Makefile
MASTER_IMAGE = dev-env:latest

# --- Docker Config ---
# Since this Makefile is now in the root, we point INTO .devcontainer
COMPOSE = docker compose -f .devcontainer/docker-compose.yml
PS_FORMAT = --format '{{.Service}}: {{.Ports}}'

# --- Discovery (Relative to Root) ---
HAS_CARGO  := $(shell [ -f Cargo.toml ] && echo "yes")
HAS_MIX    := $(shell [ -f mix.exs ] && echo "yes")
HAS_KOTLIN := $(shell find src -name "*.kt" 2>/dev/null | grep -q . && echo "yes")
HAS_GLEAM  := $(shell [ -f gleam.toml ] && echo "yes")

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
	@git clean -fd

test: #Run Polyglot Tests
	@if [ "$(HAS_CARGO)" = "yes" ]; then cargo test; \
	elif [ "$(HAS_MIX)" = "yes" ]; then mix test; \
	elif [ "$(HAS_GLEAM)" = "yes" ]; then gleam test; \
	elif [ "$(HAS_KOTLIN)" = "yes" ]; then elide test; \
	else echo "❌ No test suite found."; fi

check-version: #Check Plumbing Version
	@if [ -f $(MASTER_PATH) ]; then \
		MASTER_VER=$$(grep "PLUMBING_VERSION =" $(MASTER_PATH) | head -n 1 | cut -d' ' -f3); \
		if [ "$(PLUMBING_VERSION)" != "$$MASTER_VER" ]; then \
			echo "⚠️  Update Available! Local: $(PLUMBING_VERSION) | Master: $$MASTER_VER"; \
		fi \
	fi

build-master: #Build the Global Base Image
	@echo "🏗️  Building master image: $(MASTER_IMAGE)..."
	@docker build -t $(MASTER_IMAGE) -f .devcontainer/Dockerfile .
	@echo "✅ Master image ready."


dev-init: #Initialize/Upgrade Project
	@echo "🏗️  Initializing project from master..."
	@# 1. Create the local .devcontainer folder
	@mkdir -p .devcontainer
	@# 2. Create the 1-line Dockerfile that inherits from master
	@echo "FROM $(MASTER_IMAGE)" > .devcontainer/Dockerfile
	@# 3. Copy the standard docker-compose (simplified)
	@cp ../dev-init/.devcontainer/docker-compose.yml .devcontainer/
	@# 4. Copy this Makefile
	@cp ../dev-init/Makefile .
	@# 5. Build Zed tasks
	@$(MAKE) setup-zed
	@echo "✅ Project initialized. It is now linked to $(MASTER_IMAGE)."

setup-zed: #Update Zed Tasks
	@echo "🛠️  Generating Zed tasks from Master template..."
	@bash ../dev-init/.devcontainer/gen_tasks.sh


help: #Show Commands
	@grep -E '^[a-zA-Z0-9_-]+:.*?#.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
