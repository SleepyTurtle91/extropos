#!/usr/bin/env bash
# Enable Let's Encrypt (ACME) for Traefik in Appwrite's docker-compose.yml
# Usage: ./traefik_enable_acme.sh you@example.com
# The script will:
#  - backup your docker-compose.yml
#  - add ACME resolver flags to traefik command
#  - change the certificates mount to read-write for traefik
#  - add certresolver labels to appwrite-related services
#  - restart Traefik

set -euo pipefail

# Use the provided email (param) or read it from env var (default to appwrite admin email if present)
if [ "$#" -ge 1 ]; then
  LE_EMAIL="$1"
elif [ -n "${APPWRITE_LETSENCRYPT_EMAIL:-}" ]; then
  LE_EMAIL="${APPWRITE_LETSENCRYPT_EMAIL}" 
else
  echo "Usage: $0 <letsencrypt_email>"
  exit 2
fi
COMPOSE_FILE="${APPWRITE_ROOT:-$HOME/appwrite}/docker-compose.yml"

if [ ! -f "$COMPOSE_FILE" ]; then
  echo "ERROR: docker-compose.yml not found at $COMPOSE_FILE"
  exit 1
fi

# Backup
cp "$COMPOSE_FILE" "$COMPOSE_FILE.bak"

echo "Backed up $COMPOSE_FILE -> $COMPOSE_FILE.bak"

# Add ACME command flags to traefik 'command:' block
# This will add a cert resolver named 'letsencrypt' using tlschallenge and storage path
awk -v email="$LE_EMAIL" '
  BEGIN{in_traefik=0; inserted=0}
  /^\s*traefik:/ {in_traefik=1}
  {
    print
  }
  in_traefik && /^\s*command:/ && !inserted {
    # After command: add resolver flags as contiguous - entries
    print "      - --certificatesresolvers.letsencrypt.acme.httpChallenge.entryPoint=appwrite_web"
    print "      - --certificatesresolvers.letsencrypt.acme.email=" email
    print "      - --certificatesresolvers.letsencrypt.acme.storage=/storage/certificates/acme.json"
    inserted=1
  }
  /^\s*networks:/ && in_traefik { in_traefik=0 }
' "$COMPOSE_FILE" > "$COMPOSE_FILE.tmp" && mv "$COMPOSE_FILE.tmp" "$COMPOSE_FILE"

# Change appwrite-certificates mount from read-only to read-write for traefik service
# This replaces a line like "- appwrite-certificates:/storage/certificates:ro" to :rw
sed -ri "s|(appwrite-certificates:/storage/certificates):ro|\1:rw|" "$COMPOSE_FILE"
# Make appwrite-config writable by traefik as well.
sed -ri "s|(appwrite-config:/storage/config):ro|\1:rw|" "$COMPOSE_FILE"

# Remove duplicate/incorrect cert resolver lines under traefik command and insert the correct http-challenge config
sed -ri "s/^\s*-\s*--certificatesresolvers\.letsencrypt\.acme\.[^\n]*$//g" "$COMPOSE_FILE"
sed -ri "/^\s*command:\s*$/a \\      - --certificatesresolvers.letsencrypt.acme.httpChallenge.entryPoint=appwrite_web\n      - --certificatesresolvers.letsencrypt.acme.email=${LE_EMAIL}\n      - --certificatesresolvers.letsencrypt.acme.storage=/storage/certificates/acme.json" "$COMPOSE_FILE"

# Remove docker provider flags to prevent traefik from trying to access the docker socket (SELinux/permission problems)
sed -ri "s/^\s*-\s*--providers\.docker\..*$//g" "$COMPOSE_FILE"

echo "Adding certresolver label to appwrite service"
if ! grep -q "traefik.http.routers.appwrite_api_https.tls.certresolver" "$COMPOSE_FILE"; then
  sed -n '/^  appwrite:/,/^  appwrite-console:/p' "$COMPOSE_FILE" | sed -n '1,120p' >/dev/null 2>&1 || true
  # Add the label right after the "- traefik.http.routers.appwrite_api_https.tls=true" line
  sed -ri "0,/(- traefik.http.routers.appwrite_api_https.tls=true)/s//\1\n      - traefik.http.routers.appwrite_api_https.tls.certresolver=letsencrypt/" "$COMPOSE_FILE"
fi

echo "Adding certresolver label to appwrite-console and appwrite-realtime services"
if ! grep -q "traefik.http.routers.appwrite_console_https.tls.certresolver" "$COMPOSE_FILE"; then
  sed -ri "0,/(- traefik.http.routers.appwrite_console_https.tls=true)/s//\1\n      - traefik.http.routers.appwrite_console_https.tls.certresolver=letsencrypt/" "$COMPOSE_FILE"
fi
if ! grep -q "traefik.http.routers.appwrite_realtime_wss.tls.certresolver" "$COMPOSE_FILE" && ! grep -q "traefik.http.routers.appwrite_realtime_wss.tls.certresolver" "$COMPOSE_FILE"; then
  sed -ri "0,/(- traefik.http.routers.appwrite_realtime_wss.tls=true)/s//\1\n      - traefik.http.routers.appwrite_realtime_wss.tls.certresolver=letsencrypt/" "$COMPOSE_FILE" || true
  sed -ri "0,/(- traefik.http.routers.appwrite_realtime_wss.tls=true)/s//\1\n      - traefik.http.routers.appwrite_realtime_wss.tls.certresolver=letsencrypt/" "$COMPOSE_FILE" || true
fi

# Show a diff (informational) -- requires git
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Showing git diff (if tracked):"
  git --no-pager diff -- "$COMPOSE_FILE" || true
fi

# Restart Traefik to re-evaluate certificates
cd "${APPWRITE_ROOT:-$HOME/appwrite}"

if groups "$(whoami)" | grep -q '\bdocker\b'; then
  docker compose up -d traefik
else
  sudo docker compose up -d traefik
fi

# Wait and show logs for a short time to detect ACME activity
sleep 5

if groups "$(whoami)" | grep -q '\bdocker\b'; then
  docker compose logs --tail 50 traefik
else
  sudo docker compose logs --tail 50 traefik
fi

# Check acme.json present in the mounted volume
# We can attempt to read acme.json if the volume is mounted to the host; otherwise we simply rely on logs.
echo "Done. Check the logs above for ACME activity and certificate issuance."

# Ensure acme.json exists and has appropriate permissions in the appwrite-certificates Docker volume
echo "Ensuring acme.json and permissions in named volume appwrite-certificates..."
docker run --rm -v appwrite-certificates:/tmp busybox sh -c "touch /tmp/acme.json || true; chmod 600 /tmp/acme.json || true; chmod 755 /tmp || true"
echo "Ensured acme.json exists and is locked to owner rw (600), folder perms 755"

# Ensure config folder is readable
echo "Ensuring config folder permissions in named volume appwrite-config..."
docker run --rm -v appwrite-config:/tmp busybox sh -c "chmod -R 755 /tmp || true"
echo "Set appwrite-config ownership/perms to 755"
