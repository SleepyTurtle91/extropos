import 'dart:convert';

import 'package:extropos/models/role_model.dart';
import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/audit_service.dart';
import 'package:flutter/foundation.dart';

/// Role Service - Appwrite Version
///
/// Manages roles and permissions with Appwrite backend
/// - Predefined system roles (Admin, Manager, Supervisor, Viewer)
/// - Custom roles support
/// - Permission management
/// - System role protection (cannot delete/modify predefined roles)
///
/// All changes are logged via AuditService
class RoleServiceAppwrite extends ChangeNotifier {
  static RoleServiceAppwrite? _instance;

  final AppwritePhase1Service _appwrite = AppwritePhase1Service();
  final AuditService _auditService = AuditService.instance;

  // Local cache for performance
  final Map<String, RoleModel> _roleCache = {};
  DateTime? _lastCacheRefresh;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static bool get _isTest {
    return bool.fromEnvironment('FLUTTER_TEST') ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  // Predefined system role IDs (immutable)
  static const String adminRoleId = 'role_admin';
  static const String managerRoleId = 'role_manager';
  static const String supervisorRoleId = 'role_supervisor';
  static const String viewerRoleId = 'role_viewer';

  RoleServiceAppwrite._internal() {
    _initializePredefinedRoles();
  }

  factory RoleServiceAppwrite() {
    _instance ??= RoleServiceAppwrite._internal();
    return _instance!;
  }

  static RoleServiceAppwrite get instance => RoleServiceAppwrite();

  /// Initialize predefined roles in cache
  void _initializePredefinedRoles() {
    _roleCache[adminRoleId] = RoleModel(
      id: adminRoleId,
      name: 'Admin',
      description: 'Full system access with all permissions',
      permissions: {
        'view_users': true,
        'create_users': true,
        'edit_users': true,
        'delete_users': true,
        'view_roles': true,
        'create_roles': true,
        'edit_roles': true,
        'delete_roles': true,
        'view_inventory': true,
        'adjust_inventory': true,
        'view_stock_movements': true,
        'view_activity_log': true,
        'export_activity_log': true,
        'view_reports': true,
        'export_reports': true,
        'manage_products': true,
        'manage_categories': true,
        'manage_modifiers': true,
        'manage_business_info': true,
        'manage_settings': true,
      },
      isSystemRole: true,
      createdAt: 0,
      updatedAt: 0,
    );

    _roleCache[managerRoleId] = RoleModel(
      id: managerRoleId,
      name: 'Manager',
      description: 'Manage staff, inventory, and view reports',
      permissions: {
        'view_users': true,
        'create_users': true,
        'edit_users': true,
        'delete_users': false,
        'view_roles': true,
        'create_roles': false,
        'edit_roles': false,
        'delete_roles': false,
        'view_inventory': true,
        'adjust_inventory': true,
        'view_stock_movements': true,
        'view_activity_log': true,
        'export_activity_log': false,
        'view_reports': true,
        'export_reports': true,
        'manage_products': true,
        'manage_categories': true,
        'manage_modifiers': true,
        'manage_business_info': false,
        'manage_settings': false,
      },
      isSystemRole: true,
      createdAt: 0,
      updatedAt: 0,
    );

    _roleCache[supervisorRoleId] = RoleModel(
      id: supervisorRoleId,
      name: 'Supervisor',
      description: 'Monitor operations and manage inventory',
      permissions: {
        'view_users': true,
        'create_users': false,
        'edit_users': false,
        'delete_users': false,
        'view_roles': true,
        'create_roles': false,
        'edit_roles': false,
        'delete_roles': false,
        'view_inventory': true,
        'adjust_inventory': true,
        'view_stock_movements': true,
        'view_activity_log': true,
        'export_activity_log': false,
        'view_reports': true,
        'export_reports': false,
        'manage_products': false,
        'manage_categories': false,
        'manage_modifiers': false,
        'manage_business_info': false,
        'manage_settings': false,
      },
      isSystemRole: true,
      createdAt: 0,
      updatedAt: 0,
    );

    _roleCache[viewerRoleId] = RoleModel(
      id: viewerRoleId,
      name: 'Viewer',
      description: 'View-only access to inventory and reports',
      permissions: {
        'view_users': true,
        'create_users': false,
        'edit_users': false,
        'delete_users': false,
        'view_roles': true,
        'create_roles': false,
        'edit_roles': false,
        'delete_roles': false,
        'view_inventory': true,
        'adjust_inventory': false,
        'view_stock_movements': true,
        'view_activity_log': false,
        'export_activity_log': false,
        'view_reports': true,
        'export_reports': false,
        'manage_products': false,
        'manage_categories': false,
        'manage_modifiers': false,
        'manage_business_info': false,
        'manage_settings': false,
      },
      isSystemRole: true,
      createdAt: 0,
      updatedAt: 0,
    );
  }

  /// Ensure Appwrite is initialized
  Future<bool> ensureInitialized() async {
    if (_isTest) {
      return false;
    }
    if (!_appwrite.isInitialized) {
      try {
        return await _appwrite
            .initialize()
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        print('⚠️ Appwrite initialization failed: $e');
        return false;
      }
    }
    return true;
  }

  /// Refresh cache if expired
  Future<void> _refreshCacheIfNeeded() async {
    final now = DateTime.now();
    if (_lastCacheRefresh == null ||
        now.difference(_lastCacheRefresh!).compareTo(_cacheExpiry) > 0) {
      print('🔄 Refreshing role cache...');
      final roles = await _fetchAllRolesFromAppwrite();
      for (final role in roles) {
        if (role.id != null) {
          _roleCache[role.id!] = role;
        }
      }
      _lastCacheRefresh = now;
    }
  }

  /// Get all roles (including system roles)
  Future<List<RoleModel>> getAllRoles() async {
    print('📋 Fetching all roles...');
    final initialized = await ensureInitialized();
    if (!initialized) {
      return _roleCache.values.toList();
    }

    try {
      await _refreshCacheIfNeeded();
      return _roleCache.values.toList();
    } catch (e) {
      print('❌ Error fetching roles: $e');
      return _roleCache.values.toList();
    }
  }

  /// Get only custom roles (excluding system roles)
  Future<List<RoleModel>> getCustomRoles() async {
    print('📋 Fetching custom roles...');
    final allRoles = await getAllRoles();
    return allRoles.where((role) => !role.isSystemRole).toList();
  }

  /// Get role by ID
  Future<RoleModel?> getRoleById(String roleId) async {
    print('🔍 Fetching role: $roleId');
    if (_roleCache.isEmpty) {
      _initializePredefinedRoles();
    }

    final initialized = await ensureInitialized();
    if (!initialized) {
      return _roleCache[roleId];
    }

    if (_roleCache.containsKey(roleId)) {
      return _roleCache[roleId];
    }

    try {
      final doc = await _appwrite
          .getDocument(
            collectionId: AppwritePhase1Service.rolesCol,
            documentId: roleId,
          )
          .timeout(const Duration(seconds: 2));

      final role = _documentToRoleModel(doc);
      _roleCache[roleId] = role;
      return role;
    } catch (e) {
      print('❌ Error fetching role: $e');
      return null;
    }
  }

  /// Get role by name
  Future<RoleModel?> getRoleByName(String name) async {
    print('🔍 Fetching role by name: $name');
    final allRoles = await getAllRoles();
    try {
      return allRoles.firstWhere(
        (role) => role.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Create a custom role
  Future<RoleModel> createCustomRole({
    required String name,
    required List<String> permissions,
    String? description,
    String? createdBy,
  }) async {
    print('➕ Creating role: $name');
    if (name.trim().isEmpty) {
      throw Exception('Role name cannot be empty');
    }

    // Validate name uniqueness
    if (await getRoleByName(name) != null) {
      throw Exception('Role with name $name already exists');
    }

    // Validate permissions
    if (permissions.isEmpty) {
      throw Exception('At least one permission required');
    }

    final initialized = await ensureInitialized();
    if (!initialized) {
      throw Exception('Appwrite not initialized');
    }

    // Convert list to map
    final Map<String, bool> permissionMap = {};
    for (final perm in permissions) {
      permissionMap[perm] = true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final roleId = 'role_custom_$name'.replaceAll(' ', '_').toLowerCase();

    final newRole = RoleModel(
      id: roleId,
      name: name,
      description: description ?? 'Custom role: $name',
      permissions: permissionMap,
      isSystemRole: false,
      createdAt: now,
      updatedAt: now,
    );

    try {
      // Create in Appwrite
      await _appwrite.createDocument(
        collectionId: AppwritePhase1Service.rolesCol,
        documentId: roleId,
        data: newRole.toMap(),
      );

      // Update cache
      _roleCache[roleId] = newRole;
      notifyListeners();

      // Log activity
      await _auditService.logActivity(
        userId: createdBy ?? 'system',
        userName: createdBy ?? 'system',
        action: 'CREATE',
        resourceType: 'Role',
        resourceId: roleId,
        changesAfter: newRole.toMap(),
        success: true,
      );

      print('✅ Role created: $roleId');
      return newRole;
    } catch (e) {
      print('❌ Error creating role: $e');

      await _auditService.logActivity(
        userId: createdBy ?? 'system',
        userName: createdBy ?? 'system',
        action: 'CREATE',
        resourceType: 'Role',
        resourceId: roleId,
        success: false,
      );

      throw Exception('Failed to create role: $e');
    }
  }

  /// Update role permissions (custom roles only)
  Future<RoleModel> updateRolePermissions({
    required String roleId,
    required List<String> permissions,
    String? updatedBy,
  }) async {
    print('✏️ Updating role: $roleId');
    await ensureInitialized();

    final existingRole = await getRoleById(roleId);
    if (existingRole == null) {
      throw Exception('Role not found: $roleId');
    }

    // Prevent modification of system roles
    if (existingRole.isSystemRole) {
      throw Exception('Cannot modify system role: ${existingRole.name}');
    }

    if (permissions.isEmpty) {
      throw Exception('At least one permission required');
    }

    // Convert list to map
    final Map<String, bool> permissionMap = {};
    for (final perm in permissions) {
      permissionMap[perm] = true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedRole = existingRole.copyWith(
      permissions: permissionMap,
      updatedAt: now,
    );

    try {
      await _appwrite.updateDocument(
        collectionId: AppwritePhase1Service.rolesCol,
        documentId: roleId,
        data: {
          'permissions': permissions,
          'updatedAt': now,
        },
      );

      // Update cache
      _roleCache[roleId] = updatedRole;
      notifyListeners();

      // Log activity
      await _auditService.logActivity(
        userId: updatedBy ?? 'system',
        userName: updatedBy ?? 'system',
        action: 'UPDATE',
        resourceType: 'Role',
        resourceId: roleId,
        changesBefore: existingRole.toMap(),
        changesAfter: updatedRole.toMap(),
        success: true,
      );

      print('✅ Role updated: $roleId');
      return updatedRole;
    } catch (e) {
      print('❌ Error updating role: $e');

      await _auditService.logActivity(
        userId: updatedBy ?? 'system',
        userName: updatedBy ?? 'system',
        action: 'UPDATE',
        resourceType: 'Role',
        resourceId: roleId,
        success: false,
      );

      throw Exception('Failed to update role: $e');
    }
  }

  /// Delete custom role
  Future<void> deleteRole({
    required String roleId,
    String? deletedBy,
  }) async {
    print('🗑️ Deleting role: $roleId');
    await ensureInitialized();

    final roleToDelete = await getRoleById(roleId);
    if (roleToDelete == null) {
      throw Exception('Role not found: $roleId');
    }

    // Prevent deletion of system roles
    if (roleToDelete.isSystemRole) {
      throw Exception('Cannot delete system role: ${roleToDelete.name}');
    }

    try {
      await _appwrite.deleteDocument(
        collectionId: AppwritePhase1Service.rolesCol,
        documentId: roleId,
      );

      // Remove from cache
      _roleCache.remove(roleId);
      notifyListeners();

      // Log activity
      await _auditService.logActivity(
        userId: deletedBy ?? 'system',
        userName: deletedBy ?? 'system',
        action: 'DELETE',
        resourceType: 'Role',
        resourceId: roleId,
        changesBefore: roleToDelete.toMap(),
        success: true,
      );

      print('✅ Role deleted: $roleId');
    } catch (e) {
      print('❌ Error deleting role: $e');

      await _auditService.logActivity(
        userId: deletedBy ?? 'system',
        userName: deletedBy ?? 'system',
        action: 'DELETE',
        resourceType: 'Role',
        resourceId: roleId,
        success: false,
      );

      throw Exception('Failed to delete role: $e');
    }
  }

  /// Check if role has permission
  Future<bool> roleHasPermission({
    required String roleId,
    required String permission,
  }) async {
    final role = await getRoleById(roleId);
    if (role == null) return false;
    final normalized = permission.toLowerCase();
    return role.permissions[normalized] ?? false;
  }

  /// Get all available permissions
  List<String> getAllAvailablePermissions() {
    return [
      'VIEW_USERS',
      'CREATE_USERS',
      'EDIT_USERS',
      'DELETE_USERS',
      'MANAGE_ROLES',
      'VIEW_ROLES',
      'ASSIGN_ROLES',
      'MANAGE_PERMISSIONS',
      'VIEW_ACTIVITY_LOGS',
      'MANAGE_INVENTORY',
      'VIEW_INVENTORY',
      'EDIT_INVENTORY',
      'MANAGE_STOCK',
      'VIEW_REPORTS',
      'SYSTEM_ADMIN',
    ];
  }

  /// Fetch all roles from Appwrite
  Future<List<RoleModel>> _fetchAllRolesFromAppwrite() async {
    try {
      final docs = await _appwrite
          .listDocuments(
            collectionId: AppwritePhase1Service.rolesCol,
            limit: 100,
          )
          .timeout(const Duration(seconds: 2));

      return docs.map(_documentToRoleModel).toList();
    } catch (e) {
      print('❌ Error fetching roles from Appwrite: $e');
      return [];
    }
  }

  /// Convert Appwrite document to RoleModel
  RoleModel _documentToRoleModel(Map<String, dynamic> doc) {
    final permissionsJson = doc['permissions'] ?? '[]';
    Map<String, bool> permissions = {};

    if (permissionsJson is String) {
      try {
        final list = (jsonDecode(permissionsJson) as List) ?? [];
        for (final perm in list) {
          if (perm is String) {
            permissions[perm] = true;
          }
        }
      } catch (e) {
        print('⚠️ Error parsing permissions: $e');
      }
    } else if (permissionsJson is List) {
      for (final perm in permissionsJson) {
        if (perm is String) {
          permissions[perm] = true;
        }
      }
    } else if (permissionsJson is Map) {
      permissions = Map<String, bool>.from(permissionsJson);
    }

    return RoleModel(
      id: doc[r'$id'] ?? doc['id'] ?? '',
      name: doc['name'] ?? '',
      description: doc['description'] ?? '',
      permissions: permissions,
      isSystemRole: doc['isSystemRole'] ?? false,
      createdAt: doc['createdAt'] ?? 0,
      updatedAt: doc['updatedAt'] ?? 0,
    );
  }

  /// Clear cache
  void clearCache() {
    _roleCache.clear();
    _lastCacheRefresh = null;
    _initializePredefinedRoles(); // Restore predefined roles
  }

  /// Get predefined system roles
  List<RoleModel> getSystemRoles() {
    return _roleCache.values.where((role) => role.isSystemRole).toList();
  }

  @override
  void dispose() {
    _roleCache.clear();
    super.dispose();
  }
}
