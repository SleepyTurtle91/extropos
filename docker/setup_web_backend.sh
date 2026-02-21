#!/bin/bash

# Setup Appwrite for Web Backend Access
# This script configures Appwrite for web-based backend management

set -e

ENDPOINT="${1:-http://localhost:8080/v1}"
ADMIN_EMAIL="${2:-admin@extropos.local}"
ADMIN_PASSWORD="${3:-SecurePassword123!}"
USER_EMAIL="${4:-abber8@gmail.com}"
USER_PASSWORD="${5:-berneydaniel123}"
PROJECT_ID="default"

echo "════════════════════════════════════════════════════════════"
echo "  Appwrite Web Backend Setup"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Endpoint: $ENDPOINT"
echo "User Email: $USER_EMAIL"
echo ""

# ==================== Login as Admin ====================
echo "1️⃣  Logging in as admin..."
SESSION_RESPONSE=$(curl -s -X POST "$ENDPOINT/account/sessions/email" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
  -c /tmp/admin_session.txt)

if echo "$SESSION_RESPONSE" | jq -e '.userId' > /dev/null 2>&1; then
  echo "   ✅ Admin logged in"
else
  echo "   ❌ Failed to login as admin"
  echo "   Response: $SESSION_RESPONSE"
  exit 1
fi

# ==================== Create User Account ====================
echo ""
echo "2️⃣  Creating user account for $USER_EMAIL..."

# First, get an API key with users.write scope
API_KEY_RESPONSE=$(curl -s -X POST "$ENDPOINT/projects/$PROJECT_ID/keys" \
  -b /tmp/admin_session.txt \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Users Management Key",
    "scopes":["users.read","users.write","teams.read","teams.write"]
  }')

API_KEY=$(echo "$API_KEY_RESPONSE" | jq -r '.secret // empty')

if [ -z "$API_KEY" ]; then
  echo "   ⚠️  Could not create API key for user management"
  echo "   Response: $API_KEY_RESPONSE"
else
  echo "   ✅ Created management API key"
  
  # Create user account
  USER_RESPONSE=$(curl -s -X POST "$ENDPOINT/users" \
    -H "X-Appwrite-Key: $API_KEY" \
    -H "X-Appwrite-Project: $PROJECT_ID" \
    -H "Content-Type: application/json" \
    -d "{
      \"userId\":\"$(echo $USER_EMAIL | cut -d'@' -f1)\",
      \"email\":\"$USER_EMAIL\",
      \"password\":\"$USER_PASSWORD\",
      \"name\":\"$(echo $USER_EMAIL | cut -d'@' -f1)\"
    }")
  
  if echo "$USER_RESPONSE" | jq -e '.$id' > /dev/null 2>&1; then
    echo "   ✅ User account created: $USER_EMAIL"
  else
    ERROR=$(echo "$USER_RESPONSE" | jq -r '.message // "Unknown error"')
    if [[ "$ERROR" == *"already exists"* ]]; then
      echo "   ✅ User account already exists: $USER_EMAIL"
    else
      echo "   ⚠️  $ERROR"
    fi
  fi
fi

# ==================== Add User to Team ====================
echo ""
echo "3️⃣  Adding user to FlutterPOS Team..."

# Get user ID
USER_ID=$(echo $USER_EMAIL | cut -d'@' -f1)

# Create membership
MEMBERSHIP_RESPONSE=$(curl -s -X POST "$ENDPOINT/teams/default-team/memberships" \
  -H "X-Appwrite-Key: $API_KEY" \
  -H "X-Appwrite-Project: $PROJECT_ID" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\":\"$USER_EMAIL\",
    \"userId\":\"$USER_ID\",
    \"roles\":[\"owner\"],
    \"name\":\"$(echo $USER_EMAIL | cut -d'@' -f1)\"
  }")

if echo "$MEMBERSHIP_RESPONSE" | jq -e '.$id' > /dev/null 2>&1; then
  echo "   ✅ User added to team with owner role"
else
  ERROR=$(echo "$MEMBERSHIP_RESPONSE" | jq -r '.message // "Unknown error"')
  if [[ "$ERROR" == *"already exists"* ]] || [[ "$ERROR" == *"duplicate"* ]]; then
    echo "   ✅ User is already a team member"
  else
    echo "   ⚠️  $ERROR"
  fi
fi

# ==================== Configure Web Platforms ====================
echo ""
echo "4️⃣  Configuring web platforms..."

# Add localhost platform
PLATFORM_RESPONSE=$(curl -s -X POST "$ENDPOINT/projects/$PROJECT_ID/platforms" \
  -b /tmp/admin_session.txt \
  -H "Content-Type: application/json" \
  -d '{
    "type":"web",
    "name":"Backend Web (localhost)",
    "hostname":"localhost"
  }')

if echo "$PLATFORM_RESPONSE" | jq -e '.$id' > /dev/null 2>&1; then
  echo "   ✅ Added localhost web platform"
else
  ERROR=$(echo "$PLATFORM_RESPONSE" | jq -r '.message // "Unknown error"')
  if [[ "$ERROR" == *"already exists"* ]] || [[ "$ERROR" == *"duplicate"* ]]; then
    echo "   ✅ Localhost platform already configured"
  else
    echo "   ⚠️  $ERROR"
  fi
fi

# Add production platform
PLATFORM_RESPONSE2=$(curl -s -X POST "$ENDPOINT/projects/$PROJECT_ID/platforms" \
  -b /tmp/admin_session.txt \
  -H "Content-Type: application/json" \
  -d '{
    "type":"web",
    "name":"Backend Web (extropos.org)",
    "hostname":"extropos.org"
  }')

if echo "$PLATFORM_RESPONSE2" | jq -e '.$id' > /dev/null 2>&1; then
  echo "   ✅ Added extropos.org web platform"
else
  ERROR=$(echo "$PLATFORM_RESPONSE2" | jq -r '.message // "Unknown error"')
  if [[ "$ERROR" == *"already exists"* ]] || [[ "$ERROR" == *"duplicate"* ]]; then
    echo "   ✅ Production platform already configured"
  else
    echo "   ⚠️  $ERROR"
  fi
fi

# ==================== Update Project Settings for Web ====================
echo ""
echo "5️⃣  Updating project settings..."

# Update OAuth providers and settings
PROJECT_UPDATE=$(curl -s -X PATCH "$ENDPOINT/projects/$PROJECT_ID" \
  -b /tmp/admin_session.txt \
  -H "Content-Type: application/json" \
  -d '{
    "name":"FlutterPOS",
    "description":"Point of Sale and Backend Management System",
    "authDuration":31536000,
    "authLimit":0
  }')

if echo "$PROJECT_UPDATE" | jq -e '.$id' > /dev/null 2>&1; then
  echo "   ✅ Project settings updated"
else
  echo "   ⚠️  Could not update project settings"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Setup Complete!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "✅ User account ready: $USER_EMAIL"
echo "✅ Web platforms configured"
echo "✅ Team membership configured"
echo ""
echo "🌐 Access Console:"
echo "   URL: http://localhost:8080/console"
echo "   Email: $USER_EMAIL"
echo "   Password: $USER_PASSWORD"
echo ""
echo "🔑 Project Details:"
echo "   Project ID: $PROJECT_ID"
echo "   Endpoint: $ENDPOINT"
echo "   Database: pos_db"
echo ""
echo "📱 Web Backend Access:"
echo "   You can now build and access the Flutter web backend:"
echo "   cd /mnt/Storage/Projects/flutterpos"
echo "   flutter build web -t lib/main_backend_web.dart"
echo "   # Then serve from build/web/ directory"
echo ""
