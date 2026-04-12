# Pi Setup, following /w/hermes-agent/

2026-04-11 01:44

⏺ Here's what's set up, mirroring the hermes pattern:

  Files created/updated:

  - Dockerfile -- node:22-bookworm, installs git/ripgrep/curl, builds all packages, non-root pi user, entrypoint script
  - docker/entrypoint.sh -- bootstraps config directories (sessions, extensions, skills, prompts, themes) then execs pi
  - docker-compose.yml -- mounts ~/.pi for config persistence, configurable workspace (PI_WORKSPACE_DIR), wiki, API key pass-through, security hardening
  - Makefile -- same structure as hermes:

    help                 Show this help
    build                Build the Docker image
    rebuild              Build the Docker image (no cache)
    up                   Start the container in background
    down                 Stop and remove the container
    restart              Recreate the container (down + up)
    run                  Run a disposable pi container (removed on exit)
    shell                Open a bash shell in the running container
    logs                 Tail container logs
    status               Show container status
    inspect              Show container mounts and workspace contents
    lsws                 List workspace contents
    chat                 Open interactive pi CLI in the container
    task                 Run a one-shot query (make task Q="...")
    sessions             List session files
    workspace-sync       Ensure .workspace dir exists
    clean-workspace      Wipe workspace contents
    images               List pi-related Docker images
    prune                Remove dangling images and stopped containers

  Quick start:
  make build
  make run              # disposable interactive session
  make task Q="List all .ts files"  # one-shot print mode

---

