/// Activity Log Model for Audit Trail
class ActivityLogModel {
  final String? id; // Appwrite document ID
  final String userId; // Who performed the action
  final String userName; // Cached user display name
  final String action; // e.g., 'create_user', 'update_product', 'delete_role'
  final String resourceType; // e.g., 'user', 'product', 'role', 'inventory'
  final String? resourceId; // ID of the affected resource
  final String? resourceName; // Name/title of the affected resource (cached for display)
  final String? description; // Human-readable description
  final Map<String, dynamic>? changesBefore; // Previous values (JSON)
  final Map<String, dynamic>? changesAfter; // New values (JSON)
  final String? ipAddress; // User's IP address
  final String? userAgent; // Browser/app user agent
  final bool success; // Whether the operation was successful
  final String? errorMessage; // If success=false, error details
  final int createdAt; // When the action occurred
  final String? locationId; // Which location/branch was affected

  ActivityLogModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.resourceType,
    this.resourceId,
    this.resourceName,
    this.description,
    this.changesBefore,
    this.changesAfter,
    this.ipAddress,
    this.userAgent,
    this.success = true,
    this.errorMessage,
    required this.createdAt,
    this.locationId,
  });

  /// Create a copy with modified fields
  ActivityLogModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? action,
    String? resourceType,
    String? resourceId,
    String? resourceName,
    String? description,
    Map<String, dynamic>? changesBefore,
    Map<String, dynamic>? changesAfter,
    String? ipAddress,
    String? userAgent,
    bool? success,
    String? errorMessage,
    int? createdAt,
    String? locationId,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      action: action ?? this.action,
      resourceType: resourceType ?? this.resourceType,
      resourceId: resourceId ?? this.resourceId,
      resourceName: resourceName ?? this.resourceName,
      description: description ?? this.description,
      changesBefore: changesBefore ?? this.changesBefore,
      changesAfter: changesAfter ?? this.changesAfter,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      locationId: locationId ?? this.locationId,
    );
  }

  /// Convert to JSON for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'action': action,
      'resourceType': resourceType,
      'resourceId': resourceId,
      'resourceName': resourceName,
      'description': description,
      'changesBefore': changesBefore,
      'changesAfter': changesAfter,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'success': success,
      'errorMessage': errorMessage,
      'createdAt': createdAt,
      'locationId': locationId,
    };
  }

  /// Create from JSON from Appwrite
  factory ActivityLogModel.fromMap(Map<String, dynamic> map) {
    return ActivityLogModel(
      id: map['\$id'] as String?,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Unknown',
      action: map['action'] as String? ?? '',
      resourceType: map['resourceType'] as String? ?? '',
      resourceId: map['resourceId'] as String?,
      resourceName: map['resourceName'] as String?,
      description: map['description'] as String?,
      changesBefore: map['changesBefore'] as Map<String, dynamic>?,
      changesAfter: map['changesAfter'] as Map<String, dynamic>?,
      ipAddress: map['ipAddress'] as String?,
      userAgent: map['userAgent'] as String?,
      success: map['success'] as bool? ?? true,
      errorMessage: map['errorMessage'] as String?,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      locationId: map['locationId'] as String?,
    );
  }

  /// Get a human-readable summary of changes
  String getChangesSummary() {
    if (changesBefore == null || changesAfter == null) {
      return description ?? action;
    }

    final changes = <String>[];
    changesAfter?.forEach((key, newValue) {
      final oldValue = changesBefore?[key];
      if (oldValue != newValue) {
        changes.add('$key: $oldValue → $newValue');
      }
    });

    return changes.isNotEmpty ? changes.join(', ') : 'No changes tracked';
  }

  /// Get action display name
  String getActionDisplay() {
    switch (action) {
      case 'create_user':
        return 'Created User';
      case 'update_user':
        return 'Updated User';
      case 'delete_user':
        return 'Deleted User';
      case 'create_role':
        return 'Created Role';
      case 'update_role':
        return 'Updated Role';
      case 'delete_role':
        return 'Deleted Role';
      case 'adjust_stock':
        return 'Adjusted Stock';
      case 'record_sale':
        return 'Recorded Sale';
      case 'create_product':
        return 'Created Product';
      case 'update_product':
        return 'Updated Product';
      case 'delete_product':
        return 'Deleted Product';
      case 'login':
        return 'Logged In';
      case 'logout':
        return 'Logged Out';
      case 'failed_login':
        return 'Failed Login Attempt';
      default:
        return action;
    }
  }

  /// Get resource type display name
  String getResourceTypeDisplay() {
    switch (resourceType) {
      case 'user':
        return 'User';
      case 'role':
        return 'Role';
      case 'product':
        return 'Product';
      case 'inventory':
        return 'Inventory';
      case 'stock_movement':
        return 'Stock Movement';
      default:
        return resourceType;
    }
  }

  /// Get status color (for UI)
  String getStatusColor() {
    if (!success) return 'red';
    if (action.contains('delete')) return 'orange';
    return 'green';
  }

  /// Format timestamp for display
  String getFormattedDate() {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() => 'ActivityLogModel(id: $id, action: $action, resourceType: $resourceType, success: $success)';

  /// Create a test activity log entry
  static ActivityLogModel createTestEntry({
    String userId = 'user_1',
    String userName = 'Admin User',
    String action = 'create_user',
    String resourceType = 'user',
    String? resourceId = 'user_2',
    String? resourceName = 'New User',
  }) {
    return ActivityLogModel(
      userId: userId,
      userName: userName,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      resourceName: resourceName,
      description: '$action - $resourceName',
      success: true,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
