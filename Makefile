IMAGE := pi-agent:local
SERVICE := pi
export PI_WORKSPACE_DIR ?= $(shell mkdir -p .workspace && realpath .workspace)

.DEFAULT_GOAL := help

.PHONY: help build rebuild up down restart run logs shell status \
        inspect lsws doctor workspace-sync clean clean-workspace images prune

help: ## Show this help
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-20s %s\n", $$1, $$2}'

# — Image —

build: ## Build the Docker image
	docker build -t $(IMAGE) .

rebuild: ## Build the Docker image (no cache)
	docker build --no-cache -t $(IMAGE) .

# — Container lifecycle —

up: ## Start the container in background
	docker compose up -d $(SERVICE)

down: ## Stop and remove the container
	docker compose down

restart: ## Recreate the container (down + up)
	docker compose down && docker compose up -d $(SERVICE)

# — Interactive —

run: ## Run a disposable pi container (removed on exit)
	docker compose run --rm $(SERVICE)

shell: up ## Open a bash shell in the running container (telegram disabled)
	docker compose exec -e TELEGRAM_BOT_TOKEN= $(SERVICE) bash

# — Observe —

logs: ## Tail container logs
	docker compose logs -f $(SERVICE)

status: ## Show container status
	docker compose ps

inspect: ## Show container mounts and workspace contents
	docker inspect pi-agent-pi-1 --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' && \
	echo "---" && docker compose exec $(SERVICE) ls /opt/workspace/

lsws: ## List workspace contents
	docker compose exec $(SERVICE) ls /opt/workspace/

lsvs: ## List visible services using lsof
	lsof -iTCP -sTCP:LISTEN -nP | grep -E '127\.0\.0\.1|\*:'

lsvsns: ## List visible services using netstat
	netstat -anv -p tcp | grep LISTEN

# — Pi commands —

chat: up ## Open interactive pi CLI in the container (telegram disabled — daemon owns it)
	docker compose exec -e TELEGRAM_BOT_TOKEN= $(SERVICE) pi

task: up ## Run a one-shot query (usage: make task Q="summarize this codebase")
	docker compose exec -e TELEGRAM_BOT_TOKEN= $(SERVICE) pi -p "$(Q)"

sessions: ## List session files
	docker compose exec $(SERVICE) ls -lt /home/pi/.pi/agent/sessions/

settings: up
	docker exec pi-agent-pi-1 cat /home/pi/.pi/agent/settings.json

doctor: ## Run pi doctor inside the container
	docker compose exec -e TELEGRAM_BOT_TOKEN= $(SERVICE) pi doctor


# — Workspace —

workspace-sync: ## Ensure .workspace dir exists
	@mkdir -p .workspace
	@echo "Workspace dir: $(PI_WORKSPACE_DIR)"

clean: ## Remove exited pi containers
	@ids=$$(docker ps -aq -f name=pi-agent- -f status=exited); \
	if [ -n "$$ids" ]; then docker rm $$ids; else echo "No exited pi containers."; fi

clean-workspace: ## Wipe workspace contents
	rm -rf .workspace/*

# — MLX (host-side; shared wrapper at ~/bin/mlx_serve) —

mup: ## Start MLX (default: Gemma 4 31B 4-bit; idempotent)
	$$HOME/bin/mlx_serve &

mup3: ## Swap MLX to Gemma 3 27B 4-bit
	@$(MAKE) mdown && $$HOME/bin/mlx_serve mlx-community/gemma-3-27b-it-4bit &

mup3s: ## Swap MLX to Gemma 3 12B 4-bit (small/fast)
	@$(MAKE) mdown && $$HOME/bin/mlx_serve mlx-community/gemma-3-12b-it-4bit &

mup4f: ## Swap MLX to Gemma 4 31B bf16 (full precision, ~60 GB)
	@$(MAKE) mdown && $$HOME/bin/mlx_serve mlx-community/gemma-4-31b-it-bf16 &

mdown: ## Stop the host MLX server
	@pids=$$(lsof -t -iTCP:8765 -sTCP:LISTEN 2>/dev/null); \
	if [ -n "$$pids" ]; then kill $$pids && echo "mlx stopped (pids: $$pids)"; \
	else echo "mlx not running"; fi

mstatus: ## Show whether MLX server is listening
	@if lsof -iTCP:8765 -sTCP:LISTEN -nP >/dev/null 2>&1; then \
		echo ":8765 UP  ($$(lsof -iTCP:8765 -sTCP:LISTEN -nP | awk 'NR==2 {print $$1, "pid", $$2}'))"; \
	else echo ":8765 DOWN"; fi

# — Docker housekeeping —

images: ## List pi-related Docker images
	docker images pi-agent

prune: ## Remove dangling images and stopped containers
	docker container prune -f && docker image prune -f
