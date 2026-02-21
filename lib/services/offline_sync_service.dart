import 'dart:async';
import 'dart:convert';

/// Enhanced offline sync service with intelligent queuing and conflict resolution
/// Ensures reliable data sync when network connectivity is restored
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();

  factory OfflineSyncService() {
    return _instance;
  }

  OfflineSyncService._internal();

  // Queue management
  final List<PendingSyncItem> _syncQueue = [];
  bool _isSyncing = false;
  DateTime? _lastSuccessfulSync;

  // Sync statistics
  int _totalQueued = 0;
  int _totalSynced = 0;
  int _totalFailed = 0;

  /// Check if there are pending items to sync
  bool get hasPendingSync => _syncQueue.isNotEmpty;

  /// Get number of items in queue
  int get queueSize => _syncQueue.length;

  /// Get sync statistics
  SyncStats get stats => SyncStats(
        totalQueued: _totalQueued,
        totalSynced: _totalSynced,
        totalFailed: _totalFailed,
        lastSuccessfulSync: _lastSuccessfulSync,
        pendingItems: _syncQueue.length,
      );

  /// Queue transaction for sync
  Future<void> queueTransaction(Map<String, dynamic> transactionData) async {
    try {
      final item = PendingSyncItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: SyncItemType.transaction,
        data: transactionData,
        priority: SyncPriority.high,
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      _syncQueue.add(item);
      _totalQueued++;

      print('📦 Transaction queued for sync: ${item.id}');

      // TODO: Persist to database
    } catch (e) {
      print('🔥 Error queueing transaction: $e');
      rethrow;
    }
  }

  /// Queue product for sync
  Future<void> queueProduct(Map<String, dynamic> productData) async {
    try {
      final item = PendingSyncItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: SyncItemType.product,
        data: productData,
        priority: SyncPriority.medium,
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      _syncQueue.add(item);
      _totalQueued++;

      print('📦 Product queued for sync: ${item.id}');

      // TODO: Persist to database
    } catch (e) {
      print('🔥 Error queueing product: $e');
      rethrow;
    }
  }

  /// Queue inventory update for sync
  Future<void> queueInventoryUpdate(Map<String, dynamic> inventoryData) async {
    try {
      final item = PendingSyncItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: SyncItemType.inventory,
        data: inventoryData,
        priority: SyncPriority.high,
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      _syncQueue.add(item);
      _totalQueued++;

      print('📦 Inventory update queued for sync: ${item.id}');

      // TODO: Persist to database
    } catch (e) {
      print('🔥 Error queueing inventory: $e');
      rethrow;
    }
  }

  /// Smart sync - syncs queued items in priority order when online
  Future<SyncResult> smartSync({
    bool syncImages = false,
    int maxRetries = 3,
  }) async {
    if (_isSyncing) {
      print('⚠️ Sync already in progress');
      return SyncResult(
        success: false,
        itemsSynced: 0,
        itemsFailed: 0,
        error: 'Sync already in progress',
      );
    }

    _isSyncing = true;

    try {
      print('🔄 Starting smart sync (${_syncQueue.length} items)...');

      // Sort by priority (high → medium → low)
      _syncQueue.sort((a, b) => b.priority.value.compareTo(a.priority.value));

      int synced = 0;
      int failed = 0;
      final List<PendingSyncItem> failedItems = [];

      for (final item in List.from(_syncQueue)) {
        try {
          // Check if item has exceeded max retries
          if (item.retryCount >= maxRetries) {
            print('❌ Max retries exceeded for ${item.type.name}: ${item.id}');
            _syncQueue.remove(item);
            failed++;
            _totalFailed++;
            continue;
          }

          // Sync the item
          final success = await _syncItem(item, syncImages: syncImages);

          if (success) {
            _syncQueue.remove(item);
            synced++;
            _totalSynced++;
            print('✅ Synced ${item.type.name}: ${item.id}');
          } else {
            item.retryCount++;
            item.lastRetryAt = DateTime.now();
            failedItems.add(item);
            failed++;
            print('❌ Failed to sync ${item.type.name}: ${item.id} (retry ${item.retryCount}/$maxRetries)');
          }

          // Add small delay between syncs to avoid overwhelming server
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          item.retryCount++;
          item.lastRetryAt = DateTime.now();
          failedItems.add(item);
          failed++;
          print('🔥 Error syncing ${item.type.name}: $e');
        }
      }

      if (synced > 0) {
        _lastSuccessfulSync = DateTime.now();
      }

      _isSyncing = false;

      print('✅ Smart sync completed: $synced synced, $failed failed');

      return SyncResult(
        success: failed == 0,
        itemsSynced: synced,
        itemsFailed: failed,
      );
    } catch (e) {
      _isSyncing = false;
      print('🔥 Smart sync failed: $e');

      return SyncResult(
        success: false,
        itemsSynced: 0,
        itemsFailed: _syncQueue.length,
        error: e.toString(),
      );
    }
  }

  /// Sync individual item (implement actual API calls here)
  Future<bool> _syncItem(PendingSyncItem item, {bool syncImages = false}) async {
    try {
      // TODO: Implement actual sync to backend/Appwrite

      switch (item.type) {
        case SyncItemType.transaction:
          // Sync transaction to backend
          return await _syncTransaction(item.data);

        case SyncItemType.product:
          // Sync product to backend
          return await _syncProduct(item.data, syncImages: syncImages);

        case SyncItemType.inventory:
          // Sync inventory update to backend
          return await _syncInventory(item.data);

        case SyncItemType.customer:
          // Sync customer data to backend
          return await _syncCustomer(item.data);

        case SyncItemType.settings:
          // Sync settings to backend
          return await _syncSettings(item.data);
      }
    } catch (e) {
      print('🔥 Error in _syncItem: $e');
      return false;
    }
  }

  /// Sync transaction to backend
  Future<bool> _syncTransaction(Map<String, dynamic> data) async {
    try {
      // TODO: Implement actual API call to sync transaction
      // For now, simulate success
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      print('🔥 Transaction sync failed: $e');
      return false;
    }
  }

  /// Sync product to backend
  Future<bool> _syncProduct(Map<String, dynamic> data, {bool syncImages = false}) async {
    try {
      // TODO: Implement actual API call to sync product
      // Skip image sync if bandwidth is limited
      if (!syncImages && data.containsKey('image')) {
        data.remove('image');
      }

      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      print('🔥 Product sync failed: $e');
      return false;
    }
  }

  /// Sync inventory to backend
  Future<bool> _syncInventory(Map<String, dynamic> data) async {
    try {
      // TODO: Implement actual API call to sync inventory
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      print('🔥 Inventory sync failed: $e');
      return false;
    }
  }

  /// Sync customer to backend
  Future<bool> _syncCustomer(Map<String, dynamic> data) async {
    try {
      // TODO: Implement actual API call to sync customer
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      print('🔥 Customer sync failed: $e');
      return false;
    }
  }

  /// Sync settings to backend
  Future<bool> _syncSettings(Map<String, dynamic> data) async {
    try {
      // TODO: Implement actual API call to sync settings
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (e) {
      print('🔥 Settings sync failed: $e');
      return false;
    }
  }

  /// Resolve conflict - choose which version to keep
  Future<void> resolveConflict(
    String documentId,
    ConflictResolution strategy, {
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
  }) async {
    try {
      switch (strategy) {
        case ConflictResolution.lastWriteWins:
          // Use the version with the latest timestamp
          final localTime = localData?['updated_at'] as int? ?? 0;
          final remoteTime = remoteData?['updated_at'] as int? ?? 0;

          if (localTime > remoteTime) {
            print('🔄 Conflict: Using local version (last write wins)');
            // Queue local data for sync
          } else {
            print('🔄 Conflict: Using remote version (last write wins)');
            // Update local database with remote data
          }
          break;

        case ConflictResolution.serverWins:
          print('🔄 Conflict: Server version takes precedence');
          // Always use remote data
          break;

        case ConflictResolution.manualReview:
          print('⚠️ Conflict: Manual review required');
          // Queue for manual resolution
          break;
      }
    } catch (e) {
      print('🔥 Error resolving conflict: $e');
      rethrow;
    }
  }

  /// Clear sync queue (use with caution)
  void clearQueue() {
    _syncQueue.clear();
    print('🗑️ Sync queue cleared');
  }

  /// Get pending items by type
  List<PendingSyncItem> getPendingByType(SyncItemType type) {
    return _syncQueue.where((item) => item.type == type).toList();
  }

  /// Export sync queue for debugging
  String exportQueue() {
    return jsonEncode(_syncQueue.map((item) => item.toJson()).toList());
  }
}

