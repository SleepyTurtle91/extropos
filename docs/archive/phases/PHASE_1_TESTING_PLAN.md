# Phase 1: End-to-End Testing Plan (Task 5)

## Overview

**Status**: Task 5 - Appwrite Integration Testing
**Timeline**: 2 days (Feb 1-2, 2026)
**Scope**: Complete integration testing of Phase 1c services with Phase 1b UI

---

## Testing Strategy

### Unit Tests (Service Layer)

#### 1. BackendUserServiceAppwrite Tests

```dart
test('createUser() creates user in Appwrite', () async {
  final service = BackendUserServiceAppwrite.instance;
  
  final user = await service.createUser(
    email: 'test@example.com',
    displayName: 'Test User',
    roleId: RoleServiceAppwrite.adminRoleId,
    createdBy: 'system',
  );
  
  expect(user.email, 'test@example.com');
  expect(user.isActive, true);
  expect(user.isLockedOut, false);
});

test('getUserByEmail() returns user by email', () async {
  final service = BackendUserServiceAppwrite.instance;
  
  final user = await service.getUserByEmail('test@example.com');
  
  expect(user?.email, 'test@example.com');
});

test('updateUser() updates user fields', () async {
  final service = BackendUserServiceAppwrite.instance;
  
  final updated = await service.updateUser(
    userId: 'user_123',
    displayName: 'Updated Name',
    updatedBy: 'system',
  );
  
  expect(updated.displayName, 'Updated Name');
});

test('lockUser() prevents login', () async {
  final service = BackendUserServiceAppwrite.instance;
  
  await service.lockUser(userId: 'user_123', lockedBy: 'system');
  
  final user = await service.getUserById('user_123');
  expect(user?.isLockedOut, true);
});

test('deleteUser() removes user', () async {
  final service = BackendUserServiceAppwrite.instance;
  
  await service.deleteUser(userId: 'user_123', deletedBy: 'system');
  
  final user = await service.getUserById('user_123');
  expect(user, null);
});
```

#### 2. RoleServiceAppwrite Tests

```dart
test('createCustomRole() creates new role', () async {
  final service = RoleServiceAppwrite.instance;
  
  final role = await service.createCustomRole(
    name: 'Cashier',
    permissions: ['VIEW_USERS', 'VIEW_INVENTORY'],
    createdBy: 'system',
  );
  
  expect(role.name, 'Cashier');
  expect(role.permissions.length, 2);
});

test('system roles cannot be modified', () async {
  final service = RoleServiceAppwrite.instance;
  
  expect(
    () => service.updateRolePermissions(
      roleId: RoleServiceAppwrite.adminRoleId,
      permissions: ['VIEW_USERS'],
    ),
    throwsException,
  );
});

test('roleHasPermission() checks permission', () async {
  final service = RoleServiceAppwrite.instance;
  
  final hasPermission = await service.roleHasPermission(
    roleId: RoleServiceAppwrite.adminRoleId,
    permission: 'VIEW_USERS',
  );
  
  expect(hasPermission, true);
});
```

#### 3. AuditServiceAppwrite Tests

```dart
test('logActivity() records activity', () async {
  final service = AuditService.instance;
  
  final log = await service.logActivity(
    userId: 'user_123',
    action: 'CREATE',
    resourceType: 'User',
    resourceId: 'user_456',
    changesAfter: {'email': 'new@example.com'},
    success: true,
  );
  
  expect(log.action, 'CREATE');
  expect(log.success, true);
});

test('getActivitiesByUser() returns user activities', () async {
  final service = AuditService.instance;
  
  final activities = await service.getActivitiesByUser(
    userId: 'user_123',
    limit: 50,
  );
  
  expect(activities.isNotEmpty, true);
});

test('getActivitiesByDateRange() filters by date', () async {
  final service = AuditService.instance;
  
  final activities = await service.getActivitiesByDateRange(
    startDate: DateTime.now().subtract(Duration(days: 7)),
    endDate: DateTime.now(),
  );
  
  expect(activities.isNotEmpty, true);
});
```

#### 4. Phase1InventoryServiceAppwrite Tests

