/// Sync item types queued while operating offline.
enum SyncItemType { transaction, product, inventory, customer, settings }

/// Priority of queued sync operations.
enum SyncPriority {
  high(3),
  medium(2),
  low(1);

  final int value;
  const SyncPriority(this.value);
}

/// Conflict resolution strategies for future cloud sync.
enum ConflictResolution { lastWriteWins, serverWins, manualReview }

/// Pending item stored in local sync queue.
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
      'data': data,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.millisecondsSinceEpoch,
    };
  }
}

/// Result of one sync run.
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
      return 'Sync successful: $itemsSynced synced, $itemsFailed failed';
    }
    return 'Sync failed: $error';
  }
}

/// Aggregate queue and sync health stats.
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
}
