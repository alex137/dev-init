MASTER_IMAGE = dev-env:latest

.PHONY: build-master test-master dev-init setup-zed up down shell

# --- MASTER RULES (Run in dev-init) ---

build-master: # Build the Global Base Image from Dockerfile
	@echo "🏗️  Building master image: $(MASTER_IMAGE)..."
	@docker build -t $(MASTER_IMAGE) -f .devcontainer/Dockerfile .
	@$(MAKE) test-master
	@echo "✅ Master image ready."

test-master: # Verify toolchain health in a fresh container
	@echo "🧪 Verifying toolchain health..."
	@docker run --rm $(MASTER_IMAGE) bash -c ' \
		export PATH="/usr/local/bin:/root/.elide/bin:/root/.cargo/bin:/root/.cabal/bin:/root/.ghcup/bin:$$PATH" && \
		echo -n "✅ Rust:   " && rustc --version | head -n 1 && \
		echo -n "✅ Elixir: " && elixir --version | grep Elixir | awk "{print \$$2}" && \
		echo -n "✅ Gleam:  " && gleam --version && \
		echo -n "✅ Clash:  " && clash --version | head -n 1'

# --- PROJECT INITIALIZATION (Run from project folder) ---

dev-init: # Link project to Master Environment and setup local files
	@echo "🏗️  Linking project to Master Environment..."
	@mkdir -p .devcontainer
	@echo "FROM $(MASTER_IMAGE)" > .devcontainer/Dockerfile
	@cp -f $(dir $(lastword $(MAKEFILE_LIST))).devcontainer/docker-compose.yml .devcontainer/ 2>/dev/null || true
	@cp -f $(lastword $(MAKEFILE_LIST)) ./Makefile.tmp && mv ./Makefile.tmp Makefile
	@$(MAKE) setup-zed
	@echo "✅ Project initialized. Run 'make up' to start."

setup-zed: # Regenerate .zed/tasks.json from this Makefile
	@bash ../dev-init/.devcontainer/gen_tasks.sh

# --- DOCKER COMMANDS (Run from project folder) ---

up: # Start the dev container in the background
	@docker compose -f .devcontainer/docker-compose.yml up -d
	@echo "🚀 Container is up. Port 2222 is open for Zed SSH."

down: # Stop and remove the project container
	@docker compose -f .devcontainer/docker-compose.yml down



shell: # Enter the container terminal as 'user' in the repo directory
	@docker exec -it \
		--user user \
		--workdir /workspaces/repo \
		$$(docker ps -qf "name=.devcontainer-app") bash
