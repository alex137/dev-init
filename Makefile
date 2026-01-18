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
	@cp -r ../dev-init/.devcontainer ../
	@cp ../dev-init/Makefile ../
	@$(MAKE) setup-zed

setup-zed: #Update Zed Tasks
	@chmod +x gen_tasks.sh
	@../dev-init/.devcontainer/gen_tasks.sh

help: #Show Commands
	@grep -E '^[a-zA-Z0-9_-]+:.*?#.*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
