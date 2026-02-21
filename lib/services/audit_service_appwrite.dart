import 'dart:convert';

import 'package:extropos/models/activity_log_model.dart';
import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:flutter/foundation.dart';

/// Audit Service - Appwrite Version
///
/// Logs all user activities and changes to the activity_logs collection
/// Provides queryable activity history with filtering and analytics
///
/// Automatically logs:
/// - User creation, updates, deletions
/// - Role modifications
/// - Inventory changes
/// - Permission assignments
/// - Failed operations
class AuditServiceAppwrite extends ChangeNotifier {
  static AuditServiceAppwrite? _instance;

  final AppwritePhase1Service _appwrite = AppwritePhase1Service();

  // Local cache for recent activities (last 1000 entries)
  final List<ActivityLogModel> _activityCache = [];
  static const int _maxCacheSize = 1000;

  AuditServiceAppwrite._internal();

  factory AuditServiceAppwrite() {
    _instance ??= AuditServiceAppwrite._internal();
    return _instance!;
  }

  static AuditServiceAppwrite get instance => AuditServiceAppwrite();

  /// Ensure Appwrite is initialized
  Future<bool> ensureInitialized() async {
    if (!_appwrite.isInitialized) {
      return await _appwrite.initialize();
    }
    return true;
  }

  /// Log an activity
  Future<ActivityLogModel> logActivity({
    required String userId,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? changesBefore,
    Map<String, dynamic>? changesAfter,
    bool success = true,
    String? ipAddress,
    String? userAgent,
    String? userName,
  }) async {
    print('📝 Logging activity: $action on $resourceType/$resourceId');

    final now = DateTime.now();
    final log = ActivityLogModel(
      id: _generateLogId(),
      userId: userId,
      userName: userName ?? 'Unknown',
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      changesBefore: changesBefore,
      changesAfter: changesAfter,
      success: success,
      createdAt: now.millisecondsSinceEpoch,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    try {
      await ensureInitialized();

      // If Appwrite disabled, persist locally instead of calling network
      if (!AppwritePhase1Service.isEnabled) {
        await _insertLocalActivity(log);
      } else {
        // Create document in Appwrite
        final docId = log.id ?? _generateLogId();
        await _appwrite.createDocument(
          collectionId: AppwritePhase1Service.activityLogsCol,
          documentId: docId,
          data: {
            'userId': log.userId,
            'action': log.action,
            'resourceType': log.resourceType,
            'resourceId': log.resourceId,
            'changesBefore': log.changesBefore != null
                ? jsonEncode(log.changesBefore)
                : null,
            'changesAfter': log.changesAfter != null
                ? jsonEncode(log.changesAfter)
                : null,
            'success': log.success,
            'createdAt': log.createdAt,
            'ipAddress': log.ipAddress,
            'userAgent': log.userAgent,
            'userName': log.userName,
          },
        );
        // Also persist locally as a copy for offline access
        await _insertLocalActivity(log);
      }

      // Add to cache
      _activityCache.insert(0, log);
      if (_activityCache.length > _maxCacheSize) {
        _activityCache.removeLast();
      }

      notifyListeners();
      print('✅ Activity logged: ${log.id}');
      return log;
    } catch (e) {
      print('❌ Error logging activity: $e');
      // Still add to cache even if Appwrite fails
      _activityCache.insert(0, log);
      if (_activityCache.length > _maxCacheSize) {
        _activityCache.removeLast();
      }
      return log;
    }
  }

  /// Get all activities
  Future<List<ActivityLogModel>> getAllActivities({
    int limit = 100,
    int offset = 0,
  }) async {
    print('📋 Fetching all activities...');
    await ensureInitialized();

    // If Appwrite disabled, read from local DB
    if (!AppwritePhase1Service.isEnabled) {
      try {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.query(
          'user_activity_log',
          orderBy: 'id DESC',
          limit: limit,
          offset: offset,
        );
        return rows.map(_rowToActivityLog).toList();
      } catch (e) {
        print('❌ Local DB error fetching activities: $e');
        return _activityCache.take(limit).toList();
      }
    }

    try {
      final docs = await _appwrite.listDocuments(
        collectionId: AppwritePhase1Service.activityLogsCol,
        limit: limit,
        offset: offset,
      );

      return docs.map(_documentToActivityLog).toList();
    } catch (e) {
      print('❌ Error fetching activities: $e');
      return _activityCache.take(limit).toList();
    }
  }

  /// Get activities by user
  Future<List<ActivityLogModel>> getActivitiesByUser({
    required String userId,
    int limit = 50,
  }) async {
    print('👤 Fetching activities for user: $userId');
    await ensureInitialized();

    try {
      // Use cache first for performance
      final cachedResults = _activityCache
          .where((log) => log.userId == userId)
          .take(limit)
          .toList();

      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }

      // If not in cache, fetch from Appwrite or local DB
      if (!AppwritePhase1Service.isEnabled) {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.query(
          'user_activity_log',
          where: 'user_id = ?',
          whereArgs: [userId],
          orderBy: 'id DESC',
          limit: limit,
        );
        return rows.map(_rowToActivityLog).toList();
      }

      final docs = await _appwrite.listDocuments(
        collectionId: AppwritePhase1Service.activityLogsCol,
        queries: ['userId=$userId'],
        limit: limit,
      );

      return docs.map(_documentToActivityLog).toList();
    } catch (e) {
      print('❌ Error fetching user activities: $e');
      return [];
    }
  }

