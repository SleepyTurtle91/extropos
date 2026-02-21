#!/usr/bin/env bash
set -euo pipefail

# Appwrite Configuration & Multi-Tenant Test Script
# Tests Appwrite connectivity and tenant provisioning capabilities

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Appwrite Configuration Test Suite       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# Configuration (set these via environment or interactively)
APPWRITE_ENDPOINT="${APPWRITE_ENDPOINT:-}"
APPWRITE_PROJECT_ID="${APPWRITE_PROJECT_ID:-}"
APPWRITE_API_KEY="${APPWRITE_API_KEY:-}"

# Interactive prompt if not set
if [ -z "$APPWRITE_ENDPOINT" ]; then
  echo -e "${YELLOW}Enter Appwrite Endpoint (e.g., http://localhost/v1):${NC}"
  read -r APPWRITE_ENDPOINT
fi

if [ -z "$APPWRITE_PROJECT_ID" ]; then
  echo -e "${YELLOW}Enter Appwrite Project ID:${NC}"
  read -r APPWRITE_PROJECT_ID
fi

if [ -z "$APPWRITE_API_KEY" ]; then
  echo -e "${YELLOW}Enter Appwrite API Key:${NC}"
  read -rs APPWRITE_API_KEY
  echo ""
fi

echo ""
echo -e "${BLUE}Testing with:${NC}"
echo "  Endpoint: $APPWRITE_ENDPOINT"
echo "  Project:  $APPWRITE_PROJECT_ID"
echo "  API Key:  ${APPWRITE_API_KEY:0:20}..."
echo ""

# Test 1: Health Check
echo -e "${BLUE}[1/5] Testing Appwrite Health Endpoint...${NC}"
if curl -sf "$APPWRITE_ENDPOINT/health/version" > /dev/null; then
  VERSION=$(curl -s "$APPWRITE_ENDPOINT/health/version" | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
  echo -e "${GREEN}✓ Appwrite is reachable (version: ${VERSION:-unknown})${NC}"
else
  echo -e "${RED}✗ Cannot reach Appwrite at $APPWRITE_ENDPOINT${NC}"
  echo "  Check if Appwrite is running and endpoint is correct"
  exit 1
fi

# Test 2: API Key Authentication
echo -e "${BLUE}[2/5] Testing API Key Authentication...${NC}"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$APPWRITE_ENDPOINT/databases" \
  -H "X-Appwrite-Project: $APPWRITE_PROJECT_ID" \
  -H "X-Appwrite-Key: $APPWRITE_API_KEY" \
  -H "Content-Type: application/json")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✓ API Key is valid and authenticated${NC}"
  DB_COUNT=$(echo "$BODY" | grep -o '"total":[0-9]*' | cut -d':' -f2 || echo "0")
  echo "  Found $DB_COUNT database(s)"
else
  echo -e "${RED}✗ Authentication failed (HTTP $HTTP_CODE)${NC}"
  echo "  Response: $BODY"
  echo "  Check API key and project ID"
  exit 1
fi

# Test 3: Check API Key Permissions
echo -e "${BLUE}[3/5] Checking API Key Permissions...${NC}"

# Try to create a test attribute to verify write permissions
TEST_DB_ID="test_permissions_$(date +%s)"
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$APPWRITE_ENDPOINT/databases" \
  -H "X-Appwrite-Project: $APPWRITE_PROJECT_ID" \
  -H "X-Appwrite-Key: $APPWRITE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"databaseId\":\"$TEST_DB_ID\",\"name\":\"Permission Test DB\"}")

CREATE_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)

if [ "$CREATE_CODE" = "201" ]; then
  echo -e "${GREEN}✓ API Key has databases.write permission${NC}"
  
  # Clean up test database
  DELETE_RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$APPWRITE_ENDPOINT/databases/$TEST_DB_ID" \
    -H "X-Appwrite-Project: $APPWRITE_PROJECT_ID" \
    -H "X-Appwrite-Key: $APPWRITE_API_KEY")
  
  DELETE_CODE=$(echo "$DELETE_RESPONSE" | tail -n1)
  if [ "$DELETE_CODE" = "204" ]; then
    echo -e "${GREEN}✓ API Key has databases.delete permission${NC}"
  fi
elif [ "$CREATE_CODE" = "401" ] || [ "$CREATE_CODE" = "403" ]; then
  echo -e "${YELLOW}⚠ API Key lacks databases.write permission${NC}"
  echo "  This key can only read databases, not create them"
  echo "  Tenant provisioning will fail - update key scopes in Appwrite Console"
else
  echo -e "${YELLOW}⚠ Permission check inconclusive (HTTP $CREATE_CODE)${NC}"
fi

# Test 4: List Existing Databases
echo -e "${BLUE}[4/5] Listing Existing Databases...${NC}"
DATABASES=$(curl -s -X GET "$APPWRITE_ENDPOINT/databases" \
  -H "X-Appwrite-Project: $APPWRITE_PROJECT_ID" \
  -H "X-Appwrite-Key: $APPWRITE_API_KEY" \
  -H "Content-Type: application/json")

echo "$DATABASES" | grep -o '"name":"[^"]*"' | cut -d'"' -f4 | while read -r db_name; do
  echo "  - $db_name"
done || echo "  (No databases found)"

# Test 5: Configuration Summary
echo ""
echo -e "${BLUE}[5/5] Configuration Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✓ Appwrite server is accessible${NC}"
echo -e "${GREEN}✓ API authentication successful${NC}"

if [ "$CREATE_CODE" = "201" ]; then
  echo -e "${GREEN}✓ Full permissions (read + write)${NC}"
  echo ""
  echo -e "${GREEN}Ready for multi-tenant provisioning!${NC}"
else
  echo -e "${YELLOW}⚠ Limited permissions (read-only)${NC}"
  echo ""
  echo -e "${YELLOW}Update API key scopes for tenant provisioning${NC}"
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Open FlutterPOS Backend app"
echo "2. Go to Settings → Appwrite Integration"
echo "3. Enter these credentials:"
echo "   - Endpoint: $APPWRITE_ENDPOINT"
echo "   - Project ID: $APPWRITE_PROJECT_ID"
echo "   - API Key: (paste the key)"
echo "4. Test connection and save"
echo "5. Use Tenant Onboarding to create isolated databases"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "  - docs/APPWRITE_MULTI_TENANT_SETUP.md"
echo "  - docs/APPWRITE_SELF_HOSTING.md"
echo ""
echo -e "${GREEN}Test complete!${NC}"
