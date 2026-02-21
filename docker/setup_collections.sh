#!/bin/bash

# Initialize Appwrite database and collections for FlutterPOS
# Creates pos_db database and all required collections
# Usage: ./setup_collections.sh [endpoint] [api-key]

set -e

ENDPOINT="${1:-http://localhost:8080/v1}"
API_KEY="${2:-}"
PROJECT_ID="${3:-default}"
DB_ID="pos_db"

# If no API key provided, show error
if [ -z "$API_KEY" ]; then
  echo "❌ Error: API_KEY is required"
  echo "Usage: ./setup_collections.sh [endpoint] [api-key] [project-id]"
  exit 1
fi

echo "════════════════════════════════════════════════════════════"
echo "  FlutterPOS Appwrite Collections Setup"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "Creating database and collections at: $ENDPOINT"
echo ""

# ==================== Create Database ====================
echo "1️⃣  Creating database '$DB_ID'..."
DB_RESPONSE=$(curl -s -X POST "$ENDPOINT/databases" \
  -H "X-Appwrite-Key: $API_KEY" \
  -H "X-Appwrite-Project: $PROJECT_ID" \
  -H "Content-Type: application/json" \
  -d "{\"databaseId\": \"$DB_ID\", \"name\": \"POS Database\"}")

if echo "$DB_RESPONSE" | jq -e '.code' > /dev/null 2>&1; then
  echo "   ✅ Database created or already exists"
else
  echo "   ⚠️  Database response: $(echo $DB_RESPONSE | jq -r '.message // .status' 2>/dev/null || echo $DB_RESPONSE)"
fi
echo ""

# Helper function to create a collection
create_collection() {
  local COLL_NAME=$1
  local COLL_ID=$2
  
  echo "   Creating collection: $COLL_NAME..."
  COLL_RESPONSE=$(curl -s -X POST "$ENDPOINT/databases/$DB_ID/collections" \
    -H "X-Appwrite-Key: $API_KEY" \
    -H "X-Appwrite-Project: $PROJECT_ID" \
    -H "Content-Type: application/json" \
    -d "{\"collectionId\": \"$COLL_ID\", \"name\": \"$COLL_NAME\"}")
  
  if echo "$COLL_RESPONSE" | jq -e '.\$id' > /dev/null 2>&1; then
    echo "   ✅ $COLL_NAME"
  else
    ERROR=$(echo "$COLL_RESPONSE" | jq -r '.message // .status' 2>/dev/null)
    if [[ "$ERROR" == *"duplicate"* ]] || [[ "$ERROR" == *"exists"* ]]; then
      echo "   ✅ $COLL_NAME (already exists)"
    else
      echo "   ⚠️  $COLL_NAME: $ERROR"
    fi
  fi
}

# ==================== Create Collections ====================
echo "2️⃣  Creating collections..."

create_collection "Categories" "categories"
create_collection "Items/Products" "items"
create_collection "Orders" "orders"
create_collection "Order Items" "order_items"
create_collection "Users" "users"
create_collection "Tables" "tables"
create_collection "Payment Methods" "payment_methods"
create_collection "Customers" "customers"
create_collection "Transactions" "transactions"
create_collection "Printers" "printers"
create_collection "Customer Displays" "customer_displays"
create_collection "Receipt Settings" "receipt_settings"
create_collection "Modifier Groups" "modifier_groups"
create_collection "Modifier Items" "modifier_items"
create_collection "Business Info" "business_info"
create_collection "Licenses" "licenses"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Setup Complete"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "✅ Database 'pos_db' and collections are ready!"
echo ""
echo "Next steps:"
echo "  1. Create an API key in Appwrite console for your app"
echo "  2. Build Backend flavor:"
echo "     flutter run lib/main_backend.dart \\"
echo "       --dart-define=APPWRITE_ENDPOINT=$ENDPOINT \\"
echo "       --dart-define=APPWRITE_API_KEY=<your-key>"
echo ""
