import 'package:extropos/models/backend_user_model.dart';
import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:extropos/services/audit_service.dart';
import 'package:extropos/services/backend_user_service_appwrite.dart';
import 'package:extropos/services/phase1_inventory_service_appwrite.dart';
import 'package:extropos/services/role_service_appwrite.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2 Backend Integration Tests
///
/// Tests end-to-end workflows with Appwrite services in test mode
/// to ensure all services work together correctly.
void main() {
  group('Phase 2 Backend Integration Tests', () {
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
        final now = DateTime.now().millisecondsSinceEpoch;
        final newUser = BackendUserModel(
          email: 'integration.test@example.com',
          displayName: 'Integration Test User',
          phone: '+60123456789',
          roleId: adminRole.id,
          roleName: adminRole.name,
          locationIds: ['loc_main'],
          isActive: true,
          createdAt: now,
          updatedAt: now,
        );

        final createdUser = await userService.createUser(newUser);
        expect(createdUser, isNotNull);
        expect(createdUser.email, equals(newUser.email));
        expect(createdUser.id, isNotNull);

        // 3. Verify user appears in list
        final allUsers = await userService.getAllUsers();
        expect(
          allUsers.any((u) => u.email == newUser.email),
          isTrue,
          reason: 'Created user should appear in all users list',
        );

        // 4. Update user
        final updatedUser = createdUser.copyWith(
          displayName: 'Updated Test User',
          phone: '+60198765432',
        );

        final result = await userService.updateUser(updatedUser);
        expect(result, isTrue);

        // 5. Verify update
        final fetchedUser = await userService.getUserById(createdUser.id!);
        expect(fetchedUser, isNotNull);
        expect(fetchedUser!.displayName, equals('Updated Test User'));
        expect(fetchedUser.phone, equals('+60198765432'));

        // 6. Deactivate user
        final deactivated = await userService.deactivateUser(createdUser.id!);
        expect(deactivated, isTrue);

        final inactiveUser = await userService.getUserById(createdUser.id!);
        expect(inactiveUser, isNotNull);
        expect(inactiveUser!.isActive, isFalse);

        // 7. Delete user
        final deleted = await userService.deleteUser(createdUser.id!);
        expect(deleted, isTrue);

        // 8. Verify deletion
        final deletedUser = await userService.getUserById(createdUser.id!);
        expect(deletedUser, isNull);
      });

      test('Email uniqueness validation works across operations', () async {
        final roles = await roleService.getAllRoles();
        final viewerRole = roles.firstWhere((r) => r.name == 'Viewer');

        // Create first user
        final now = DateTime.now().millisecondsSinceEpoch;
        final user1 = BackendUserModel(
          email: 'unique.test@example.com',
          displayName: 'User One',
          roleId: viewerRole.id,
          roleName: viewerRole.name,
          locationIds: ['loc_main'],
          createdAt: now,
          updatedAt: now,
        );

        final created1 = await userService.createUser(user1);
        expect(created1, isNotNull);

        // Attempt to create second user with same email
        final user2 = BackendUserModel(
          email: 'unique.test@example.com',
          displayName: 'User Two',
          roleId: viewerRole.id,
          roleName: viewerRole.name,
          locationIds: ['loc_main'],
          createdAt: now,
          updatedAt: now,
        );

        final created2 = await userService.createUser(user2);
        expect(created2, isNull, reason: 'Should reject duplicate email');

        // Cleanup
        await userService.deleteUser(created1.id!);
            });
    });

    group('Role and Permission Workflow', () {
      test('User permissions are correctly loaded and checked', () async {
        // 1. Get predefined manager role
        final roles = await roleService.getAllRoles();
        final managerRole = roles.firstWhere((r) => r.name == 'Manager');
        expect(managerRole, isNotNull);

        // 2. Create user with manager role
        final now = DateTime.now().millisecondsSinceEpoch;
        final user = BackendUserModel(
          email: 'manager.test@example.com',
          displayName: 'Test Manager',
          roleId: managerRole.id,
          roleName: managerRole.name,
          locationIds: ['loc_main'],
          createdAt: now,
          updatedAt: now,
        );

        final createdUser = await userService.createUser(user);
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
        await userService.deleteUser(createdUser.id!);
            });

      test('Admin user has all permissions', () async {
        final roles = await roleService.getAllRoles();
        final adminRole = roles.firstWhere((r) => r.name == 'Admin');

        final now = DateTime.now().millisecondsSinceEpoch;
        final adminUser = BackendUserModel(
          email: 'admin.test@example.com',
          displayName: 'Test Admin',
          roleId: adminRole.id,
          roleName: adminRole.name,
          locationIds: ['loc_main'],
          createdAt: now,
          updatedAt: now,
        );

        final createdUser = await userService.createUser(adminUser);
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
        await userService.deleteUser(createdUser.id!);
            });
    });

    group('Inventory Management Workflow', () {
      test('Complete inventory lifecycle with movements', () async {
        // 1. Create inventory item
        final inventory = InventoryModel(
          productId: 'test_prod_123',
          productName: 'Integration Test Product',
          locationId: 'warehouse_1',
          currentQuantity: 100.0,
          minimumStockLevel: 20.0,
          maximumStockLevel: 200.0,
          reorderQuantity: 50.0,
          costPerUnit: 15.50,
          lastCountedAt: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          movements: [],
        );

        final created = await inventoryService.createInventoryItem(inventory);
        expect(created, isNotNull);
        expect(created.productId, equals(inventory.productId));
        expect(created.currentQuantity, equals(100.0));

        // 2. Record SALE movement
        await inventoryService.addStockMovement(
          productId: 'test_prod_123',
          movementType: StockMovementType.sale,
          quantity: 10.0,
          reason: 'Customer purchase',
          userId: 'integration_test',
        );

        var updated = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(updated, isNotNull);
        expect(updated!.currentQuantity, equals(90.0));
        expect(updated.movements.length, equals(1));
        expect(updated.movements[0].type, equals(StockMovementType.sale));

        // 3. Record RESTOCK movement
        await inventoryService.addStockMovement(
          productId: 'test_prod_123',
          movementType: StockMovementType.purchase,
          quantity: 50.0,
          reason: 'Supplier delivery',
          userId: 'integration_test',
        );

        updated = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(updated!.currentQuantity, equals(140.0));
        expect(updated.movements.length, equals(2));

        // 4. Record DAMAGE movement
        await inventoryService.addStockMovement(
          productId: 'test_prod_123',
          movementType: StockMovementType.waste,
          quantity: 5.0,
          reason: 'Damaged during handling',
          userId: 'integration_test',
        );

        updated = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(updated!.currentQuantity, equals(135.0));
        expect(updated.movements.length, equals(3));

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
        expect(stockTakeMovement.notes, contains('Variance: -5.0'));

        // 6. Calculate inventory value
        final totalValue = await inventoryService.calculateInventoryValue();
        expect(totalValue, greaterThan(0));

        // 7. Get movement history
        final history = await inventoryService.getMovementHistory('test_prod_123');
        expect(history.length, equals(4));
        expect(history.every((m) => m.productId == 'test_prod_123'), isTrue);

        // Cleanup - delete inventory item
        await inventoryService.deleteInventoryItem('test_prod_123');
        final deleted = await inventoryService.getInventoryByProductId('test_prod_123');
        expect(deleted, isNull);
      });

      test('Low stock alerts are generated correctly', () async {
        // Create item with low stock
        final lowStockItem = InventoryModel(
          productId: 'low_stock_test',
          productName: 'Low Stock Item',
          locationId: 'main_warehouse',
          currentQuantity: 5.0,
          minStockLevel: 20.0,
          maxStockLevel: 100.0,
          costPerUnit: 10.0,
          reorderQuantity: 50.0,
          lastCountedAt: DateTime.now(),
          movements: [],
        );

        await inventoryService.createInventoryItem(lowStockItem);

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
        final initialLogCount = auditService.getRecentLogs(limit: 100).length;

        // Create user
        final roles = await roleService.getAllRoles();
        final testRole = roles.first;

        final now = DateTime.now().millisecondsSinceEpoch;
        final user = BackendUserModel(
          email: 'audit.test@example.com',
          displayName: 'Audit Test User',
          roleId: testRole.id,
          roleName: testRole.name,
          locationIds: ['loc_main'],
          createdAt: now,
          updatedAt: now,
        );

        final createdUser = await userService.createUser(user);
        expect(createdUser, isNotNull);

        // Check audit log increased
        final afterCreate = auditService.getRecentLogs(limit: 100).length;
        expect(afterCreate, greaterThan(initialLogCount));

        // Update user
        final updated = createdUser.copyWith(displayName: 'Updated Audit User');
        await userService.updateUser(updated);

        // Check audit log increased again
        final afterUpdate = auditService.getRecentLogs(limit: 100).length;
        expect(afterUpdate, greaterThan(afterCreate));

        // Get logs for this user
        final userLogs = auditService.getLogsByResourceId(createdUser.id!);
        expect(userLogs.length, greaterThanOrEqualTo(2));

        // Verify log contents
        final createLog = userLogs.firstWhere((log) => log.action == 'CREATE');
        expect(createLog.resourceType, equals('USER'));
        expect(createLog.success, isTrue);

        final updateLog = userLogs.firstWhere((log) => log.action == 'UPDATE');
        expect(updateLog.resourceType, equals('USER'));
        expect(updateLog.success, isTrue);

        // Cleanup
        await userService.deleteUser(createdUser.id!);
      });
    });

    group('Cache Behavior', () {
      test('Services use cache when backend unavailable', () async {
        // Pre-populate cache by fetching data
        final users = await userService.getAllUsers();
        final roles = await roleService.getAllRoles();
        final inventory = await inventoryService.getAllInventory();

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
        // Attempt to create user with invalid email
        final now = DateTime.now().millisecondsSinceEpoch;
        final invalidUser = BackendUserModel(
          email: 'not-an-email',
          displayName: 'Invalid User',
          roleId: 'some_role',
          roleName: 'Role',
          locationIds: ['loc_main'],
          createdAt: now,
          updatedAt: now,
        );

        final result = await userService.createUser(invalidUser);
        expect(result, isNull, reason: 'Should reject invalid email');
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
        final item = InventoryModel(
          productId: 'negative_test',
          productName: 'Negative Test Item',
          sku: 'NEG-001',
          currentQuantity: 10.0,
          minStockLevel: 5.0,
          maxStockLevel: 50.0,
          costPerUnit: 5.0,
          movements: [],
        );

        await inventoryService.createInventoryItem(item);

        // Attempt to sell more than available
        try {
          await inventoryService.addStockMovement(
            productId: 'negative_test',
            movementType: StockMovementType.sale,
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

        final now = DateTime.now().millisecondsSinceEpoch;
        final manager = BackendUserModel(
          email: 'workflow.manager@example.com',
          displayName: 'Workflow Manager',
          roleId: managerRole.id,
          roleName: managerRole.name,
          locationIds: ['loc_main', 'loc_branch1'],
          createdAt: now,
          updatedAt: now,
        );

        final createdManager = await userService.createUser(manager);
        expect(createdManager, isNotNull);

        // 2. Initialize access control
        await accessControlService.initialize(createdManager, managerRole);

        // 3. Check if manager can view inventory
        final canViewInventory = await accessControlService.hasPermission('view_inventory');
        expect(canViewInventory, isTrue);

        // 4. Manager creates inventory item
        final product = InventoryModel(
          productId: 'workflow_prod_001',
          productName: 'Workflow Product',
          sku: 'WORK-001',
          currentQuantity: 50.0,
          minStockLevel: 10.0,
          maxStockLevel: 100.0,
          costPerUnit: 20.0,
          movements: [],
        );

        final createdProduct = await inventoryService.createInventoryItem(product);
        expect(createdProduct, isNotNull);

        // 5. Manager performs stock operations
        await inventoryService.addStockMovement(
          productId: 'workflow_prod_001',
          movementType: StockMovementType.sale,
          quantity: 5.0,
          reason: 'Customer sale',
          userId: createdManager.id!,
        );

        // 6. Verify audit trail captured all operations
        final logs = auditService.getLogsByUserId(createdManager.id!);
        expect(logs.isNotEmpty, isTrue);

        // 7. Get final inventory state
        final finalInventory = await inventoryService.getInventoryByProductId('workflow_prod_001');
        expect(finalInventory, isNotNull);
        expect(finalInventory!.currentQuantity, equals(45.0));

        // Cleanup
        accessControlService.logout();
        await inventoryService.deleteInventoryItem('workflow_prod_001');
        await userService.deleteUser(createdManager.id!);
      });
    });
  });
}
