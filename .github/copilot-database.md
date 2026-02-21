# FlutterPOS Database Guide



## SQLite to Isar Migration Guide



### Overview


FlutterPOS currently uses **SQLite** via the `sqflite` package for local data persistence.

**Key Components**:


- **DatabaseHelper** (`lib/services/database_helper.dart`): Singleton service managing SQLite operations

- **Tables**: products, transactions, users, categories, printers, etc.

- **Platform Support**: Android, Windows, Linux, Web (via sqlflite_ffi)


### Database Schema

```sql
-- Products table

CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  category_id TEXT,
  sku TEXT,
  icon TEXT,
  image_url TEXT,
  variants_json TEXT,
  modifier_group_ids_json TEXT,
  quantity REAL DEFAULT 0.0,
  cost_per_unit REAL,
  is_active INTEGER DEFAULT 1,
  is_synced INTEGER DEFAULT 0,
  last_synced_at INTEGER,
  created_at INTEGER,
  updated_at INTEGER
);

-- Transactions table

CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_number TEXT UNIQUE,
  transaction_date INTEGER,
  user_id TEXT,
  subtotal REAL,
  tax_amount REAL,
  service_charge_amount REAL,
  total_amount REAL,
  discount_amount REAL,
  payment_method TEXT,
  business_mode TEXT,
  table_id TEXT,
  order_number INTEGER,
  customer_id TEXT,
  items_json TEXT,
  payments_json TEXT,
  refund_status TEXT DEFAULT 'none',
  refund_amount REAL DEFAULT 0.0,
  is_synced INTEGER DEFAULT 0,
  last_synced_at INTEGER,
  created_at INTEGER,
  updated_at INTEGER
);

```


### Current Usage Patterns

```dart
// Initialize database
final db = await DatabaseHelper.instance.database;

// Query operations
final products = await db.query('products',
  where: 'is_active = ?',
  whereArgs: [1],
  orderBy: 'name ASC'
);

// Insert operations
await db.insert('products', product.toMap());

// Update operations
await db.update('products', product.toMap(),
  where: 'id = ?',
  whereArgs: [product.id]
);

// Delete operations
await db.delete('products',
  where: 'id = ?',
  whereArgs: [productId]
);

```


## Planned Database System (Isar)



### Overview

FlutterPOS is **planned** to migrate to **Isar** (high-performance local database) for offline-first data persistence.

**Key Benefits** (when integrated):


- ✅ Instant offline access to all data

- ✅ Automatic conflict resolution on sync

- ✅ Type-safe Dart models with code generation

- ✅ Fast queries and transactions

- ✅ Encrypted local storage support

- ✅ No external dependencies for core functionality


### Isar Models


Three primary models handle all data:


#### 1. IsarProduct (`lib/models/isar/product_model.dart`)

```dart
@collection
class IsarProduct {
  Id id = Isar.autoIncrement;           // Local ID
  late String backendId;                // Appwrite document ID for sync matching
  late String name;
  late double price;
  late String categoryId;
  String? categoryName;
  String? sku;
  String? icon;
  String? imageUrl;
  String? variantsJson;                 // JSON array of variants
  String? modifierGroupIdsJson;         // JSON array of modifier group IDs
  double quantity = 0.0;                // Stock level
  double? costPerUnit;
  bool isActive = true;
  bool isSynced = false;                // false = needs backend push, true = in sync
  int? lastSyncedAt;                    // Milliseconds since epoch
  late int createdAt;
  late int updatedAt;

  // Methods:
  factory IsarProduct.fromJson(Map<String, dynamic> json)  // Backend → Isar
  Map<String, dynamic> toJson()                             // Isar → Backend
}

```


#### 2. IsarTransaction (`lib/models/isar/transaction_model.dart`)

