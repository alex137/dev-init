MASTER_IMAGE = dev-env:latest
PROJ_NAME = $(shell basename $$(pwd))

# Load variables from the generated .env if it exists
-include .devcontainer/.env

.PHONY: build-master test-master dev-init setup-zed up down shell list

# --- MASTER RULES (Run in dev-init) ---

build-master: # Build the Global Base Image from Dockerfile
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
	@mkdir -p .devcontainer
	@if [ "$(PROJ_NAME)" != "dev-init" ]; then \
		echo "FROM $(MASTER_IMAGE)" > .devcontainer/Dockerfile; \
		echo "WORKDIR /workspaces/repo" >> .devcontainer/Dockerfile; \
		echo "USER root" >> .devcontainer/Dockerfile; \
		echo "RUN mkdir -p /var/run/sshd && ssh-keygen -A" >> .devcontainer/Dockerfile; \
		echo "USER root" >> .devcontainer/Dockerfile; \
		ln -sf ../dev-init/Makefile Makefile; \
		cp ../dev-init/.devcontainer/docker-compose.yml .devcontainer/docker-compose.yml; \
		echo "✨ Project-specific files created."; \
	else \
		echo "🏠 Operating in dev-init root. Skipping self-copy."; \
	fi
	@$(MAKE) setup-zed
	@echo "✅ Setup complete for $(PROJ_NAME)."

setup-zed: # Register project and generate Zed tasks.json
	@if [ "$(PROJ_NAME)" = "dev-init" ]; then \
		PROJ_NAME=$(PROJ_NAME) bash .devcontainer/gen_tasks.sh; \
	else \
		PROJ_NAME=$(PROJ_NAME) bash ../dev-init/.devcontainer/gen_tasks.sh; \
	fi

list: # Show all registered projects and their ports
	@echo "📋 Registered Projects:"
	@if [ -f projects.reg ]; then cat projects.reg; else echo "No projects registered."; fi

# --- DOCKER COMMANDS (Run from project folder) ---

up: # Start the dev container in the background
	@docker compose -f .devcontainer/docker-compose.yml up -d --build
	@echo "🚀 Container is up. Port $(HOST_PORT_SSH) is open for SSH."

down: # Stop and remove the project container
	@docker compose -f .devcontainer/docker-compose.yml down

shell: # Enter the container terminal as 'user' in the repo directory
	@docker exec -it \
		--user user \
		--workdir /workspaces/repo \
		$(PROJ_NAME)-app bash

fresh: #Reset docker container
	docker rm -f $(PROJ_NAME)-app
	@$(MAKE) up
