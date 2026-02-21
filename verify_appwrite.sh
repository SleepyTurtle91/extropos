#!/bin/bash

# FlutterPOS - Appwrite Setup Verification Script
# Verifies that all databases, collections, and buckets are properly configured

ENDPOINT="https://appwrite.extropos.org/v1"
PROJECT_ID="6940a64500383754a37f"
API_KEY="088ea83f36a48f15cc11adf63392f2da1f98f16aa554fa161baf5b28044bcd94ae3cd5e8c0365b161aadbfecb8e3cfa00e4ef24e46299903586388203272156da954c2b4204971321233701997c5bcda4764d25f774ac54fbfc595524a2900b4e216d35cbea9a1923970a099cc89463880f2b110f8362a7fdd1231f0e628b03f"
DATABASE_ID="pos_db"

echo "🔍 FlutterPOS - Appwrite Setup Verification"
echo "===========================================" 
echo ""

# Check Appwrite server
echo "1️⃣  Checking Appwrite Server..."
if curl -s "$ENDPOINT/health/version" > /dev/null; then
    VERSION=$(curl -s "$ENDPOINT/health/version" | grep -o '"version":"[^"]*' | cut -d'"' -f4)
    echo "   ✅ Appwrite running (v$VERSION)"
else
    echo "   ❌ Appwrite not responding"
    exit 1
fi
echo ""

# Check database
echo "2️⃣  Checking Database..."
DB_RESPONSE=$(curl -s -X GET "$ENDPOINT/databases/$DATABASE_ID" \
    -H "X-Appwrite-Project: $PROJECT_ID" \
    -H "X-Appwrite-Key: $API_KEY")

if echo "$DB_RESPONSE" | grep -q '"name":"POS Database"'; then
    echo "   ✅ Database exists: $DATABASE_ID"
else
    echo "   ❌ Database not found"
fi
echo ""

# Check collections
echo "3️⃣  Checking Collections..."
COLLECTIONS=$(curl -s -X GET "$ENDPOINT/databases/$DATABASE_ID/collections" \
    -H "X-Appwrite-Project: $PROJECT_ID" \
    -H "X-Appwrite-Key: $API_KEY")

COUNT=$(echo "$COLLECTIONS" | grep -o '"name"' | wc -l)
echo "   Found: $COUNT collections"

for coll in categories items orders order_items users tables payment_methods customers transactions printers customer_displays receipt_settings modifier_groups modifier_items; do
    if echo "$COLLECTIONS" | grep -q "\"\$id\":\"$coll\""; then
        echo "   ✅ $coll"
    else
        echo "   ❌ $coll (missing)"
    fi
done
echo ""

# Check buckets
echo "4️⃣  Checking Storage Buckets..."
BUCKETS=$(curl -s -X GET "$ENDPOINT/storage/buckets" \
    -H "X-Appwrite-Project: $PROJECT_ID" \
    -H "X-Appwrite-Key: $API_KEY")

COUNT=$(echo "$BUCKETS" | grep -o '"name"' | wc -l)
echo "   Found: $COUNT buckets"

for bucket in receipt_images product_images logo_images reports; do
    if echo "$BUCKETS" | grep -q "\"\$id\":\"$bucket\""; then
        echo "   ✅ $bucket"
    else
        echo "   ❌ $bucket (missing)"
    fi
done
echo ""

# Check API Key
echo "5️⃣  Checking API Key Configuration..."
if [ -f "lib/config/environment.dart" ]; then
    if grep -q "appwriteApiKey" lib/config/environment.dart; then
        echo "   ✅ API key configured in environment.dart"
    else
        echo "   ❌ API key not in environment.dart"
    fi
else
    echo "   ❌ environment.dart not found"
fi
echo ""

echo "✅ Verification complete!"
echo ""
echo "If any collections or buckets are missing, run:"
echo "   ./setup_appwrite_collections.sh"
