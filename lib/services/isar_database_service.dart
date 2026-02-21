import 'package:extropos/models/isar/inventory_model.dart';
import 'package:extropos/models/isar/product_model.dart';
import 'package:extropos/models/isar/transaction_model.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

/// Isar Database Service
/// Handles all local Isar database operations with offline-first sync support
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

  /// Get product by backend ID (for sync matching)
  static Future<IsarProduct?> getProductByBackendId(String backendId) async {
    return _isar.isarProducts
      .filter()
      .backendIdEqualTo(backendId)
      .findFirst();
  }

  /// Get products by category
  static Future<List<IsarProduct>> getProductsByCategory(
      String categoryId) async {
    return _isar.isarProducts
        .filter()
        .categoryIdEqualTo(categoryId)
        .findAll();
  }

  /// Get unsynced products (for pushing to backend)
  static Future<List<IsarProduct>> getUnsyncedProducts() async {
    return _isar.isarProducts.filter().isSyncedEqualTo(false).findAll();
  }

  /// Insert or update product
  static Future<int> saveProduct(IsarProduct product) async {
    return _isar.writeTxn(() async {
      product.updatedAt = DateTime.now().millisecondsSinceEpoch;
      return _isar.isarProducts.put(product);
    });
  }

  /// Insert multiple products
  static Future<void> saveProducts(List<IsarProduct> products) async {
    await _isar.writeTxn(() async {
      for (var product in products) {
        product.updatedAt = DateTime.now().millisecondsSinceEpoch;
      }
      await _isar.isarProducts.putAll(products);
    });
  }

  /// Delete product
  static Future<bool> deleteProduct(int id) async {
    return _isar.writeTxn(() async {
      return _isar.isarProducts.delete(id);
    });
  }

  /// ==================== TRANSACTION OPERATIONS ====================

  /// Get all transactions
  static Future<List<IsarTransaction>> getAllTransactions() async {
    return _isar.isarTransactions
        .where()
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get transaction by ID
  static Future<IsarTransaction?> getTransactionById(int id) async {
    return _isar.isarTransactions.get(id);
  }

  /// Get transaction by backend ID
  static Future<IsarTransaction?> getTransactionByBackendId(
      String backendId) async {
    return _isar.isarTransactions
        .filter()
        .backendIdEqualTo(backendId)
        .findFirst();
  }

  /// Get transactions by date range
  static Future<List<IsarTransaction>> getTransactionsByDateRange(
      DateTime start, DateTime end) async {
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    return _isar.isarTransactions
        .filter()
        .transactionDateBetween(startMs, endMs)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get transactions by user
  static Future<List<IsarTransaction>> getTransactionsByUser(
      String userId) async {
    return _isar.isarTransactions
        .filter()
        .userIdEqualTo(userId)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Get unsynced transactions (for pushing to backend)
  static Future<List<IsarTransaction>> getUnsyncedTransactions() async {
    return _isar.isarTransactions
      .filter()
      .isSyncedEqualTo(false)
        .sortByTransactionDateDesc()
        .findAll();
  }

  /// Insert or update transaction
  static Future<int> saveTransaction(IsarTransaction transaction) async {
    return _isar.writeTxn(() async {
      transaction.updatedAt = DateTime.now().millisecondsSinceEpoch;
      return _isar.isarTransactions.put(transaction);
    });
  }

  /// Insert multiple transactions
  static Future<void> saveTransactions(
      List<IsarTransaction> transactions) async {
    await _isar.writeTxn(() async {
      for (var tx in transactions) {
        tx.updatedAt = DateTime.now().millisecondsSinceEpoch;
      }
      await _isar.isarTransactions.putAll(transactions);
    });
  }

  /// Delete transaction
  static Future<bool> deleteTransaction(int id) async {
    return _isar.writeTxn(() async {
      return _isar.isarTransactions.delete(id);
    });
  }

  /// ==================== INVENTORY OPERATIONS ====================

  /// Get all inventory records
  static Future<List<IsarInventory>> getAllInventory() async {
    return _isar.isarInventorys.where().findAll();
  }

  /// Get inventory by product ID
  static Future<IsarInventory?> getInventoryByProductId(
      String productId) async {
    return _isar.isarInventorys
      .filter()
      .productIdEqualTo(productId)
        .findFirst();
  }

  /// Get inventory by backend ID
  static Future<IsarInventory?> getInventoryByBackendId(
      String backendId) async {
    return _isar.isarInventorys
      .filter()
      .backendIdEqualTo(backendId)
        .findFirst();
  }

  /// Get low stock items
  static Future<List<IsarInventory>> getLowStockItems() async {
    final all = await _isar.isarInventorys.where().findAll();
    return all.where((inv) => inv.isStockLow()).toList();
  }

  /// Get unsynced inventory records
  static Future<List<IsarInventory>> getUnsyncedInventory() async {
    return _isar.isarInventorys.filter().isSyncedEqualTo(false).findAll();
  }

  /// Insert or update inventory
  static Future<int> saveInventory(IsarInventory inventory) async {
    return _isar.writeTxn(() async {
      inventory.updatedAt = DateTime.now().millisecondsSinceEpoch;
      return _isar.isarInventorys.put(inventory);
    });
  }

  /// Insert multiple inventory records
  static Future<void> saveInventories(List<IsarInventory> items) async {
    await _isar.writeTxn(() async {
      for (var item in items) {
        item.updatedAt = DateTime.now().millisecondsSinceEpoch;
      }
      await _isar.isarInventorys.putAll(items);
    });
  }

  /// Delete inventory record
  static Future<bool> deleteInventory(int id) async {
    return _isar.writeTxn(() async {
      return _isar.isarInventorys.delete(id);
    });
  }

  /// ==================== SYNC OPERATIONS ====================

  /// Sync products from backend JSON to Isar
  /// Call this when receiving product data from Appwrite/backend
  static Future<void> syncProductsFromBackend(
      List<Map<String, dynamic>> jsonProducts) async {
    final products = jsonProducts
        .map((json) => IsarProduct.fromJson(json))
        .toList();

    await _isar.writeTxn(() async {
      for (var product in products) {
        // Check if product already exists by backendId
        final existing = await _isar.isarProducts
          .filter()
          .backendIdEqualTo(product.backendId)
          .findFirst();

        if (existing != null) {
          // Update existing
          product.id = existing.id; // Preserve local ID
          product.isSynced = true;
          product.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
        } else {
          // New product
          product.isSynced = true;
          product.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
        }
      }
      await _isar.isarProducts.putAll(products);
    });
  }

  /// Sync transactions from backend JSON to Isar
  static Future<void> syncTransactionsFromBackend(
      List<Map<String, dynamic>> jsonTransactions) async {
    final transactions = jsonTransactions
        .map((json) => IsarTransaction.fromJson(json))
        .toList();

    await _isar.writeTxn(() async {
      for (var tx in transactions) {
        final existing = await _isar.isarTransactions
          .filter()
          .backendIdEqualTo(tx.backendId)
          .findFirst();

        if (existing != null) {
          tx.id = existing.id;
          tx.isSynced = true;
          tx.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
        } else {
          tx.isSynced = true;
          tx.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
        }
      }
      await _isar.isarTransactions.putAll(transactions);
    });
  }

  /// Sync inventory from backend JSON to Isar
  static Future<void> syncInventoryFromBackend(
      List<Map<String, dynamic>> jsonInventory) async {
    final inventoryList = jsonInventory
        .map((json) => IsarInventory.fromJson(json))
        .toList();

    await _isar.writeTxn(() async {
      for (var inv in inventoryList) {
        final existing = await _isar.isarInventorys
            .filter()
            .backendIdEqualTo(inv.backendId)
            .findFirst();

        if (existing != null) {
          inv.id = existing.id;
          inv.isSynced = true;
          inv.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
        } else {
          inv.isSynced = true;
          inv.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
        }
      }
      await _isar.isarInventorys.putAll(inventoryList);
    });
  }

  /// Export unsynced products as JSON (for pushing to backend)
  static Future<List<Map<String, dynamic>>> exportUnsyncedProducts() async {
    final unsynced = await getUnsyncedProducts();
    return unsynced.map((p) => p.toJson()).toList();
  }

  /// Export unsynced transactions as JSON
  static Future<List<Map<String, dynamic>>>
      exportUnsyncedTransactions() async {
    final unsynced = await getUnsyncedTransactions();
    return unsynced.map((t) => t.toJson()).toList();
  }

  /// Export unsynced inventory as JSON
  static Future<List<Map<String, dynamic>>> exportUnsyncedInventory() async {
    final unsynced = await getUnsyncedInventory();
    return unsynced.map((i) => i.toJson()).toList();
  }

  /// Mark products as synced (call after successful backend push)
  static Future<void> markProductsAsSynced(List<String> backendIds) async {
    await _isar.writeTxn(() async {
      for (final backendId in backendIds) {
        final product = await _isar.isarProducts
          .filter()
          .backendIdEqualTo(backendId)
            .findFirst();

        if (product != null) {
          product.isSynced = true;
          product.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
          await _isar.isarProducts.put(product);
        }
      }
    });
  }

  /// Mark transactions as synced
  static Future<void> markTransactionsAsSynced(List<String> backendIds) async {
    await _isar.writeTxn(() async {
      for (final backendId in backendIds) {
        final tx = await _isar.isarTransactions
          .filter()
          .backendIdEqualTo(backendId)
            .findFirst();

        if (tx != null) {
          tx.isSynced = true;
          tx.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
          await _isar.isarTransactions.put(tx);
        }
      }
    });
  }

  /// Mark inventory as synced
  static Future<void> markInventoryAsSynced(List<String> backendIds) async {
    await _isar.writeTxn(() async {
      for (final backendId in backendIds) {
        final inv = await _isar.isarInventorys
            .filter()
            .backendIdEqualTo(backendId)
            .findFirst();

        if (inv != null) {
          inv.isSynced = true;
          inv.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;
          await _isar.isarInventorys.put(inv);
        }
      }
    });
  }

  /// Clear all local data (for factory reset)
  static Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.isarProducts.clear();
      await _isar.isarTransactions.clear();
      await _isar.isarInventorys.clear();
    });
  }

  /// Get database statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final productCount = await _isar.isarProducts.count();
    final transactionCount = await _isar.isarTransactions.count();
    final inventoryCount = await _isar.isarInventorys.count();

    final unsyncedProducts = await getUnsyncedProducts();
    final unsyncedTransactions = await getUnsyncedTransactions();
    final unsyncedInventory = await getUnsyncedInventory();

    return {
      'products': {
        'total': productCount,
        'unsynced': unsyncedProducts.length,
      },
      'transactions': {
        'total': transactionCount,
        'unsynced': unsyncedTransactions.length,
      },
      'inventory': {
        'total': inventoryCount,
        'unsynced': unsyncedInventory.length,
      },
      'lastChecked': DateTime.now().toIso8601String(),
    };
  }

  /// Close Isar database
  static Future<void> close() async {
    if (_isInitialized) {
      await _isar.close();
      _isInitialized = false;
    }
  }
}
