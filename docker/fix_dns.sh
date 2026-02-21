#!/bin/bash

# Cloudflare DNS Fix Script for api.extropos.org
# This script updates the DNS record to point to your server IP and disables proxying

# Replace with your actual Cloudflare API token
CF_API_TOKEN='ClYGCQnaJXFPqBpwORDOqyZKQyueh1m0YhN8_hxF'

echo "🔧 Fixing Cloudflare DNS for api.extropos.org..."

# Get Zone ID for extropos.org
echo "📡 Getting Zone ID..."
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=extropos.org" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$ZONE_ID" = "null" ] || [ -z "$ZONE_ID" ]; then
  echo "❌ Failed to get Zone ID. Check your API token and domain name."
  exit 1
fi

echo "✅ Zone ID: $ZONE_ID"

# Get DNS Record ID for api.extropos.org
echo "📡 Getting DNS Record ID..."
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=api.extropos.org" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [ "$RECORD_ID" = "null" ] || [ -z "$RECORD_ID" ]; then
  echo "❌ Failed to get DNS Record ID. Check if api.extropos.org exists in Cloudflare."
  exit 1
fi

echo "✅ Record ID: $RECORD_ID"

# Update DNS Record
echo "🔄 Updating DNS record to point to 118.100.24.69 with proxied=true (Cloudflare tunnel)..."
RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "Authorization: Bearer $CF_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"A","name":"api.extropos.org","content":"118.100.24.69","proxied":true}')

SUCCESS=$(echo $RESPONSE | jq -r '.success')

if [ "$SUCCESS" = "true" ]; then
  echo "✅ DNS record updated successfully!"
  echo "⏳ DNS propagation may take 5-30 minutes."
  echo "🧪 Test with: curl https://api.extropos.org/health"
  echo "ℹ️  Note: Requests will now go through Cloudflare tunnel, bypassing ISP port blocking."
else
  echo "❌ Failed to update DNS record."
  echo "Response: $RESPONSE"
  exit 1
fi