```dart
test('createInventoryItem() creates inventory', () async {
  final service = Phase1InventoryServiceAppwrite.instance;
  
  final inventory = await service.createInventoryItem(
    productId: 'prod_001',
    productName: 'Pizza',
    minStockLevel: 10,
    maxStockLevel: 50,
    initialQuantity: 30,
    costPerUnit: 5.50,
    createdBy: 'system',
  );
  
  expect(inventory.productId, 'prod_001');
  expect(inventory.currentQuantity, 30);
});

test('addStockMovement() records movement', () async {
  final service = Phase1InventoryServiceAppwrite.instance;
  
  final updated = await service.addStockMovement(
    productId: 'prod_001',
    movementType: 'SALE',
    quantity: 2,
    reason: 'POS transaction',
    userId: 'user_123',
  );
  
  expect(updated.currentQuantity, 28); // 30 - 2
  expect(updated.movements.length, 2); // Initial + Sale
});

test('performStockTake() records physical count', () async {
  final service = Phase1InventoryServiceAppwrite.instance;
  
  final updated = await service.performStockTake(
    productId: 'prod_001',
    countedQuantity: 25,
    userId: 'user_123',
  );
  
  expect(updated.currentQuantity, 25);
  expect(updated.movements.last.type, 'STOCKTAKE');
});

test('getLowStockItems() returns low stock', () async {
  final service = Phase1InventoryServiceAppwrite.instance;
  
  final lowStock = await service.getLowStockItems();
  
  expect(
    lowStock.every((item) => item.currentQuantity <= item.minStockLevel),
    true,
  );
});
```

---

### Integration Tests (Workflows)

#### 1. Complete User Management Workflow

```dart
testWidgets('User management workflow', (WidgetTester tester) async {
  // Setup
  final userService = BackendUserServiceAppwrite.instance;
  
  // 1. Create user
  final user = await userService.createUser(
    email: 'integration-test@example.com',
    displayName: 'Integration Test User',
    roleId: RoleServiceAppwrite.managerRoleId,
    createdBy: 'test_system',
  );
  expect(user.id.isNotEmpty, true);
  
  // 2. Retrieve created user
  final retrieved = await userService.getUserById(user.id);
  expect(retrieved?.email, user.email);
  
  // 3. Update user
  final updated = await userService.updateUser(
    userId: user.id,
    displayName: 'Updated Test User',
    updatedBy: 'test_system',
  );
  expect(updated.displayName, 'Updated Test User');
  
  // 4. Lock user
  await userService.lockUser(userId: user.id, lockedBy: 'test_system');
  final lockedUser = await userService.getUserById(user.id);
  expect(lockedUser?.isLockedOut, true);
  
  // 5. Unlock user
  await userService.unlockUser(userId: user.id, unlockedBy: 'test_system');
  final unlockedUser = await userService.getUserById(user.id);
  expect(unlockedUser?.isLockedOut, false);
  
  // 6. Deactivate user
  await userService.deactivateUser(userId: user.id, deactivatedBy: 'test_system');
  final deactivatedUser = await userService.getUserById(user.id);
  expect(deactivatedUser?.isActive, false);
  
  // 7. Delete user
  await userService.deleteUser(userId: user.id, deletedBy: 'test_system');
  final deletedUser = await userService.getUserById(user.id);
  expect(deletedUser, null);
  
  // 8. Verify audit trail
  final auditService = AuditService.instance;
  final activities = await auditService.getActivitiesByUser(
    userId: 'test_system',
    limit: 100,
  );
  expect(activities.isNotEmpty, true);
});
```

#### 2. Role Management Workflow

```dart
testWidgets('Role management workflow', (WidgetTester tester) async {
  final roleService = RoleServiceAppwrite.instance;
  
  // 1. Get system roles
  final systemRoles = roleService.getSystemRoles();
  expect(systemRoles.length, 4); // Admin, Manager, Supervisor, Viewer
  
  // 2. Create custom role
  final customRole = await roleService.createCustomRole(
    name: 'Test Role ${DateTime.now().millisecondsSinceEpoch}',
    permissions: ['VIEW_USERS', 'VIEW_INVENTORY'],
    createdBy: 'test_system',
  );
  expect(customRole.isSystemRole, false);
  
  // 3. Get custom role
  final retrieved = await roleService.getRoleById(customRole.id);
  expect(retrieved?.name, customRole.name);
  
  // 4. Update permissions
  final updated = await roleService.updateRolePermissions(
    roleId: customRole.id,
    permissions: ['VIEW_USERS', 'VIEW_INVENTORY', 'VIEW_REPORTS'],
    updatedBy: 'test_system',
  );
  expect(updated.permissions.length, 3);
  
  // 5. Delete custom role
  await roleService.deleteRole(roleId: customRole.id, deletedBy: 'test_system');
  final deleted = await roleService.getRoleById(customRole.id);
  expect(deleted, null);
});
```

#### 3. Inventory Management Workflow

