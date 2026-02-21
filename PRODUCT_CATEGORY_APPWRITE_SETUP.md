# Appwrite Product & Category Collections Setup

## Quick Summary

Created 2 new backend services for Product and Category management.

**Status**: ✅ 53/53 tests passing (100%)
**Test Duration**: 1.8 seconds
**New Collections Needed**: `products`, `categories`

---

## 1. Products Collection

### Collection Configuration

- **Collection ID**: `products`
- **Name**: Products
- **Permissions**: Document-level security

### Attributes

| Attribute | Type | Size | Required | Default | Array | Description |
|-----------|------|------|----------|---------|-------|-------------|
| `name` | string | 255 | ✅ Yes | - | No | Product name |
| `description` | string | 2000 | No | `""` | No | Product description |
| `sku` | string | 100 | No | - | No | Stock keeping unit |
| `basePrice` | double | - | ✅ Yes | - | No | Base selling price |
| `costPrice` | double | - | No | - | No | Cost per unit |
| `categoryId` | string | 255 | ✅ Yes | - | No | Category reference |
| `categoryName` | string | 255 | No | - | No | Cached category name |
| `isActive` | boolean | - | No | `true` | No | Active status |
| `trackInventory` | boolean | - | No | `true` | No | Whether to track inventory |
| `variantIds` | string | 50 | No | `[]` | Yes | Variant references |
| `modifierGroupIds` | string | 50 | No | `[]` | Yes | Modifier group references |
| `imageUrl` | string | 1000 | No | - | No | Product image URL |
| `customFields` | string | 5000 | No | `{}` | No | JSON for flexible data |
| `createdAt` | integer | - | ✅ Yes | - | No | Creation timestamp (ms) |
| `updatedAt` | integer | - | ✅ Yes | - | No | Update timestamp (ms) |
| `createdBy` | string | 255 | No | - | No | Creator user ID |
| `updatedBy` | string | 255 | No | - | No | Last updater user ID |

### Indexes

| Key | Type | Attributes | Orders |
|-----|------|------------|--------|
| `categoryId_idx` | key | `categoryId` | ASC |
| `isActive_idx` | key | `isActive` | ASC |
| `sku_idx` | unique | `sku` | ASC |
| `name_search` | fulltext | `name` | - |

### Appwrite CLI Commands

```bash
# Create collection
appwrite databases createCollection \
  --databaseId pos_db \
  --collectionId products \
  --name "Products" \
  --permissions "create('users')" "read('users')" "update('users')" "delete('users')"

# Create string attributes
appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key name \
  --size 255 \
  --required true

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key description \
  --size 2000 \
  --required false \
  --default ""

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key sku \
  --size 100 \
  --required false

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key categoryId \
  --size 255 \
  --required true

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key categoryName \
  --size 255 \
  --required false

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key imageUrl \
  --size 1000 \
  --required false

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key customFields \
  --size 5000 \
  --required false \
  --default "{}"

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key createdBy \
  --size 255 \
  --required false

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key updatedBy \
  --size 255 \
  --required false

# Create double attributes
appwrite databases createFloatAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key basePrice \
  --required true

appwrite databases createFloatAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key costPrice \
  --required false

# Create boolean attributes
appwrite databases createBooleanAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key isActive \
  --required false \
  --default true

appwrite databases createBooleanAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key trackInventory \
  --required false \
  --default true

# Create integer attributes
appwrite databases createIntegerAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key createdAt \
  --required true

appwrite databases createIntegerAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key updatedAt \
  --required true

# Create array attributes
appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key variantIds \
  --size 50 \
  --required false \
  --array true \
  --default []

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId products \
  --key modifierGroupIds \
  --size 50 \
  --required false \
  --array true \
  --default []

# Create indexes
appwrite databases createIndex \
  --databaseId pos_db \
  --collectionId products \
  --key categoryId_idx \
  --type key \
  --attributes categoryId \
  --orders ASC

appwrite databases createIndex \
  --databaseId pos_db \
  --collectionId products \
  --key isActive_idx \
  --type key \
  --attributes isActive \
  --orders ASC

appwrite databases createIndex \
  --databaseId pos_db \
  --collectionId products \
  --key sku_idx \
  --type unique \
  --attributes sku \
  --orders ASC

appwrite databases createIndex \
  --databaseId pos_db \
  --collectionId products \
  --key name_search \
  --type fulltext \
  --attributes name
```

