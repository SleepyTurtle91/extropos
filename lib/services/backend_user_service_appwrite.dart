import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/services/appwrite_phase1_service.dart';
import 'package:extropos/services/audit_service.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Backend User Service - Appwrite Version
///
/// Handles CRUD operations for backend users with Appwrite backend
/// and audit trail integration.
///
/// All operations are logged via AuditService
class BackendUserServiceAppwrite extends ChangeNotifier {
  static BackendUserServiceAppwrite? _instance;

  final AppwritePhase1Service _appwrite = AppwritePhase1Service();
  final AuditService _auditService = AuditService.instance;
  final _uuid = const Uuid();

  // Local cache for performance
  final Map<String, BackendUserModel> _userCache = {};
  DateTime? _lastCacheRefresh;
  final Duration _cacheExpiry = const Duration(minutes: 5);
  static bool get _isTest {
    return bool.fromEnvironment('FLUTTER_TEST') ||
        Platform.environment.containsKey('FLUTTER_TEST');
  }

  BackendUserServiceAppwrite._internal();

  factory BackendUserServiceAppwrite() {
    _instance ??= BackendUserServiceAppwrite._internal();
    return _instance!;
  }

  static BackendUserServiceAppwrite get instance => BackendUserServiceAppwrite();

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
      print('🔄 Refreshing user cache...');
      final users = await _fetchAllUsersFromAppwrite();
      _userCache.clear();
      for (final user in users) {
        if (user.id != null) {
          _userCache[user.id!] = user;
        }
      }
      _lastCacheRefresh = now;
    }
  }

  /// Get all users
  Future<List<BackendUserModel>> getAllUsers() async {
    print('📋 Fetching all users from Appwrite...');
    final initialized = await ensureInitialized();
    if (!initialized) {
      return _userCache.values.toList();
    }

    try {
      await _refreshCacheIfNeeded();
      return _userCache.values.toList();
    } catch (e) {
      print('❌ Error fetching users: $e');
      // Fallback to cache
      return _userCache.values.toList();
    }
  }

  /// Get active users only
  Future<List<BackendUserModel>> getActiveUsers() async {
    print('👥 Fetching active users...');
    final initialized = await ensureInitialized();
    if (!initialized) {
      return _userCache.values
          .where((user) => user.isActive && !user.isLockedOut)
          .toList();
    }

    try {
      final allUsers = await getAllUsers();
      return allUsers
          .where((user) => user.isActive && !user.isLockedOut)
          .toList();
    } catch (e) {
      print('❌ Error fetching active users: $e');
      return [];
    }
  }

  /// Get user by ID
  Future<BackendUserModel?> getUserById(String userId) async {
    print('🔍 Fetching user: $userId');
    final initialized = await ensureInitialized();
    if (!initialized) {
      return _userCache[userId];
    }

    try {
      // Check cache first
      if (_userCache.containsKey(userId)) {
        return _userCache[userId];
      }

      final doc = await _appwrite
          .getDocument(
            collectionId: AppwritePhase1Service.backendUsersCol,
            documentId: userId,
          )
          .timeout(const Duration(seconds: 2));

      final user = _documentToBackendUserModel(doc);
      _userCache[userId] = user;
      return user;
    } catch (e) {
      print('❌ Error fetching user: $e');
      return null;
    }
  }

  /// Get user by email
  Future<BackendUserModel?> getUserByEmail(String email) async {
    print('🔍 Fetching user by email: $email');
    final initialized = await ensureInitialized();
    if (!initialized) {
      for (final user in _userCache.values) {
        if (user.email.toLowerCase() == email.toLowerCase()) {
          return user;
        }
      }
      return null;
    }

    try {
      final users = await getAllUsers();
      for (final user in users) {
        if (user.email.toLowerCase() == email.toLowerCase()) {
          return user;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user by email: $e');
      return null;
    }
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
    // Validate email format
    if (!_isValidEmail(email)) {
      throw Exception('Invalid email format');
    }

    // Validate display name
    if (displayName.isEmpty) {
      throw Exception('Display name cannot be empty');
    }

    final initialized = await ensureInitialized();
    if (!initialized) {
      throw Exception('Appwrite not initialized');
    }

    // Validate email uniqueness
    if (await getUserByEmail(email) != null) {
      throw Exception('User with email $email already exists');
    }

    final now = DateTime.now();
    final userId = 'user_${_uuid.v4()}';

    final newUser = BackendUserModel(
      id: userId,
      email: email,
      displayName: displayName,
      roleId: roleId,
      phone: phone,
      locationIds: locationIds ?? [],
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
      createdBy: createdBy,
      isActive: true,
    );

    try {
      // Create in Appwrite
      await _appwrite.createDocument(
        collectionId: AppwritePhase1Service.backendUsersCol,
        documentId: userId,
        data: newUser.toMap(),
      );

      // Update cache
      _userCache[userId] = newUser;
      notifyListeners();

      // Log activity
      await _auditService.logActivity(
        userId: createdBy ?? 'system',
        userName: createdBy ?? 'system',
        action: 'CREATE',
        resourceType: 'User',
        resourceId: userId,
        changesAfter: newUser.toMap(),
        success: true,
      );

      print('✅ User created: $userId');
      return newUser;
    } catch (e) {
      print('❌ Error creating user: $e');

      // Log failed activity
      await _auditService.logActivity(
        userId: createdBy ?? 'system',
        userName: createdBy ?? 'system',
        action: 'CREATE',
        resourceType: 'User',
        resourceId: userId,
        changesAfter: newUser.toMap(),
        success: false,
      );

      throw Exception('Failed to create user: $e');
    }
  }

  /// Update user
  Future<BackendUserModel> updateUser({
    required String userId,
    String? displayName,
    String? phone,
    String? roleId,
    List<String>? locationIds,
    String? updatedBy,
  }) async {
    print('✏️ Updating user: $userId');
    await ensureInitialized();

    final existingUser = await getUserById(userId);
    if (existingUser == null) {
      throw Exception('User not found: $userId');
    }

    // Build update map with only changed fields
    final updates = <String, dynamic>{};
    if (displayName != null && displayName != existingUser.displayName) {
      updates['displayName'] = displayName;
    }
    if (phone != null && phone != existingUser.phone) {
      updates['phone'] = phone;
    }
    if (roleId != null && roleId != existingUser.roleId) {
      updates['roleId'] = roleId;
    }
    if (locationIds != null) {
      updates['locationIds'] = locationIds;
    }

    if (updates.isEmpty) {
      print('ℹ️ No changes to update');
      return existingUser;
    }

    updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

    try {
      await _appwrite.updateDocument(
        collectionId: AppwritePhase1Service.backendUsersCol,
        documentId: userId,
        data: updates,
      );

      // Update cache
      final updatedUser = existingUser.copyWith(
        displayName: displayName ?? existingUser.displayName,
        phone: phone ?? existingUser.phone,
        roleId: roleId ?? existingUser.roleId,
        locationIds: locationIds ?? existingUser.locationIds,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );

      _userCache[userId] = updatedUser;
      notifyListeners();

      // Log activity
      await _auditService.logActivity(
        userId: updatedBy ?? 'system',
        userName: updatedBy ?? 'system',
        action: 'UPDATE',
        resourceType: 'User',
        resourceId: userId,
        changesBefore: existingUser.toMap(),
        changesAfter: updatedUser.toMap(),
        success: true,
      );

      print('✅ User updated: $userId');
      return updatedUser;
    } catch (e) {
      print('❌ Error updating user: $e');

      await _auditService.logActivity(
        userId: updatedBy ?? 'system',
        userName: updatedBy ?? 'system',
        action: 'UPDATE',
        resourceType: 'User',
        resourceId: userId,
        success: false,
      );

      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user
  Future<void> deleteUser({
    required String userId,
    String? deletedBy,
  }) async {
    print('🗑️ Deleting user: $userId');
    await ensureInitialized();

    final userToDelete = await getUserById(userId);
    if (userToDelete == null) {
      throw Exception('User not found: $userId');
    }

    try {
      await _appwrite.deleteDocument(
        collectionId: AppwritePhase1Service.backendUsersCol,
        documentId: userId,
      );

      // Remove from cache
      _userCache.remove(userId);
      notifyListeners();

      // Log activity
      await _auditService.logActivity(
        userId: deletedBy ?? 'system',
        userName: deletedBy ?? 'system',
        action: 'DELETE',
        resourceType: 'User',
        resourceId: userId,
        changesBefore: userToDelete.toMap(),
        success: true,
      );

      print('✅ User deleted: $userId');
    } catch (e) {
      print('❌ Error deleting user: $e');

      await _auditService.logActivity(
        userId: deletedBy ?? 'system',
        userName: deletedBy ?? 'system',
        action: 'DELETE',
        resourceType: 'User',
        resourceId: userId,
        success: false,
      );

      throw Exception('Failed to delete user: $e');
    }
  }

  /// Lock user account (prevent login)
  Future<void> lockUser({
    required String userId,
    String? lockedBy,
  }) async {
    print('🔒 Locking user: $userId');
    await ensureInitialized();

    try {
      await _appwrite.updateDocument(
        collectionId: AppwritePhase1Service.backendUsersCol,
        documentId: userId,
        data: {
          'isLocked': true,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Update cache
      final user = _userCache[userId];
      if (user != null) {
        _userCache[userId] = user.copyWith(isLockedOut: true);
      }
      notifyListeners();

      await _auditService.logActivity(
        userId: lockedBy ?? 'system',
        userName: lockedBy ?? 'system',
        action: 'LOCK',
        resourceType: 'User',
        resourceId: userId,
        success: true,
      );

      print('✅ User locked: $userId');
    } catch (e) {
      print('❌ Error locking user: $e');
      throw Exception('Failed to lock user: $e');
    }
  }

  /// Unlock user account
  Future<void> unlockUser({
    required String userId,
    String? unlockedBy,
  }) async {
    print('🔓 Unlocking user: $userId');
    await ensureInitialized();

    try {
      await _appwrite.updateDocument(
        collectionId: AppwritePhase1Service.backendUsersCol,
        documentId: userId,
        data: {
          'isLocked': false,
          'failedLoginAttempts': 0,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Update cache
      final user = _userCache[userId];
      if (user != null) {
        _userCache[userId] = user.copyWith(isLockedOut: false);
      }
      notifyListeners();

      await _auditService.logActivity(
        userId: unlockedBy ?? 'system',
        userName: unlockedBy ?? 'system',
        action: 'UNLOCK',
        resourceType: 'User',
        resourceId: userId,
        success: true,
      );

      print('✅ User unlocked: $userId');
    } catch (e) {
      print('❌ Error unlocking user: $e');
      throw Exception('Failed to unlock user: $e');
    }
  }

  /// Deactivate user
  Future<void> deactivateUser({
    required String userId,
    String? deactivatedBy,
  }) async {
    print('⚠️ Deactivating user: $userId');
    await ensureInitialized();

    try {
      await _appwrite.updateDocument(
        collectionId: AppwritePhase1Service.backendUsersCol,
        documentId: userId,
        data: {
          'isActive': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Update cache
      final user = _userCache[userId];
      if (user != null) {
        _userCache[userId] = user.copyWith(isActive: false);
      }
      notifyListeners();

      await _auditService.logActivity(
        userId: deactivatedBy ?? 'system',
        userName: deactivatedBy ?? 'system',
        action: 'DEACTIVATE',
        resourceType: 'User',
        resourceId: userId,
        success: true,
      );

      print('✅ User deactivated: $userId');
    } catch (e) {
      print('❌ Error deactivating user: $e');
      throw Exception('Failed to deactivate user: $e');
    }
  }

  /// Fetch all users from Appwrite
  Future<List<BackendUserModel>> _fetchAllUsersFromAppwrite() async {
    try {
      final docs = await _appwrite
          .listDocuments(
            collectionId: AppwritePhase1Service.backendUsersCol,
            limit: 100,
          )
          .timeout(const Duration(seconds: 2));

      return docs.map(_documentToBackendUserModel).toList();
    } catch (e) {
      print('❌ Error fetching users from Appwrite: $e');
      return [];
    }
  }

  /// Convert Appwrite document to BackendUserModel
  BackendUserModel _documentToBackendUserModel(Map<String, dynamic> doc) {
    return BackendUserModel(
      id: doc[r'$id'] ?? doc['id'] ?? '',
      email: doc['email'] ?? '',
      displayName: doc['displayName'] ?? '',
      roleId: doc['roleId'] ?? '',
      phone: doc['phone'],
      locationIds: (doc['locationIds'] is List)
          ? List<String>.from(doc['locationIds'])
          : [],
      isActive: doc['isActive'] ?? true,
      createdAt: doc['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: doc['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      createdBy: doc['createdBy'],
    );
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Clear cache
  void clearCache() {
    _userCache.clear();
    _lastCacheRefresh = null;
  }

  /// Initialize with test data (for development only)
  Future<void> seedTestData() async {
    print('🌱 Seeding test data...');
    // In production, this would be removed
    // Test data is created via separate admin tool
  }

  @override
  void dispose() {
    _userCache.clear();
    super.dispose();
  }
}
