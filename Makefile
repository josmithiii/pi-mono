IMAGE := pi-agent:local
SERVICE := pi
export PI_WORKSPACE_DIR ?= $(shell mkdir -p .workspace && realpath .workspace)

.DEFAULT_GOAL := help

.PHONY: help build rebuild up down restart run logs shell status \
        inspect lsws workspace-sync clean-workspace images prune

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-20s %s\n", $$1, $$2}'

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

shell: up ## Open a bash shell in the running container
	docker compose exec $(SERVICE) bash

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

chat: up ## Open interactive pi CLI in the container
	docker compose exec $(SERVICE) pi

task: up ## Run a one-shot query (usage: make task Q="summarize this codebase")
	docker compose exec $(SERVICE) pi -p "$(Q)"

sessions: ## List session files
	docker compose exec $(SERVICE) ls -lt /home/pi/.pi/agent/sessions/

# — Workspace —

workspace-sync: ## Ensure .workspace dir exists
	@mkdir -p .workspace
	@echo "Workspace dir: $(PI_WORKSPACE_DIR)"

clean-workspace: ## Wipe workspace contents
	rm -rf .workspace/*

# — Docker housekeeping —

images: ## List pi-related Docker images
	docker images pi-agent

prune: ## Remove dangling images and stopped containers
	docker container prune -f && docker image prune -f
