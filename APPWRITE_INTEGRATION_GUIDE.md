# FlutterPOS - Appwrite Integration Guide

**For Developers**: Quick start guide to integrate Appwrite into FlutterPOS

---

## 🚀 Quick Start

### 1. Initialize Appwrite Client

```dart
import 'package:appwrite/appwrite.dart';
import 'package:flutterpos/config/environment.dart';

class AppwriteService {
  static final AppwriteService instance = AppwriteService._internal();
  AppwriteService._internal();

  late Client _client;
  late Databases _databases;
  late Storage _storage;

  void initialize() {
    _client = Client()
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId);

    _databases = Databases(_client);
    _storage = Storage(_client);
  }
}

```

### 2. Database Operations

```dart
// Create a category
Future<Document> createCategory(String name, int sortOrder) async {
  return await _databases.createDocument(
    databaseId: Environment.posDatabase,
    collectionId: Environment.categoriesCollection,
    documentId: ID.unique(),
    data: {
      'name': name,
      'sort_order': sortOrder,
      'is_active': true,
    },
  );
}

// Get all categories
Future<List<Document>> getCategories() async {
  final result = await _databases.listDocuments(
    databaseId: Environment.posDatabase,
    collectionId: Environment.categoriesCollection,
    queries: [
      Query.orderAsc('sort_order'),
      Query.equal('is_active', true),
    ],
  );
  return result.documents;
}

// Update a category
Future<Document> updateCategory(String documentId, Map<String, dynamic> data) async {
  return await _databases.updateDocument(
    databaseId: Environment.posDatabase,
    collectionId: Environment.categoriesCollection,
    documentId: documentId,
    data: data,
  );
}

// Delete a category
Future<void> deleteCategory(String documentId) async {
  await _databases.deleteDocument(
    databaseId: Environment.posDatabase,
    collectionId: Environment.categoriesCollection,
    documentId: documentId,
  );
}

```

### 3. File Storage Operations

```dart
// Upload product image
Future<File> uploadProductImage(String filePath, String fileName) async {
  return await _storage.createFile(
    bucketId: 'product_images',
    fileId: ID.unique(),
    file: InputFile.fromPath(path: filePath, filename: fileName),
  );
}

// Get file download URL
String getProductImageUrl(String fileId) {
  return _storage.getFileDownload(
    bucketId: 'product_images',
    fileId: fileId,
  ).toString();
}

// Get image preview (thumbnail)
String getProductImagePreview(String fileId, {int width = 200}) {
  return _storage.getFilePreview(
    bucketId: 'product_images',
    fileId: fileId,
    width: width,
  ).toString();
}

// Delete file
Future<void> deleteProductImage(String fileId) async {
  await _storage.deleteFile(
    bucketId: 'product_images',
    fileId: fileId,
  );
}

```

### 4. Real-time Subscriptions

```dart
// Listen for new orders
RealtimeSubscription? _orderSubscription;

void subscribeToOrders() {
  _orderSubscription = _client.subscribe([
    'databases.${Environment.posDatabase}.collections.${Environment.ordersCollection}.documents'
  ]);

  _orderSubscription?.stream.listen((event) {
    if (event.event == 'database.documents.create') {
      print('New order created: ${event.payload}');
      // Handle new order notification
    }
  });
}

void unsubscribeFromOrders() {
  _orderSubscription?.close();
}

```

---

## 📋 Collection Reference

|Collection|ID|Common Operations|
|----------|--|------------------|
|Categories|`categories`|CRUD, sort by `sort_order`|
|Items|`items`|CRUD, filter by `is_available`|
|Orders|`orders`|Create, read, update status|
|Order Items|`order_items`|Create with order reference|
|Users|`users`|CRUD, authentication|
|Tables|`tables`|CRUD, status management|
|Payment Methods|`payment_methods`|CRUD|
|Customers|`customers`|CRUD, search by phone/email|
|Transactions|`transactions`|Create, read history|
|Printers|`printers`|CRUD, status updates|
|Customer Displays|`customer_displays`|CRUD, configuration|
|Receipt Settings|`receipt_settings`|CRUD, per-user settings|
|Modifier Groups|`modifier_groups`|CRUD, nested with items|
|Modifier Items|`modifier_items`|CRUD, belongs to groups|

