# Phase 2 Day 2: Quick Start Guide

**Status**: Ready to Execute  
**Date**: February 2, 2026  
**Duration**: ~3 hours  

---

## 🎯 Phase 2 Day 2 Overview

Continue Sprint 1 by adding attributes to the Appwrite collections created on Day 1.

**Objective**: Configure products and categories collections with all required fields.

**Expected Outcome**: 
- 17 attributes for products collection
- 13 attributes for categories collection
- 4 indexes created
- Sample data inserted
- All tests passing

---

## 📋 Step-by-Step Commands

### Step 1: Verify Current Collections (5 minutes)

```powershell
# Check Appwrite CLI status
appwrite --version

# List existing collections
appwrite databases list-collections --database pos_db
```

**Expected Output**: 6 collections (backend_users, roles, activity_logs, inventory_items, products, categories)

---

### Step 2: Add Products Attributes (45 minutes)

**Reference Document**: [PRODUCT_CATEGORY_APPWRITE_SETUP.md](PRODUCT_CATEGORY_APPWRITE_SETUP.md)

```powershell
# Run the attribute setup script
.\scripts\setup_product_category_attributes.ps1
```

**Attributes to be created** (17 for products):
- id (String, Required)
- name (String, Required)
- description (String, Optional)
- sku (String, Optional)
- basePrice (Float, Required)
- costPrice (Float, Optional)
- categoryId (String, Required)
- categoryName (String, Optional)
- isActive (Boolean, Required)
- trackInventory (Boolean, Required)
- variantIds (String/JSON Array)
- modifierGroupIds (String/JSON Array)
- imageUrl (String, Optional)
- customFields (String/JSON Object)
- createdAt (Integer, Required)
- updatedAt (Integer, Required)
- syncStatus (String, Optional)

**Command Syntax** (if running manually):
```bash
appwrite databases create-string-attribute \
  --database pos_db \
  --collection products \
  --key name \
  --required \
  --size 255
```

---

### Step 3: Add Categories Attributes (30 minutes)

**Attributes to be created** (13 for categories):
- id (String, Required)
- name (String, Required)
- description (String, Optional)
- parentCategoryId (String, Optional - for hierarchies)
- displayOrder (Integer, Optional)
- isActive (Boolean, Required)
- icon (String, Optional)
- color (String, Optional)
- imageUrl (String, Optional)
- customFields (String/JSON Object)
- createdAt (Integer, Required)
- updatedAt (Integer, Required)
- syncStatus (String, Optional)

---

### Step 4: Create Indexes (15 minutes)

```powershell
# Create indexes for performance

# Products indexes
appwrite databases create-index \
  --database pos_db \
  --collection products \
  --key is_active_idx \
  --type key \
  --attributes isActive

appwrite databases create-index \
  --database pos_db \
  --collection products \
  --key sku_idx \
  --type unique \
  --attributes sku

appwrite databases create-index \
  --database pos_db \
  --collection products \
  --key category_idx \
  --type key \
  --attributes categoryId

appwrite databases create-index \
  --database pos_db \
  --collection products \
  --key sync_status_idx \
  --type key \
  --attributes syncStatus
```

---

### Step 5: Insert Sample Data (20 minutes)

```powershell
# Use Appwrite CLI to insert sample products

# Method 1: Via CLI (one by one)
appwrite databases create-document \
  --database pos_db \
  --collection products \
  --data '{"id":"TEST-1","name":"Product 1","basePrice":99.99,"categoryId":"cat1","isActive":true,"trackInventory":true,"createdAt":'$(date +%s000)',"updatedAt":'$(date +%s000)'}'

# Method 2: Via script (run batch insert)
.\scripts\insert_sample_data.ps1
```

**Sample Data to Insert**:
- 5-10 test products with different categories
- 3-5 test categories with hierarchy

---

### Step 6: Verify Configuration (10 minutes)

