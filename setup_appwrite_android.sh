#!/bin/bash
set -e

echo "🔧 FlutterPOS Backend - Appwrite Android Setup"
echo ""

# Check device connection
if ! adb devices | grep -q "device$"; then
  echo "❌ No Android device connected"
  echo "Connect device via USB or WiFi ADB and try again"
  exit 1
fi

echo "✅ Android device detected"
adb devices -l | grep "device$"

# Check Appwrite running
if ! docker ps | grep -q appwrite; then
  echo ""
  echo "❌ Appwrite Docker containers not running"
  echo "Starting Appwrite..."
  cd ~/appwrite
  docker compose up -d
  echo "Waiting for Appwrite to start..."
  sleep 10
fi

echo ""
echo "✅ Appwrite is running"
docker ps | grep appwrite | wc -l | xargs echo "  Containers:"

# Set up port forwarding
echo ""
echo "Setting up ADB reverse port forwarding..."
adb reverse --remove-all 2>/dev/null || true
adb reverse tcp:8080 tcp:80

echo ""
echo "✅ Port forwarding configured!"
adb reverse --list

# Test connectivity
echo ""
echo "Testing connectivity..."
if adb shell curl -s http://localhost:8080/v1/health/version 2>/dev/null | grep -q "version"; then
  echo "✅ Connection test successful!"
  adb shell curl -s http://localhost:8080/v1/health/version
else
  echo "⚠️  Connection test failed - check Appwrite logs"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 On your Android device:"
echo "  1. Open FlutterPOS Backend app"
echo "  2. Go to Menu → Appwrite Config"
echo "  3. Set endpoint to: http://localhost:8080/v1"
echo "  4. Set project ID to: 689965770017299bd5a5"
echo "  5. Click 'Test Connection'"
echo "  6. Should see: ✅ Ping successful!"
echo ""
echo "🔗 Port forwarding active:"
echo "   Android localhost:8080 → PC localhost:80"
echo ""
echo "⚠️  Note: Re-run this script after disconnecting/reconnecting device"
echo ""
