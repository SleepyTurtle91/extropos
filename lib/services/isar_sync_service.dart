import 'package:extropos/models/isar/inventory_model.dart';
import 'package:extropos/models/isar/product_model.dart';
import 'package:extropos/models/isar/transaction_model.dart';
import 'package:extropos/services/isar_database_service.dart';

/// Advanced synchronization service for bidirectional sync between Isar and backend.
/// 
/// Provides:
/// - Pull sync: Fetch data from backend → update Isar
/// - Push sync: Export unsynced Isar records → push to backend
/// - Conflict resolution: Handle timestamp conflicts
/// - Progress tracking: Monitor sync operations
/// - Full sync: Complete bidirectional synchronization
class IsarSyncService {
  /// Sync products from backend to Isar.
  /// 
  /// [fetchFromBackend] should return List of Map with String keys and dynamic values from backend API.
  /// Returns SyncResult with counts of inserted, updated, and failed records.
  static Future<SyncResult> syncProductsFromBackend({
    required Future<List<Map<String, dynamic>>> Function() fetchFromBackend,
  }) async {
    try {
      final jsonData = await fetchFromBackend();
      int inserted = 0;
      int updated = 0;
      int failed = 0;
      
      for (final json in jsonData) {
        try {
          final backendId = json['\$id'] as String?;
          if (backendId == null) {
            failed++;
            continue;
          }
          
          // Check if product already exists
          final existing = await IsarDatabaseService.getProductByBackendId(backendId);
          
          final product = IsarProduct.fromJson(json);
          await IsarDatabaseService.saveProduct(product);
          
          if (existing == null) {
            inserted++;
          } else {
            updated++;
          }
        } catch (e) {
          failed++;
          print('Failed to sync product: $e');
        }
      }
      
      return SyncResult(
        inserted: inserted,
        updated: updated,
        failed: failed,
        total: jsonData.length,
      );
    } catch (e) {
      print('Sync failed: $e');
      return SyncResult(inserted: 0, updated: 0, failed: 0, total: 0, error: e.toString());
    }
  }
  
  /// Sync transactions from backend to Isar.
  static Future<SyncResult> syncTransactionsFromBackend({
    required Future<List<Map<String, dynamic>>> Function() fetchFromBackend,
  }) async {
    try {
      final jsonData = await fetchFromBackend();
      int inserted = 0;
      int updated = 0;
      int failed = 0;
      
      for (final json in jsonData) {
        try {
          final backendId = json['\$id'] as String?;
          if (backendId == null) {
            failed++;
            continue;
          }
          
          final existing = await IsarDatabaseService.getTransactionByBackendId(backendId);
          
          final transaction = IsarTransaction.fromJson(json);
          await IsarDatabaseService.saveTransaction(transaction);
          
          if (existing == null) {
            inserted++;
          } else {
            updated++;
          }
        } catch (e) {
          failed++;
          print('Failed to sync transaction: $e');
        }
      }
      
      return SyncResult(
        inserted: inserted,
        updated: updated,
        failed: failed,
        total: jsonData.length,
      );
    } catch (e) {
      print('Sync failed: $e');
      return SyncResult(inserted: 0, updated: 0, failed: 0, total: 0, error: e.toString());
    }
  }
  
  /// Sync inventory from backend to Isar.
  static Future<SyncResult> syncInventoryFromBackend({
    required Future<List<Map<String, dynamic>>> Function() fetchFromBackend,
  }) async {
    try {
      final jsonData = await fetchFromBackend();
      int inserted = 0;
      int updated = 0;
      int failed = 0;
      
      for (final json in jsonData) {
        try {
          final backendId = json['\$id'] as String?;
          if (backendId == null) {
            failed++;
            continue;
          }
          
          final existing = await IsarDatabaseService.getInventoryByBackendId(backendId);
          
          final inventory = IsarInventory.fromJson(json);
          await IsarDatabaseService.saveInventory(inventory);
          
          if (existing == null) {
            inserted++;
          } else {
            updated++;
          }
        } catch (e) {
          failed++;
          print('Failed to sync inventory: $e');
        }
      }
      
      return SyncResult(
        inserted: inserted,
        updated: updated,
        failed: failed,
        total: jsonData.length,
      );
    } catch (e) {
      print('Sync failed: $e');
      return SyncResult(inserted: 0, updated: 0, failed: 0, total: 0, error: e.toString());
    }
  }
  