  /// Get activities by action
  Future<List<ActivityLogModel>> getActivitiesByAction({
    required String action,
    int limit = 50,
  }) async {
    print('🔍 Fetching activities with action: $action');
    await ensureInitialized();

    try {
      final cachedResults = _activityCache
          .where((log) => log.action == action)
          .take(limit)
          .toList();

      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }

      if (!AppwritePhase1Service.isEnabled) {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.query(
          'user_activity_log',
          where: 'activity_type = ?',
          whereArgs: [action],
          orderBy: 'id DESC',
          limit: limit,
        );
        return rows.map(_rowToActivityLog).toList();
      }

      final docs = await _appwrite.listDocuments(
        collectionId: AppwritePhase1Service.activityLogsCol,
        queries: ['action=$action'],
        limit: limit,
      );

      return docs.map(_documentToActivityLog).toList();
    } catch (e) {
      print('❌ Error fetching activities by action: $e');
      return [];
    }
  }

  /// Get activities by resource
  Future<List<ActivityLogModel>> getActivitiesByResource({
    required String resourceType,
    String? resourceId,
    int limit = 50,
  }) async {
    print(
      '📦 Fetching activities for resource: $resourceType${resourceId != null ? '/$resourceId' : ''}',
    );
    await ensureInitialized();

    try {
      final cachedResults = _activityCache
          .where((log) => log.resourceType == resourceType)
          .where((log) => resourceId == null || log.resourceId == resourceId)
          .take(limit)
          .toList();

      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }

      List<String> queries = ['resourceType=$resourceType'];
      if (resourceId != null) {
        queries.add('resourceId=$resourceId');
      }

      if (!AppwritePhase1Service.isEnabled) {
        final db = await DatabaseHelper.instance.database;
        String where = 'resourceType = ?';
        List<dynamic> whereArgs = [resourceType];
        if (resourceId != null) {
          where += ' AND resourceId = ?';
          whereArgs.add(resourceId);
        }
        final rows = await db.query(
          'user_activity_log',
          where: where,
          whereArgs: whereArgs,
          orderBy: 'id DESC',
          limit: limit,
        );
        return rows.map(_rowToActivityLog).toList();
      }

      final docs = await _appwrite.listDocuments(
        collectionId: AppwritePhase1Service.activityLogsCol,
        queries: queries,
        limit: limit,
      );

      return docs.map(_documentToActivityLog).toList();
    } catch (e) {
      print('❌ Error fetching resource activities: $e');
      return [];
    }
  }

  /// Get activities by date range
  Future<List<ActivityLogModel>> getActivitiesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 100,
  }) async {
    print(
      '📅 Fetching activities between ${startDate.toString()} and ${endDate.toString()}',
    );
    await ensureInitialized();

    try {
      final startMs = startDate.millisecondsSinceEpoch;
      final endMs = endDate.millisecondsSinceEpoch;

      // Filter cache first
        final cachedResults = _activityCache
          .where((log) => log.createdAt >= startMs && log.createdAt <= endMs)
          .take(limit)
          .toList();

      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }

      if (!AppwritePhase1Service.isEnabled) {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.query(
          'user_activity_log',
          orderBy: 'id DESC',
          limit: limit,
        );
        return rows.map(_rowToActivityLog).where((log) => log.createdAt >= startMs && log.createdAt <= endMs).toList();
      }

      // Query Appwrite (timestamp-based queries may vary by backend)
      final docs = await _appwrite.listDocuments(
        collectionId: AppwritePhase1Service.activityLogsCol,
        limit: limit,
      );

      return docs
        .map(_documentToActivityLog)
        .where((log) => log.createdAt >= startMs && log.createdAt <= endMs)
        .toList();
    } catch (e) {
      print('❌ Error fetching activities by date range: $e');
      return [];
    }
  }

  /// Get failed activities
  Future<List<ActivityLogModel>> getFailedActivities({int limit = 50}) async {
    print('❌ Fetching failed activities...');
    await ensureInitialized();

    try {
      final cachedResults = _activityCache
          .where((log) => !log.success)
          .take(limit)
          .toList();

      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }

      if (!AppwritePhase1Service.isEnabled) {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.query(
          'user_activity_log',
          where: '1=1',
          orderBy: 'id DESC',
          limit: limit,
        );
        return rows.map(_rowToActivityLog).where((r) => !r.success).toList();
      }

      final docs = await _appwrite.listDocuments(
        collectionId: AppwritePhase1Service.activityLogsCol,
        queries: ['success=false'],
        limit: limit,
      );

      return docs.map(_documentToActivityLog).toList();
    } catch (e) {
      print('❌ Error fetching failed activities: $e');
      return [];
    }
  }

  // Insert activity into local SQLite table `user_activity_log`
  Future<void> _insertLocalActivity(ActivityLogModel log) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('user_activity_log', {
        'user_id': log.userId,
        'activity_type': log.action,
        'description': jsonEncode({
          'resourceType': log.resourceType,
          'resourceId': log.resourceId,
          'changesBefore': log.changesBefore,
          'changesAfter': log.changesAfter,
          'userName': log.userName,
        }),
        'order_id': log.resourceId,
        'amount': 0.0,
        'payment_method': null,
        'discount_amount': 0.0,
        'tax_amount': 0.0,
        'tax_rate': 0.0,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(log.createdAt).toIso8601String(),
      });
    } catch (e) {
      print('⚠️ Failed to persist activity locally: $e');
    }
  }

  // Convert local DB row to ActivityLogModel
  ActivityLogModel _rowToActivityLog(Map<String, dynamic> row) {
    int createdAtMs = 0;
    try {
      final ts = row['timestamp']?.toString();
      if (ts != null && ts.isNotEmpty) {
        createdAtMs = DateTime.parse(ts).millisecondsSinceEpoch;
      }
    } catch (_) {
      createdAtMs = 0;
    }

    Map<String, dynamic>? parsedDesc;
    try {
      if (row['description'] != null) {
        parsedDesc = jsonDecode(row['description']);
      }
    } catch (_) {
      parsedDesc = null;
    }

    return ActivityLogModel(
      id: (row['id'] ?? '').toString(),
      userId: row['user_id']?.toString() ?? '',
      userName: parsedDesc != null ? (parsedDesc['userName'] ?? 'Unknown') : 'Unknown',
      action: row['activity_type']?.toString() ?? '',
      resourceType: parsedDesc != null ? (parsedDesc['resourceType'] ?? '') : '',
      resourceId: parsedDesc != null ? (parsedDesc['resourceId'] ?? '') : '',
      changesBefore: parsedDesc != null ? (parsedDesc['changesBefore'] as Map<String, dynamic>?) : null,
      changesAfter: parsedDesc != null ? (parsedDesc['changesAfter'] as Map<String, dynamic>?) : null,
      success: true,
      createdAt: createdAtMs,
      ipAddress: null,
      userAgent: null,
    );
  }

  /// Get activity statistics
  Future<Map<String, dynamic>> getStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    print('📊 Calculating activity statistics...');

    try {
      final activities = await getActivitiesByDateRange(
        startDate: startDate,
        endDate: endDate,
        limit: 1000,
      );

      final totalActivities = activities.length;
      final successfulActivities =
          activities.where((log) => log.success).length;
      final failedActivities = activities.where((log) => !log.success).length;

      // Count by action
      final actionCounts = <String, int>{};
      for (final log in activities) {
        actionCounts[log.action] = (actionCounts[log.action] ?? 0) + 1;
      }

      // Count by resource type
      final resourceCounts = <String, int>{};
      for (final log in activities) {
        resourceCounts[log.resourceType] =
            (resourceCounts[log.resourceType] ?? 0) + 1;
      }

      // Count by user
      final userCounts = <String, int>{};
      for (final log in activities) {
        userCounts[log.userId] = (userCounts[log.userId] ?? 0) + 1;
      }

      return {
        'totalActivities': totalActivities,
        'successfulActivities': successfulActivities,
        'failedActivities': failedActivities,
        'successRate': totalActivities > 0
            ? (successfulActivities / totalActivities * 100).toStringAsFixed(2)
            : '0.00',
        'actionCounts': actionCounts,
        'resourceCounts': resourceCounts,
        'userCounts': userCounts,
        'topActions': actionCounts.entries
            .toList()
            .asMap()
            .entries
            .toList()
            .take(5)
            .map((e) => {'action': e.value.key, 'count': e.value.value})
            .toList(),
      };
    } catch (e) {
      print('❌ Error calculating statistics: $e');
      return {};
    }
  }

  /// Convert Appwrite document to ActivityLogModel
  ActivityLogModel _documentToActivityLog(Map<String, dynamic> doc) {
    Map<String, dynamic>? changesBefore;
    Map<String, dynamic>? changesAfter;

    if (doc['changesBefore'] != null && doc['changesBefore'].isNotEmpty) {
      try {
        changesBefore = jsonDecode(doc['changesBefore']);
      } catch (e) {
        print('⚠️ Error parsing changesBefore: $e');
      }
    }

    if (doc['changesAfter'] != null && doc['changesAfter'].isNotEmpty) {
      try {
        changesAfter = jsonDecode(doc['changesAfter']);
      } catch (e) {
        print('⚠️ Error parsing changesAfter: $e');
      }
    }

    return ActivityLogModel(
      id: doc[r'$id'] ?? doc['id'] ?? '',
      userId: doc['userId'] ?? '',
      userName: doc['userName'] ?? 'Unknown',
      action: doc['action'] ?? '',
      resourceType: doc['resourceType'] ?? '',
      resourceId: doc['resourceId'] ?? '',
      changesBefore: changesBefore,
      changesAfter: changesAfter,
      success: doc['success'] ?? false,
      createdAt: doc['createdAt'] ?? 0,
      ipAddress: doc['ipAddress'],
      userAgent: doc['userAgent'],
    );
  }

  /// Generate unique log ID
  String _generateLogId() {
    return 'log_${DateTime.now().millisecondsSinceEpoch}_${_activityCache.length}';
  }

  /// Clear cache
  void clearCache() {
    _activityCache.clear();
  }

  /// Get cached activities (for immediate display)
  List<ActivityLogModel> getCachedActivities({int limit = 50}) {
    return _activityCache.take(limit).toList();
  }

  @override
  void dispose() {
    _activityCache.clear();
    super.dispose();
  }
}
