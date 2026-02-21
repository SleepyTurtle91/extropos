#!/bin/bash

# Bypass Traefik - Expose Appwrite port directly
# Use this if Traefik routing fails

echo "🔧 Exposing Appwrite Container Port (Bypass Traefik)"
echo "====================================================="
echo ""

echo "⚠️  This script will modify docker-compose.yml to expose"
echo "   Appwrite's internal port 80 as host port 8081"
echo ""
echo "   This bypasses Traefik (which has routing issues)"
echo ""

cd ~/appwrite

# Backup docker-compose.yml
cp docker-compose.yml docker-compose.yml.backup
echo "✅ Backed up docker-compose.yml"

# Find the appwrite service and add port mapping
echo "Modifying docker-compose.yml..."

# Use a temporary file with proper escaping
cat > /tmp/add_port.awk << 'AWK_SCRIPT'
/^  appwrite:/ { 
    in_appwrite = 1 
}

/^  [a-z]/ && !/^  appwrite:/ { 
    if (in_appwrite && !port_added) {
        print "    ports:"
        print "      - \"8081:80\""
        port_added = 1
    }
    in_appwrite = 0
}

{ print }

END {
    if (in_appwrite && !port_added) {
        print "    ports:"
        print "      - \"8081:80\""
    }
}
AWK_SCRIPT

awk -f /tmp/add_port.awk docker-compose.yml > docker-compose.yml.new
mv docker-compose.yml.new docker-compose.yml
rm /tmp/add_port.awk

echo "✅ Modified docker-compose.yml"
echo ""
echo "Restarting Appwrite..."
docker compose down
docker compose up -d appwrite

echo ""
echo "Waiting for Appwrite to start..."
sleep 5

# Test connection
echo "Testing direct connection..."
RESULT=$(curl -s http://localhost:8081/v1/health/version 2>/dev/null || echo "")

if [[ "$RESULT" == *"version"* ]]; then
    echo "✅ Appwrite is accessible on port 8081!"
    echo ""
    echo "Response: $RESULT"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📱 Update Backend app endpoint:"
    echo "   Menu → Appwrite Config"
    echo "   Endpoint: http://localhost:8081/v1"
    echo ""
    echo "🔄 Update ADB port forwarding:"
    echo "   adb reverse tcp:8080 tcp:8081"
    echo ""
    echo "   Android app endpoint stays: http://localhost:8080/v1"
    echo "   (but now routes to 8081 instead of 80)"
else
    echo "❌ Connection test failed"
    echo "Response: $RESULT"
    echo ""
    echo "Restoring backup..."
    mv docker-compose.yml.backup docker-compose.yml
    exit 1
fi
