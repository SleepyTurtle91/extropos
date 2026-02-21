import 'package:extropos/models/role_model.dart';
import 'package:flutter/foundation.dart';

/// Role Service for Role Management
/// Handles CRUD operations and permission management for roles
class RoleService extends ChangeNotifier {
  static RoleService? _instance;

  // In-memory storage (in Phase 2, this will use Appwrite)
  final Map<String, RoleModel> _roles = {};

  RoleService._internal();

  factory RoleService() {
    _instance ??= RoleService._internal();
    return _instance!;
  }

  static RoleService get instance => RoleService();

  /// Get all roles
  Future<List<RoleModel>> getAllRoles() async {
    print('📋 Fetching all roles...');
    await Future.delayed(const Duration(milliseconds: 100));
    return _roles.values.toList();
  }

  /// Get active roles only
  Future<List<RoleModel>> getActiveRoles() async {
    print('📋 Fetching active roles...');
    await Future.delayed(const Duration(milliseconds: 100));
    return _roles.values.where((role) => role.isActive).toList();
  }

  /// Get role by ID
  Future<RoleModel?> getRoleById(String roleId) async {
    print('🔍 Fetching role: $roleId');
    await Future.delayed(const Duration(milliseconds: 50));
    return _roles[roleId];
  }

  /// Get role by name
  Future<RoleModel?> getRoleByName(String name) async {
    print('🔍 Fetching role by name: $name');
    await Future.delayed(const Duration(milliseconds: 50));
    return _roles.values.firstWhere(
      (role) => role.name.toLowerCase() == name.toLowerCase(),
      orElse: () => null as dynamic,
    ) as RoleModel?;
  }

  /// Create a new role
  Future<RoleModel> createRole({
    required String name,
    required String description,
    required Map<String, bool> permissions,
  }) async {
    print('➕ Creating role: $name');

    // Validate name uniqueness
    if (await getRoleByName(name) != null) {
      throw Exception('Role with name $name already exists');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newRole = RoleModel(
      name: name,
      description: description,
      permissions: permissions,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      isSystemRole: false,
    );

    _roles[name.toLowerCase()] = newRole;
    print('✅ Role created: $name');
    notifyListeners();
    return newRole;
  }

  /// Update an existing role
  Future<RoleModel> updateRole({
    required String roleId,
    String? name,
    String? description,
    Map<String, bool>? permissions,
    bool? isActive,
  }) async {
    print('✏️  Updating role: $roleId');

    final role = _roles[roleId];
    if (role == null) {
      throw Exception('Role $roleId not found');
    }

    // Cannot modify system roles
    if (role.isSystemRole) {
      throw Exception('Cannot modify system role: ${role.name}');
    }

    final updatedRole = role.copyWith(
      name: name,
      description: description,
      permissions: permissions,
      isActive: isActive,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _roles[roleId] = updatedRole;
    print('✅ Role updated: $roleId');
    notifyListeners();
    return updatedRole;
  }

  /// Delete a role (cannot delete system roles)
  Future<void> deleteRole(String roleId) async {
    print('🗑️  Deleting role: $roleId');

    final role = _roles[roleId];
    if (role == null) {
      throw Exception('Role $roleId not found');
    }

    if (role.isSystemRole) {
      throw Exception('Cannot delete system role: ${role.name}');
    }

    _roles.remove(roleId);
    print('✅ Role deleted: $roleId');
    notifyListeners();
  }

  /// Update permissions for a role
  Future<RoleModel> updateRolePermissions({
    required String roleId,
    required Map<String, bool> permissions,
  }) async {
    print('🔐 Updating permissions for role: $roleId');

    final role = _roles[roleId];
    if (role == null) {
      throw Exception('Role $roleId not found');
    }

    final updatedRole = role.copyWith(
      permissions: permissions,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _roles[roleId] = updatedRole;
    print('✅ Permissions updated for role: $roleId');
    notifyListeners();
    return updatedRole;
  }

  /// Grant a permission to a role
  Future<void> grantPermission(String roleId, String permission) async {
    final role = _roles[roleId];
    if (role == null) throw Exception('Role $roleId not found');

    final permissions = {...role.permissions};
    permissions[permission] = true;

    await updateRolePermissions(roleId: roleId, permissions: permissions);
    print('✅ Permission granted: $permission to $roleId');
  }

  /// Revoke a permission from a role
  Future<void> revokePermission(String roleId, String permission) async {
    final role = _roles[roleId];
    if (role == null) throw Exception('Role $roleId not found');

    final permissions = {...role.permissions};
    permissions[permission] = false;

    await updateRolePermissions(roleId: roleId, permissions: permissions);
    print('✅ Permission revoked: $permission from $roleId');
  }

  /// Check if a role has a specific permission
  Future<bool> roleHasPermission(String roleId, String permission) async {
    final role = await getRoleById(roleId);
    return role?.hasPermission(permission) ?? false;
  }

  /// Seed predefined roles
  Future<void> seedPredefinedRoles() async {
    print('🌱 Seeding predefined roles...');

    try {
      final adminRole = RoleModel.createAdminRole();
      _roles['admin'] = adminRole;

      final managerRole = RoleModel.createManagerRole();
      _roles['manager'] = managerRole;

      final supervisorRole = RoleModel.createSupervisorRole();
      _roles['supervisor'] = supervisorRole;

      final viewerRole = RoleModel.createViewerRole();
      _roles['viewer'] = viewerRole;

      print('✅ Predefined roles seeded successfully');
      notifyListeners();
    } catch (e) {
      print('❌ Error seeding predefined roles: $e');
    }
  }

  /// Get total roles count
  Future<int> getTotalRolesCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _roles.length;
  }

  /// Get system roles count
  Future<int> getSystemRolesCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _roles.values.where((role) => role.isSystemRole).length;
  }

  /// Clear all roles (for testing)
  void _clearAllRoles() {
    _roles.clear();
    notifyListeners();
  }

  @override
  String toString() => 'RoleService(totalRoles: ${_roles.length})';
}
