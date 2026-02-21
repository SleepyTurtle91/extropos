#!/bin/bash

# FlutterPOS Appwrite Connection Tester
# Tests connection to your Docker Appwrite instance

set -e

echo "╔════════════════════════════════════════╗"
echo "║  FlutterPOS Appwrite Connection Test  ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to test endpoint
test_endpoint() {
    local endpoint=$1
    echo -e "${BLUE}Testing endpoint:${NC} $endpoint"
    
    if curl -s -f "$endpoint/health/version" > /dev/null 2>&1; then
        local version=$(curl -s "$endpoint/health/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}✓ Connection successful!${NC} Appwrite version: $version"
        return 0
    else
        echo -e "${RED}✗ Connection failed${NC}"
        return 1
    fi
}

# Auto-detect Docker Appwrite
echo "1. Checking for local Docker Appwrite..."
if docker ps | grep -q appwrite; then
    echo -e "${GREEN}✓ Appwrite Docker container found${NC}"
    
    # Check if bound to localhost or all interfaces
    port_binding=$(docker ps | grep appwrite | grep -o "0.0.0.0:80\|127.0.0.1:80" | head -1)
    if [[ "$port_binding" == "0.0.0.0:80" ]]; then
        echo -e "${GREEN}✓ Bound to all interfaces (0.0.0.0)${NC} - accessible from network"
    elif [[ "$port_binding" == "127.0.0.1:80" ]]; then
        echo -e "${YELLOW}⚠ Bound to localhost only (127.0.0.1)${NC} - only accessible locally"
        echo "  To allow network access, update docker-compose.yml:"
        echo "  ports: \"0.0.0.0:80:80\" instead of \"127.0.0.1:80:80\""
    fi
else
    echo -e "${YELLOW}⚠ No Appwrite Docker container found${NC}"
    echo "  Start Appwrite: cd /path/to/appwrite && docker-compose up -d"
fi

echo ""
echo "2. Testing connection endpoints..."
echo ""

# Test localhost
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Testing: localhost"
test_endpoint "http://localhost/v1"
echo ""

# Get and test local IPs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Detecting local IP addresses..."
local_ips=$(hostname -I 2>/dev/null || ip addr show | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | cut -d'/' -f1)

if [ -z "$local_ips" ]; then
    echo -e "${YELLOW}⚠ Could not detect local IPs${NC}"
else
    for ip in $local_ips; do
        echo ""
        echo "Testing: $ip (local network)"
        test_endpoint "http://$ip/v1"
    done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Summary
echo "3. Summary & Recommendations"
echo ""

# Get primary IP
primary_ip=$(hostname -I 2>/dev/null | awk '{print $1}')

if [ -n "$primary_ip" ]; then
    echo -e "${BLUE}For FlutterPOS Backend App configuration:${NC}"
    echo ""
    echo "  📱 Same Machine (Desktop):"
    echo "     Endpoint: http://localhost/v1"
    echo ""
    echo "  📱 Android Device (Same WiFi):"
    echo "     Endpoint: http://$primary_ip/v1"
    echo ""
    echo "  🔑 Project ID:"
    echo "     Get from: http://$primary_ip → Settings"
    echo ""
    echo "  💾 Database ID:"
    echo "     Use: extropos_db"
    echo ""
fi

# Check firewall (Linux only)
if command -v ufw &> /dev/null; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "4. Firewall Status (UFW)"
    echo ""
    if sudo ufw status | grep -q "80.*ALLOW"; then
        echo -e "${GREEN}✓ Port 80 is allowed${NC}"
    else
        echo -e "${YELLOW}⚠ Port 80 not explicitly allowed${NC}"
        echo "  To allow: sudo ufw allow 80/tcp"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next Steps:"
echo ""
echo "1. Open FlutterPOS Backend app"
echo "2. Navigate to: Appwrite Config"
echo "3. Enter endpoint from above"
echo "4. Get Project ID from Appwrite Console"
echo "5. Tap 'Test Connection'"
echo "6. Tap 'Save Config'"
echo ""
echo "Need help? See: docs/DOCKER_APPWRITE_SETUP.md"
echo ""
