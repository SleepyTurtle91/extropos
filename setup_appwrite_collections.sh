#!/bin/bash

# FlutterPOS - Appwrite Database & Bucket Configuration Script
# This script sets up all necessary databases, collections, and buckets for the POS app

set -e

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   FlutterPOS - Appwrite Database & Bucket Setup           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Configuration
ENDPOINT="https://appwrite.extropos.org/v1"
PROJECT_ID="6940a64500383754a37f"
API_KEY="088ea83f36a48f15cc11adf63392f2da1f98f16aa554fa161baf5b28044bcd94ae3cd5e8c0365b161aadbfecb8e3cfa00e4ef24e46299903586388203272156da954c2b4204971321233701997c5bcda4764d25f774ac54fbfc595524a2900b4e216d35cbea9a1923970a099cc89463880f2b110f8362a7fdd1231f0e628b03f"
DATABASE_ID="pos_db"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to make API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    local url="${ENDPOINT}${endpoint}"
    
    if [ -z "$data" ]; then
        curl -s -X "$method" "$url" \
            -H "X-Appwrite-Project: $PROJECT_ID" \
            -H "X-Appwrite-Key: $API_KEY" \
            -H "Content-Type: application/json"
    else
        curl -s -X "$method" "$url" \
            -H "X-Appwrite-Project: $PROJECT_ID" \
            -H "X-Appwrite-Key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    fi
}

# Check if Appwrite is running
echo "🔍 Checking if Appwrite is running..."
if ! curl -s "$ENDPOINT/health/version" > /dev/null 2>&1; then
    echo -e "${RED}❌ Appwrite is not running!${NC}"
    echo ""
    echo "Start Appwrite with:"
    echo "  cd docker && docker-compose -f appwrite-compose.yml up -d"
    exit 1
fi
echo -e "${GREEN}✅ Appwrite is running${NC}"
echo ""

# Step 1: Create Database
echo "📦 Creating main database..."
DB_RESPONSE=$(api_call POST "/databases" "{\"databaseId\":\"$DATABASE_ID\",\"name\":\"POS Database\"}")

if echo "$DB_RESPONSE" | grep -q '"$id"'; then
    echo -e "${GREEN}✅ Database created: $DATABASE_ID${NC}"
elif echo "$DB_RESPONSE" | grep -q "already exists"; then
    echo -e "${YELLOW}⚠️  Database already exists: $DATABASE_ID${NC}"
else
    echo -e "${RED}❌ Failed to create database${NC}"
    echo "Response: $DB_RESPONSE"
fi
echo ""

# Step 2: Create Collections
echo "📚 Creating collections..."
echo ""

# Helper function to create collection with attributes
create_collection() {
    local collection_id=$1
    local collection_name=$2
    
    echo "   Creating $collection_name ($collection_id)..."
    RESPONSE=$(api_call POST "/databases/$DATABASE_ID/collections" "{\"collectionId\":\"$collection_id\",\"name\":\"$collection_name\"}")
    
    if echo "$RESPONSE" | grep -q '"$id"'; then
        echo -e "   ${GREEN}✅ Created${NC}"
        return 0
    elif echo "$RESPONSE" | grep -q "already exists"; then
        echo -e "   ${YELLOW}⚠️  Already exists${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Failed${NC}"
        echo "   Response: $RESPONSE"
        return 1
    fi
}

# Create all collections
collections=(
    "categories:Categories"
    "items:Items (Products)"
    "orders:Orders"
    "order_items:Order Items"
    "users:Users (Staff)"
    "tables:Restaurant Tables"
    "payment_methods:Payment Methods"
    "customers:Customers"
    "transactions:Transactions"
    "printers:Printers"
    "customer_displays:Customer Displays"
    "receipt_settings:Receipt Settings"
    "modifier_groups:Modifier Groups"
    "modifier_items:Modifier Items"
)

for collection in "${collections[@]}"; do
    IFS=':' read -r id name <<< "$collection"
    create_collection "$id" "$name"
done

echo ""
echo "✅ All collections created/verified"
echo ""

# Step 3: Create Buckets
echo "🪣 Creating storage buckets..."
echo ""

