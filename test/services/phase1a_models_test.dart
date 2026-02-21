import 'package:extropos/models/activity_log_model.dart';
import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 1a Models', () {
    
    // ========== RoleModel Tests ==========
    group('RoleModel', () {
      test('creates admin role with all permissions', () {
        final adminPermissions = {
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
        };

        final adminRole = RoleModel(
          id: 'admin_role',
          name: 'Admin',
          description: 'Full system access',
          permissions: adminPermissions,
          isSystemRole: true,
          createdAt: 0,
          updatedAt: 0,
        );

        expect(adminRole.name, 'Admin');
        expect(adminRole.isSystemRole, true);
        expect(adminRole.permissions.length, 20);
      });

      test('RoleModel converts to map and back', () {
        final perms = {
          'view_users': true,
          'create_users': true,
        };

        final role = RoleModel(
          id: 'test_role',
          name: 'Test',
          description: 'Test role',
          permissions: perms,
          isSystemRole: false,
          createdAt: 100,
          updatedAt: 200,
        );

        final roleMap = role.toMap();
        expect(roleMap['name'], 'Test');
        expect(roleMap['description'], 'Test role');
      });

      test('Permission constants are defined', () {
        expect(Permission.VIEW_USERS, isNotNull);
        expect(Permission.CREATE_USERS, isNotNull);
        expect(Permission.ALL_PERMISSIONS.length, greaterThan(0));
      });
    });

    // ========== ActivityLogModel Tests ==========
    group('ActivityLogModel', () {
      test('creates activity log entry', () {
        final log = ActivityLogModel(
          id: 'log_1',
          userId: 'user_1',
          userName: 'John Doe',
          action: 'CREATE',
          resourceType: 'User',
          resourceId: 'user_2',
          description: 'Created new user',
          success: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(log.userId, 'user_1');
        expect(log.userName, 'John Doe');
        expect(log.action, 'CREATE');
        expect(log.success, true);
      });

      test('activity log with changes tracks before/after', () {
        final log = ActivityLogModel(
          id: 'log_2',
          userId: 'user_1',
          userName: 'Admin',
          action: 'UPDATE',
          resourceType: 'Role',
          resourceId: 'role_1',
          description: 'Updated role permissions',
          changesBefore: {'permissions': 'old_value'},
          changesAfter: {'permissions': 'new_value'},
          success: true,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(log.changesBefore, isNotNull);
        expect(log.changesAfter, isNotNull);
        expect(log.changesBefore!['permissions'], 'old_value');
      });

      test('activity log supports error tracking', () {
        final log = ActivityLogModel(
          id: 'log_3',
          userId: 'user_1',
          userName: 'Test User',
          action: 'DELETE',
          resourceType: 'User',
          resourceId: 'user_999',
          description: 'Attempted to delete user',
          success: false,
          errorMessage: 'User not found',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        expect(log.success, false);
        expect(log.errorMessage, 'User not found');
      });
    });

    // ========== BackendUserModel Tests ==========
    group('BackendUserModel', () {
      test('creates backend user', () {
        final user = BackendUserModel(
          id: 'user_1',
          email: 'admin@example.com',
          displayName: 'Admin User',
          roleId: 'admin_role',
          locationIds: ['loc_1', 'loc_2'],
          isActive: true,
          createdAt: 0,
          updatedAt: 0,
        );

        expect(user.email, 'admin@example.com');
        expect(user.displayName, 'Admin User');
        expect(user.roleId, 'admin_role');
        expect(user.isActive, true);
      });

      test('backend user can be deactivated', () {
        final user = BackendUserModel(
          id: 'user_2',
          email: 'user@example.com',
          displayName: 'Regular User',
          roleId: 'viewer_role',
          locationIds: ['loc_1'],
          isActive: true,
          createdAt: 0,
          updatedAt: 0,
        );

        final inactiveUser = user.copyWith(isActive: false);
        expect(inactiveUser.isActive, false);
      });

      test('backend user converts to map', () {
        final user = BackendUserModel(
          id: 'user_3',
          email: 'test@example.com',
          displayName: 'Test User',
          roleId: 'test_role',
          locationIds: ['loc_1', 'loc_3'],
          isActive: true,
          createdAt: 100,
          updatedAt: 200,
        );

        final userMap = user.toMap();
        expect(userMap['email'], 'test@example.com');
        expect(userMap['displayName'], 'Test User');
      });
    });

    // ========== InventoryModel Tests ==========
    group('InventoryModel', () {
      test('creates inventory item', () {
        final inventory = InventoryModel(
          id: 'inv_1',
          productId: 'prod_1',
          productName: 'Widget',
          locationId: 'warehouse_1',
          currentQuantity: 100.0,
          minimumStockLevel: 20.0,
          maximumStockLevel: 500.0,
          reorderQuantity: 50.0,
          lastCountedAt: DateTime.now().millisecondsSinceEpoch,
          createdAt: 0,
          updatedAt: 0,
        );

        expect(inventory.productId, 'prod_1');
        expect(inventory.productName, 'Widget');
        expect(inventory.currentQuantity, 100.0);
      });

      test('inventory tracks stock level changes', () {
        final inventory = InventoryModel(
          id: 'inv_2',
          productId: 'prod_2',
          productName: 'Gadget',
          locationId: 'warehouse_1',
          currentQuantity: 50.0,
          minimumStockLevel: 10.0,
          maximumStockLevel: 300.0,
          reorderQuantity: 30.0,
          lastCountedAt: DateTime.now().millisecondsSinceEpoch,
          createdAt: 0,
          updatedAt: 0,
        );

        final updated = inventory.copyWith(currentQuantity: 45.0);
        expect(updated.currentQuantity, 45.0);
      });

      test('inventory converts to map', () {
        final inventory = InventoryModel(
          id: 'inv_3',
          productId: 'prod_3',
          productName: 'Device',
          locationId: 'warehouse_2',
          currentQuantity: 75.0,
          minimumStockLevel: 15.0,
          maximumStockLevel: 400.0,
          reorderQuantity: 40.0,
          lastCountedAt: DateTime.now().millisecondsSinceEpoch,
          createdAt: 100,
          updatedAt: 200,
        );

        final invMap = inventory.toMap();
        expect(invMap['productName'], 'Device');
        expect(invMap['currentQuantity'], 75.0);
      });
    });

    // ========== Permission Constants ==========
    group('Permission Constants', () {
      test('all permission constants are defined', () {
        expect(Permission.VIEW_USERS, 'view_users');
        expect(Permission.CREATE_USERS, 'create_users');
        expect(Permission.EDIT_USERS, 'edit_users');
        expect(Permission.DELETE_USERS, 'delete_users');
        expect(Permission.VIEW_ROLES, 'view_roles');
        expect(Permission.CREATE_ROLES, 'create_roles');
        expect(Permission.EDIT_ROLES, 'edit_roles');
        expect(Permission.DELETE_ROLES, 'delete_roles');
        expect(Permission.VIEW_INVENTORY, 'view_inventory');
        expect(Permission.ADJUST_INVENTORY, 'adjust_inventory');
        expect(Permission.VIEW_STOCK_MOVEMENTS, 'view_stock_movements');
        expect(Permission.VIEW_ACTIVITY_LOG, 'view_activity_log');
        expect(Permission.EXPORT_ACTIVITY_LOG, 'export_activity_log');
        expect(Permission.VIEW_REPORTS, 'view_reports');
        expect(Permission.EXPORT_REPORTS, 'export_reports');
        expect(Permission.MANAGE_PRODUCTS, 'manage_products');
        expect(Permission.MANAGE_CATEGORIES, 'manage_categories');
        expect(Permission.MANAGE_MODIFIERS, 'manage_modifiers');
        expect(Permission.MANAGE_BUSINESS_INFO, 'manage_business_info');
        expect(Permission.MANAGE_SETTINGS, 'manage_settings');
      });

      test('ALL_PERMISSIONS includes all 20 permissions', () {
        expect(Permission.ALL_PERMISSIONS.length, 20);
      });
    });
  });
}
