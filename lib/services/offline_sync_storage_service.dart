import 'package:extropos/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Persists offline sync queue and statistics in SQLite.
class OfflineSyncStorageService {
  static final OfflineSyncStorageService _instance =
      OfflineSyncStorageService._internal();

  factory OfflineSyncStorageService() => _instance;

  OfflineSyncStorageService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final db = await DatabaseHelper.instance.database;
    await _ensureTables(db);
    _isInitialized = true;
  }

  Future<void> _ensureTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        priority INTEGER DEFAULT 2,
        data TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        last_retry_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_stats (
        id INTEGER PRIMARY KEY,
        total_queued INTEGER DEFAULT 0,
        total_synced INTEGER DEFAULT 0,
        total_failed INTEGER DEFAULT 0,
        last_successful_sync INTEGER,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_priority ON sync_queue(priority)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_created ON sync_queue(created_at)',
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('sync_stats', {
      'id': 1,
      'total_queued': 0,
      'total_synced': 0,
      'total_failed': 0,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> upsertQueueItem({
    required String id,
    required String type,
    required int priority,
    required String data,
    required int retryCount,
    int? lastRetryAt,
    required int createdAt,
  }) async {
    await initialize();
    final db = await DatabaseHelper.instance.database;
    await db.insert('sync_queue', {
      'id': id,
      'type': type,
      'priority': priority,
      'data': data,
      'retry_count': retryCount,
      'last_retry_at': lastRetryAt,
      'created_at': createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getQueueItems() async {
    await initialize();
    final db = await DatabaseHelper.instance.database;
    return db.query('sync_queue', orderBy: 'priority DESC, created_at ASC');
  }

  Future<void> updateQueueItemRetry({
    required String id,
    required int retryCount,
    int? lastRetryAt,
  }) async {
    await initialize();
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'sync_queue',
      {
        'retry_count': retryCount,
        'last_retry_at': lastRetryAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> removeQueueItem(String id) async {
    await initialize();
    final db = await DatabaseHelper.instance.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearQueue() async {
    await initialize();
    final db = await DatabaseHelper.instance.database;
    await db.delete('sync_queue');
  }

  Future<int> getPendingCount() async {
    await initialize();
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM sync_queue',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<Map<String, dynamic>> getStatsRow() async {
    await initialize();
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('sync_stats', where: 'id = ?', whereArgs: [1]);
    if (rows.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      return {
        'id': 1,
        'total_queued': 0,
        'total_synced': 0,
        'total_failed': 0,
        'last_successful_sync': null,
        'updated_at': now,
      };
    }
    return rows.first;
  }

  Future<void> updateStats({
    int queuedDelta = 0,
    int syncedDelta = 0,
    int failedDelta = 0,
    int? lastSuccessfulSync,
  }) async {
    await initialize();
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.rawUpdate(
      '''
      UPDATE sync_stats
      SET total_queued = MAX(0, total_queued + ?),
          total_synced = MAX(0, total_synced + ?),
          total_failed = MAX(0, total_failed + ?),
          last_successful_sync = COALESCE(?, last_successful_sync),
          updated_at = ?
      WHERE id = 1
      ''',
      [queuedDelta, syncedDelta, failedDelta, lastSuccessfulSync, now],
    );
  }
}
