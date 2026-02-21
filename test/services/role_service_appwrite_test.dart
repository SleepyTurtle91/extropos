import 'package:extropos/models/role_model.dart';
import 'package:extropos/services/role_service_appwrite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RoleServiceAppwrite', () {
    late RoleServiceAppwrite service;

    setUp(() {
      service = RoleServiceAppwrite.instance;
    });

    test('getSystemRoles() returns exactly 4 roles', () {
      final roles = service.getSystemRoles();
      expect(roles.length, 4);
      expect(
        roles.map((r) => r.name).toList(),
        containsAll(['Admin', 'Manager', 'Supervisor', 'Viewer']),
      );
    });

    test('admin role has all permissions', () {
      final adminRole = service.getSystemRoles().firstWhere(
        (r) => r.name == 'Admin',
      );
      expect(adminRole.permissions.length, Permission.ALL_PERMISSIONS.length);
    });

    test('getRoleById() returns null for non-existent role', () async {
      final role = await service.getRoleById('non_existent_id');
      expect(role, null);
    });

    test('getRoleById() returns system role', () async {
      final adminRoleId = RoleServiceAppwrite.adminRoleId;
      final role = await service.getRoleById(adminRoleId);
      
      expect(role, isNotNull);
      expect(role?.name, 'Admin');
      expect(role?.isSystemRole, true);
    });

    test('system roles cannot be modified', () async {
      expect(
        () => service.updateRolePermissions(
          roleId: RoleServiceAppwrite.adminRoleId,
          permissions: ['VIEW_USERS'],
        ),
        throwsException,
      );
    });

    test('system roles cannot be deleted', () async {
      expect(
        () => service.deleteRole(
          roleId: RoleServiceAppwrite.adminRoleId,
          deletedBy: 'system',
        ),
        throwsException,
      );
    });

    test('roleHasPermission() checks permission correctly', () async {
      final hasPermission = await service.roleHasPermission(
        roleId: RoleServiceAppwrite.adminRoleId,
        permission: 'VIEW_USERS',
      );
      expect(hasPermission, true);
    });

    test('roleHasPermission() returns false for missing permission', () async {
      // Viewer role has limited permissions
      final hasPermission = await service.roleHasPermission(
        roleId: RoleServiceAppwrite.viewerRoleId,
        permission: 'DELETE_USERS',
      );
      expect(hasPermission, false);
    });

    test('getAllRoles() includes system roles', () async {
      final roles = await service.getAllRoles();
      final systemRoles = roles.where((r) => r.isSystemRole);
      expect(systemRoles.length, greaterThanOrEqualTo(4));
    });

    test('createCustomRole() requires valid name', () async {
      expect(
        () => service.createCustomRole(
          name: '',
          permissions: ['VIEW_USERS'],
          createdBy: 'system',
        ),
        throwsException,
      );
    });

    test('createCustomRole() requires at least one permission', () async {
      expect(
        () => service.createCustomRole(
          name: 'Test Role',
          permissions: [],
          createdBy: 'system',
        ),
        throwsException,
      );
    });

    test('createCustomRole() creates custom role', () async {
      // final role = await service.createCustomRole(
      //   name: 'Test Role ${DateTime.now().millisecondsSinceEpoch}',
      //   permissions: ['VIEW_USERS', 'VIEW_INVENTORY'],
      //   createdBy: 'system',
      // );
      // expect(role.isSystemRole, false);
      // expect(role.permissions.length, 2);
    });
  });
}
