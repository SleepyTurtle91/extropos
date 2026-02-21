
/// User Model for Backend User Management System
/// This is BACKEND-specific, separate from POS User model
class BackendUserModel {
  final String? id; // Appwrite document ID
  final String email;
  final String displayName;
  final String? phone;
  final String roleId; // Reference to RoleModel.id
  final String? roleName; // Cached role name for display
  final List<String> locationIds; // For multi-location access
  final bool isActive;
  final String? lastLoginAt; // ISO8601 timestamp
  final int createdAt;
  final int updatedAt;
  final String? createdBy; // User ID who created this user
  final String? updatedBy; // User ID who last updated this user
  final bool isLockedOut; // Account locked due to too many failed attempts
  final int? failedLoginAttempts;

  BackendUserModel({
    this.id,
    required this.email,
    required this.displayName,
    this.phone,
    required this.roleId,
    this.roleName,
    required this.locationIds,
    this.isActive = true,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.isLockedOut = false,
    this.failedLoginAttempts = 0,
  });

  /// Create a copy with modified fields
  BackendUserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    String? roleId,
    String? roleName,
    List<String>? locationIds,
    bool? isActive,
    String? lastLoginAt,
    int? createdAt,
    int? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isLockedOut,
    int? failedLoginAttempts,
  }) {
    return BackendUserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      locationIds: locationIds ?? this.locationIds,
      isActive: isActive ?? this.isActive,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isLockedOut: isLockedOut ?? this.isLockedOut,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
    );
  }

  /// Convert to JSON for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'roleId': roleId,
      'roleName': roleName,
      'locationIds': locationIds,
      'isActive': isActive,
      'lastLoginAt': lastLoginAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isLockedOut': isLockedOut,
      'failedLoginAttempts': failedLoginAttempts,
    };
  }

  /// Create from JSON from Appwrite
  factory BackendUserModel.fromMap(Map<String, dynamic> map) {
    return BackendUserModel(
      id: map['\$id'] as String?,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      phone: map['phone'] as String?,
      roleId: map['roleId'] as String? ?? '',
      roleName: map['roleName'] as String?,
      locationIds: List<String>.from(map['locationIds'] as List<dynamic>? ?? []),
      isActive: map['isActive'] as bool? ?? true,
      lastLoginAt: map['lastLoginAt'] as String?,
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      createdBy: map['createdBy'] as String?,
      updatedBy: map['updatedBy'] as String?,
      isLockedOut: map['isLockedOut'] as bool? ?? false,
      failedLoginAttempts: map['failedLoginAttempts'] as int? ?? 0,
    );
  }

  /// Check if user can access a specific location
  bool canAccessLocation(String locationId) {
    return locationIds.contains(locationId);
  }

  /// Check if user can access all locations
  bool hasAccessToAllLocations() {
    return locationIds.isEmpty || locationIds.contains('*');
  }

  /// Get user status for display
  String getStatus() {
    if (isLockedOut) return 'Locked Out';
    if (!isActive) return 'Inactive';
    return 'Active';
  }

  /// Check if user is currently active (not locked, not inactive)
  bool get isCurrentlyActive => isActive && !isLockedOut;

  @override
  String toString() => 'BackendUserModel(id: $id, email: $email, displayName: $displayName, roleId: $roleId)';

  /// Create a test user
  static BackendUserModel createTestUser({
    String email = 'test@example.com',
    String displayName = 'Test User',
    String roleId = 'admin',
    String? roleName = 'Admin',
    List<String>? locationIds,
  }) {
    return BackendUserModel(
      email: email,
      displayName: displayName,
      roleId: roleId,
      roleName: roleName,
      locationIds: locationIds ?? [],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
