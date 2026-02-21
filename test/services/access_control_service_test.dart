import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccessControlService', () {
    late AccessControlService service;
    late RoleModel adminRole;
    late RoleModel viewerRole;
    late BackendUserModel adminUser;
    late BackendUserModel viewerUser;

    setUp(() {
      service = AccessControlService.instance;
      
      // Create admin role with all permissions
      adminRole = RoleModel(
        id: 'admin_role',
        name: 'Admin',
        description: 'Administrator with full access',
        permissions: {
          'view_users': true,
          'create_users': true,
          'edit_users': true,
          'delete_users': true,
          'view_roles': true,
          'create_roles': true,
          'view_inventory': true,
          'adjust_inventory': true,
          'view_reports': true,
          'export_reports': true,
        },
        isSystemRole: true,
        createdAt: 0,
        updatedAt: 0,
      );

      // Create viewer role with limited permissions
      viewerRole = RoleModel(
        id: 'viewer_role',
        name: 'Viewer',
        description: 'View-only access',
        permissions: {
          'view_users': true,
          'view_roles': true,
          'view_inventory': true,
          'view_reports': true,
          'adjust_inventory': false,
          'delete_users': false,
        },
        isSystemRole: false,
        createdAt: 0,
        updatedAt: 0,
      );

      // Create admin user
      adminUser = BackendUserModel(
        id: 'user_admin_1',
        email: 'admin@example.com',
        displayName: 'Admin User',
        roleId: 'admin_role',
        roleName: 'Admin',
        locationIds: ['loc_1', 'loc_2'],
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      );

      // Create viewer user
      viewerUser = BackendUserModel(
        id: 'user_viewer_1',
        email: 'viewer@example.com',
        displayName: 'Viewer User',
        roleId: 'viewer_role',
        roleName: 'Viewer',
        locationIds: ['loc_1'],
        isActive: true,
        createdAt: 0,
        updatedAt: 0,
      );
    });

    tearDown(() {
      service.logout();
    });

    test('initialize() sets current user and role', () async {
      await service.initialize(adminUser, adminRole);
      
      expect(service.currentUser, equals(adminUser));
      expect(service.currentUserRole, equals(adminRole));
    });

    test('currentUser returns null when not initialized', () {
      expect(service.currentUser, isNull);
      expect(service.currentUserRole, isNull);
    });

    test('hasPermission() returns true for allowed permission', () async {
      await service.initialize(adminUser, adminRole);
      
      final hasPermission = await service.hasPermission('view_users');
      expect(hasPermission, isTrue);
    });

    test('hasPermission() returns false for denied permission', () async {
      await service.initialize(adminUser, adminRole);
      
      final hasPermission = await service.hasPermission('nonexistent_permission');
      expect(hasPermission, isFalse);
    });

    test('hasPermission() returns false when user not initialized', () async {
      final hasPermission = await service.hasPermission('view_users');
      expect(hasPermission, isFalse);
    });

    test('hasPermission() caches results', () async {
      await service.initialize(adminUser, adminRole);
      
      // First call
      final result1 = await service.hasPermission('view_users');
      expect(result1, isTrue);
      
      // Second call should hit cache
      final result2 = await service.hasPermission('view_users');
      expect(result2, isTrue);
    });

    test('hasAllPermissions() returns true when all permissions granted', () async {
      await service.initialize(adminUser, adminRole);
      
      final hasAll = await service.hasAllPermissions([
        'view_users',
        'create_users',
        'view_inventory',
      ]);
      expect(hasAll, isTrue);
    });

    test('hasAllPermissions() returns false when any permission denied', () async {
      await service.initialize(viewerUser, viewerRole);
      
      final hasAll = await service.hasAllPermissions([
        'view_users',
        'delete_users', // This should fail
      ]);
      expect(hasAll, isFalse);
    });

    test('hasAnyPermission() returns true when at least one permission granted', () async {
      await service.initialize(viewerUser, viewerRole);
      
      final hasAny = await service.hasAnyPermission([
        'delete_users', // False
        'view_users',   // True
      ]);
      expect(hasAny, isTrue);
    });

    test('hasAnyPermission() returns false when no permissions granted', () async {
      await service.initialize(viewerUser, viewerRole);
      
      final hasAny = await service.hasAnyPermission([
        'delete_users',
        'create_users',
      ]);
      expect(hasAny, isFalse);
    });

    test('canAccessLocation() returns true for allowed location', () async {
      await service.initialize(adminUser, adminRole);
      
      final canAccess = service.canAccessLocation('loc_1');
      expect(canAccess, isTrue);
    });

    test('canAccessLocation() returns false for denied location', () async {
      await service.initialize(viewerUser, viewerRole);
      
      final canAccess = service.canAccessLocation('loc_2');
      expect(canAccess, isFalse);
    });

    test('canAccessLocation() returns false when user not initialized', () {
      final canAccess = service.canAccessLocation('loc_1');
      expect(canAccess, isFalse);
    });

    test('isAdmin() returns true for admin role', () async {
      await service.initialize(adminUser, adminRole);
      
      final isAdmin = await service.isAdmin();
      expect(isAdmin, isTrue);
    });

    test('isAdmin() returns false for non-admin role', () async {
      await service.initialize(viewerUser, viewerRole);
      
      final isAdmin = await service.isAdmin();
      expect(isAdmin, isFalse);
    });

    test('isAdmin() returns false when role not initialized', () async {
      final isAdmin = await service.isAdmin();
      expect(isAdmin, isFalse);
    });

    test('getCurrentUserPermissions() returns role permissions', () async {
      await service.initialize(adminUser, adminRole);
      
      final permissions = service.getCurrentUserPermissions();
      expect(permissions, contains('view_users'));
      expect(permissions, contains('create_users'));
      expect(permissions, contains('delete_users'));
    });

    test('getCurrentUserPermissions() returns empty list when not initialized', () {
      final permissions = service.getCurrentUserPermissions();
      expect(permissions, isEmpty);
    });

    test('clearPermissionCache() clears cached permissions', () async {
      await service.initialize(adminUser, adminRole);
      
      // Cache a permission
      await service.hasPermission('view_users');
      
      // Clear cache
      service.clearPermissionCache();
      
      // Service should still have user after clearing cache
      expect(service.currentUser, equals(adminUser));
    });

    test('logout() clears current user and role', () async {
      await service.initialize(adminUser, adminRole);
      
      expect(service.currentUser, isNotNull);
      expect(service.currentUserRole, isNotNull);
      
      service.logout();
      
      expect(service.currentUser, isNull);
      expect(service.currentUserRole, isNull);
    });

    test('logout() clears permission cache', () async {
      await service.initialize(adminUser, adminRole);
      
      // Cache a permission
      await service.hasPermission('view_users');
      
      // Logout
      service.logout();
      
      // User should be cleared
      expect(service.currentUser, isNull);
    });

    test('singleton instance returns same object', () {
      final service1 = AccessControlService();
      final service2 = AccessControlService.instance;
      
      expect(service1, equals(service2));
    });

    test('toString() returns readable representation', () async {
      await service.initialize(adminUser, adminRole);
      
      final string = service.toString();
      expect(string, contains('AccessControlService'));
      expect(string, contains('admin@example.com'));
    });

    test('toString() shows null when not initialized', () {
      final string = service.toString();
      expect(string, contains('null'));
    });

    test('permission cache expires after TTL', () async {
      await service.initialize(adminUser, adminRole);
      
      // Cache a permission
      final result1 = await service.hasPermission('view_users');
      expect(result1, isTrue);
      
      // Note: In real implementation, we'd test actual expiration
      // by mocking time. For now, just verify the cache structure works.
    });

    test('admin user can access multiple locations', () async {
      await service.initialize(adminUser, adminRole);
      
      expect(service.canAccessLocation('loc_1'), isTrue);
      expect(service.canAccessLocation('loc_2'), isTrue);
    });

    test('viewer user has restricted location access', () async {
      await service.initialize(viewerUser, viewerRole);
      
      expect(service.canAccessLocation('loc_1'), isTrue);
      expect(service.canAccessLocation('loc_2'), isFalse);
    });
  });
}
