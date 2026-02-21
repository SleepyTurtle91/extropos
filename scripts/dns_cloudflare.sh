#!/usr/bin/env bash
# Create or update an A record (api.<domain>) pointing to your PUBLIC_IP using Cloudflare API
# Usage: CF_API_TOKEN="token" ./dns_cloudflare.sh extrotarget.com 203.0.113.10

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: CF_API_TOKEN=token $0 <domain> <public-ip> [subdomain]"
  echo "Example: CF_API_TOKEN=xxx $0 extrotarget.com 203.0.113.10 api"
  exit 2
fi

DOMAIN="$1"
PUBLIC_IP="$2"
SUBDOMAIN="${3:-api}"
RECORD_NAME="$SUBDOMAIN.$DOMAIN"

if [ -z "${CF_API_TOKEN:-}" ]; then
  echo "ERROR: CF_API_TOKEN environment variable must be set with a Cloudflare API token."
  exit 1
fi

# Get zone id
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ -z "$ZONE_ID" ] || [ "$ZONE_ID" == "null" ]; then
  echo "Could not find Cloudflare zone for ${DOMAIN}. Ensure the domain exists in Cloudflare account."
  exit 1
fi

echo "Found zone: ${ZONE_ID} for domain ${DOMAIN}"

# Check if record exists
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?type=A&name=${RECORD_NAME}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" | jq -r '.result[0].id // empty')

if [ -n "$RECORD_ID" ]; then
  echo "Updating A record ${RECORD_NAME} -> ${PUBLIC_IP}"
  curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID}" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'"${RECORD_NAME}"'","content":"'"${PUBLIC_IP}"'","proxied":false}' \
  | jq -r '.success // false' | grep -q true && echo "✅ A record updated." || echo "❌ Failed to update A record."
else
  echo "Creating A record ${RECORD_NAME} -> ${PUBLIC_IP}"
  CREATE_RESULT=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${CF_API_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'"${RECORD_NAME}"'","content":"'"${PUBLIC_IP}"'","ttl":1,"proxied":false}')

  if echo "$CREATE_RESULT" | jq -e '.success==true' >/dev/null 2>&1; then
    echo "✅ A record created."
  else
    echo "❌ Failed to create A record"
    echo "$CREATE_RESULT" | jq -r '.errors[]?.message // .'
    exit 1
  fi
fi

echo "Done. Please allow DNS to propagate (usually instant for Cloudflare, but may take minutes)."