```dart
@collection
class IsarTransaction {
  Id id = Isar.autoIncrement;
  late String backendId;
  late String transactionNumber;        // e.g., "ORD-20251230-001"
  late int transactionDate;
  late String userId;
  late double subtotal;
  double taxAmount = 0.0;
  double serviceChargeAmount = 0.0;
  late double totalAmount;
  double discountAmount = 0.0;
  late String paymentMethod;
  late String businessMode;             // "retail", "cafe", "restaurant"
  String? tableId;                      // Restaurant mode only
  int? orderNumber;                     // Cafe mode only
  String? customerId;
  late String itemsJson;                // JSON array of line items
  String? paymentsJson;                 // JSON array of payment splits
  String refundStatus = 'none';         // "none", "partial", "full"
  double refundAmount = 0.0;
  bool isSynced = false;
  int? lastSyncedAt;
  late int createdAt;
  late int updatedAt;

  // Methods:
  factory IsarTransaction.fromJson(Map<String, dynamic> json)
  Map<String, dynamic> toJson()
}

```


#### 3. IsarInventory (`lib/models/isar/inventory_model.dart`)

```dart
@collection
class IsarInventory {
  Id id = Isar.autoIncrement;
  late String backendId;
  late String productId;
  late double currentQuantity;
  double minStockLevel = 0.0;
  double maxStockLevel = 0.0;
  double reorderQuantity = 0.0;
  String movementsJson = '[]';          // JSON array of stock movements
  double? costPerUnit;
  double? inventoryValue;
  bool isSynced = false;
  int? lastSyncedAt;
  late int createdAt;
  late int updatedAt;

  // Methods:
  factory IsarInventory.fromJson(Map<String, dynamic> json)
  Map<String, dynamic> toJson()
  void addMovement({required String type, required double quantity, required String reason, String? userId})
  bool isStockLow()
  bool needsReorder()
}

```


### Isar Database Service (`lib/services/isar_database_service.dart`)


Singleton service for all database operations:


