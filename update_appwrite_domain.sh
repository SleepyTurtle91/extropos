#!/bin/bash

# Update Appwrite Domain Configuration
# Run this script to allow access via IP address

echo "🔧 Updating Appwrite Domain Configuration..."
echo ""

# Find the Appwrite main container
CONTAINER=$(docker ps --format "{{.Names}}" | grep "^appwrite$")

if [ -z "$CONTAINER" ]; then
    echo "❌ Appwrite container not found"
    exit 1
fi

echo "Found container: $CONTAINER"
echo ""
echo "Current domain configuration:"
docker exec $CONTAINER env | grep "_APP_DOMAIN=" | head -5
echo ""

echo "To allow access from network (192.168.1.234), you need to:"
echo "1. Stop Appwrite: docker-compose down"
echo "2. Edit .env file and change:"
echo "   _APP_DOMAIN=localhost"
echo "   to"
echo "   _APP_DOMAIN=192.168.1.234"
echo ""
echo "3. Restart Appwrite: docker-compose up -d"
echo ""
echo "OR to access console now:"
echo "   Browser: http://localhost (on this machine)"
echo "   FlutterPOS endpoint: http://localhost/v1"
echo ""
