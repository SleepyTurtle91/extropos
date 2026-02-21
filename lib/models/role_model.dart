
/// Permission levels for the RBAC system
class Permission {
  static const String VIEW_USERS = 'view_users';
  static const String CREATE_USERS = 'create_users';
  static const String EDIT_USERS = 'edit_users';
  static const String DELETE_USERS = 'delete_users';
  
  static const String VIEW_ROLES = 'view_roles';
  static const String CREATE_ROLES = 'create_roles';
  static const String EDIT_ROLES = 'edit_roles';
  static const String DELETE_ROLES = 'delete_roles';
  
  static const String VIEW_INVENTORY = 'view_inventory';
  static const String ADJUST_INVENTORY = 'adjust_inventory';
  static const String VIEW_STOCK_MOVEMENTS = 'view_stock_movements';
  
  static const String VIEW_ACTIVITY_LOG = 'view_activity_log';
  static const String EXPORT_ACTIVITY_LOG = 'export_activity_log';
  
  static const String VIEW_REPORTS = 'view_reports';
  static const String EXPORT_REPORTS = 'export_reports';
  
  static const String MANAGE_PRODUCTS = 'manage_products';
  static const String MANAGE_CATEGORIES = 'manage_categories';
  static const String MANAGE_MODIFIERS = 'manage_modifiers';
  
  static const String MANAGE_BUSINESS_INFO = 'manage_business_info';
  static const String MANAGE_SETTINGS = 'manage_settings';

  /// All available permissions
  static const List<String> ALL_PERMISSIONS = [
    VIEW_USERS,
    CREATE_USERS,
    EDIT_USERS,
    DELETE_USERS,
    VIEW_ROLES,
    CREATE_ROLES,
    EDIT_ROLES,
    DELETE_ROLES,
    VIEW_INVENTORY,
    ADJUST_INVENTORY,
    VIEW_STOCK_MOVEMENTS,
    VIEW_ACTIVITY_LOG,
    EXPORT_ACTIVITY_LOG,
    VIEW_REPORTS,
    EXPORT_REPORTS,
    MANAGE_PRODUCTS,
    MANAGE_CATEGORIES,
    MANAGE_MODIFIERS,
    MANAGE_BUSINESS_INFO,
    MANAGE_SETTINGS,
  ];
}

/// Predefined role names
class PredefinedRoles {
  static const String ADMIN = 'admin';
  static const String MANAGER = 'manager';
  static const String SUPERVISOR = 'supervisor';
  static const String VIEWER = 'viewer';
}

/// Role Model for RBAC System
class RoleModel {
  final String? id; // Appwrite document ID
  final String name;
  final String description;
  final Map<String, bool> permissions; // permission key -> bool
  final int createdAt;
  final int updatedAt;
  final bool isActive;
  final bool isSystemRole; // Cannot be deleted if true

  RoleModel({
    this.id,
    required this.name,
    required this.description,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.isSystemRole = false,
  });

  /// Create a copy with modified fields
  RoleModel copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, bool>? permissions,
    int? createdAt,
    int? updatedAt,
    bool? isActive,
    bool? isSystemRole,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isSystemRole: isSystemRole ?? this.isSystemRole,
    );
  }

  /// Convert to JSON for Appwrite
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'permissions': permissions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'isSystemRole': isSystemRole,
    };
  }

  /// Create from JSON from Appwrite
  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      id: map['\$id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      permissions: Map<String, bool>.from(
        map['permissions'] as Map<dynamic, dynamic>? ?? {},
      ),
      createdAt: map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: map['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isActive: map['isActive'] as bool? ?? true,
      isSystemRole: map['isSystemRole'] as bool? ?? false,
    );
  }

  /// Check if role has a specific permission
  bool hasPermission(String permission) {
    return permissions[permission] ?? false;
  }

  /// Get all permissions this role has
  List<String> getPermissions() {
    return permissions.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if role is admin
  bool get isAdmin => name.toLowerCase() == PredefinedRoles.ADMIN;

  @override
  String toString() => 'RoleModel(id: $id, name: $name, permissions: ${getPermissions().length})';

  /// Create predefined ADMIN role
  static RoleModel createAdminRole() {
    final permissions = <String, bool>{};
    for (var perm in Permission.ALL_PERMISSIONS) {
      permissions[perm] = true;
    }
    return RoleModel(
      name: 'Admin',
      description: 'Full system access',
      permissions: permissions,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isActive: true,
      isSystemRole: true,
    );
  }

  /// Create predefined MANAGER role
  static RoleModel createManagerRole() {
    final permissions = <String, bool>{};
    for (var perm in Permission.ALL_PERMISSIONS) {
      permissions[perm] = true;
    }
    // Remove dangerous permissions
    permissions[Permission.DELETE_USERS] = false;
    permissions[Permission.DELETE_ROLES] = false;
    permissions[Permission.MANAGE_SETTINGS] = false;

    return RoleModel(
      name: 'Manager',
      description: 'Can manage users, inventory, and reports',
      permissions: permissions,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isActive: true,
      isSystemRole: true,
    );
  }

  /// Create predefined SUPERVISOR role
  static RoleModel createSupervisorRole() {
    final permissions = <String, bool>{};
    for (var perm in Permission.ALL_PERMISSIONS) {
      permissions[perm] = false;
    }
    // Add specific permissions
    permissions[Permission.VIEW_USERS] = true;
    permissions[Permission.VIEW_ROLES] = true;
    permissions[Permission.VIEW_INVENTORY] = true;
    permissions[Permission.ADJUST_INVENTORY] = true;
    permissions[Permission.VIEW_STOCK_MOVEMENTS] = true;
    permissions[Permission.VIEW_ACTIVITY_LOG] = true;
    permissions[Permission.VIEW_REPORTS] = true;
    permissions[Permission.MANAGE_PRODUCTS] = true;
    permissions[Permission.MANAGE_CATEGORIES] = true;

    return RoleModel(
      name: 'Supervisor',
      description: 'Can view and adjust inventory, manage products',
      permissions: permissions,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isActive: true,
      isSystemRole: true,
    );
  }

  /// Create predefined VIEWER role
  static RoleModel createViewerRole() {
    final permissions = <String, bool>{};
    for (var perm in Permission.ALL_PERMISSIONS) {
      permissions[perm] = false;
    }
    // Add minimal view permissions
    permissions[Permission.VIEW_USERS] = true;
    permissions[Permission.VIEW_ROLES] = true;
    permissions[Permission.VIEW_INVENTORY] = true;
    permissions[Permission.VIEW_STOCK_MOVEMENTS] = true;
    permissions[Permission.VIEW_ACTIVITY_LOG] = true;
    permissions[Permission.VIEW_REPORTS] = true;

    return RoleModel(
      name: 'Viewer',
      description: 'Read-only access to system',
      permissions: permissions,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      isActive: true,
      isSystemRole: true,
    );
  }
}