/// Pending sync item
class PendingSyncItem {
  final String id;
  final SyncItemType type;
  final Map<String, dynamic> data;
  final SyncPriority priority;
  final DateTime createdAt;
  int retryCount;
  DateTime? lastRetryAt;

  PendingSyncItem({
    required this.id,
    required this.type,
    required this.data,
    required this.priority,
    required this.createdAt,
    required this.retryCount,
    this.lastRetryAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.millisecondsSinceEpoch,
    };
  }
}

/// Sync item types
enum SyncItemType { transaction, product, inventory, customer, settings }

/// Sync priority
enum SyncPriority {
  high(3),
  medium(2),
  low(1);

  final int value;
  const SyncPriority(this.value);
}

/// Conflict resolution strategies
enum ConflictResolution { lastWriteWins, serverWins, manualReview }

/// Sync result
class SyncResult {
  final bool success;
  final int itemsSynced;
  final int itemsFailed;
  final String? error;

  SyncResult({
    required this.success,
    required this.itemsSynced,
    required this.itemsFailed,
    this.error,
  });

  @override
  String toString() {
    if (success) {
      return '✅ Sync successful: $itemsSynced synced, $itemsFailed failed';
    } else {
      return '❌ Sync failed: $error';
    }
  }
}

/// Sync statistics
class SyncStats {
  final int totalQueued;
  final int totalSynced;
  final int totalFailed;
  final DateTime? lastSuccessfulSync;
  final int pendingItems;

  SyncStats({
    required this.totalQueued,
    required this.totalSynced,
    required this.totalFailed,
    this.lastSuccessfulSync,
    required this.pendingItems,
  });

  double get successRate {
    if (totalQueued == 0) return 0.0;
    return (totalSynced / totalQueued) * 100;
  }

  @override
  String toString() {
    return '''
Sync Statistics:
  • Total Queued: $totalQueued
  • Total Synced: $totalSynced
  • Total Failed: $totalFailed
  • Pending: $pendingItems
  • Success Rate: ${successRate.toStringAsFixed(1)}%
  • Last Sync: ${lastSuccessfulSync?.toString() ?? 'Never'}
''';
  }
}