---

## 🪣 Bucket Reference

|Bucket|ID|File Types|Use Case|
|------|--|-----------|---------|
|Product Images|`product_images`|JPG, PNG, WebP|Product photos|
|Logo Images|`logo_images`|JPG, PNG, SVG|Business branding|
|Receipt Images|`receipt_images`|JPG, PNG, PDF|Generated receipts|
|Reports|`reports`|PDF, CSV, XLSX|Business reports|

---

## 🔍 Query Examples

```dart
// Filter active items with stock > 0
final items = await _databases.listDocuments(
  databaseId: Environment.posDatabase,
  collectionId: Environment.itemsCollection,
  queries: [
    Query.equal('is_available', true),
    Query.greaterThan('stock', 0),
  ],
);

// Search customers by name
final customers = await _databases.listDocuments(
  databaseId: Environment.posDatabase,
  collectionId: Environment.customersCollection,
  queries: [
    Query.search('name', searchTerm),
  ],
);

// Get orders for specific date range
final orders = await _databases.listDocuments(
  databaseId: Environment.posDatabase,
  collectionId: Environment.ordersCollection,
  queries: [
    Query.greaterThanEqual('\$createdAt', startDate),
    Query.lessThanEqual('\$createdAt', endDate),
  ],
);

```

---

## ⚠️ Error Handling

```dart
try {
  final result = await _databases.listDocuments(...);
  return result.documents;
} on AppwriteException catch (e) {
  print('Appwrite error: ${e.message}');
  // Handle specific error codes
  switch (e.code) {
    case 404:
      throw Exception('Resource not found');
    case 401:
      throw Exception('Unauthorized access');
    default:
      throw Exception('Database error: ${e.message}');
  }
} catch (e) {
  print('Network error: $e');
  throw Exception('Connection failed');
}

```

---

## 🔄 Migration from SQLite

### Step 1: Export Existing Data

```dart
// In your current SQLite service
Future<List<Map<String, dynamic>>> exportCategories() async {
  final db = await database;
  return await db.query('categories');
}

```

### Step 2: Transform and Import

```dart
Future<void> migrateCategories() async {
  final sqliteData = await sqliteService.exportCategories();
  
  for (final category in sqliteData) {
    await _databases.createDocument(
      databaseId: Environment.posDatabase,
      collectionId: Environment.categoriesCollection,
      documentId: ID.unique(),
      data: {
        'name': category['name'],
        'sort_order': category['sort_order'] ?? 0,
        'is_active': category['is_active'] ?? true,
      },
    );
  }
}

```

### Step 3: Update UI Code

```dart
// Before (SQLite)
final categories = await sqliteService.getCategories();

// After (Appwrite)
final categories = await appwriteService.getCategories();

```

---

## 🧪 Testing Integration

```dart
// Unit test example
void main() {
  test('should create and retrieve category', () async {
    // Initialize service
    final service = AppwriteService.instance;
    service.initialize();
    
    // Create test category
    final category = await service.createCategory('Test Category', 1);
    expect(category.data['name'], 'Test Category');
    
    // Retrieve categories
    final categories = await service.getCategories();
    expect(categories.length, greaterThan(0));
  });
}

```

---

## 📊 Performance Tips

1. **Use Indexes**: Create indexes on frequently queried fields
2. **Pagination**: Always use limits for large datasets
3. **Caching**: Cache frequently accessed data locally
4. **Batch Operations**: Use batch writes for multiple operations
5. **Real-time**: Use subscriptions sparingly to avoid performance issues

---

## 🔒 Security Best Practices

1. **API Keys**: Use scoped keys with minimal permissions
2. **File Security**: Enable file security for sensitive documents
3. **Document Security**: Enable document-level permissions
4. **Authentication**: Always authenticate users before operations
5. **Input Validation**: Validate all user inputs before database operations

---

## 📞 Need Help?

- **Documentation**: `APPWRITE_DATABASE_SETUP_COMPLETE.md`

- **API Reference**: <https://appwrite.io/docs>

- **Console**: <http://localhost:8080>

- **Test Script**: `./verify_appwrite.sh`

---

**Happy Coding!** 🚀
