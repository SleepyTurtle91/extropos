#!/usr/bin/env bash
# Update Appwrite .env domain and restart compose.
# Usage: ./appwrite_set_domain.sh api.extrotarget.com 203.0.113.10

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <domain> <public-ip>"
  echo "Example: $0 api.extrotarget.com 203.0.113.10"
  exit 2
fi

DOMAIN="$1"
PUBLIC_IP="$2"
APPWRITE_ROOT="${APPWRITE_ROOT:-$HOME/appwrite}"
ENV_FILE="$APPWRITE_ROOT/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: $ENV_FILE not found. Please ensure Appwrite is installed in $APPWRITE_ROOT"
  exit 1
fi

# Backup
cp "$ENV_FILE" "$ENV_FILE.bak" && echo "Backed up $ENV_FILE -> $ENV_FILE.bak"

# Replace variables in .env (best effort)
update_env() {
  local key="$1"
  local value="$2"
  if grep -qE "^${key}=" "$ENV_FILE"; then
    sed -ri "s|^(${key}=).*|\1${value}|" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

# Set domain values
update_env _APP_DOMAIN "$DOMAIN"
update_env _APP_DOMAIN_TARGET "$DOMAIN"
update_env _APP_DOMAIN_TARGET_A "$PUBLIC_IP"
update_env _APP_DOMAIN_FUNCTIONS "functions.${DOMAIN}"
update_env _APP_DOMAIN_SITES "sites.${DOMAIN}"

echo "Updated domain entries in $ENV_FILE"

# Optional: list the values for check
grep -E "^_APP_DOMAIN|_APP_DOMAIN_TARGET|_APP_DOMAIN_TARGET_A|_APP_DOMAIN_FUNCTIONS|_APP_DOMAIN_SITES" "$ENV_FILE"

# Restart Appwrite
echo "Restarting Appwrite..."
cd "$APPWRITE_ROOT"

# Use sudo to avoid permission issues on docker.sock unless the current user is in docker group
if groups "$(whoami)" | grep -q '\bdocker\b'; then
  docker compose down
  docker compose pull || true
  docker compose up -d
else
  echo "Warning: current user not in 'docker' group, running with sudo"
  sudo docker compose down
  sudo docker compose pull || true
  sudo docker compose up -d
fi

# Give containers time to start
sleep 8

# Test health endpoint
TEST_URL="https://${DOMAIN}/v1/health/version"

if curl -sSf --retry 3 --max-time 5 "$TEST_URL" >/dev/null; then
  echo "✅ Appwrite reachable at: $TEST_URL"
else
  echo "⚠️  Unable to reach Appwrite at $TEST_URL"
  echo "Check Traefik logs and firewall if needed."
fi
