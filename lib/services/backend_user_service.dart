import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/services/audit_service.dart';
import 'package:flutter/foundation.dart';

/// Backend User Service for User Management
/// Handles CRUD operations for backend users with audit trail
class BackendUserService extends ChangeNotifier {
  static BackendUserService? _instance;

  // In-memory storage (in Phase 2, this will use Appwrite)
  final Map<String, BackendUserModel> _users = {};
  final AuditService _auditService = AuditService.instance;

  BackendUserService._internal();

  factory BackendUserService() {
    _instance ??= BackendUserService._internal();
    return _instance!;
  }

  static BackendUserService get instance => BackendUserService();

  /// Get all users
  Future<List<BackendUserModel>> getAllUsers() async {
    print('📋 Fetching all users...');
    await Future.delayed(const Duration(milliseconds: 100));
    return _users.values.toList();
  }

  /// Get active users only
  Future<List<BackendUserModel>> getActiveUsers() async {
    print('👥 Fetching active users...');
    await Future.delayed(const Duration(milliseconds: 100));
    return _users.values.where((user) => user.isActive && !user.isLockedOut).toList();
  }

  /// Get user by ID
  Future<BackendUserModel?> getUserById(String userId) async {
    print('🔍 Fetching user: $userId');
    await Future.delayed(const Duration(milliseconds: 50));
    return _users[userId];
  }

  /// Get user by email
  Future<BackendUserModel?> getUserByEmail(String email) async {
    print('🔍 Fetching user by email: $email');
    await Future.delayed(const Duration(milliseconds: 50));
    return _users.values.firstWhere(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
      orElse: () => null as dynamic,
    ) as BackendUserModel?;
  }

