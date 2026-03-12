import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:extropos/services/audit_service.dart';
import 'package:extropos/services/backend_user_service_appwrite.dart';
import 'package:extropos/services/phase1_inventory_service_appwrite.dart';
import 'package:extropos/services/role_service_appwrite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:universal_io/io.dart' show Platform;

final bool _runAppwriteIntegration =
  bool.fromEnvironment('RUN_APPWRITE_INTEGRATION') ||
  Platform.environment['RUN_APPWRITE_INTEGRATION'] == '1' ||
  (Platform.environment['RUN_APPWRITE_INTEGRATION']?.toLowerCase() ==
    'true');

/// Phase 2 Backend Integration Tests
///
/// Tests end-to-end workflows with Appwrite services in test mode
/// to ensure all services work together correctly.
void main() {
  group(
    'Phase 2 Backend Integration Tests',
    () {
    late BackendUserServiceAppwrite userService;
    late RoleServiceAppwrite roleService;
    late Phase1InventoryServiceAppwrite inventoryService;
    late AuditService auditService;
    late AccessControlService accessControlService;

    setUp(() {
      userService = BackendUserServiceAppwrite.instance;
      roleService = RoleServiceAppwrite.instance;
      inventoryService = Phase1InventoryServiceAppwrite.instance;
      auditService = AuditService.instance;
      accessControlService = AccessControlService.instance;

      // Clear all caches
      userService.clearCache();
      roleService.clearCache();
      inventoryService.clearCache();
      auditService.clearCache();
      accessControlService.logout();
    });

    group('User Lifecycle Workflow', () {
      test('Complete user creation, update, and deletion workflow', () async {
        // 1. Get predefined roles
        final roles = await roleService.getAllRoles();
        expect(roles.isNotEmpty, isTrue, reason: 'Should have predefined roles');

        final adminRole = roles.firstWhere((r) => r.name == 'Admin');
        expect(adminRole, isNotNull);

        // 2. Create a new user
        final createdUser = await userService.createUser(
          email: 'integration.test@example.com',
          displayName: 'Integration Test User',
          phone: '+60123456789',
          roleId: adminRole.id!,
          locationIds: ['loc_main'],
        );
        expect(createdUser, isNotNull);
        expect(createdUser.email, equals('integration.test@example.com'));
        expect(createdUser.id, isNotNull);

        // 3. Verify user appears in list
        final allUsers = await userService.getAllUsers();
        expect(
          allUsers.any((u) => u.email == 'integration.test@example.com'),
          isTrue,
          reason: 'Created user should appear in all users list',
        );

        // 4. Update user
        await userService.updateUser(
          userId: createdUser.id!,
          displayName: 'Updated Test User',
          phone: '+60198765432',
        );

        // 5. Verify update
        final fetchedUser = await userService.getUserById(createdUser.id!);
        expect(fetchedUser, isNotNull);
        expect(fetchedUser!.displayName, equals('Updated Test User'));
        expect(fetchedUser.phone, equals('+60198765432'));

        // 6. Deactivate user
        await userService.deactivateUser(userId: createdUser.id!);

        final inactiveUser = await userService.getUserById(createdUser.id!);
        expect(inactiveUser, isNotNull);
        expect(inactiveUser!.isActive, isFalse);

        // 7. Delete user
        await userService.deleteUser(userId: createdUser.id!);

        // 8. Verify deletion
        final deletedUser = await userService.getUserById(createdUser.id!);
        expect(deletedUser, isNull);
      });

      test('Email uniqueness validation works across operations', () async {
        final roles = await roleService.getAllRoles();
        final viewerRole = roles.firstWhere((r) => r.name == 'Viewer');

        // Create first user
        final created1 = await userService.createUser(
          email: 'unique.test@example.com',
          displayName: 'User One',
          roleId: viewerRole.id!,
          locationIds: ['loc_main'],
        );
        expect(created1, isNotNull);

        // Attempt to create second user with same email — service throws
        try {
          await userService.createUser(
            email: 'unique.test@example.com',
            displayName: 'User Two',
            roleId: viewerRole.id!,
            locationIds: ['loc_main'],
          );
          fail('Should reject duplicate email');
        } catch (e) {
          expect(e.toString(), contains('already exists'));
        }

        // Cleanup
        await userService.deleteUser(userId: created1.id!);
            });
    });

    group('Role and Permission Workflow', () {
      test('User permissions are correctly loaded and checked', () async {
        // 1. Get predefined manager role
        final roles = await roleService.getAllRoles();
        final managerRole = roles.firstWhere((r) => r.name == 'Manager');
        expect(managerRole, isNotNull);

        // 2. Create user with manager role
        final createdUser = await userService.createUser(
          email: 'manager.test@example.com',
          displayName: 'Test Manager',
          roleId: managerRole.id!,
          locationIds: ['loc_main'],
        );
        expect(createdUser, isNotNull);

        // 3. Initialize access control service
        await accessControlService.initialize(createdUser, managerRole);
        expect(accessControlService.currentUser, isNotNull);
        expect(accessControlService.currentUserRole, isNotNull);

        // 4. Check manager permissions
        final canViewUsers = await accessControlService.hasPermission('view_users');
        expect(canViewUsers, isTrue, reason: 'Manager should have view_users permission');

        final canDeleteUsers = await accessControlService.hasPermission('delete_users');
        expect(canDeleteUsers, isFalse, reason: 'Manager should NOT have delete_users permission');

        final canViewInventory = await accessControlService.hasPermission('view_inventory');
        expect(canViewInventory, isTrue, reason: 'Manager should have view_inventory permission');

        // 5. Check admin status
        final isAdmin = await accessControlService.isAdmin();
        expect(isAdmin, isFalse, reason: 'Manager should NOT be admin');

        // 6. Cleanup
        accessControlService.logout();
        await userService.deleteUser(userId: createdUser.id!);
            });

      test('Admin user has all permissions', () async {
        final roles = await roleService.getAllRoles();
        final adminRole = roles.firstWhere((r) => r.name == 'Admin');

        final createdUser = await userService.createUser(
          email: 'admin.test@example.com',
          displayName: 'Test Admin',
          roleId: adminRole.id!,
          locationIds: ['loc_main'],
        );
        expect(createdUser, isNotNull);

        await accessControlService.initialize(createdUser, adminRole);

        // Check multiple permissions
        final hasViewUsers = await accessControlService.hasPermission('view_users');
        final hasCreateUsers = await accessControlService.hasPermission('create_users');
        final hasDeleteUsers = await accessControlService.hasPermission('delete_users');
        final hasManageRoles = await accessControlService.hasPermission('manage_roles');

        expect(hasViewUsers, isTrue);
        expect(hasCreateUsers, isTrue);
        expect(hasDeleteUsers, isTrue);
        expect(hasManageRoles, isTrue);

        final isAdmin = await accessControlService.isAdmin();
        expect(isAdmin, isTrue);

        // Cleanup
        accessControlService.logout();
        await userService.deleteUser(userId: createdUser.id!);
            });
    });

    group('Inventory Management Workflow', () {
      test('Complete inventory lifecycle with movements', () async {
        // 1. Create inventory item
        final created = await inventoryService.createInventoryItem(
          productId: 'test_prod_123',
          productName: 'Integration Test Product',
          locationId: 'warehouse_1',
          initialQuantity: 100.0,
          minimumStockLevel: 20.0,
          maximumStockLevel: 200.0,
          costPerUnit: 15.50,
        );
        expect(created, isNotNull);
        expect(created.productId, equals('test_prod_123'));
        expect(created.currentQuantity, equals(100.0));

        // 2. Record SALE movement
        await inventoryService.addStockMovement(
          productId: 'test_prod_123',
          movementType: StockMovementType.sale.name,
          quantity: 10.0,
          reason: 'Customer purchase',
          userId: 'integration_test',
        );

        var updated = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(updated, isNotNull);
        expect(updated!.currentQuantity, equals(90.0));
        expect(updated.movements.last.type, equals(StockMovementType.sale));

        // 3. Record RESTOCK movement
        await inventoryService.addStockMovement(
          productId: 'test_prod_123',
          movementType: StockMovementType.purchase.name,
          quantity: 50.0,
          reason: 'Supplier delivery',
          userId: 'integration_test',
        );

        updated = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(updated!.currentQuantity, equals(140.0));

        // 4. Record DAMAGE movement
        await inventoryService.addStockMovement(
          productId: 'test_prod_123',
          movementType: StockMovementType.waste.name,
          quantity: 5.0,
          reason: 'Damaged during handling',
          userId: 'integration_test',
        );

        updated = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(updated!.currentQuantity, equals(135.0));

        // 5. Perform stock take
        await inventoryService.performStockTake(
          productId: 'test_prod_123',
          countedQuantity: 130.0,
          userId: 'integration_test',
          notes: 'Weekly physical count',
        );

        updated = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(updated!.currentQuantity, equals(130.0));
        expect(updated.movements.length, equals(4));

        final stockTakeMovement = updated.movements.last;
        expect(stockTakeMovement.type, equals(StockMovementType.adjustment));
        expect(stockTakeMovement.reason, contains('Weekly physical count'));

        // 6. Calculate inventory value
        final totalValue = await inventoryService.calculateInventoryValue();
        expect(totalValue, greaterThan(0));

        // 7. Get movement history
        final history = await inventoryService.getMovementHistory(productId: 'test_prod_123');
        expect(history.isNotEmpty, isTrue);
        expect(history.every((m) => m.productId == 'test_prod_123'), isTrue);

        // Cleanup - delete inventory item
        await inventoryService.deleteInventoryItem('test_prod_123');
        final deleted = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(deleted, isNull);
      });

      test('Low stock alerts are generated correctly', () async {
        // Create item with low stock
        await inventoryService.createInventoryItem(
          productId: 'low_stock_test',
          productName: 'Low Stock Item',
          locationId: 'main_warehouse',
          initialQuantity: 5.0,
          minimumStockLevel: 20.0,
          maximumStockLevel: 100.0,
          costPerUnit: 10.0,
        );

        // Get low stock items
        final lowItems = await inventoryService.getLowStockItems();
        expect(
          lowItems.any((item) => item.productId == 'low_stock_test'),
          isTrue,
          reason: 'Item should be in low stock list',
        );

        // Cleanup
        await inventoryService.deleteInventoryItem('low_stock_test');
      });
    });

    group('Audit Trail Workflow', () {
      test('All operations are logged in audit trail', () async {
        final initialLogs = await auditService.getRecentActivityLogs(limit: 100);
        final initialLogCount = initialLogs.length;

        // Create user
        final roles = await roleService.getAllRoles();
        final testRole = roles.first;

        final createdUser = await userService.createUser(
          email: 'audit.test@example.com',
          displayName: 'Audit Test User',
          roleId: testRole.id!,
          locationIds: ['loc_main'],
        );
        expect(createdUser, isNotNull);

        // Check audit log increased
        final afterCreateLogs = await auditService.getRecentActivityLogs(limit: 100);
        expect(afterCreateLogs.length, greaterThan(initialLogCount));

        // Update user
        await userService.updateUser(
          userId: createdUser.id!,
          displayName: 'Updated Audit User',
        );

        // Check audit log increased again
        final afterUpdateLogs = await auditService.getRecentActivityLogs(limit: 100);
        expect(afterUpdateLogs.length, greaterThan(afterCreateLogs.length));

        // Get logs for this resource
        final userLogs = await auditService.getResourceHistory(createdUser.id!);
        expect(userLogs.length, greaterThanOrEqualTo(2));

        // Verify log contents
        final createLog = userLogs.firstWhere((log) => log.action == 'CREATE');
        expect(createLog.resourceType, equals('User'));
        expect(createLog.success, isTrue);

        final updateLog = userLogs.firstWhere((log) => log.action == 'UPDATE');
        expect(updateLog.resourceType, equals('User'));
        expect(updateLog.success, isTrue);

        // Cleanup
        await userService.deleteUser(userId: createdUser.id!);
      });
    });

    group('Cache Behavior', () {
      test('Services use cache when backend unavailable', () async {
        // Pre-populate cache by fetching data
        final users = await userService.getAllUsers();
        final roles = await roleService.getAllRoles();
        await inventoryService.getAllInventory();

        expect(users, isNotEmpty, reason: 'Should have some users in cache');
        expect(roles, isNotEmpty, reason: 'Should have roles in cache');

        // In test mode, backend is unavailable
        // Services should return cached data

        // Fetch again - should come from cache
        final cachedUsers = await userService.getAllUsers();
        final cachedRoles = await roleService.getAllRoles();

        expect(cachedUsers.length, equals(users.length));
        expect(cachedRoles.length, equals(roles.length));
      });

      test('Cache is cleared correctly', () async {
        // Populate cache
        await userService.getAllUsers();
        await roleService.getAllRoles();
        await inventoryService.getAllInventory();

        // Clear caches
        userService.clearCache();
        roleService.clearCache();
        inventoryService.clearCache();

        // In test mode with cleared cache, operations should still work
        // but may return empty lists
        final users = await userService.getAllUsers();
        expect(users, isNotNull);
      });
    });

    group('Error Handling', () {
      test('Services handle invalid data gracefully', () async {
        // Attempt to create user with invalid email — service throws
        try {
          await userService.createUser(
            email: 'not-an-email',
            displayName: 'Invalid User',
            roleId: 'some_role',
            locationIds: ['loc_main'],
          );
          fail('Should reject invalid email');
        } catch (e) {
          expect(e.toString(), contains('Invalid email'));
        }
      });

      test('Services handle missing data gracefully', () async {
        // Attempt to get non-existent user
        final user = await userService.getUserById('non_existent_id');
        expect(user, isNull);

        // Attempt to get non-existent inventory
        final inventory = await inventoryService.getInventoryByProductId('non_existent');
        expect(inventory, isNull);
      });

      test('Inventory prevents negative stock', () async {
        await inventoryService.createInventoryItem(
          productId: 'negative_test',
          productName: 'Negative Test Item',
          locationId: 'main_warehouse',
          initialQuantity: 10.0,
          minimumStockLevel: 5.0,
          maximumStockLevel: 50.0,
          costPerUnit: 5.0,
        );

        // Attempt to sell more than available
        try {
          await inventoryService.addStockMovement(
            productId: 'negative_test',
            movementType: StockMovementType.sale.name,
            quantity: 999.0,
            reason: 'Over-selling',
            userId: 'test',
          );

          // Should not reach here
          fail('Should have thrown exception for insufficient stock');
        } catch (e) {
          expect(e.toString(), contains('Insufficient stock'));
        }

        // Cleanup
        await inventoryService.deleteInventoryItem('negative_test');
      });
    });

    group('Multi-Service Integration', () {
      test('Complete business workflow: User creates inventory and performs operations', () async {
        // 1. Create manager user
        final roles = await roleService.getAllRoles();
        final managerRole = roles.firstWhere((r) => r.name == 'Manager');

        final createdManager = await userService.createUser(
          email: 'workflow.manager@example.com',
          displayName: 'Workflow Manager',
          roleId: managerRole.id!,
          locationIds: ['loc_main', 'loc_branch1'],
        );
        expect(createdManager, isNotNull);

        // 2. Initialize access control
        await accessControlService.initialize(createdManager, managerRole);

        // 3. Check if manager can view inventory
        final canViewInventory = await accessControlService.hasPermission('view_inventory');
        expect(canViewInventory, isTrue);

        // 4. Manager creates inventory item
        final createdProduct = await inventoryService.createInventoryItem(
          productId: 'workflow_prod_001',
          productName: 'Workflow Product',
          locationId: 'main_warehouse',
          initialQuantity: 50.0,
          minimumStockLevel: 10.0,
          maximumStockLevel: 100.0,
          costPerUnit: 20.0,
        );
        expect(createdProduct, isNotNull);

        // 5. Manager performs stock operations
        await inventoryService.addStockMovement(
          productId: 'workflow_prod_001',
          movementType: StockMovementType.sale.name,
          quantity: 5.0,
          reason: 'Customer sale',
          userId: createdManager.id!,
        );

        // 6. Verify audit trail captured all operations
        final logs = await auditService.filterByUser(createdManager.id!);
        expect(logs.isNotEmpty, isTrue);

        // 7. Get final inventory state
        final finalInventory = await inventoryService.getInventoryByProductId('workflow_prod_001');
        expect(finalInventory, isNotNull);
        expect(finalInventory!.currentQuantity, equals(45.0));

        // Cleanup
        accessControlService.logout();
        await inventoryService.deleteInventoryItem('workflow_prod_001');
        await userService.deleteUser(userId: createdManager.id!);
      });
    });
    },
    skip: _runAppwriteIntegration
        ? false
        : 'Requires Appwrite backend. Set RUN_APPWRITE_INTEGRATION=true to run.',
  );
}