```dart
testWidgets('Inventory management workflow', (WidgetTester tester) async {
  final inventoryService = Phase1InventoryServiceAppwrite.instance;
  
  // 1. Create inventory
  final inventory = await inventoryService.createInventoryItem(
    productId: 'test_prod_${DateTime.now().millisecondsSinceEpoch}',
    productName: 'Test Product',
    minStockLevel: 5,
    maxStockLevel: 50,
    initialQuantity: 30,
    costPerUnit: 10.0,
    createdBy: 'test_system',
  );
  expect(inventory.currentQuantity, 30);
  
  // 2. Record sales
  final afterSale1 = await inventoryService.addStockMovement(
    productId: inventory.productId,
    movementType: 'SALE',
    quantity: 5,
    reason: 'POS #1001',
    userId: 'test_user',
  );
  expect(afterSale1.currentQuantity, 25);
  
  final afterSale2 = await inventoryService.addStockMovement(
    productId: inventory.productId,
    movementType: 'SALE',
    quantity: 3,
    reason: 'POS #1002',
    userId: 'test_user',
  );
  expect(afterSale2.currentQuantity, 22);
  
  // 3. Restock
  final afterRestock = await inventoryService.addStockMovement(
    productId: inventory.productId,
    movementType: 'RESTOCK',
    quantity: 20,
    reason: 'Supplier order #5001',
    userId: 'test_user',
  );
  expect(afterRestock.currentQuantity, 42);
  
  // 4. Perform stock take (physical count)
  final afterStockTake = await inventoryService.performStockTake(
    productId: inventory.productId,
    countedQuantity: 40,
    userId: 'test_user',
    notes: 'Monthly inventory count',
  );
  expect(afterStockTake.currentQuantity, 40);
  
  // 5. Get movement history
  final history = await inventoryService.getMovementHistory(
    productId: inventory.productId,
  );
  expect(history.length, 5); // Initial + 2 sales + 1 restock + 1 stocktake
  
  // 6. Calculate inventory value
  final totalValue = await inventoryService.calculateInventoryValue();
  expect(totalValue, greaterThan(0));
});
```

---

### Manual QA Checklist

#### BackendHomeScreen Navigation

- [ ] Users menu item appears if user has VIEW_USERS permission
- [ ] Users menu item is hidden if user lacks VIEW_USERS permission
- [ ] Clicking Users navigates to UserManagementScreen
- [ ] Roles & Permissions menu item appears if user has VIEW_ROLES permission
- [ ] Roles & Permissions menu item is hidden if user lacks permission
- [ ] Clicking Roles navigates to RoleManagementScreen
- [ ] Inventory menu item appears if user has MANAGE_INVENTORY permission
- [ ] Clicking Inventory navigates to InventoryDashboardScreen
- [ ] Activity Logs menu item appears if user has VIEW_ACTIVITY_LOGS permission
- [ ] Clicking Activity Logs navigates to ActivityLogScreen

#### UserManagementScreen

- [ ] Screen loads without errors
- [ ] User list displays existing users
- [ ] Search filters users by name/email
- [ ] Pagination works (if > 10 users)
- [ ] "Add User" button opens AddUserDialog
- [ ] Form validates email format
- [ ] Form validates email uniqueness
- [ ] Form validates display name (not empty)
- [ ] Create user saves to Appwrite
- [ ] Edit user updates Appwrite
- [ ] Lock user button disables account
- [ ] Unlock user button enables account
- [ ] Deactivate user removes from active list
- [ ] Delete user removes permanently
- [ ] All operations trigger activity log

#### RoleManagementScreen

- [ ] System roles display with lock icon (not editable)
- [ ] Custom roles can be edited
- [ ] Permission matrix shows all 15 permissions
- [ ] Checked permissions save to Appwrite
- [ ] System roles cannot be edited (button disabled)
- [ ] System roles cannot be deleted
- [ ] Custom roles can be created
- [ ] Custom roles can be deleted
- [ ] All changes logged in activity log

#### ActivityLogScreen

- [ ] Activity log loads and displays
- [ ] Activities sorted by timestamp (newest first)
- [ ] Date range filter works
- [ ] Filter by user works
- [ ] Filter by action works
- [ ] Before/after snapshots display correctly
- [ ] Failed activities marked as failed
- [ ] Statistics show correct counts
- [ ] Export button works (if implemented)

#### InventoryDashboardScreen

