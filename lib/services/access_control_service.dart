import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:flutter/foundation.dart';

/// Access Control Service for RBAC
/// Handles permission checking and role-based access control
class AccessControlService extends ChangeNotifier {
  static AccessControlService? _instance;
  
  // In-memory cache with 5-minute TTL
  final Map<String, _CachedPermission> _permissionCache = {};
  final Duration _cacheTTL = const Duration(minutes: 5);

  // Current user (set after login)
  BackendUserModel? _currentUser;
  RoleModel? _currentUserRole;

  // Mock data store (in Phase 2, this will use Appwrite)
  final Map<String, RoleModel> _roles = {};
  final Map<String, BackendUserModel> _users = {};

  AccessControlService._internal();

  factory AccessControlService() {
    _instance ??= AccessControlService._internal();
    return _instance!;
  }

  static AccessControlService get instance => AccessControlService();

  /// Initialize with current user
  Future<void> initialize(BackendUserModel user, RoleModel role) async {
    _currentUser = user;
    _currentUserRole = role;
    notifyListeners();
    print('✅ AccessControlService initialized for user: ${user.email}');
  }

  /// Get current user
  BackendUserModel? get currentUser => _currentUser;

  /// Get current user role
  RoleModel? get currentUserRole => _currentUserRole;

  /// Check if user has a specific permission
  Future<bool> hasPermission(String permissionKey) async {
    if (_currentUserRole == null) return false;
    
    // Check cache first
    final cached = _permissionCache[permissionKey];
    if (cached != null && !cached.isExpired()) {
      print('🔄 Cache hit for permission: $permissionKey');
      return cached.value;
    }

    // Simulate network delay (in real implementation, this would query Appwrite)
    await Future.delayed(const Duration(milliseconds: 50));
    
    final hasPermission = _currentUserRole!.hasPermission(permissionKey);
    
    // Cache the result
    _permissionCache[permissionKey] = _CachedPermission(hasPermission, _cacheTTL);
    print('✓ Permission check: $permissionKey = $hasPermission');
    
    return hasPermission;
  }

  /// Check if user has all permissions
  Future<bool> hasAllPermissions(List<String> permissionKeys) async {
    for (final perm in permissionKeys) {
      if (!await hasPermission(perm)) return false;
    }
    return true;
  }

  /// Check if user has any permission
  Future<bool> hasAnyPermission(List<String> permissionKeys) async {
    for (final perm in permissionKeys) {
      if (await hasPermission(perm)) return true;
    }
    return false;
  }

  /// Check if user can access a specific location
  bool canAccessLocation(String locationId) {
    if (_currentUser == null) return false;
    return _currentUser!.canAccessLocation(locationId);
  }

  /// Check if user is admin
  Future<bool> isAdmin() async {
    return _currentUserRole?.isAdmin ?? false;
  }

  /// Get all permissions for current user
  List<String> getCurrentUserPermissions() {
    return _currentUserRole?.getPermissions() ?? [];
  }

  /// Clear permission cache
  void clearPermissionCache() {
    _permissionCache.clear();
    print('🗑️  Permission cache cleared');
  }

  /// Logout - clear current user
  void logout() {
    _currentUser = null;
    _currentUserRole = null;
    clearPermissionCache();
    notifyListeners();
    print('👋 User logged out, cache cleared');
  }

  /// Mock method: Add a role (for testing)
  void _addRole(RoleModel role) {
    _roles[role.id ?? role.name] = role;
  }

  /// Mock method: Add a user (for testing)
  void _addUser(BackendUserModel user) {
    _users[user.id ?? user.email] = user;
  }

  /// Get role by ID (for testing)
  RoleModel? _getRoleById(String roleId) {
    return _roles[roleId];
  }

  /// Get user by ID (for testing)
  BackendUserModel? _getUserById(String userId) {
    return _users[userId];
  }

  @override
  String toString() => 'AccessControlService(currentUser: ${_currentUser?.email})';
}

/// Internal class for caching permissions
class _CachedPermission {
  final bool value;
  final DateTime cachedAt;
  final Duration ttl;

  _CachedPermission(this.value, this.ttl) : cachedAt = DateTime.now();

  bool isExpired() {
    return DateTime.now().difference(cachedAt) > ttl;
  }
}
