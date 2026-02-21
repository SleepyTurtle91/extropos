# Phase 1 Testing Execution Guide

## Quick Start

### Running All Tests

```bash
# Run all unit tests
flutter test test/services/

# Run specific test file
flutter test test/services/backend_user_service_appwrite_test.dart

# Run tests with verbose output
flutter test -v test/services/

# Run tests with coverage
flutter test --coverage test/services/

# Run specific test
flutter test test/services/appwrite_phase1_service_test.dart -n "initialize()"
```

---

## Unit Tests (Day 1)

### Morning: Core Services Unit Tests

#### 1. AppwritePhase1Service Tests

```bash
# Run AppwritePhase1Service tests
flutter test test/services/appwrite_phase1_service_test.dart

# Expected Results:
# ✅ All tests should pass
# ✅ No errors with Appwrite connection
# ✅ Collections are initialized correctly
```

**Key Assertions**:
- Service initializes without error
- Collections can be created multiple times (idempotency)
- Collection existence can be checked

#### 2. BackendUserServiceAppwrite Tests

```bash
# Run BackendUserServiceAppwrite tests
flutter test test/services/backend_user_service_appwrite_test.dart

# Expected Results:
# ✅ CRUD operations work
# ✅ Email validation enforced
# ✅ Display name validation enforced
# ✅ User locking/unlocking works
# ✅ User deactivation works
# ✅ User deletion works
```

**Key Assertions**:
- Invalid email rejected with exception
- Empty display name rejected with exception
- User creation persists to Appwrite
- User updates are reflected in database
- Lock/unlock toggles isLockedOut flag
- Deactivation sets isActive to false
- Deletion removes user completely

### Afternoon: Role & Audit Services

#### 3. RoleServiceAppwrite Tests

```bash
# Run RoleServiceAppwrite tests
flutter test test/services/role_service_appwrite_test.dart

# Expected Results:
# ✅ System roles are immutable
# ✅ Custom roles can be created
# ✅ Permissions are validated
# ✅ Admin role has all 15 permissions
```

**Key Assertions**:
- System roles (4) cannot be modified
- System roles (4) cannot be deleted
- Custom roles can be created with valid permissions
- Admin role has all permissions
- Permission checking works correctly
- Role updates are persisted

#### 4. AuditService Tests

```bash
# Run AuditService tests
flutter test test/services/audit_service_test.dart

# Expected Results:
# ✅ Activities are logged
# ✅ Queries by user work
# ✅ Date range filtering works
# ✅ Before/after snapshots recorded
```

**Key Assertions**:
- Valid actions are accepted
- Valid resource types are accepted
- Invalid actions/types throw exception
- Activity logging works
- Queries by user return correct activities
- Date range filtering is accurate
- Failed activities are recorded with reason

### Late Afternoon: Inventory Service

#### 5. Phase1InventoryServiceAppwrite Tests

```bash
# Run Phase1InventoryServiceAppwrite tests
flutter test test/services/phase1_inventory_service_appwrite_test.dart

# Expected Results:
# ✅ Inventory creation works
# ✅ Stock movements recorded
# ✅ Stock takes perform variance calculations
# ✅ Low stock detection works
# ✅ Inventory value calculation works
```

**Key Assertions**:
- Inventory creation validates required fields
- Initial movement created on creation
- Sales reduce quantity
- Restocks increase quantity
- Stock takes update quantity to counted amount
- Variance is calculated correctly
- Movement history is complete
- Low stock items identified correctly

---

## Summary: Unit Test Checklist (Day 1)