```dart
class IsarDatabaseService {
  static late Isar _isar;
  static bool _isInitialized = false;

  /// Initialize Isar database
  /// Call this once in main.dart or main_backend.dart
  static Future<void> initialize({bool encrypted = false}) async {
    if (_isInitialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();

      _isar = await Isar.open(
        [IsarProductSchema, IsarTransactionSchema, IsarInventorySchema],
        directory: dir.path,
        inspector: true, // Enable inspector for debugging
      );

      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Isar: $e');
    }
  }

  /// Get Isar instance (must call initialize() first)
  static Isar get instance {
    if (!_isInitialized) {
      throw Exception(
          'Isar not initialized. Call IsarDatabaseService.initialize() first.');
    }
    return _isar;
  }

  /// ==================== PRODUCT OPERATIONS ====================

  /// Get all products
  static Future<List<IsarProduct>> getAllProducts() async {
    return _isar.isarProducts.where().findAll();
  }

  /// Get product by ID
  static Future<IsarProduct?> getProductById(int id) async {
    return _isar.isarProducts.get(id);
  }

  /// Get product by backend ID
  static Future<IsarProduct?> getProductByBackendId(String backendId) async {
    return _isar.isarProducts
        .where()
        .backendIdEqualTo(backendId)
        .findFirst();
  }

  /// Get products by category
  static Future<List<IsarProduct>> getProductsByCategory(String categoryId) async {
    return _isar.isarProducts
        .where()
        .categoryIdEqualTo(categoryId)
        .findAll();
  }

  /// Get unsynced products
  static Future<List<IsarProduct>> getUnsyncedProducts() async {
    return _isar.isarProducts
        .where()
        .isSyncedEqualTo(false)
        .findAll();
  }

  /// Save product (insert or update)
  static Future<int> saveProduct(IsarProduct product) async {
    return _isar.writeTxn(() async {
      return _isar.isarProducts.put(product);
    });
  }

  /// Save multiple products
  static Future<void> saveProducts(List<IsarProduct> products) async {
    return _isar.writeTxn(() async {
      _isar.isarProducts.putAll(products);
    });
  }

  /// ==================== TRANSACTION OPERATIONS ====================

  /// Get all transactions
  static Future<List<IsarTransaction>> getAllTransactions() async {
    return _isar.isarTransactions.where().findAll();
  }

  /// Get transactions by date range
  static Future<List<IsarTransaction>> getTransactionsByDateRange(
    DateTime start, DateTime end) async {

    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    return _isar.isarTransactions
        .where()
        .transactionDateBetween(startMs, endMs)
        .findAll();
  }

  /// Get unsynced transactions
  static Future<List<IsarTransaction>> getUnsyncedTransactions() async {
    return _isar.isarTransactions
        .where()
        .isSyncedEqualTo(false)
        .findAll();
  }

  /// Save transaction (insert or update)
  static Future<int> saveTransaction(IsarTransaction transaction) async {
    return _isar.writeTxn(() async {
      return _isar.isarTransactions.put(transaction);
    });
  }

  /// ==================== INVENTORY OPERATIONS ====================

  /// Get all inventory
  static Future<List<IsarInventory>> getAllInventory() async {
    return _isar.isarInventory.where().findAll();
  }

  /// Get low stock items
  static Future<List<IsarInventory>> getLowStockItems() async {
    return _isar.isarInventory
        .where()
        .currentQuantityLessThan(5.0) // Example threshold
        .findAll();
  }

  /// Save inventory (insert or update)
  static Future<int> saveInventory(IsarInventory inventory) async {
    return _isar.writeTxn(() async {
      return _isar.isarInventory.put(inventory);
    });
  }

  /// ==================== SYNC HELPERS (OFFLINE-FIRST PATTERN) ====================

  /// Sync products from backend
  static Future<void> syncProductsFromBackend(List<Map<String, dynamic>> jsonProducts) async {
    final products = jsonProducts.map((json) => IsarProduct.fromJson(json)).toList();
    await saveProducts(products);
  }

  /// Sync transactions from backend
  static Future<void> syncTransactionsFromBackend(List<Map<String, dynamic>> jsonTransactions) async {
    final transactions = jsonTransactions.map((json) => IsarTransaction.fromJson(json)).toList();

    await _isar.writeTxn(() async {
      _isar.isarTransactions.putAll(transactions);
    });
  }

  /// Sync inventory from backend
  static Future<void> syncInventoryFromBackend(List<Map<String, dynamic>> jsonInventory) async {
    final inventory = jsonInventory.map((json) => IsarInventory.fromJson(json)).toList();

    await _isar.writeTxn(() async {
      _isar.isarInventory.putAll(inventory);
    });
  }

  /// Export unsynced products for backend push
  static Future<List<Map<String, dynamic>>> exportUnsyncedProducts() async {
    final products = await getUnsyncedProducts();
    return products.map((p) => p.toJson()).toList();
  }

  /// Export unsynced transactions for backend push
  static Future<List<Map<String, dynamic>>> exportUnsyncedTransactions() async {
    final transactions = await getUnsyncedTransactions();
    return transactions.map((t) => t.toJson()).toList();
  }

  /// Export unsynced inventory for backend push
  static Future<List<Map<String, dynamic>>> exportUnsyncedInventory() async {
    final inventory = await _isar.isarInventory
        .where()
        .isSyncedEqualTo(false)
        .findAll();

    return inventory.map((i) => i.toJson()).toList();
  }

  /// Mark products as synced
  static Future<void> markProductsAsSynced(List<String> backendIds) async {
    await _isar.writeTxn(() async {
      for (final backendId in backendIds) {
        final product = await _isar.isarProducts
            .where()
            .backendIdEqualTo(backendId)
            .findFirst();

        if (product != null) {
          product.isSynced = true;
          product.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
          _isar.isarProducts.put(product);
        }
      }
    });
  }

  /// Mark transactions as synced
  static Future<void> markTransactionsAsSynced(List<String> backendIds) async {
    await _isar.writeTxn(() async {
      for (final backendId in backendIds) {
        final transaction = await _isar.isarTransactions
            .where()
            .backendIdEqualTo(backendId)
            .findFirst();

        if (transaction != null) {
          transaction.isSynced = true;
          transaction.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
          _isar.isarTransactions.put(transaction);
        }
      }
    });
  }

  /// Mark inventory as synced
  static Future<void> markInventoryAsSynced(List<String> backendIds) async {
    await _isar.writeTxn(() async {
      for (final backendId in backendIds) {
        final inventory = await _isar.isarInventory
            .where()
            .backendIdEqualTo(backendId)
            .findFirst();

        if (inventory != null) {
          inventory.isSynced = true;
          inventory.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
          _isar.isarInventory.put(inventory);
        }
      }
    });
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final productCount = await _isar.isarProducts.count();
    final transactionCount = await _isar.isarTransactions.count();
    final inventoryCount = await _isar.isarInventory.count();

    final unsyncedProducts = await getUnsyncedProducts();
    final unsyncedTransactions = await getUnsyncedTransactions();
    final unsyncedInventory = await _isar.isarInventory
        .where()
        .isSyncedEqualTo(false)
        .count();

    return {
      'products': productCount,
      'transactions': transactionCount,
      'inventory': inventoryCount,
      'unsyncedProducts': unsyncedProducts.length,
      'unsyncedTransactions': unsyncedTransactions.length,
      'unsyncedInventory': unsyncedInventory,
    };
  }
}

```


