FROM node:22-bookworm

# Install system utilities useful for the coding agent's bash tool
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git ripgrep curl && \
    rm -rf /var/lib/apt/lists/*

COPY . /opt/pi
WORKDIR /opt/pi

# Install dependencies and build all packages
RUN npm install --prefer-offline --no-audit && \
    npm run build && \
    npm cache clean --force

RUN chmod +x /opt/pi/docker/entrypoint.sh && \
    ln -sf /opt/pi/packages/coding-agent/dist/cli.js /usr/local/bin/pi

# Create non-root user with workspace and config directories
RUN useradd -m -s /bin/bash pi && \
    mkdir -p /opt/workspace /home/pi/.pi/agent && \
    chown -R pi:pi /opt/workspace /home/pi/.pi /opt/pi

USER pi
ENV TERM=xterm-256color

WORKDIR /opt/workspace
ENTRYPOINT ["/opt/pi/docker/entrypoint.sh"]