```
✅ AppwritePhase1Service
   - initialize()
   - createCollectionsIfNeeded()
   - hasCollection()

✅ BackendUserServiceAppwrite
   - createUser() validation
   - getUserById()
   - getUserByEmail()
   - getAllUsers()
   - updateUser()
   - lockUser()
   - unlockUser()
   - deactivateUser()
   - deleteUser()
   - Cache clearing

✅ RoleServiceAppwrite
   - getSystemRoles() returns 4
   - System role immutability
   - getRoleById()
   - roleHasPermission()
   - createCustomRole()
   - updateRolePermissions()
   - deleteRole()
   - getAllRoles()

✅ AuditService
   - logActivity() validation
   - logActivity() success
   - logActivity() failure
   - getActivitiesByUser()
   - getActivitiesByResource()
   - getActivitiesByDateRange()
   - getActivityById()
   - Statistics

✅ Phase1InventoryServiceAppwrite
   - createInventoryItem() validation
   - addStockMovement() validation
   - Movement types (SALE, RESTOCK, ADJUSTMENT)
   - performStockTake()
   - getLowStockItems()
   - getMovementHistory()
   - calculateInventoryValue()
```

---

## Integration Tests (Day 2 Morning)

### Complete Workflow Tests

Run integration tests for end-to-end workflows:

```bash
# Run all integration tests
flutter test test/integration/

# Run specific integration test
flutter test test/integration/user_management_workflow_test.dart
```

#### 1. User Management Workflow Integration Test

**Steps**:
1. Create user
2. Retrieve created user
3. Update user
4. Lock user
5. Unlock user
6. Deactivate user
7. Delete user
8. Verify audit trail

**Expected**: All operations complete successfully, audit trail records all changes

#### 2. Role Management Workflow Integration Test

**Steps**:
1. Get system roles
2. Create custom role
3. Update role permissions
4. Delete custom role
5. Verify system roles unchanged

**Expected**: System roles protected, custom roles work correctly

#### 3. Inventory Management Workflow Integration Test

**Steps**:
1. Create inventory
2. Record sales (multiple)
3. Record restock
4. Perform stock take
5. Get movement history
6. Calculate inventory value
7. Verify all movements recorded

**Expected**: All movements tracked, quantity accurate, value calculated

---

## Manual QA (Day 2 Afternoon)

### BackendHomeScreen Navigation

```
✅ Verify layout loads without errors
✅ Verify welcome card displays
✅ Verify sync status card displays
✅ Verify management tiles grid displays
✅ Verify all 9 tiles visible (5 existing + 4 Phase 1):
   - Register Backend User
   - Categories
   - Products
   - Modifiers
   - Business Information
   - Users (NEW - Phase 1)
   - Roles & Permissions (NEW - Phase 1)
   - Inventory (NEW - Phase 1)
   - Activity Logs (NEW - Phase 1)
✅ Tap Users tile → navigates to UserManagementScreen
✅ Tap Roles tile → navigates to RoleManagementScreen
✅ Tap Inventory tile → navigates to InventoryDashboardScreen
✅ Tap Activity Logs tile → navigates to ActivityLogScreen
✅ Back button returns to BackendHomeScreen
```

### UserManagementScreen QA

```
✅ Screen loads without errors
✅ User list displays
✅ Search field filters by name/email
✅ Pagination works (if > 10 users)
✅ "Add User" button opens AddUserDialog
✅ Dialog validates email format
✅ Dialog validates email uniqueness
✅ Dialog validates display name (not empty)
✅ Dialog validates role selection
✅ Create user appears in list
✅ Edit user updates display
✅ Lock user button disables account
✅ Unlock user button enables account
✅ Deactivate user removes from list
✅ Delete user removes permanently
✅ All operations show success toast
✅ All operations logged in activity log
```

---

## Test Results Format

For each test, document:

```
Test Name: [name]
Status: ✅ PASS / ❌ FAIL
Duration: [ms]
Platform: [Android/Windows]
Date: [2026-02-01]
Notes: [any details, errors, or issues]
```

---

## Success Criteria

- [ ] All 40+ unit tests pass
- [ ] All 3 integration tests pass
- [ ] All 71+ manual QA checks pass
- [ ] Performance targets met (<200ms queries)
- [ ] Offline fallback tested
- [ ] Error handling verified
- [ ] Zero crashes or exceptions

**Phase 1 Testing**: Ready for deployment ✅