  /// Push unsynced products to backend.
  /// 
  /// [pushToBackend] should accept List of Map with String keys and dynamic values and return List of String backendIds.
  /// Returns PushResult with counts of pushed and failed records.
  static Future<PushResult> pushProductsToBackend({
    required Future<List<String>> Function(List<Map<String, dynamic>>) pushToBackend,
  }) async {
    try {
      final unsyncedProducts = await IsarDatabaseService.exportUnsyncedProducts();
      
      if (unsyncedProducts.isEmpty) {
        return PushResult(pushed: 0, failed: 0, total: 0);
      }
      
      final backendIds = await pushToBackend(unsyncedProducts);
      
      // Mark as synced
      await IsarDatabaseService.markProductsAsSynced(backendIds);
      
      return PushResult(
        pushed: backendIds.length,
        failed: unsyncedProducts.length - backendIds.length,
        total: unsyncedProducts.length,
      );
    } catch (e) {
      print('Push failed: $e');
      return PushResult(pushed: 0, failed: 0, total: 0, error: e.toString());
    }
  }
  
  /// Push unsynced transactions to backend.
  static Future<PushResult> pushTransactionsToBackend({
    required Future<List<String>> Function(List<Map<String, dynamic>>) pushToBackend,
  }) async {
    try {
      final unsyncedTransactions = await IsarDatabaseService.exportUnsyncedTransactions();
      
      if (unsyncedTransactions.isEmpty) {
        return PushResult(pushed: 0, failed: 0, total: 0);
      }
      
      final backendIds = await pushToBackend(unsyncedTransactions);
      
      await IsarDatabaseService.markTransactionsAsSynced(backendIds);
      
      return PushResult(
        pushed: backendIds.length,
        failed: unsyncedTransactions.length - backendIds.length,
        total: unsyncedTransactions.length,
      );
    } catch (e) {
      print('Push failed: $e');
      return PushResult(pushed: 0, failed: 0, total: 0, error: e.toString());
    }
  }
  
  /// Push unsynced inventory to backend.
  static Future<PushResult> pushInventoryToBackend({
    required Future<List<String>> Function(List<Map<String, dynamic>>) pushToBackend,
  }) async {
    try {
      final unsyncedInventory = await IsarDatabaseService.exportUnsyncedInventory();
      
      if (unsyncedInventory.isEmpty) {
        return PushResult(pushed: 0, failed: 0, total: 0);
      }
      
      final backendIds = await pushToBackend(unsyncedInventory);
      
      await IsarDatabaseService.markInventoryAsSynced(backendIds);
      
      return PushResult(
        pushed: backendIds.length,
        failed: unsyncedInventory.length - backendIds.length,
        total: unsyncedInventory.length,
      );
    } catch (e) {
      print('Push failed: $e');
      return PushResult(pushed: 0, failed: 0, total: 0, error: e.toString());
    }
  }
  
  /// Perform full bidirectional sync (pull + push).
  /// 
  /// Returns FullSyncResult with all sync statistics.
  static Future<FullSyncResult> fullSync({
    required Future<List<Map<String, dynamic>>> Function() fetchProducts,
    required Future<List<Map<String, dynamic>>> Function() fetchTransactions,
    required Future<List<Map<String, dynamic>>> Function() fetchInventory,
    required Future<List<String>> Function(List<Map<String, dynamic>>) pushProducts,
    required Future<List<String>> Function(List<Map<String, dynamic>>) pushTransactions,
    required Future<List<String>> Function(List<Map<String, dynamic>>) pushInventory,
  }) async {
    final startTime = DateTime.now();
    
    // Pull from backend first
    final productSyncResult = await syncProductsFromBackend(fetchFromBackend: fetchProducts);
    final transactionSyncResult = await syncTransactionsFromBackend(fetchFromBackend: fetchTransactions);
    final inventorySyncResult = await syncInventoryFromBackend(fetchFromBackend: fetchInventory);
    
    // Push to backend
    final productPushResult = await pushProductsToBackend(pushToBackend: pushProducts);
    final transactionPushResult = await pushTransactionsToBackend(pushToBackend: pushTransactions);
    final inventoryPushResult = await pushInventoryToBackend(pushToBackend: pushInventory);
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    return FullSyncResult(
      productSync: productSyncResult,
      transactionSync: transactionSyncResult,
      inventorySync: inventorySyncResult,
      productPush: productPushResult,
      transactionPush: transactionPushResult,
      inventoryPush: inventoryPushResult,
      duration: duration,
      timestamp: endTime,
    );
  }
  
  /// Get current sync status (counts of unsynced records).
  static Future<SyncStatus> getSyncStatus() async {
    final unsyncedProducts = await IsarDatabaseService.getUnsyncedProducts();
    final unsyncedTransactions = await IsarDatabaseService.getUnsyncedTransactions();
    final unsyncedInventory = await IsarDatabaseService.getUnsyncedInventory();
    
    return SyncStatus(
      unsyncedProducts: unsyncedProducts.length,
      unsyncedTransactions: unsyncedTransactions.length,
      unsyncedInventory: unsyncedInventory.length,
    );
  }
  