- [ ] Inventory cards display correctly
- [ ] Low stock items highlighted in red
- [ ] "Add Inventory" button opens dialog
- [ ] Stock adjustment dialog saves correctly
- [ ] Stock take dialog records variance
- [ ] Movement history displays
- [ ] Inventory value calculates correctly
- [ ] Low stock alerts appear for items below min

---

### Performance Testing

#### Query Times (Target: <200ms average)

- [ ] Get all users: **<10ms** (cached)
- [ ] Get user by ID: **<50ms** (Appwrite + cache)
- [ ] Create user: **150-200ms** (Appwrite + audit)
- [ ] Update user: **150-200ms** (Appwrite + audit)
- [ ] Get all roles: **<10ms** (cached)
- [ ] Get all inventory: **<10ms** (cached)
- [ ] Add stock movement: **200-300ms** (JSON + movements)
- [ ] Get activity logs: **<50ms** (Appwrite query)

#### Load Testing

- [ ] Create 100 users (sequential) - should complete in <30 seconds
- [ ] Create 1000 activity log entries (sequential) - should complete in <1 minute
- [ ] Query 100 activity logs - should complete in <200ms
- [ ] Calculate inventory value for 100 products - should complete in <500ms

---

### Offline & Fallback Testing

#### Cache Fallback

- [ ] Disable Appwrite connection
- [ ] Query user list - returns cached data
- [ ] Query roles - returns cached data
- [ ] Query inventory - returns cached data
- [ ] Create user - shows error, user not created
- [ ] Restart app - previous queries still work with cache

#### Cache Expiry

- [ ] Wait 5+ minutes after query
- [ ] Verify cache refreshes on next query
- [ ] Verify new data is fetched from Appwrite

#### Manual Cache Clear

- [ ] Call `service.clearCache()` in console
- [ ] Next query fetches from Appwrite

---

### Error Handling Tests

#### Email Validation

- [ ] Creating user with invalid email shows error
- [ ] Creating user with duplicate email shows error
- [ ] Creating user with empty email shows error

#### Permission Checks

- [ ] User without VIEW_USERS permission cannot see Users screen
- [ ] User without MANAGE_INVENTORY permission cannot see Inventory
- [ ] User without VIEW_ROLES permission cannot see Roles

#### Network Errors

- [ ] Appwrite offline - shows error message
- [ ] Appwrite returns error - user gets notification
- [ ] Failed operation - activity log records failure

#### Data Validation

- [ ] Cannot create role with empty permissions
- [ ] Cannot create user with empty display name
- [ ] Cannot add negative stock quantity
- [ ] Cannot set stock below 0

---

## Testing Execution Plan

### Day 1 (Feb 1)

**Morning (4 hours)**:
- [ ] Run all unit tests for BackendUserServiceAppwrite
- [ ] Run all unit tests for RoleServiceAppwrite
- [ ] Run all unit tests for AuditServiceAppwrite
- [ ] Fix any failing tests

**Afternoon (4 hours)**:
- [ ] Run all unit tests for Phase1InventoryServiceAppwrite
- [ ] Run integration tests for user workflow
- [ ] Run integration tests for role workflow
- [ ] Fix any failing integration tests

### Day 2 (Feb 2)

**Morning (4 hours)**:
- [ ] Run integration tests for inventory workflow
- [ ] Perform manual QA on BackendHomeScreen
- [ ] Perform manual QA on UserManagementScreen
- [ ] Perform manual QA on RoleManagementScreen

**Afternoon (4 hours)**:
- [ ] Perform manual QA on ActivityLogScreen
- [ ] Perform manual QA on InventoryDashboardScreen
- [ ] Performance testing (query times)
- [ ] Error handling testing

---

## Test Results Format

Each test should document:

```
Test Name: [test name]
Status: ✅ PASS / ❌ FAIL
Duration: [ms]
Notes: [any issues or details]
```

---

## Success Criteria

- [ ] All 20+ unit tests pass
- [ ] All 3 integration tests pass
- [ ] All manual QA checklist items pass
- [ ] Performance testing shows <200ms average queries
- [ ] Offline fallback testing passes
- [ ] Error handling tests pass
- [ ] Zero crashes or unhandled exceptions
- [ ] All activity logs recorded correctly

**Overall Status**: Phase 1 Integration Testing Complete

---

## Blockers & Issues

Document any issues found:

| Issue | Severity | Status | Fix |
|-------|----------|--------|-----|
| (example) | HIGH | Open | (fix description) |

---

## Sign-Off

- [ ] All tests passed
- [ ] QA approved for deployment
- [ ] Ready for Phase 1 completion

**Date Completed**: _________________
**Tested By**: _________________
**Approved By**: _________________

