#!/usr/bin/env bash
# Troubleshoot Traefik Docker socket permission issues
# Run this script to report suggestions and optionally add the user to docker group

set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed or not in PATH"
  exit 1
fi

echo "Inspecting /var/run/docker.sock"
ls -l /var/run/docker.sock || true

auth_socket_owner=$(stat -c '%U' /var/run/docker.sock || true)
auth_socket_group=$(stat -c '%G' /var/run/docker.sock || true)

echo "Owner: ${auth_socket_owner} Group: ${auth_socket_group}"

if groups "$(whoami)" | grep -q '\bdocker\b'; then
  echo "OK: Current user is in 'docker' group. Traefik should be able to access the socket if running in container with correct volume mapping."
else
  echo "NOTE: Current user is not in 'docker' group. You can add it with:"
  echo "  sudo usermod -aG docker \$(whoami) ; newgrp docker"
  echo "After adding, re-run the Docker compose commands as the unprivileged user (no sudo)."
fi

# Also show Traefik service config if in ~/appwrite/docker-compose.yml
COMPOSE_FILE="${APPWRITE_ROOT:-$HOME/appwrite}/docker-compose.yml"

if [ -f "$COMPOSE_FILE" ]; then
  echo "\nChecking traefik service block in $COMPOSE_FILE"
  grep -n "appwrite-traefik" -n "$COMPOSE_FILE" || true
  grep -n "docker.sock" "$COMPOSE_FILE" || true
else
  echo "No compose file found at $COMPOSE_FILE — skipping content checks"
fi

echo "\nRecommendation: If Traefik can't access the socket, either run 'sudo docker compose up -d' OR add your user to the 'docker' group and avoid sudo."

echo "Done. If you still have Traefik 'permission denied' errors, check Traefik logs with:"
echo "  sudo docker compose logs -f appwrite-traefik"
