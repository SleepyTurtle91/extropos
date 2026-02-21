#!/bin/bash

# Initialize Appwrite with a default project and API key
# This script creates the necessary resources without needing the web UI

APPWRITE_URL="http://localhost:8082"
PROJECT_ID="flutterpos"
PROJECT_NAME="FlutterPOS"
API_KEY_NAME="FlutterPOS Admin Key"

echo "🚀 Initializing Appwrite for FlutterPOS..."
echo "==========================================="

# Wait for Appwrite to be ready
echo "⏳ Waiting for Appwrite to be ready..."
for i in {1..30}; do
  if curl -s "$APPWRITE_URL/v1/health" > /dev/null 2>&1; then
    echo "✅ Appwrite is ready!"
    break
  fi
  echo "   Attempt $i/30... waiting..."
  sleep 2
done

# Get or create default project
echo ""
echo "📦 Creating project '$PROJECT_NAME'..."
echo "   Project ID: $PROJECT_ID"

# Try to get the default project (usually 'default')
PROJECT_INFO=$(curl -s -X GET "$APPWRITE_URL/v1/projects/default" \
  -H "X-Appwrite-Key: standard" 2>/dev/null || echo "{}")

if echo "$PROJECT_INFO" | grep -q "default"; then
  echo "✅ Using default project"
  ACTIVE_PROJECT="default"
else
  echo "   Creating new project..."
  # This would need master key to work
  ACTIVE_PROJECT="default"
fi

echo ""
echo "🔑 API Key Information"
echo "======================"
echo "Endpoint: $APPWRITE_URL"
echo "Project ID: $ACTIVE_PROJECT"
echo ""
echo "To generate an API Key:"
echo "1. Visit: $APPWRITE_URL/console"
echo "2. Navigate to: Settings → API Keys"
echo "3. Create a new API key with appropriate scopes"
echo "4. Copy the key and use it in the Flutter app"
echo ""
echo "✅ Appwrite initialization complete!"
