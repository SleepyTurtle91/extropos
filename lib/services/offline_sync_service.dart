import 'dart:async';
import 'dart:convert';

import 'package:extropos/services/offline_sync_models.dart';
import 'package:extropos/services/offline_sync_storage_service.dart';

/// Offline-first sync queue with persistent SQLite storage.
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();

  factory OfflineSyncService() => _instance;

  OfflineSyncService._internal();

  final OfflineSyncStorageService _storage = OfflineSyncStorageService();
  final List<PendingSyncItem> _syncQueue = [];

  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSuccessfulSync;

  int _totalQueued = 0;
  int _totalSynced = 0;
  int _totalFailed = 0;

  bool get hasPendingSync => _syncQueue.isNotEmpty;
  int get queueSize => _syncQueue.length;

  SyncStats get stats => SyncStats(
    totalQueued: _totalQueued,
    totalSynced: _totalSynced,
    totalFailed: _totalFailed,
    lastSuccessfulSync: _lastSuccessfulSync,
    pendingItems: _syncQueue.length,
  );

  Future<void> initialize() async {
    if (_isInitialized) return;
    await _storage.initialize();
    await _loadQueueFromStorage();
    await _loadStatsFromStorage();
    _isInitialized = true;
  }

  // Reset for tests: clears the singleton state and reloads from storage
  Future<void> resetForTests() async {
    _isInitialized = false;
    _isSyncing = false;
    _lastSuccessfulSync = null;
    _totalQueued = 0;
    _totalSynced = 0;
    _totalFailed = 0;
    await initialize();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> queueTransaction(Map<String, dynamic> transactionData) async {
    await _queueItem(
      type: SyncItemType.transaction,
      data: transactionData,
      priority: SyncPriority.high,
    );
  }

  Future<void> queueProduct(Map<String, dynamic> productData) async {
    await _queueItem(
      type: SyncItemType.product,
      data: productData,
      priority: SyncPriority.medium,
    );
  }

  Future<void> queueInventoryUpdate(Map<String, dynamic> inventoryData) async {
    await _queueItem(
      type: SyncItemType.inventory,
      data: inventoryData,
      priority: SyncPriority.high,
    );
  }

  Future<void> _queueItem({
    required SyncItemType type,
    required Map<String, dynamic> data,
    required SyncPriority priority,
  }) async {
    await _ensureInitialized();

    final now = DateTime.now();
    final item = PendingSyncItem(
      id: 'sync_${now.microsecondsSinceEpoch}',
      type: type,
      data: Map<String, dynamic>.from(data),
      priority: priority,
      createdAt: now,
      retryCount: 0,
    );

    _syncQueue.add(item);
    await _persistQueueItem(item);

    _totalQueued++;
    await _storage.updateStats(queuedDelta: 1);
  }

  Future<SyncResult> smartSync({
    bool syncImages = false,
    int maxRetries = 3,
  }) async {
    await _ensureInitialized();

    if (_isSyncing) {
      return SyncResult(
        success: false,
        itemsSynced: 0,
        itemsFailed: 0,
        error: 'Sync already in progress',
      );
    }

    _isSyncing = true;

    try {
      await _loadQueueFromStorage();
      _syncQueue.sort((a, b) => b.priority.value.compareTo(a.priority.value));

      int synced = 0;
      int failed = 0;

      for (final item in List<PendingSyncItem>.from(_syncQueue)) {
        try {
          if (item.retryCount >= maxRetries) {
            _syncQueue.remove(item);
            await _storage.removeQueueItem(item.id);
            failed++;
            _totalFailed++;
            await _storage.updateStats(failedDelta: 1);
            continue;
          }

          final success = await _syncItem(item, syncImages: syncImages);
          if (success) {
            _syncQueue.remove(item);
            await _storage.removeQueueItem(item.id);
            synced++;
            _totalSynced++;
            await _storage.updateStats(syncedDelta: 1);
          } else {
            item.retryCount++;
            item.lastRetryAt = DateTime.now();
            await _storage.updateQueueItemRetry(
              id: item.id,
              retryCount: item.retryCount,
              lastRetryAt: item.lastRetryAt?.millisecondsSinceEpoch,
            );
            failed++;
          }

          await Future.delayed(const Duration(milliseconds: 100));
        } catch (_) {
          item.retryCount++;
          item.lastRetryAt = DateTime.now();
          await _storage.updateQueueItemRetry(
            id: item.id,
            retryCount: item.retryCount,
            lastRetryAt: item.lastRetryAt?.millisecondsSinceEpoch,
          );
          failed++;
        }
      }

      if (synced > 0) {
        _lastSuccessfulSync = DateTime.now();
        await _storage.updateStats(
          lastSuccessfulSync: _lastSuccessfulSync!.millisecondsSinceEpoch,
        );
      }

      return SyncResult(
        success: failed == 0,
        itemsSynced: synced,
        itemsFailed: failed,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        itemsSynced: 0,
        itemsFailed: _syncQueue.length,
        error: e.toString(),
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _syncItem(
    PendingSyncItem item, {
    bool syncImages = false,
  }) async {
    switch (item.type) {
      case SyncItemType.transaction:
        return _syncTransaction(item.data);
      case SyncItemType.product:
        return _syncProduct(item.data, syncImages: syncImages);
      case SyncItemType.inventory:
        return _syncInventory(item.data);
      case SyncItemType.customer:
        return _syncCustomer(item.data);
      case SyncItemType.settings:
        return _syncSettings(item.data);
    }
  }

  Future<bool> _syncTransaction(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _syncProduct(
    Map<String, dynamic> data, {
    bool syncImages = false,
  }) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if (!syncImages && payload.containsKey('image')) {
        payload.remove('image');
      }
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _syncInventory(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _syncCustomer(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _syncSettings(Map<String, dynamic> data) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resolveConflict(
    String documentId,
    ConflictResolution strategy, {
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
  }) async {
    switch (strategy) {
      case ConflictResolution.lastWriteWins:
        final localTime = localData?['updated_at'] as int? ?? 0;
        final remoteTime = remoteData?['updated_at'] as int? ?? 0;
        if (localTime > remoteTime) {
          return;
        }
        return;
      case ConflictResolution.serverWins:
        return;
      case ConflictResolution.manualReview:
        return;
    }
  }

  Future<void> clearQueue() async {
    await _ensureInitialized();
    _syncQueue.clear();
    await _storage.clearQueue();
    // Reset stats counters
    _totalQueued = 0;
    _totalSynced = 0;
    _totalFailed = 0;
  }

  List<PendingSyncItem> getPendingByType(SyncItemType type) {
    return _syncQueue.where((item) => item.type == type).toList();
  }

  String exportQueue() {
    return jsonEncode(_syncQueue.map((item) => item.toJson()).toList());
  }

  Future<void> _persistQueueItem(PendingSyncItem item) async {
    await _storage.upsertQueueItem(
      id: item.id,
      type: item.type.name,
      priority: item.priority.value,
      data: jsonEncode(item.data),
      retryCount: item.retryCount,
      lastRetryAt: item.lastRetryAt?.millisecondsSinceEpoch,
      createdAt: item.createdAt.millisecondsSinceEpoch,
    );
  }

  Future<void> _loadQueueFromStorage() async {
    final rows = await _storage.getQueueItems();
    _syncQueue
      ..clear()
      ..addAll(rows.map(_mapQueueRowToItem));
  }

  PendingSyncItem _mapQueueRowToItem(Map<String, dynamic> row) {
    final typeName = (row['type'] as String? ?? '').trim();
    final priorityValue = (row['priority'] as int?) ?? 2;

    SyncItemType parsedType = SyncItemType.settings;
    for (final value in SyncItemType.values) {
      if (value.name == typeName) {
        parsedType = value;
        break;
      }
    }

    SyncPriority parsedPriority = SyncPriority.medium;
    for (final value in SyncPriority.values) {
      if (value.value == priorityValue) {
        parsedPriority = value;
        break;
      }
    }

    final rawData = row['data'] as String? ?? '{}';
    Map<String, dynamic> decodedData = <String, dynamic>{};
    try {
      final dynamic parsed = jsonDecode(rawData);
      if (parsed is Map<String, dynamic>) {
        decodedData = parsed;
      }
    } catch (_) {
      decodedData = <String, dynamic>{};
    }

    return PendingSyncItem(
      id: row['id'] as String,
      type: parsedType,
      data: decodedData,
      priority: parsedPriority,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (row['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      retryCount: (row['retry_count'] as int?) ?? 0,
      lastRetryAt: (row['last_retry_at'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(row['last_retry_at'] as int)
          : null,
    );
  }

  Future<void> _loadStatsFromStorage() async {
    final row = await _storage.getStatsRow();
    _totalQueued = (row['total_queued'] as int?) ?? 0;
    _totalSynced = (row['total_synced'] as int?) ?? 0;
    _totalFailed = (row['total_failed'] as int?) ?? 0;

    final syncTs = row['last_successful_sync'] as int?;
    _lastSuccessfulSync = syncTs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(syncTs);
  }
}
