#!/usr/bin/env bash
# Simple DuckDNS updater script
# Usage: ./update_duckdns.sh <duck-domain> <token>
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <duck-domain> <token>"
  exit 1
fi

DOMAIN="$1"
TOKEN="$2"

URL="https://www.duckdns.org/update?domains=${DOMAIN}&token=${TOKEN}&ip="

# Perform update
curl -fsS --retry 3 "${URL}" || {
  echo "DuckDNS update failed"
  exit 1
}

echo "DuckDNS update completed for ${DOMAIN}"