```powershell
# Check products collection attributes
appwrite databases get-collection \
  --database pos_db \
  --collection products

# Check categories collection attributes
appwrite databases get-collection \
  --database pos_db \
  --collection categories

# Count documents
appwrite databases list-documents \
  --database pos_db \
  --collection products

appwrite databases list-documents \
  --database pos_db \
  --collection categories
```

**Expected Results**:
- Products collection: 17 attributes + 4 indexes
- Categories collection: 13 attributes
- At least 5 sample products
- At least 3 sample categories

---

### Step 7: Run Integration Tests (10 minutes)

```powershell
# Run tests to verify configuration
flutter test test/integration/appwrite_connectivity_test.dart

# Run service tests
flutter test test/services/

# Expected: 163/163 tests passing
```

---

## 📊 Time Budget

| Task | Duration | Status |
|------|----------|--------|
| Verify collections | 5 min | TBD |
| Add products attributes | 45 min | TBD |
| Add categories attributes | 30 min | TBD |
| Create indexes | 15 min | TBD |
| Insert sample data | 20 min | TBD |
| Verify configuration | 10 min | TBD |
| Run integration tests | 10 min | TBD |
| **TOTAL** | **135 min (2.25 h)** | **TBD** |

---

## ✅ Success Criteria

- ✅ Products collection has all 17 attributes
- ✅ Categories collection has all 13 attributes
- ✅ 4 indexes created for performance
- ✅ At least 5 sample products inserted
- ✅ At least 3 sample categories inserted
- ✅ All integration tests passing (163/163)
- ✅ Console shows correct configuration

---

## 🔧 Troubleshooting

### If attributes creation fails:

```powershell
# Check attribute exists
appwrite databases list-attributes \
  --database pos_db \
  --collection products

# Delete and recreate
appwrite databases delete-attribute \
  --database pos_db \
  --collection products \
  --key attribute_name

# Then recreate with correct parameters
```

### If document insertion fails:

```powershell
# Check collection permissions
appwrite databases get-collection \
  --database pos_db \
  --collection products

# Verify document format
# Use Appwrite console for troubleshooting
```

### If tests fail:

```powershell
# Run with verbose output
flutter test test/services/ -v

# Check Appwrite connectivity
# Verify endpoint: https://appwrite.extropos.org/v1
# Verify project ID: 6940a64500383754a37f
```

---

## 📚 Reference Files

- **[PRODUCT_CATEGORY_APPWRITE_SETUP.md](PRODUCT_CATEGORY_APPWRITE_SETUP.md)** - Detailed attribute specifications
- **[scripts/setup_product_category_attributes.ps1](scripts/setup_product_category_attributes.ps1)** - Attribute creation script
- **[scripts/insert_sample_data.ps1](scripts/insert_sample_data.ps1)** - Sample data insertion script

---

## 🚀 What's Next

### After Day 2 Completes:
1. ✅ Collections fully configured
2. ✅ Sample data ready for testing
3. ✅ Ready to begin Backend UI development (Sprint 2)

### Phase 2 Day 3+ (Sprint 2):
1. Create Products Management Screen
2. Create Categories Management Screen
3. Implement CRUD operations
4. Test with real backend
5. Prepare for POS integration

---

## 💡 Tips for Success

1. **Run scripts in order** - Don't skip steps
2. **Verify each step** - Check console output before moving next
3. **Use console for inspection** - https://appwrite.extropos.org/console
4. **Keep tests running** - Run after each major change
5. **Check documentation** - Reference PRODUCT_CATEGORY_APPWRITE_SETUP.md for details

---

## 🎯 Command Cheat Sheet

```powershell
# Quick reference commands
appwrite --version                                    # Check CLI
appwrite databases list-collections --database pos_db  # List collections
appwrite databases get-collection --database pos_db --collection products  # View schema
appwrite databases list-indexes --database pos_db --collection products   # View indexes
flutter test test/services/ -v                        # Run verbose tests
```

---

*Phase 2 Day 2 Quick Start Guide*  
*Ready to Execute*
