#!/usr/bin/env bash
# Create Traefik static dynamic file to proxy Appwrite services without Docker provider
# This writes a dynamic config to the appwrite-config volume and restarts Traefik

set -euo pipefail

COMPOSE_FILE="${APPWRITE_ROOT:-$HOME/appwrite}/docker-compose.yml"
DOMAIN=${1:-api.extrotarget.com}

CONFIG_FILE="/tmp/traefik_dynamic_${DOMAIN}.yml"

# Use a single-quoted heredoc so that backticks/dollars aren't expanded/shell-interpolated.
cat > "$CONFIG_FILE" <<'YAML'
http:
  routers:
    appwrite_api_http:
      entryPoints:
        - appwrite_web
      rule: "Host(`${DOMAIN}`) && PathPrefix(`/`)"
      service: appwrite_api
      priority: 10

    appwrite_api_https:
      entryPoints:
        - appwrite_websecure
      rule: "Host(`${DOMAIN}`) && PathPrefix(`/`)"
      service: appwrite_api
      tls:
        certResolver: letsencrypt
      priority: 10

    appwrite_console_http:
      entryPoints:
        - appwrite_web
      rule: "Host(`${DOMAIN}`) && PathPrefix(`/console`)"
      service: appwrite_console
      priority: 10

    appwrite_console_https:
      entryPoints:
        - appwrite_websecure
      rule: "Host(`${DOMAIN}`) && PathPrefix(`/console`)"
      service: appwrite_console
      tls:
        certResolver: letsencrypt
      priority: 10

    appwrite_realtime_ws:
      entryPoints:
        - appwrite_web
      rule: "Host(`${DOMAIN}`) && PathPrefix(`/v1/realtime`)"
      service: appwrite_realtime
      priority: 10

    appwrite_realtime_wss:
      entryPoints:
        - appwrite_websecure
      rule: "Host(`${DOMAIN}`) && PathPrefix(`/v1/realtime`)"
      service: appwrite_realtime
      tls:
        certResolver: letsencrypt
      priority: 10

  services:
    appwrite_api:
      loadBalancer:
        servers:
          - url: "http://appwrite:80"

    appwrite_console:
      loadBalancer:
        servers:
          - url: "http://appwrite-console:80"

    appwrite_realtime:
      loadBalancer:
        servers:
          - url: "http://appwrite-realtime:80"
YAML

# Write this file into the appwrite-config volume
if groups "$(whoami)" | grep -q '\bdocker\b'; then
  docker run --rm -v appwrite_appwrite-config:/tmp busybox sh -c "cat > /tmp/dynamic_config.yml" < "$CONFIG_FILE"
  docker run --rm -v appwrite_appwrite-config:/tmp busybox sh -c "chmod 644 /tmp/dynamic_config.yml || true"
else
  echo "Warning: Non-docker group user; attempting with sudo"
  sudo docker run --rm -v appwrite_appwrite-config:/tmp busybox sh -c "cat > /tmp/dynamic_config.yml" < "$CONFIG_FILE"
  sudo docker run --rm -v appwrite_appwrite-config:/tmp busybox sh -c "chmod 644 /tmp/dynamic_config.yml || true"
fi

# Restart Traefik
cd "${APPWRITE_ROOT:-$HOME/appwrite}"
if groups "$(whoami)" | grep -q '\bdocker\b'; then
  docker compose up -d traefik
else
  sudo docker compose up -d traefik
fi

# Show logs for a while
sleep 5
if groups "$(whoami)" | grep -q '\bdocker\b'; then
  docker compose logs --tail 40 traefik
else
  sudo docker compose logs --tail 40 traefik
fi

echo "Dynamic configuration installed to appwrite-config volume as dynamic_config.yml and Traefik restarted."
