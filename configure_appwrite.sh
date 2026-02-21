#!/bin/bash

# FlutterPOS - Appwrite IP Configuration Helper
# This script detects your local IP and updates environment.dart

set -e

echo "🔍 FlutterPOS Appwrite Configuration Helper"
echo "=========================================="
echo ""

# Detect local IP
echo "📡 Detecting your local IP address..."

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    LOCAL_IP=$(hostname -I | awk '{print $1}')
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    LOCAL_IP=$(ipconfig getifaddr en0 || ipconfig getifaddr en1)
else
    echo "⚠️  Unknown OS. Please manually find your IP address."
    echo ""
    echo "Linux/macOS: ip addr show | grep 'inet '"
    echo "Windows: ipconfig | findstr IPv4"
    exit 1
fi

if [ -z "$LOCAL_IP" ]; then
    echo "❌ Could not detect IP address automatically."
    echo ""
    echo "Please find your IP manually:"
    echo "  Linux: ip addr show | grep 'inet '"
    echo "  macOS: ipconfig getifaddr en0"
    echo "  Windows: ipconfig | findstr IPv4"
    exit 1
fi

echo "✅ Found IP: $LOCAL_IP"
echo ""

# Show current configuration
echo "📋 Current Appwrite Configuration:"
echo "   Endpoint: http://localhost:8080/v1"
echo "   Project ID: 69392e4c0017357bd3d5"
echo ""

# Ask user what to configure
echo "🎯 Select configuration target:"
echo "   1) Desktop/Web development (use localhost)"
echo "   2) Android/iOS testing (use $LOCAL_IP)"
echo ""
read -p "Enter choice [1-2]: " choice

ENDPOINT=""
case $choice in
    1)
        ENDPOINT="http://localhost:8080/v1"
        echo ""
        echo "✅ Configuring for Desktop/Web development"
        ;;
    2)
        ENDPOINT="http://$LOCAL_IP:8080/v1"
        echo ""
        echo "✅ Configuring for Android/iOS testing"
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

# Update environment.dart
ENV_FILE="lib/config/environment.dart"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: $ENV_FILE not found!"
    echo "   Make sure you're running this from the FlutterPOS root directory."
    exit 1
fi

echo ""
echo "📝 Updating $ENV_FILE..."

cat > "$ENV_FILE" << EOF
class Environment {
  // Local Appwrite Docker instance
  static const String appwriteProjectId =
      '69392e4c0017357bd3d5'; // Your local Appwrite project ID
  static const String appwriteProjectName = 'ExtroPOS';
  
  // Endpoint configured for: $([ "$choice" == "1" ] && echo "Desktop/Web" || echo "Android/iOS")
  // IP detected: $LOCAL_IP
  static const String appwritePublicEndpoint =
      '$ENDPOINT';
}
EOF

echo "✅ Configuration updated!"
echo ""
echo "📋 New Configuration:"
echo "   Endpoint: $ENDPOINT"
echo "   Project ID: 69392e4c0017357bd3d5"
echo ""

# Verify Appwrite is running
echo "🔍 Checking if Appwrite is running..."

if command -v curl &> /dev/null; then
    if curl -s "http://localhost:8080/v1/health/version" > /dev/null 2>&1; then
        VERSION=$(curl -s "http://localhost:8080/v1/health/version" | grep -o '"version":"[^"]*' | cut -d'"' -f4)
        echo "✅ Appwrite is running (version: $VERSION)"
    else
        echo "⚠️  Appwrite is not responding on localhost:8080"
        echo ""
        echo "Start Appwrite with:"
        echo "  cd docker"
        echo "  docker-compose -f appwrite-compose.yml up -d"
    fi
else
    echo "⚠️  curl not found - cannot test connection"
fi

echo ""
echo "🎉 Configuration complete!"
echo ""
echo "Next Steps:"
echo "  1. Run: flutter run -d windows (Desktop)"
echo "  2. Or build: ./build_flavors.sh pos debug (Android)"
echo "  3. Test connection in Settings → Appwrite Integration"
echo ""
echo "📖 See APPWRITE_LOCAL_SETUP.md for detailed instructions"
