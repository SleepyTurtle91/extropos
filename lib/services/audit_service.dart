import 'package:extropos/models/activity_log_model.dart';
import 'package:flutter/foundation.dart';

/// Audit Service for Activity Logging
/// Logs all user actions for compliance and debugging
class AuditService extends ChangeNotifier {
  static AuditService? _instance;

  // In-memory storage (in Phase 2, this will use Appwrite)
  final List<ActivityLogModel> _activityLogs = [];

  AuditService._internal();

  factory AuditService() {
    _instance ??= AuditService._internal();
    return _instance!;
  }

  static AuditService get instance => AuditService();

  /// Valid action types
  static const List<String> _validActions = [
    'CREATE', 'UPDATE', 'DELETE', 'LOGIN', 'LOGOUT',
    'VIEW', 'EXPORT', 'IMPORT', 'LOCK', 'UNLOCK',
    'ACTIVATE', 'DEACTIVATE', 'RESET_PASSWORD', 'CHANGE_ROLE',
    'STOCK_MOVEMENT', 'ADJUST_INVENTORY', 'REORDER',
  ];

  /// Valid resource types
  static const List<String> _validResourceTypes = [
    'User', 'Role', 'Product', 'Category', 'Modifier',
    'Inventory', 'Transaction', 'Report', 'Settings',
    'BusinessInfo', 'Table', 'Order',
  ];

  /// Log an activity
  Future<ActivityLogModel> logActivity({
    required String userId,
    required String userName,
    required String action,
    required String resourceType,
    String? resourceId,
    String? resourceName,
    String? description,
    Map<String, dynamic>? changesBefore,
    Map<String, dynamic>? changesAfter,
    String? ipAddress,
    String? userAgent,
    bool success = true,
    String? errorMessage,
    String? locationId,
  }) async {
    // Validate action
    if (!_validActions.contains(action)) {
      throw Exception('Invalid action: $action. Must be one of: ${_validActions.join(", ")}');
    }

    // Validate resource type
    if (!_validResourceTypes.contains(resourceType)) {
      throw Exception('Invalid resourceType: $resourceType. Must be one of: ${_validResourceTypes.join(", ")}');
    }

    print('📝 Logging activity: $action by $userName');

    final log = ActivityLogModel(
      userId: userId,
      userName: userName,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      resourceName: resourceName,
      description: description ?? '$action on $resourceType',
      changesBefore: changesBefore,
      changesAfter: changesAfter,
      ipAddress: ipAddress,
      userAgent: userAgent,
      success: success,
      errorMessage: errorMessage,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      locationId: locationId,
    );

    _activityLogs.add(log);
    print('✅ Activity logged: ${log.getActionDisplay()}');
    notifyListeners();
    return log;
  }

  /// Get all activity logs
  Future<List<ActivityLogModel>> getAllActivityLogs() async {
    print('📋 Fetching all activity logs...');
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_activityLogs.reversed); // Return newest first
  }

  /// Get recent activity logs
  Future<List<ActivityLogModel>> getRecentActivityLogs({int limit = 50}) async {
    print('📋 Fetching recent activity logs (limit: $limit)...');
    await Future.delayed(const Duration(milliseconds: 100));
    final reversed = List.from(_activityLogs.reversed);
    return reversed.take(limit).toList() as List<ActivityLogModel>;
  }

  /// Filter activity logs by date range
  Future<List<ActivityLogModel>> filterByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    print('🔍 Filtering activity logs: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');
    await Future.delayed(const Duration(milliseconds: 100));

    final startMs = startDate.millisecondsSinceEpoch;
    final endMs = endDate.millisecondsSinceEpoch;

    return _activityLogs
        .where((log) => log.createdAt >= startMs && log.createdAt <= endMs)
        .toList();
  }

  /// Filter activity logs by user
  Future<List<ActivityLogModel>> filterByUser(String userId) async {
    print('🔍 Filtering activity logs for user: $userId');
    await Future.delayed(const Duration(milliseconds: 100));
    return _activityLogs.where((log) => log.userId == userId).toList();
  }

  /// Filter activity logs by action
  Future<List<ActivityLogModel>> filterByAction(String action) async {
    print('🔍 Filtering activity logs by action: $action');
    await Future.delayed(const Duration(milliseconds: 100));
    return _activityLogs.where((log) => log.action == action).toList();
  }

  /// Filter activity logs by resource type
  Future<List<ActivityLogModel>> filterByResourceType(String resourceType) async {
    print('🔍 Filtering activity logs by resource type: $resourceType');
    await Future.delayed(const Duration(milliseconds: 100));
    return _activityLogs.where((log) => log.resourceType == resourceType).toList();
  }

  /// Filter failed activities only
  Future<List<ActivityLogModel>> getFailedActivities() async {
    print('🔍 Fetching failed activities...');
    await Future.delayed(const Duration(milliseconds: 100));
    return _activityLogs.where((log) => !log.success).toList();
  }

  /// Get activity logs for a specific resource
  Future<List<ActivityLogModel>> getResourceHistory(String resourceId) async {
    print('🔍 Fetching history for resource: $resourceId');
    await Future.delayed(const Duration(milliseconds: 100));
    return _activityLogs
        .where((log) => log.resourceId == resourceId)
        .toList();
  }

  /// Get total activity count
  Future<int> getTotalActivityCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _activityLogs.length;
  }

  /// Get activity count for a specific user
  Future<int> getUserActivityCount(String userId) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _activityLogs.where((log) => log.userId == userId).length;
  }

  /// Get activity statistics
  Future<Map<String, dynamic>> getActivityStatistics() async {
    print('📊 Calculating activity statistics...');
    await Future.delayed(const Duration(milliseconds: 200));

    final totalCount = _activityLogs.length;
    final successCount = _activityLogs.where((log) => log.success).length;
    final failureCount = _activityLogs.where((log) => !log.success).length;

    // Count by action
    final actionCount = <String, int>{};
    for (var log in _activityLogs) {
      actionCount[log.action] = (actionCount[log.action] ?? 0) + 1;
    }

    // Count by resource type
    final resourceCount = <String, int>{};
    for (var log in _activityLogs) {
      resourceCount[log.resourceType] = (resourceCount[log.resourceType] ?? 0) + 1;
    }

    // Get most active users
    final userCount = <String, int>{};
    for (var log in _activityLogs) {
      userCount[log.userId] = (userCount[log.userId] ?? 0) + 1;
    }
    final topUsers = userCount.entries
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'totalActivities': totalCount,
      'successCount': successCount,
      'failureCount': failureCount,
      'successRate': totalCount > 0 ? (successCount / totalCount * 100).toStringAsFixed(2) : '0',
      'activitiesByAction': actionCount,
      'activitiesByResourceType': resourceCount,
      'topUsers': topUsers.take(5).map((e) => {'userId': e.key, 'count': e.value}).toList(),
    };
  }

  /// Export logs to JSON
  Future<List<Map<String, dynamic>>> exportLogsAsJson() async {
    print('📤 Exporting activity logs as JSON...');
    await Future.delayed(const Duration(milliseconds: 100));
    return _activityLogs.map((log) => log.toMap()).toList();
  }

  /// Clear all logs (for testing only)
  void _clearAllLogs() {
    _activityLogs.clear();
    notifyListeners();
  }

  @override
  String toString() => 'AuditService(totalLogs: ${_activityLogs.length})';
}