---

## 2. Categories Collection

### Collection Configuration

- **Collection ID**: `categories`
- **Name**: Categories
- **Permissions**: Document-level security

### Attributes

| Attribute | Type | Size | Required | Default | Array | Description |
|-----------|------|------|----------|---------|-------|-------------|
| `name` | string | 255 | ✅ Yes | - | No | Category name |
| `description` | string | 1000 | No | `""` | No | Category description |
| `parentCategoryId` | string | 255 | No | - | No | Parent category reference (null = root) |
| `sortOrder` | integer | - | No | `0` | No | Display order |
| `isActive` | boolean | - | No | `true` | No | Active status |
| `iconName` | string | 50 | No | - | No | Icon reference |
| `colorHex` | string | 7 | No | - | No | Color code (e.g., #FF5733) |
| `defaultTaxRate` | double | - | No | - | No | Default tax rate (0.10 = 10%) |
| `customFields` | string | 2000 | No | `{}` | No | JSON for flexible data |
| `createdAt` | integer | - | ✅ Yes | - | No | Creation timestamp (ms) |
| `updatedAt` | integer | - | ✅ Yes | - | No | Update timestamp (ms) |
| `createdBy` | string | 255 | No | - | No | Creator user ID |
| `updatedBy` | string | 255 | No | - | No | Last updater user ID |

### Indexes

| Key | Type | Attributes | Orders |
|-----|------|------------|--------|
| `sortOrder_idx` | key | `sortOrder` | ASC |
| `isActive_idx` | key | `isActive` | ASC |
| `parentCategoryId_idx` | key | `parentCategoryId` | ASC |
| `name_idx` | unique | `name` | ASC |

### Appwrite CLI Commands

```bash
# Create collection
appwrite databases createCollection \
  --databaseId pos_db \
  --collectionId categories \
  --name "Categories" \
  --permissions "create('users')" "read('users')" "update('users')" "delete('users')"

# Create string attributes
appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key name \
  --size 255 \
  --required true

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key description \
  --size 1000 \
  --required false \
  --default ""

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key parentCategoryId \
  --size 255 \
  --required false

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key iconName \
  --size 50 \
  --required false

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key colorHex \
  --size 7 \
  --required false

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key customFields \
  --size 2000 \
  --required false \
  --default "{}"

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key createdBy \
  --size 255 \
  --required false

appwrite databases createStringAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key updatedBy \
  --size 255 \
  --required false

# Create integer attributes
appwrite databases createIntegerAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key sortOrder \
  --required false \
  --default 0

appwrite databases createIntegerAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key createdAt \
  --required true

appwrite databases createIntegerAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key updatedAt \
  --required true

# Create double attribute
appwrite databases createFloatAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key defaultTaxRate \
  --required false

# Create boolean attribute
appwrite databases createBooleanAttribute \
  --databaseId pos_db \
  --collectionId categories \
  --key isActive \
  --required false \
  --default true

# Create indexes
appwrite databases createIndex \
  --databaseId pos_db \
  --collectionId categories \
  --key sortOrder_idx \
  --type key \
  --attributes sortOrder \
  --orders ASC

appwrite databases createIndex \
  --databaseId pos_db \
  --collectionId categories \
  --key isActive_idx \
  --type key \
  --attributes isActive \
  --orders ASC

appwrite databases createIndex \
  --databaseId pos_db \
  --collectionId categories \
  --key parentCategoryId_idx \
  --type key \
  --attributes parentCategoryId \
  --orders ASC

appwrite databases createIndex \
  --databaseId pos_db \
  --collectionId categories \
  --key name_idx \
  --type unique \
  --attributes name \
  --orders ASC
```

---

## 3. Integration with Existing Inventory

### Relationship

```
Category (1) ──< (N) Product (1) ──< (N) InventoryItem
```

### Linking Strategy

**Option A: Denormalized (Recommended)**
- `InventoryItem.productId` references `Product.id`
- `InventoryItem.productName` cached from `Product.name`
- Fast queries, no joins needed

**Option B: Normalized**
- `InventoryItem.productId` references `Product.id`
- Query product details when needed
- More consistent but slower

### Migration Path

1. Add `productId` to existing `InventoryItem` documents
2. Create Product records for existing inventory items
3. Update inventory movement tracking to reference products
4. Add category-based inventory reports

---

## 4. Usage Examples

### Create Category

```dart
final category = BackendCategoryModel(
  name: 'Beverages',
  description: 'Hot and cold beverages',
  sortOrder: 1,
  iconName: 'local_cafe',
  colorHex: '#FF5733',
  defaultTaxRate: 0.06,
  createdAt: DateTime.now().millisecondsSinceEpoch,
  updatedAt: DateTime.now().millisecondsSinceEpoch,
);

final created = await categoryService.createCategory(
  category,
  currentUserId: 'user_123',
);
```

### Create Product

```dart
final product = BackendProductModel(
  name: 'Cappuccino',
  description: 'Italian coffee with steamed milk',
  sku: 'BEV-CAP-001',
  basePrice: 5.50,
  costPrice: 2.00,
  categoryId: created.id!,
  categoryName: created.name,
  isActive: true,
  trackInventory: true,
  variantIds: ['size-small', 'size-large'],
  modifierGroupIds: ['milk-options'],
  createdAt: DateTime.now().millisecondsSinceEpoch,
  updatedAt: DateTime.now().millisecondsSinceEpoch,
);

final createdProduct = await productService.createProduct(
  product,
  currentUserId: 'user_123',
);
```

### Query Products by Category

```dart
final beverageProducts = await productService.fetchProductsByCategory(
  created.id!,
);

print('Found ${beverageProducts.length} beverage products');
```

### Search Products

```dart
final results = await productService.searchProducts('coffee');
print('Found ${results.length} products matching "coffee"');
```

---

## 5. Testing Commands

### Run New Service Tests Only

```powershell
flutter test test/services/backend_product_service_appwrite_test.dart test/services/backend_category_service_appwrite_test.dart
```

### Run All Phase 1 Tests (including new services)

```powershell
flutter test test/services/ test/models/
```

### Test Results

```
✅ BackendProductServiceAppwrite: 25/25 tests passing
✅ BackendCategoryServiceAppwrite: 28/28 tests passing
⏱️  Total Duration: 1.8 seconds
```

---

## 6. Next Steps

### Phase 2 Integration

1. **Create Collections**: Run Appwrite CLI commands above
2. **Test Real Backend**: Run connectivity tests with `--dart-define=REAL_APPWRITE=true`
3. **Migrate POS Data**: Create migration script to convert POS products to backend products
4. **Update Backend App**: Add Product/Category management UI
5. **Sync Logic**: Implement periodic sync between backend and POS instances

### Future Enhancements

- **Product Variants**: Create `ProductVariant` model and service
- **Modifier Groups**: Create `ModifierGroup` model and service
- **Price History**: Track price changes over time
- **Category Hierarchies**: Support multi-level category trees
- **Bulk Operations**: Batch import/export for products
- **Image Management**: Integrate with Appwrite Storage
- **Barcode Support**: Add barcode scanning and generation

---

## 7. Phase 1 Summary

### Completed Services (6/6)

| Service | Tests | Status | Description |
|---------|-------|--------|-------------|
| AccessControlService | 27/27 | ✅ | RBAC permission checking |
| BackendUserService | 11/11 | ✅ | User CRUD and management |
| AuditService | 18/18 | ✅ | Activity logging |
| InventoryService | 18/18 | ✅ | Stock tracking |
| **ProductService** | **25/25** | ✅ **NEW** | Product management |
| **CategoryService** | **28/28** | ✅ **NEW** | Category management |

### Total Test Coverage

- **Phase 1 Tests**: 127/127 passing (100%)
- **Test Duration**: ~4 seconds
- **Code Coverage**: Excellent (all services fully tested)

---

*Last updated: February 1, 2026*
*Version: Phase 1 + Product/Category Services*