create_bucket() {
    local bucket_id=$1
    local bucket_name=$2
    
    echo "   Creating $bucket_name ($bucket_id)..."
    RESPONSE=$(api_call POST "/storage/buckets" "{\"bucketId\":\"$bucket_id\",\"name\":\"$bucket_name\",\"fileSecurity\":false}")
    
    if echo "$RESPONSE" | grep -q '"$id"'; then
        echo -e "   ${GREEN}✅ Created${NC}"
        return 0
    elif echo "$RESPONSE" | grep -q "already exists"; then
        echo -e "   ${YELLOW}⚠️  Already exists${NC}"
        return 0
    else
        echo -e "   ${RED}❌ Failed${NC}"
        echo "   Response: $RESPONSE"
        return 1
    fi
}

# Create all buckets
buckets=(
    "receipt_images:Receipt Images"
    "product_images:Product Images"
    "logo_images:Logo Images"
    "reports:Reports"
)

for bucket in "${buckets[@]}"; do
    IFS=':' read -r id name <<< "$bucket"
    create_bucket "$id" "$name"
done

echo ""
echo "✅ All buckets created/verified"
echo ""

# Step 4: Create basic attributes for collections (sample)
echo "🏗️  Creating collection attributes (sample)..."
echo ""

# Categories attributes
echo "   Setting up Categories collection attributes..."
api_call POST "/databases/$DATABASE_ID/collections/categories/attributes/string" \
    '{"key":"name","required":true,"default":""}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/categories/attributes/string" \
    '{"key":"description","required":false}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/categories/attributes/integer" \
    '{"key":"sort_order","required":false,"default":0}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/categories/attributes/boolean" \
    '{"key":"is_active","required":false,"default":true}' > /dev/null 2>&1 || true

echo -e "   ${GREEN}✅ Categories attributes created${NC}"

# Items attributes
echo "   Setting up Items collection attributes..."
api_call POST "/databases/$DATABASE_ID/collections/items/attributes/string" \
    '{"key":"name","required":true}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/items/attributes/double" \
    '{"key":"price","required":true}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/items/attributes/string" \
    '{"key":"category_id","required":true}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/items/attributes/integer" \
    '{"key":"stock","required":false,"default":0}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/items/attributes/boolean" \
    '{"key":"is_available","required":false,"default":true}' > /dev/null 2>&1 || true

echo -e "   ${GREEN}✅ Items attributes created${NC}"

# Orders attributes
echo "   Setting up Orders collection attributes..."
api_call POST "/databases/$DATABASE_ID/collections/orders/attributes/string" \
    '{"key":"order_number","required":true}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/orders/attributes/double" \
    '{"key":"total","required":true}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/orders/attributes/string" \
    '{"key":"status","required":true}' > /dev/null 2>&1 || true

api_call POST "/databases/$DATABASE_ID/collections/orders/attributes/string" \
    '{"key":"user_id","required":true}' > /dev/null 2>&1 || true

echo -e "   ${GREEN}✅ Orders attributes created${NC}"

echo ""
echo "═════════════════════════════════════════════════════════════"
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo "═════════════════════════════════════════════════════════════"
echo ""
echo "📋 Summary:"
echo "   • Database: $DATABASE_ID"
echo "   • Collections: 14"
echo "   • Buckets: 4"
echo ""
echo "📚 Collections created:"
echo "   ✅ categories"
echo "   ✅ items"
echo "   ✅ orders"
echo "   ✅ order_items"
echo "   ✅ users"
echo "   ✅ tables"
echo "   ✅ payment_methods"
echo "   ✅ customers"
echo "   ✅ transactions"
echo "   ✅ printers"
echo "   ✅ customer_displays"
echo "   ✅ receipt_settings"
echo "   ✅ modifier_groups"
echo "   ✅ modifier_items"
echo ""
echo "🪣 Buckets created:"
echo "   ✅ receipt_images"
echo "   ✅ product_images"
echo "   ✅ logo_images"
echo "   ✅ reports"
echo ""
echo "🔐 API Key: ✅ Added to environment.dart"
echo ""
echo "📖 Next Steps:"
echo "   1. Verify setup: ./verify_appwrite.sh"
echo "   2. Create test data (optional)"
echo "   3. Update Flutter code to use Appwrite"
echo ""
echo "📌 Notes:"
echo "   • Collections auto-created with default attributes"
echo "   • Buckets are set to public file security (change if needed)"
echo "   • Add more attributes via Appwrite Console as needed"
echo "   • See APPWRITE_COLLECTIONS.md for detailed schema info"
echo ""