  /// Create a new user
  Future<BackendUserModel> createUser({
    required String email,
    required String displayName,
    required String roleId,
    String? phone,
    List<String>? locationIds,
    String? createdBy,
    String? createdByName,
  }) async {
    print('➕ Creating user: $email');

    // Validate email uniqueness
    if (await getUserByEmail(email) != null) {
      throw Exception('User with email $email already exists');
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    // Validate display name
    if (displayName.isEmpty) {
      throw Exception('Display name cannot be empty');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final newUser = BackendUserModel(
      email: email,
      displayName: displayName,
      roleId: roleId,
      phone: phone,
      locationIds: locationIds ?? [],
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      isActive: true,
    );

    // Generate temporary ID (in Phase 2, Appwrite will do this)
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    final userWithId = newUser.copyWith(id: userId);
    
    _users[userId] = userWithId;

    // Log activity
    await _auditService.logActivity(
      userId: createdBy ?? 'system',
      userName: createdByName ?? createdBy ?? 'System',
      action: 'create_user',
      resourceType: 'user',
      resourceId: userId,
      resourceName: email,
      description: 'Created user: $displayName ($email)',
      changesAfter: userWithId.toMap(),
      success: true,
    );

    print('✅ User created: $email (ID: $userId)');
    notifyListeners();
    return userWithId;
  }

  /// Update an existing user
  Future<BackendUserModel> updateUser({
    required String userId,
    String? displayName,
    String? phone,
    String? roleId,
    List<String>? locationIds,
    bool? isActive,
    String? updatedBy,
    String? updatedByName,
  }) async {
    print('✏️  Updating user: $userId');

    final user = _users[userId];
    if (user == null) {
      throw Exception('User $userId not found');
    }

    // Validate display name if provided
    if (displayName != null && displayName.isEmpty) {
      throw Exception('Display name cannot be empty');
    }

    final changesBefore = user.toMap();
    
    final updatedUser = user.copyWith(
      displayName: displayName,
      phone: phone,
      roleId: roleId,
      locationIds: locationIds,
      isActive: isActive,
      updatedBy: updatedBy,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _users[userId] = updatedUser;

    // Log activity
    await _auditService.logActivity(
      userId: updatedBy ?? 'system',
      userName: updatedByName ?? updatedBy ?? 'System',
      action: 'update_user',
      resourceType: 'user',
      resourceId: userId,
      resourceName: user.email,
      description: 'Updated user: ${user.displayName}',
      changesBefore: changesBefore,
      changesAfter: updatedUser.toMap(),
      success: true,
    );

    print('✅ User updated: $userId');
    notifyListeners();
    return updatedUser;
  }

  /// Delete a user (soft delete - sets isActive to false)
  Future<void> deleteUser(
    String userId, {
    String? deletedBy,
    String? deletedByName,
  }) async {
    print('🗑️  Deleting user: $userId');

    final user = _users[userId];
    if (user == null) {
      throw Exception('User $userId not found');
    }

    // Cannot delete if it's the only admin
    if (user.roleId.toLowerCase().contains('admin')) {
      final adminCount = _users.values
          .where((u) => u.roleId.toLowerCase().contains('admin') && u.isActive)
          .length;
      if (adminCount <= 1) {
        throw Exception('Cannot delete the last admin user');
      }
    }

    final changesBefore = user.toMap();
    
    final deletedUser = user.copyWith(
      isActive: false,
      updatedBy: deletedBy,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _users[userId] = deletedUser;

    // Log activity
    await _auditService.logActivity(
      userId: deletedBy ?? 'system',
      userName: deletedByName ?? deletedBy ?? 'System',
      action: 'delete_user',
      resourceType: 'user',
      resourceId: userId,
      resourceName: user.email,
      description: 'Deleted user: ${user.displayName}',
      changesBefore: changesBefore,
      changesAfter: deletedUser.toMap(),
      success: true,
    );

    print('✅ User deleted (soft): $userId');
    notifyListeners();
  }

  /// Lock a user account (due to too many failed login attempts)
  Future<void> lockUser(String userId, {String? reason}) async {
    print('🔒 Locking user: $userId');

    final user = _users[userId];
    if (user == null) {
      throw Exception('User $userId not found');
    }

    final lockedUser = user.copyWith(
      isLockedOut: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _users[userId] = lockedUser;

    // Log activity
    await _auditService.logActivity(
      userId: 'system',
      userName: 'System',
      action: 'lock_user',
      resourceType: 'user',
      resourceId: userId,
      resourceName: user.email,
      description: 'Locked user account. Reason: ${reason ?? 'Too many failed login attempts'}',
      success: true,
    );

    print('✅ User locked: $userId');
    notifyListeners();
  }

  /// Unlock a user account
  Future<void> unlockUser(String userId, {String? unlockedBy, String? unlockedByName}) async {
    print('🔓 Unlocking user: $userId');

    final user = _users[userId];
    if (user == null) {
      throw Exception('User $userId not found');
    }

    final unlockedUser = user.copyWith(
      isLockedOut: false,
      failedLoginAttempts: 0,
      updatedBy: unlockedBy,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    _users[userId] = unlockedUser;

    // Log activity
    await _auditService.logActivity(
      userId: unlockedBy ?? 'system',
      userName: unlockedByName ?? unlockedBy ?? 'System',
      action: 'unlock_user',
      resourceType: 'user',
      resourceId: userId,
      resourceName: user.email,
      description: 'Unlocked user account',
      success: true,
    );

    print('✅ User unlocked: $userId');
    notifyListeners();
  }

  /// Record failed login attempt
  Future<void> recordFailedLoginAttempt(String email, {String? ipAddress}) async {
    final user = await getUserByEmail(email);
    if (user == null) return;

    final attempts = (user.failedLoginAttempts ?? 0) + 1;

    // Lock account after 5 failed attempts
    if (attempts >= 5) {
      await lockUser(user.id ?? email, reason: 'Too many failed login attempts');
      print('🔒 User account locked after $attempts failed attempts: $email');
    } else {
      // Just increment the counter
      final updatedUser = user.copyWith(
        failedLoginAttempts: attempts,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      _users[user.id ?? email] = updatedUser;
      print('⚠️  Failed login attempt $attempts/5: $email');
    }

    // Log activity
    await _auditService.logActivity(
      userId: 'system',
      userName: 'System',
      action: 'failed_login',
      resourceType: 'user',
      resourceId: user.id,
      resourceName: email,
      description: 'Failed login attempt ($attempts/5)',
      ipAddress: ipAddress,
      success: false,
      errorMessage: 'Invalid password',
    );
  }

  /// Record successful login
  Future<void> recordSuccessfulLogin(String userId, {String? ipAddress}) async {
    final user = _users[userId];
    if (user == null) return;

    final now = DateTime.now();
    final updatedUser = user.copyWith(
      failedLoginAttempts: 0,
      lastLoginAt: now.toIso8601String(),
      updatedAt: now.millisecondsSinceEpoch,
    );

    _users[userId] = updatedUser;

    // Log activity
    await _auditService.logActivity(
      userId: userId,
      userName: user.displayName,
      action: 'login',
      resourceType: 'user',
      resourceId: userId,
      resourceName: user.email,
      description: 'User logged in',
      ipAddress: ipAddress,
      success: true,
    );

    print('✅ Login recorded for: ${user.email}');
    notifyListeners();
  }

  /// Search users by name or email
  Future<List<BackendUserModel>> searchUsers(String query) async {
    print('🔍 Searching users: "$query"');
    await Future.delayed(const Duration(milliseconds: 100));

    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return _users.values
        .where((user) =>
            user.email.toLowerCase().contains(lowerQuery) ||
            user.displayName.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get users by role
  Future<List<BackendUserModel>> getUsersByRole(String roleId) async {
    print('👥 Fetching users with role: $roleId');
    await Future.delayed(const Duration(milliseconds: 100));
    return _users.values
        .where((user) => user.roleId == roleId && user.isActive)
        .toList();
  }

  /// Get users with access to a location
  Future<List<BackendUserModel>> getUsersWithLocationAccess(String locationId) async {
    print('📍 Fetching users with access to location: $locationId');
    await Future.delayed(const Duration(milliseconds: 100));
    return _users.values
        .where((user) => user.canAccessLocation(locationId))
        .toList();
  }

  /// Get active users count
  Future<int> getActiveUsersCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _users.values.where((user) => user.isActive && !user.isLockedOut).length;
  }

  /// Get total users count (including inactive)
  Future<int> getTotalUsersCount() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _users.length;
  }

  /// Get users statistics
  Future<Map<String, dynamic>> getUserStatistics() async {
    print('📊 Calculating user statistics...');
    await Future.delayed(const Duration(milliseconds: 200));

    final totalCount = _users.length;
    final activeCount = _users.values.where((u) => u.isActive && !u.isLockedOut).length;
    final inactiveCount = _users.values.where((u) => !u.isActive).length;
    final lockedCount = _users.values.where((u) => u.isLockedOut).length;

    // Count by role
    final roleCount = <String, int>{};
    for (var user in _users.values) {
      roleCount[user.roleId] = (roleCount[user.roleId] ?? 0) + 1;
    }

    return {
      'totalUsers': totalCount,
      'activeUsers': activeCount,
      'inactiveUsers': inactiveCount,
      'lockedUsers': lockedCount,
      'usersByRole': roleCount,
    };
  }

  /// Seed test data
  Future<void> seedTestData({String? createdBy}) async {
    print('🌱 Seeding test users...');

    try {
      await createUser(
        email: 'admin@example.com',
        displayName: 'System Administrator',
        roleId: 'admin',
        phone: '+60123456789',
        createdBy: createdBy ?? 'system',
        createdByName: 'System',
      );

      await createUser(
        email: 'manager@example.com',
        displayName: 'Store Manager',
        roleId: 'manager',
        phone: '+60187654321',
        createdBy: createdBy ?? 'system',
        createdByName: 'System',
      );

      await createUser(
        email: 'supervisor@example.com',
        displayName: 'Inventory Supervisor',
        roleId: 'supervisor',
        phone: '+60145678901',
        createdBy: createdBy ?? 'system',
        createdByName: 'System',
      );

      await createUser(
        email: 'viewer@example.com',
        displayName: 'Report Viewer',
        roleId: 'viewer',
        phone: '+60156789012',
        createdBy: createdBy ?? 'system',
        createdByName: 'System',
      );

      print('✅ Test data seeded successfully (4 users)');
    } catch (e) {
      print('❌ Error seeding test data: $e');
      rethrow;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Clear all users (for testing)
  void _clearAllUsers() {
    _users.clear();
    notifyListeners();
  }

  /// Export all users as JSON
  Future<List<Map<String, dynamic>>> exportUsersAsJson() async {
    print('📤 Exporting users as JSON...');
    await Future.delayed(const Duration(milliseconds: 100));
    return _users.values.map((user) => user.toMap()).toList();
  }

  @override
  String toString() => 'BackendUserService(totalUsers: ${_users.length})';
}