### Offline-First Workflow



#### 1. App Startup (May be Offline)

```dart
// In main.dart or main_backend.dart:
await IsarDatabaseService.initialize(encrypted: true);

// Load cached data from Isar (instant, no network needed)
final products = await IsarDatabaseService.getAllProducts();
final recentTransactions = await IsarDatabaseService.getAllTransactions();

```


#### 2. User Creates Transaction (Write to Isar)

```dart
final transaction = IsarTransaction(
  backendId: '', // Empty until backend assigns
  transactionNumber: 'ORD-20251230-001',
  transactionDate: DateTime.now().millisecondsSinceEpoch,
  userId: 'user_1',
  subtotal: 50.0,
  taxAmount: 5.0,
  totalAmount: 55.0,
  paymentMethod: 'cash',
  businessMode: 'retail',
  itemsJson: jsonEncode(cartItems),
  isSynced: false,  // LOCAL - NOT YET SYNCED

);

// Save to Isar immediately (offline-first)
await IsarDatabaseService.saveTransaction(transaction);

```


#### 3. App Comes Online (Push & Pull)

```dart
// Export unsynced records for backend push
final unsyncedTxs = await IsarDatabaseService.exportUnsyncedTransactions();

// Push to backend API
final response = await backendApi.pushTransactions(unsyncedTxs);

// Appwrite returns backendIds for synced records
for (final result in response['results']) {
  await IsarDatabaseService.markTransactionsAsSynced([result['id']]);
}

// Pull new data from backend
final newProducts = await backendApi.getProducts();
await IsarDatabaseService.syncProductsFromBackend(newProducts);

```


### Key Design Patterns



#### Pattern 1: Always Use backendId for Sync Matching

```dart
// WRONG: Using local ID for sync
final product = await IsarDatabaseService.getProductById(123);

// CORRECT: Using backendId to match with backend
final product = await IsarDatabaseService.getProductByBackendId('prod_xyz');

```


#### Pattern 2: fromJson/toJson for Backend Compatibility

```dart
// Receiving from backend:
final jsonData = {'$id': 'prod_1', 'name': 'Pizza', 'price': 10.0};
final product = IsarProduct.fromJson(jsonData);
await IsarDatabaseService.saveProduct(product);

// Sending to backend:
final product = await IsarDatabaseService.getProductById(5);
final json = product!.toJson();
await backendApi.updateProduct(json);

```


#### Pattern 3: Check Sync Status Before Displaying

```dart
// Example: Show sync indicator in UI
final unsyncedCount = (await IsarDatabaseService.getUnsyncedProducts()).length;
if (unsyncedCount > 0) {
  // Show "Syncing..." badge
}

```


### Migration from SQLite


If migrating from sqflite/drift:

1. **Stop using sqflite queries** → Use `IsarDatabaseService` instead

2. **Convert models** → Create `IsarProduct`, `IsarTransaction`, `IsarInventory`

3. **Implement sync helpers** → Use `syncFromBackend()` and `exportUnsynced()`

4. **Update main()** → Call `IsarDatabaseService.initialize()` at startup

