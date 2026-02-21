#!/bin/bash

# FlutterPOS - Quick Appwrite Connection Test
# Tests if FlutterPOS can connect to your local Appwrite instance

echo "🧪 Testing Appwrite Connection"
echo "=============================="
echo ""

# Test 1: Check if Appwrite is running
echo "1️⃣  Testing Appwrite server..."
RESPONSE=$(curl -s https://appwrite.extropos.org/v1/health/version 2>&1)

if echo "$RESPONSE" | grep -q "version"; then
    VERSION=$(echo "$RESPONSE" | grep -o '"version":"[^"]*' | cut -d'"' -f4)
    echo "   ✅ Appwrite is running (version: $VERSION)"
else
    echo "   ❌ Appwrite is not responding"
    echo "   Response: $RESPONSE"
    echo ""
    echo "   Start Appwrite with:"
    echo "   cd docker && docker-compose -f appwrite-compose.yml up -d"
    exit 1
fi

# Test 2: Check project exists
echo ""
echo "2️⃣  Testing project access..."
PROJECT_ID="6940a64500383754a37f"
API_KEY="088ea83f36a48f15cc11adf63392f2da1f98f16aa554fa161baf5b28044bcd94ae3cd5e8c0365b161aadbfecb8e3cfa00e4ef24e46299903586388203272156da954c2b4204971321233701997c5bcda4764d25f774ac54fbfc595524a2900b4e216d35cbea9a1923970a099cc89463880f2b110f8362a7fdd1231f0e628b03f"

# Note: This will fail without authentication, but we can check if the endpoint is reachable
HEALTH=$(curl -s http://localhost:8080/v1/health/db 2>&1)
if echo "$HEALTH" | grep -q "status"; then
    echo "   ✅ Appwrite database is accessible"
else
    echo "   ⚠️  Cannot verify database (may need authentication)"
fi

# Test 3: Check current FlutterPOS configuration
echo ""
echo "3️⃣  Checking FlutterPOS configuration..."
if [ -f "lib/config/environment.dart" ]; then
    ENDPOINT=$(grep "appwritePublicEndpoint" lib/config/environment.dart | grep -o 'http[^"]*')
    PROJ_ID=$(grep "appwriteProjectId" lib/config/environment.dart | grep -o "'[^']*'" | head -1 | tr -d "'")
    
    echo "   Endpoint: $ENDPOINT"
    echo "   Project ID: $PROJ_ID"
    
    if [ "$PROJ_ID" == "6940a64500383754a37f" ]; then
        echo "   ✅ Project ID matches your remote Appwrite"
    else
        echo "   ⚠️  Project ID doesn't match (expected: 6940a64500383754a37f)"
    fi
    
    if echo "$ENDPOINT" | grep -q "localhost"; then
        echo "   📱 Config: Desktop/Web (localhost)"
        echo "   ⚠️  For Android testing, run: ./configure_appwrite.sh"
    else
        echo "   📱 Config: Android/iOS (using IP)"
    fi
else
    echo "   ❌ environment.dart not found"
fi

# Test 4: Show Appwrite console URL
echo ""
echo "4️⃣  Appwrite Console Access:"
echo "   URL: http://localhost:8080"
echo "   Email: abber8@gmail.com"
echo "   Password: Berneydaniel123"

# Test 5: Docker containers status
echo ""
echo "5️⃣  Docker containers:"
CONTAINERS=$(docker ps --filter "name=appwrite" --format "table {{.Names}}\t{{.Status}}" 2>/dev/null)
if [ -n "$CONTAINERS" ]; then
    echo "$CONTAINERS" | head -10
    TOTAL=$(docker ps --filter "name=appwrite" --format "{{.Names}}" | wc -l)
    echo ""
    echo "   ✅ $TOTAL Appwrite containers running"
else
    echo "   ⚠️  No Appwrite containers found"
fi

echo ""
echo "=============================="
echo "🎉 Test Complete!"
echo ""
echo "Next Steps:"
echo "  • Run FlutterPOS: flutter run -d windows"
echo "  • Configure IP for Android: ./configure_appwrite.sh"
echo "  • Read docs: APPWRITE_LOCAL_SETUP.md"