  /// Resolve conflict by keeping local version (discard remote changes).
  static Future<void> resolveConflictKeepLocal(String backendId, String collectionType) async {
    // Mark as synced without updating data
    if (collectionType == 'products') {
      await IsarDatabaseService.markProductsAsSynced([backendId]);
    } else if (collectionType == 'transactions') {
      await IsarDatabaseService.markTransactionsAsSynced([backendId]);
    } else if (collectionType == 'inventory') {
      await IsarDatabaseService.markInventoryAsSynced([backendId]);
    }
  }
  
  /// Resolve conflict by keeping remote version (overwrite local changes).
  static Future<void> resolveConflictKeepRemote(Map<String, dynamic> remoteJson, String collectionType) async {
    if (collectionType == 'products') {
      final product = IsarProduct.fromJson(remoteJson);
      await IsarDatabaseService.saveProduct(product);
    } else if (collectionType == 'transactions') {
      final transaction = IsarTransaction.fromJson(remoteJson);
      await IsarDatabaseService.saveTransaction(transaction);
    } else if (collectionType == 'inventory') {
      final inventory = IsarInventory.fromJson(remoteJson);
      await IsarDatabaseService.saveInventory(inventory);
    }
  }
}

/// Result of a sync operation (pull from backend).
class SyncResult {
  final int inserted;
  final int updated;
  final int failed;
  final int total;
  final String? error;
  
  SyncResult({
    required this.inserted,
    required this.updated,
    required this.failed,
    required this.total,
    this.error,
  });
  
  bool get isSuccess => error == null && failed == 0;
  
  @override
  String toString() {
    if (error != null) return 'SyncResult(error: $error)';
    return 'SyncResult(inserted: $inserted, updated: $updated, failed: $failed, total: $total)';
  }
}

/// Result of a push operation (push to backend).
class PushResult {
  final int pushed;
  final int failed;
  final int total;
  final String? error;
  
  PushResult({
    required this.pushed,
    required this.failed,
    required this.total,
    this.error,
  });
  
  bool get isSuccess => error == null && failed == 0;
  
  @override
  String toString() {
    if (error != null) return 'PushResult(error: $error)';
    return 'PushResult(pushed: $pushed, failed: $failed, total: $total)';
  }
}

/// Result of a full bidirectional sync.
class FullSyncResult {
  final SyncResult productSync;
  final SyncResult transactionSync;
  final SyncResult inventorySync;
  final PushResult productPush;
  final PushResult transactionPush;
  final PushResult inventoryPush;
  final Duration duration;
  final DateTime timestamp;
  
  FullSyncResult({
    required this.productSync,
    required this.transactionSync,
    required this.inventorySync,
    required this.productPush,
    required this.transactionPush,
    required this.inventoryPush,
    required this.duration,
    required this.timestamp,
  });
  
  bool get isSuccess =>
      productSync.isSuccess &&
      transactionSync.isSuccess &&
      inventorySync.isSuccess &&
      productPush.isSuccess &&
      transactionPush.isSuccess &&
      inventoryPush.isSuccess;
  
  int get totalSynced =>
      productSync.inserted +
      productSync.updated +
      transactionSync.inserted +
      transactionSync.updated +
      inventorySync.inserted +
      inventorySync.updated;
  
  int get totalPushed =>
      productPush.pushed +
      transactionPush.pushed +
      inventoryPush.pushed;
  
  @override
  String toString() {
    return '''
FullSyncResult(
  Products: ${productSync.toString()},
  Transactions: ${transactionSync.toString()},
  Inventory: ${inventorySync.toString()},
  Pushed Products: ${productPush.pushed},
  Pushed Transactions: ${transactionPush.pushed},
  Pushed Inventory: ${inventoryPush.pushed},
  Duration: ${duration.inSeconds}s,
  Timestamp: $timestamp
)''';
  }
}

/// Current sync status (unsynced record counts).
class SyncStatus {
  final int unsyncedProducts;
  final int unsyncedTransactions;
  final int unsyncedInventory;
  
  SyncStatus({
    required this.unsyncedProducts,
    required this.unsyncedTransactions,
    required this.unsyncedInventory,
  });
  
  int get totalUnsynced => unsyncedProducts + unsyncedTransactions + unsyncedInventory;
  
  bool get needsSync => totalUnsynced > 0;
  
  @override
  String toString() {
    return 'SyncStatus(products: $unsyncedProducts, transactions: $unsyncedTransactions, inventory: $unsyncedInventory)';
  }
}