5. **Run codegen** → `flutter pub run build_runner build`

6. **Migrate existing data** → Use `SQLiteToIsarMigration.migrateAll()` for one-time data transfer


### Code Generation


Isar requires code generation for collections and queries:


```bash

# Generate Isar code (run once after model changes)

flutter pub run build_runner build


# Watch for changes and regenerate automatically

flutter pub run build_runner watch

```

**Generated Files**:

- `lib/models/isar/product_model.g.dart` - Product queries and schema

- `lib/models/isar/transaction_model.g.dart` - Transaction queries and schema

- `lib/models/isar/inventory_model.g.dart` - Inventory queries and schema


### Testing


Run unit tests for Isar models:


```bash
flutter test test/isar_models_test.dart

```

Tests cover:

- JSON serialization/deserialization

- Sync flag management

- Query operations

- Timestamp handling

- Offline-first patterns


### Advanced Features & Extensions



#### 1. Isar Sync Service (`lib/services/isar_sync_service.dart`)


Complete bidirectional sync with conflict resolution:


```dart
// Full sync (pull + push)

final result = await IsarSyncService.fullSync(
  fetchProducts: () => appwriteService.getProducts(),
  fetchTransactions: () => appwriteService.getTransactions(),
  fetchInventory: () => appwriteService.getInventory(),
  pushProducts: (json) => appwriteService.pushProducts(json),
  pushTransactions: (json) => appwriteService.pushTransactions(json),
  pushInventory: (json) => appwriteService.pushInventory(json),
);

print('Total synced: ${result.totalSynced}');
print('Total pushed: ${result.totalPushed}');
print('Duration: ${result.duration.inSeconds}s');

// Check sync status
final status = await IsarSyncService.getSyncStatus();
if (status.needsSync) {
  print('Unsynced: ${status.totalUnsynced} records');
}

// Conflict resolution
await IsarSyncService.resolveConflictKeepLocal(backendId, 'products');
await IsarSyncService.resolveConflictKeepRemote(remoteJson, 'products');

```

**Classes**:

- `SyncResult` - Pull sync results (inserted, updated, failed counts)

- `PushResult` - Push sync results (pushed, failed counts)

- `FullSyncResult` - Complete sync statistics with duration

- `SyncStatus` - Current unsynced record counts


#### 2. POS Helper (`lib/helpers/pos_isar_helper.dart`)


POS-specific integration for cart/transaction/inventory workflows:


```dart
// Create transaction from cart
final transaction = await POSIsarHelper.createTransactionFromCart(
  cartItems: cartItems,
  userId: currentUserId,
  paymentMethod: 'cash',
  businessMode: 'retail',
  discountAmount: 5.0,
);

// Update inventory after sale
await POSIsarHelper.updateInventoryAfterSale(
  cartItems: cartItems,
  transactionNumber: transaction.transactionNumber,
  userId: currentUserId,
);

// Process refund
final refundedTx = await POSIsarHelper.processRefund(
  transactionNumber: 'ORD-20251230-001',
  refundAmount: 50.0,
  userId: currentUserId,
  isPartial: false,
  reason: 'Customer request',
);

// Get daily sales summary
final summary = await POSIsarHelper.getDailySalesSummary(DateTime.now());
print('Gross Sales: ${summary.grossSales}');
print('Transactions: ${summary.transactionCount}');
print('Average Ticket: ${summary.averageTicket}');

// Get top selling products
final topProducts = await POSIsarHelper.getTopSellingProducts(
  start: DateTime.now().subtract(Duration(days: 7)),
  end: DateTime.now(),
  limit: 10,
);

```

**Classes**:

- `DailySalesSummary` - Aggregated daily sales with breakdowns

- `ProductSalesData` - Product sales metrics (units, revenue)


#### 3. SQLite Migration (`lib/helpers/sqlite_to_isar_migration.dart`)


Migrate existing SQLite data to Isar:


