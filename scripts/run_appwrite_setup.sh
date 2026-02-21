#!/usr/bin/env bash
# Orchestrator script to run DNS + Appwrite domain setup
# Usage: ./run_appwrite_setup.sh <domain> <public-ip> [dns-provider]
# Example: ./run_appwrite_setup.sh api.extrotarget.com 203.0.113.10 cloudflare

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <domain> <public-ip> [dns-provider: cloudflare(default)|none]"
  echo "Example: $0 api.extrotarget.com 203.0.113.10 cloudflare"
  exit 2
fi

DOMAIN="$1"
PUBLIC_IP="$2"
DNS_PROVIDER="${3:-cloudflare}"

# Split domain into base and subdomain
BASE_DOMAIN=$(echo "$DOMAIN" | awk -F. '{print $(NF-1)"."$(NF)}')
SUBDOMAIN=$(echo "$DOMAIN" | sed "s/.${BASE_DOMAIN}//" | sed 's/^\.//')

echo "Running Appwrite Setup - Extro Target Sdn Bhd"
echo "Domain: ${DOMAIN}"
echo "Public IP: ${PUBLIC_IP}"
echo "Base domain: ${BASE_DOMAIN} Subdomain: ${SUBDOMAIN}"

echo "\nStep 1: DNS (provider: ${DNS_PROVIDER})"
if [ "${DNS_PROVIDER}" == "cloudflare" ]; then
  if [ -z "${CF_API_TOKEN:-}" ]; then
    echo "ERROR: CF_API_TOKEN not set. Export it and try again."
    echo "  export CF_API_TOKEN=your_cloudflare_api_token"
    exit 1
  fi
  ./scripts/dns_cloudflare.sh "${BASE_DOMAIN}" "${PUBLIC_IP}" "${SUBDOMAIN}"
else
  echo "Skipping DNS automation; please create an A record ${DOMAIN} -> ${PUBLIC_IP}"
fi

# Step 2: Update Appwrite .env and restart
./scripts/appwrite_set_domain.sh "${DOMAIN}" "${PUBLIC_IP}"

# Step 3: Help to inspect Traefik Docker socket if necessary
./scripts/fix_traefik_docker_perms.sh || true

# Step 4: Test health endpoint
echo "\nTesting health endpoint via HTTPS"
if curl -sSf --retry 3 --max-time 5 "https://${DOMAIN}/v1/health/version" >/dev/null; then
  echo "✅ Appwrite is reachable at https://${DOMAIN}/v1/health/version"
else
  echo "⚠️  Appwrite did not respond over HTTPS. Consider checking Traefik logs, firewall, and DNS propagation."
  echo "Run: sudo docker compose logs -f appwrite-traefik"
fi

# Final instructions
cat <<EOF

Done. Next steps:
1) Open Appwrite console: https://${DOMAIN}
2) Create a Project (or use Project ID) and add platform entries for Android/iOS/Web.
3) Configure your Flutter/Dart apps to use the endpoint 'https://${DOMAIN}/v1' and the Project ID.
EOF
