#!/bin/bash
# Docker entrypoint: bootstrap config directories, then run pi.
set -e

PI_HOME="/home/pi/.pi/agent"
INSTALL_DIR="/opt/pi"
WORKSPACE="/opt/workspace"

# Create essential directory structure
mkdir -p "$PI_HOME"/{sessions,extensions,skills,prompts,themes}

# Copy repo context files into workspace if not already present
for f in AGENTS.md CLAUDE.md; do
    if [ -f "$INSTALL_DIR/$f" ] && [ ! -f "$WORKSPACE/$f" ]; then
        cp "$INSTALL_DIR/$f" "$WORKSPACE/$f"
    fi
done

# Copy docker-specific context files into workspace if not already present
for f in README.md AGENTS.md; do
    if [ -f "$INSTALL_DIR/docker/$f" ] && [ ! -f "$WORKSPACE/$f" ]; then
        cp "$INSTALL_DIR/docker/$f" "$WORKSPACE/$f"
    elif [ -f "$INSTALL_DIR/docker/$f" ] && [ -f "$WORKSPACE/$f" ]; then
        # Append docker-specific sections if not already present
        if ! grep -q "Shared Project State" "$WORKSPACE/$f" 2>/dev/null; then
            printf '\n' >> "$WORKSPACE/$f"
            cat "$INSTALL_DIR/docker/$f" >> "$WORKSPACE/$f"
        fi
    fi
done

exec node "$INSTALL_DIR/packages/coding-agent/dist/cli.js" "$@"
