#!/usr/bin/env bash
# Verify TLS certificate for a domain and print details
# Usage: ./verify_tls.sh api.extrotarget.com

set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <domain>"
  exit 2
fi

DOMAIN="$1"

echo "Testing HTTPS endpoint and certificate for: $DOMAIN"

# Basic curl, print HTTP status and body
echo "\n=== HTTP(S) check ==="
if curl -sI "https://${DOMAIN}/v1/health/version" | grep -q "200"; then
  echo "✅ HTTP 200 response returned"
else
  echo "⚠️  Non-200 response from ${DOMAIN} or unreachable"
fi

# Show certificate details via openssl
echo "\n=== Certificate details (openssl s_client) ==="
openssl s_client -showcerts -servername "${DOMAIN}" -connect "${DOMAIN}:443" < /dev/null 2>/dev/null | openssl x509 -noout -text | sed -n '1,120p'

# Print certificate subject and issuer
echo "\n=== Certificate subject and issuer ==="
openssl s_client -servername "${DOMAIN}" -connect "${DOMAIN}:443" < /dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates

# Print cert fingerprint
echo "\n=== Certificate fingerprint (SHA256) ==="
openssl s_client -showcerts -servername "${DOMAIN}" -connect "${DOMAIN}:443" < /dev/null 2>/dev/null | openssl x509 -noout -fingerprint -sha256

echo "\nDone. If this fails, check Traefik logs and firewall."