#!/bin/bash
# Prunes dev-tool caches that no distro's package manager touches
# (AUR build cache, npm cache, Docker images/containers, pip cache).
# Run by systemd/user/dev-cache-cleanup.timer — not meant to be run as root.
set -e

log() { echo "[dev-cache-cleanup] $*"; }

if command -v yay &>/dev/null; then
    log "Pruning yay build cache..."
    yay -Sc --noconfirm || true
fi

if command -v npm &>/dev/null; then
    log "Cleaning npm cache..."
    npm cache clean --force || true
fi

if command -v pip &>/dev/null; then
    log "Purging pip cache..."
    pip cache purge || true
fi

if command -v docker &>/dev/null && docker info &>/dev/null; then
    log "Pruning dangling Docker images, stopped containers, unused networks..."
    log "(tagged images are never touched, even if unused; volumes are never touched)"
    docker system prune -f || true
fi

log "Done. Disk usage: $(df -h /home | awk 'NR==2{print $5}')"
