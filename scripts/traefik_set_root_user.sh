#!/usr/bin/env bash
# Add `user: root` to the traefik service in docker-compose.yml so Traefik can access docker.sock
# Usage: ./traefik_set_root_user.sh

set -euo pipefail

COMPOSE_FILE="${APPWRITE_ROOT:-$HOME/appwrite}/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "Composition file not found: $COMPOSE_FILE"
  exit 1
fi

cp "$COMPOSE_FILE" "$COMPOSE_FILE.bak.user"

# If `user:` already exists in the traefik block, skip modification
if awk '
  BEGIN { in_block=0 }
  /^
\s*traefik:\s*$/ { in_block=1; next }
  /^[^[:space:]]/ { in_block=0 }
  in_block && /\buser:/ { print; exit }
' "$COMPOSE_FILE" | grep -q '.' 2>/dev/null; then
  echo "traefik service already declares a user directive; no change required."
  exit 0
fi

# Add `user: root` right after `traefik:` line
awk 'BEGIN{added=0}
/^\s*traefik:\s*$/ {print; print "    user: root"; added=1; next} {print}
END{if (!added) exit 1}' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"

# Restart Traefik
cd "${APPWRITE_ROOT:-$HOME/appwrite}"
if groups "$(whoami)" | grep -q '\bdocker\b'; then
  docker compose up -d traefik
else
  sudo docker compose up -d traefik
fi

echo "Updated traefik service to run as root and restarted it. Backup at $COMPOSE_FILE.bak.user"
