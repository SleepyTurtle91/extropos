#!/bin/bash

# Setup Appwrite CORS for extropos.org
# Usage: ./setup_appwrite_cors.sh <appwrite-endpoint> <api-key>
# Example: ./setup_appwrite_cors.sh https://appwrite.extropos.org/v1 your-api-key-here

set -e

ENDPOINT="${1:-https://appwrite.extropos.org/v1}"
API_KEY="${2:-}"
PROJECT_ID="6940a64500383754a37f"

if [ -z "$API_KEY" ]; then
  echo "❌ Error: API_KEY not provided"
  echo "Usage: ./setup_appwrite_cors.sh <endpoint> <api-key>"
  exit 1
fi

echo "🔧 Configuring Appwrite CORS for extropos.org..."
echo "   Endpoint: $ENDPOINT"
echo "   Project: $PROJECT_ID"

# Update settings via Appwrite API (requires admin/server key)
curl -s -X PATCH \
  "$ENDPOINT/console/projects/$PROJECT_ID/settings" \
  -H "X-Appwrite-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "corsOrigins": [
      "https://extropos.org",
      "https://www.extropos.org",
      "http://localhost:3000",
      "http://localhost:8080"
    ],
    "corsCredentials": true
  }' | jq .

echo "✅ CORS configured successfully"
echo ""
echo "Allowed origins:"
echo "  • https://extropos.org"
echo "  • https://www.extropos.org"
echo "  • http://localhost:3000 (local dev)"
echo "  • http://localhost:8080 (local Appwrite console)"
