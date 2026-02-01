MASTER_IMAGE = dev-env:latest
HASKELL_IMAGE = dev-env-haskell:latest
PROJ_NAME = $(shell basename $$(pwd))

# Load variables from .env.local (project-specific config + secrets)
-include .env.local

.PHONY: build-master build-haskell test-master update-base dev-init setup-zed up down shell restart fresh list

# --- MASTER RULES (Run in dev-init) ---

build-haskell: # Build Haskell/Clash image (slow, only run when updating GHC/Clash)
	@echo "🏗️  Building Haskell image: $(HASKELL_IMAGE)..."
	@echo "⏳ This takes 10-20 minutes. Only needed when updating GHC/Clash versions."
	@docker build -t $(HASKELL_IMAGE) -f .devcontainer/Dockerfile.haskell .
	@echo "✅ Haskell image ready. Now run 'make build-master'."

update-base: # Update pinned base image digest (run build-haskell after)
	@echo "🔍 Fetching latest base image digest..."
	@NEW_DIGEST=$$(curl -sI "https://mcr.microsoft.com/v2/devcontainers/base/manifests/trixie" \
		-H "Accept: application/vnd.oci.image.index.v1+json" | grep -i docker-content-digest | awk '{print $$2}' | tr -d '\r'); \
	if [ -z "$$NEW_DIGEST" ]; then \
		echo "❌ Failed to fetch digest"; exit 1; \
	fi; \
	OLD_DIGEST=$$(grep -m1 "@sha256:" .devcontainer/Dockerfile | sed 's/.*@//' | sed 's/ .*//' ); \
	if [ "$$OLD_DIGEST" = "$$NEW_DIGEST" ]; then \
		echo "✅ Already up to date: $$NEW_DIGEST"; \
	else \
		sed -i.bak "s|@sha256:[a-f0-9]*|@$$NEW_DIGEST|g" .devcontainer/Dockerfile .devcontainer/Dockerfile.haskell && rm -f .devcontainer/*.bak; \
		echo "✅ Updated: $$OLD_DIGEST → $$NEW_DIGEST"; \
		echo "⚠️  Run 'make build-haskell' then 'make build-master'"; \
	fi

build-master: # Build the Global Base Image (fast, requires build-haskell first)
	@echo "🏗️  Building master image: $(MASTER_IMAGE)..."
	@docker build -t $(MASTER_IMAGE) -f .devcontainer/Dockerfile .
	@$(MAKE) test-master
	@echo "✅ Master image ready."

test-master: # Verify toolchain health in a fresh container
	@echo "🧪 Verifying toolchain health..."
	@docker run --rm $(MASTER_IMAGE) bash -c 'echo -n "✅ Rust: " && rustc --version | head -n 1'

# --- PROJECT INITIALIZATION (Run from project folder) ---

dev-init: # Initialize current folder with Docker and Zed configs
	@echo "🏗️  Initializing project environment..."
	@if [ "$(PROJ_NAME)" = "dev-init" ]; then \
		echo "🏠 Operating in dev-init root. Run container commands directly: make up, make shell"; \
		exit 0; \
	fi
	@rm -rf .devcontainer 2>/dev/null || true
	@ln -sf ../dev-init/.devcontainer .devcontainer
	@ln -sf ../dev-init/.devcontainer/dev-wrapper.sh ./dev
	@for entry in .devcontainer dev .env.local .zed/ user/; do \
		grep -qxF "$$entry" .gitignore 2>/dev/null || echo "$$entry" >> .gitignore; \
	done
	@PROJ_NAME=$(PROJ_NAME) bash .devcontainer/gen_tasks.sh
	@echo "✅ Setup complete for $(PROJ_NAME)."
	@echo "📋 Container commands: ./dev up, ./dev shell, ./dev down"
	@echo "🔐 Put secrets in .env.local"

setup-zed: # Register project and generate Zed tasks.json
	@PROJ_NAME=$(PROJ_NAME) bash .devcontainer/gen_tasks.sh

list: # Show all registered projects and their ports
	@echo "📋 Registered Projects:"
	@if [ -f projects.reg ]; then cat projects.reg; else echo "No projects registered."; fi

# --- DOCKER COMMANDS (Run from project folder) ---

up: # Start the dev container in the background
	@docker compose -f .devcontainer/docker-compose.yml --env-file .env.local up -d
	@echo "🚀 Container is up. Port $(HOST_PORT_SSH) is open for SSH."

down: # Stop and remove the project container
	@docker compose -f .devcontainer/docker-compose.yml --env-file .env.local down

shell: # Enter the container terminal as 'user' in the repo directory
	@if [ -f /.dockerenv ]; then \
		echo "✅ You're already inside the container!"; \
	elif docker ps --format '{{.Names}}' | grep -q "^$(PROJ_NAME)-app$$"; then \
		docker exec -it --user user --workdir /workspaces/repo $(PROJ_NAME)-app bash; \
	else \
		docker compose -f .devcontainer/docker-compose.yml --env-file .env.local up -d && \
		docker exec -it --user user --workdir /workspaces/repo $(PROJ_NAME)-app bash; \
	fi

fresh: # Reset docker container (rebuilds image, may lose Claude auth)
	@docker rm -f $(PROJ_NAME)-app
	@$(MAKE) up

restart: # Restart container without rebuilding (preserves Claude auth)
	@docker restart $(PROJ_NAME)-app
	@echo "✅ Container restarted."