```dart
final sqliteDb = await openDatabase('pos.db');
final migration = SQLiteToIsarMigration(sqliteDb);

// Migrate all tables
final results = await migration.migrateAll();
for (final result in results) {
  print(result.toString());
}

// Verify migration integrity
final verification = await migration.verifyMigration();
print('Products: SQLite=${verification['products']!['sqlite']}, Isar=${verification['products']!['isar']}');

// Or migrate individual tables
final productResult = await migration.migrateProducts();
final transactionResult = await migration.migrateTransactions();
final inventoryResult = await migration.migrateInventory();

```

**Classes**:

- `MigrationResult` - Migration statistics per table (migrated, failed, success rate)


#### 4. Performance Monitor (`lib/helpers/isar_performance_monitor.dart`)


Track operation performance for optimization:


```dart
// Time an operation
final products = await IsarPerformanceMonitor.timeOperation(
  'getAllProducts',
  () => IsarDatabaseService.getAllProducts(),
);

// Get statistics
final stats = IsarPerformanceMonitor.getStats('getAllProducts');
print('Average: ${stats?.avgMs}ms');
print('Performance: ${stats?.performanceRating}');

// Print full report
IsarPerformanceMonitor.printStats();

// Get top slowest operations
final slowest = IsarPerformanceMonitor.getTopSlowest(limit: 5);
for (final stat in slowest) {
  print('${stat.operationName}: ${stat.avgMs.toStringAsFixed(2)}ms avg');
}

// Check for slow operations
final slowOps = IsarPerformanceMonitor.getSlowOperations(thresholdMs: 100);
if (slowOps.isNotEmpty) {
  print('Warning: Slow operations detected:');
  slowOps.forEach(print);
}

// Clear stats
IsarPerformanceMonitor.clear();

```

**Classes**:

- `OperationStats` - Performance metrics (count, avg, min, max, median, rating)


#### 5. Model Extensions (`lib/models/isar/isar_model_extensions.dart`)


Extension methods for working with JSON fields:


```dart
// IsarProduct extensions
final variants = product.getVariants();  // Decode variantsJson
final modifierIds = product.getModifierGroupIds();
final inStock = product.isInStock();
final needsRestock = product.needsRestock(threshold: 10.0);
final profitMargin = product.getProfitMargin();  // Returns %
final inventoryValue = product.getInventoryValue();
final displayName = product.getDisplayName();  // With SKU if available

// IsarTransaction extensions
final items = transaction.getItems();  // Decode itemsJson
final payments = transaction.getPayments();
final itemCount = transaction.getTotalItemCount();
final netTotal = transaction.getNetTotal();  // After refunds
final isRefunded = transaction.isRefunded();
final refundPct = transaction.getRefundPercentage();
final txDate = transaction.getTransactionDateTime();
final isToday = transaction.isToday();
final formattedDate = transaction.getFormattedDate();

// IsarInventory extensions
final movements = inventory.getMovements();  // Decode movementsJson
final latestMovement = inventory.getLatestMovement();
final value = inventory.calculateInventoryValue();
final status = inventory.getStockStatus();  // Enum: outOfStock, low, reorderPoint, normal, overstock
final statusDisplay = inventory.getStockStatusDisplay();  // "Out of Stock", "Low Stock", etc.
final stockPct = inventory.getStockPercentage();  // 0-100%
final totalAdded = inventory.getTotalQuantityAdded();
final totalRemoved = inventory.getTotalQuantityRemoved();
final movementCounts = inventory.getMovementCountsByType();  // {'sale': 10, 'restock': 3}
final quantityByType = inventory.getTotalQuantityChangeByType();
final daysUntilReorder = inventory.getDaysUntilReorder(averageDailySales: 5.0);

```

**Enums**:

- `StockStatus` - outOfStock, low, reorderPoint, normal, overstock


### Usage Examples


**See** `lib/examples/isar_usage_examples.dart` for complete examples:

- `ProductInsertExample.insertProductExample()` - Insert product from backend JSON

- `TransactionExportExample.createAndExportTransactionExample()` - Create and export transaction

- `SyncFromBackendExample.syncProductCatalogExample()` - Sync catalog from backend

- `OfflineFirstWorkflowExample.runFullWorkflow()` - Complete offline-first flow
