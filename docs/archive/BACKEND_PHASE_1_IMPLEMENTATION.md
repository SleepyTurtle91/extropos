# Backend Flavor Phase 1 - Implementation Plan (Foundation)

**Timeline**: February 1 - April 30, 2026 (8-10 weeks)  
**Team**: 3-4 developers  
**Goal**: User & Access Control + Audit Logging + Inventory Basics  
**Status**: ✅ Ready to Implement

---

## Executive Summary

Phase 1 delivers the **foundation** for enterprise-grade backend management:

```
Phase 1 (Foundation) - 700 hours
├─ User & Access Control (RBAC)
├─ Audit Logging & Activity Tracking
├─ Basic Inventory Management
└─ Quick Wins (Dark Mode, Search, Bulk Ops)
```

**Outcome**: Secure, multi-user backend ready for team delegation and inventory optimization.

---

## Detailed Sprint Breakdown

### Sprint 1 (Weeks 1-2): Foundation & Architecture - 80-100 hours

**Lead**: Architecture Review + Database Setup

#### Database Setup Tasks:

**Create Appwrite Collections**:

```yaml
1. roles
   - id (documentId, auto)
   - name (string): 'Admin', 'Manager', 'Supervisor', 'Viewer'
   - description (string)
   - permissions (json): { permission_key: boolean }
   - is_editable (boolean): false for system roles
   - created_at (datetime)

2. users
   - id (documentId, auto)
   - email (string, unique, indexed)
   - name (string)
   - phone (string, optional)
   - role_id (string, indexed - foreign key)
   - location_ids (array): assigned locations
   - is_active (boolean)
   - last_login_at (datetime, optional)
   - created_at (datetime)
   - updated_at (datetime)

3. activity_logs
   - id (documentId, auto)
   - user_id (string, indexed - foreign key)
   - user_name (string)
   - action (string): 'product_created', 'inventory_adjusted'
   - resource_type (string): 'product', 'inventory'
   - resource_id (string, indexed)
   - changes (json): before/after values
   - notes (string, optional)
   - created_at (datetime, indexed)

4. inventory
   - id (documentId, auto)
   - location_id (string, indexed)
   - product_id (string, indexed)
   - current_quantity (double)
   - min_stock_level (double)
   - max_stock_level (double)
   - reorder_quantity (double)
   - cost_per_unit (double, optional)
   - movements (array[json]): stock history
   - last_counted_at (datetime, optional)
   - created_at (datetime)
   - updated_at (datetime)
```

#### Dart Model Files to Create:

```
lib/models/
├── role_model.dart
├── user_model.dart
├── activity_log_model.dart
├── inventory_model.dart
└── stock_movement_model.dart
```

**Week 1 Deliverables**:
- ✅ All Appwrite collections created with indexes
- ✅ Dart data models implemented
- ✅ Models include `toAppwrite()` and `fromAppwrite()` methods
- ✅ Sample test data loaded

**Week 2 Deliverables**:
- ✅ Service layer skeleton created
- ✅ Appwrite configuration validated
- ✅ Test database prepared
- ✅ Documentation of schema

**Acceptance Criteria**:
- [ ] Collections exist in Appwrite with correct fields
- [ ] Dart models compile without errors
- [ ] Models can serialize/deserialize correctly
- [ ] Test data loads into database
- [ ] All team members can access dev database

---

### Sprint 2 (Weeks 3-4): RBAC System - 160-180 hours

**Lead Developer** (40h): Services implementation  
**Frontend Dev #1** (70h): User management UI  
**Frontend Dev #2** (40h): Permission guards & testing  

#### Backend Services to Implement:

**1. AccessControlService** (lib/services/access_control_service.dart)

```dart
class AccessControlService {
  // Core permission checking
  Future<bool> hasPermission(String userId, String permissionKey)
  Future<bool> canAccessLocation(String userId, String locationId)
  Future<List<String>> getAllPermissions(String userId)
  
  // User management
  Future<List<String>> getUserLocations(String userId)
  Future<Map<String, dynamic>> getUserWithRole(String userId)
  
  // Caching (5-min TTL)
  Future<void> invalidateUserCache(String userId)
}
```

**2. UserService** (lib/services/user_service.dart)

```dart
class UserService {
  // CRUD operations
  Future<List<User>> getAllUsers({int page = 1, int limit = 50})
  Future<User?> getUserById(String userId)
  Future<String> createUser(User user) // Returns user ID
  Future<void> updateUser(User user)
  Future<void> deleteUser(String userId)
  
  // User management
  Future<void> activateUser(String userId)
  Future<void> deactivateUser(String userId)
  Future<void> changeUserRole(String userId, String newRoleId)
  Future<void> assignLocations(String userId, List<String> locationIds)
  
  // Batch operations
  Future<void> bulkChangeRole(List<String> userIds, String roleId)
  Future<void> bulkAssignLocations(List<String> userIds, List<String> locationIds)
}
```

**3. RoleService** (lib/services/role_service.dart)

```dart
class RoleService {
  // System roles (admin, manager, supervisor, viewer)
  Future<List<Role>> getSystemRoles()
  Future<List<Role>> getCustomRoles()
  Future<Role?> getRoleById(String roleId)
  
  // Role CRUD (admin only)
  Future<String> createRole(Role role)
  Future<void> updateRole(Role role)
  Future<void> deleteRole(String roleId)
  
  // Permission management
  Future<void> grantPermission(String roleId, String permissionKey)
  Future<void> revokePermission(String roleId, String permissionKey)
}
```

**4. Cache Service** (lib/services/cache_service.dart)

```dart
class CacheService {
  void set(String key, dynamic value, {Duration? expiry})
  dynamic get(String key)
  void invalidate(String key)
  void clear()
}
```

#### Frontend Screens to Create:

**1. UserManagementScreen** (lib/screens/user_management_screen.dart)

Features:
- List of all users with pagination
- Search/filter by name or email
- Add user button
- Edit/delete user buttons
- User role indicator
- Active/inactive status toggle
- Bulk select with multi-action buttons

**2. User Dialogs** (lib/dialogs/)

- `AddUserDialog`: Email, name, phone, role, locations
- `EditUserDialog`: Edit user details and role
- `DeleteUserDialog`: Confirmation before deletion

**3. RoleManagementScreen** (lib/screens/role_management_screen.dart)

Features:
- List system roles (view-only)
- List custom roles with edit/delete
- Create new role button
- Permission matrix editor
- Preview role access level

#### Testing:

**Unit Tests** (test/services/):
- AccessControlService tests (20 tests)
- UserService tests (25 tests)
- RoleService tests (15 tests)
- Permission caching tests (5 tests)

**Widget Tests** (test/widgets/):
- UserManagementScreen tests (10 tests)
- User dialog tests (8 tests)
- Role management tests (6 tests)

**Integration Tests**:
- Complete user lifecycle (create, modify, delete)
- Permission enforcement workflow
- Role assignment workflow

**Sprint 2 Deliverables**:
- ✅ All 4 services implemented and unit tested
- ✅ User management screen complete
- ✅ Role management screen complete
- ✅ User CRUD operations working
- ✅ Permission caching working
- ✅ System roles created in database
- ✅ 80+ unit tests passing

**Acceptance Criteria**:
- [ ] Can create, read, update, delete users
- [ ] Can assign roles and locations
- [ ] Permissions are cached correctly
- [ ] All unit tests passing (>95%)
- [ ] No permission leaks (verified by test)

---

### Sprint 3 (Weeks 5-6): Audit Logging - 140-160 hours

**Lead Developer** (30h): AuditService implementation  
**Frontend Dev #1** (50h): Activity log UI  
**Frontend Dev #2** (60h): Audit dashboard + integration  

#### Backend Services:

**1. AuditService** (lib/services/audit_service.dart)

```dart
class AuditService {
  // Logging
  Future<void> logActivity({
    required String userId,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? before,
    Map<String, dynamic>? after,
    String? notes,
  })
  
  // Querying
  Future<List<ActivityLog>> getActivityLog({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? resourceId,
    String? action,
    int page = 1,
    int limit = 50,
  })
  
  Future<List<ActivityLog>> getUserActivity(String userId)
  Future<List<ActivityLog>> getResourceActivity(String resourceId)
  Future<int> getActivityCount()
  
  // Statistics
  Future<Map<String, int>> getActivityStats(DateRange dateRange)
  Future<List<ActivityLog>> getRecentActivity({int limit = 20})
}
```

#### Add Logging to All Screens:

**In lib/screens/** - Add activity logging to:
- Items management (create, update, delete product)
- Categories management (create, update, delete category)
- Modifiers management (create, update, delete modifier)
- Business info (update settings)

**Pattern**:
```dart
// After successful operation
await AuditService().logActivity(
  userId: currentUserId,
  action: 'product_created',
  resourceType: 'product',
  resourceId: product.id,
  after: product.toMap(),
  notes: 'Created by user',
);
```

#### Frontend Screens:

**1. ActivityLogScreen** (lib/screens/activity_log_screen.dart)

Features:
- Date range selector (week, month, custom)
- User filter dropdown
- Resource type filter
- Action type filter
- Search by resource ID
- Pagination (50 per page)
- Clickable rows to see details

**2. ActivityDetailDialog**:
- Show what changed (before/after)
- Show who made change and when
- Show notes/reason if any
- Timeline view

**3. AuditDashboard** (added to backend home):
- Total activities this month
- Activities by user (top 5)
- Activities by type (chart)
- Recent activity feed
- Low stock alerts

#### Integration with Existing Screens:

**Modify backend_home_screen.dart**:
- Add audit status card
- Show latest activity
- Link to full audit log

**Modify all management screens**:
- Add logging after each operation
- Show activity timestamp in lists (hover tooltip)
- Link to view change history

#### Testing:

**Unit Tests**:
- AuditService tests (30 tests)
- Activity log filtering (10 tests)
- Statistics generation (5 tests)

**Integration Tests**:
- Create product → activity logged
- Update product → activity shows before/after
- Delete product → activity logged
- Activity search/filter working
- Activity history per resource

**Sprint 3 Deliverables**:
- ✅ AuditService fully functional
- ✅ Activity logged on all operations
- ✅ ActivityLogScreen complete
- ✅ Audit dashboard functional
- ✅ All logging integration done
- ✅ 50+ tests passing

**Acceptance Criteria**:
- [ ] Every user action is logged
- [ ] Activity log is searchable and filterable
- [ ] Change history shows before/after values
- [ ] Performance: query 10k activities in <500ms
- [ ] UI clearly shows who did what when

---

### Sprint 4 (Weeks 7-8): Inventory + Quick Wins - 180-220 hours

**Frontend Dev #1** (80h): Inventory dashboard UI  
**Frontend Dev #2** (80h): Quick wins + testing  
**Lead Developer** (40h): InventoryService + integration  

#### Backend Services:

**1. InventoryService** (lib/services/inventory_service.dart)

```dart
class InventoryService {
  // Core inventory operations
  Future<InventoryItem?> getInventoryItem(String locationId, String productId)
  Future<List<InventoryItem>> getAllInventory(String locationId)
  Future<List<InventoryItem>> getLowStockItems(String locationId)
  
  // Stock management
  Future<void> adjustStock({
    required String locationId,
    required String productId,
    required double quantity,
    required String reason,
    required String userId,
  })
  
  Future<void> recordSale({
    required String locationId,
    required String productId,
    required double quantity,
    required String transactionId,
  })
  
  // Physical inventory
  Future<void> performStockTake(String locationId, Map<String, double> counts)
  
  // Reporting
  Future<double> getTotalInventoryValue(String locationId)
  Future<List<StockMovement>> getMovementHistory(String inventoryId)
}
```

#### Inventory UI Screens:

**1. InventoryDashboardScreen** (lib/screens/inventory_dashboard_screen.dart)

Cards:
- Total inventory value
- Low stock items count
- Items needing reorder
- Recent stock adjustments

Lists:
- All products with inventory
- Columns: Product name, qty, min, max, cost, value
- Sort/filter by stock status
- Color-coded: green (ok), yellow (low), red (critical)

Dialogs:
- Stock adjustment dialog
- Stock take (physical count)
- Stock movement history viewer

**2. StockAdjustmentDialog**:
- Product selector
- Quantity input
- Reason dropdown (receive, spoilage, count-correction, return)
- Notes field
- Confirm/cancel

**3. StockTakeDialog**:
- Product list with current qty
- Quantity input for each
- Auto-calculate variance
- Confirm with reason
- Shows discrepancies

#### Quick Win #1: Dark Mode (30-50 hours)

**Tasks**:
- [ ] Add dark mode toggle to settings
- [ ] Update theme colors for both modes
- [ ] Test all screens in dark mode
- [ ] Persist theme preference
- [ ] System theme detection (optional)

**Files to modify**:
- `lib/theme/app_theme.dart` - Add dark theme
- `lib/screens/backend_home_screen.dart` - Add settings toggle
- `lib/services/theme_service.dart` - Persist preference

#### Quick Win #2: Search (20-30 hours)

**Implement search on**:
1. User list - search by email/name
2. Activity log - search by resource ID
3. Inventory list - search by product name

**Pattern**:
```dart
// Add TextField with debounce
final searchController = TextEditingController();
late Timer searchTimer;

@override
void initState() {
  searchController.addListener(() {
    searchTimer.cancel();
    searchTimer = Timer(Duration(milliseconds: 500), () {
      setState(() => _searchQuery = searchController.text);
      _loadData();
    });
  });
}
```

#### Quick Win #3: Bulk Operations (40-60 hours)

**Implement bulk actions**:
1. Users: Select multiple → Change role / Deactivate / Delete
2. Users: Assign to multiple locations
3. Inventory: Bulk adjust stock levels
4. Inventory: Set min/max levels in bulk

**Pattern**:
```dart
// Add checkboxes to list
// Multi-select with action buttons
// Batch operation dialog
// Progress indicator while processing
```

#### Integration Tasks:

**Connect inventory to POS**:
- When POS records transaction
- Call `InventoryService.recordSale()`
- Auto-decrement inventory
- Create stock movement

**Connect activity logging**:
- Log all inventory adjustments
- Log all role changes
- Log all user changes

#### Testing:

**Inventory Tests**:
- Stock adjustment changes quantity
- Low stock items detected
- Sales auto-decrement inventory
- Stock take calculates variances
- Query performance < 300ms

**Dark Mode Tests**:
- All UI visible in dark mode
- Colors have sufficient contrast
- Preference persists on reload
- System theme follows device setting

**Search Tests**:
- Search filters results correctly
- Debouncing works (no excessive calls)
- Empty search shows all results
- Case-insensitive search

**Bulk Operation Tests**:
- Bulk select works
- Bulk actions apply to all selected
- Confirmation dialogs shown
- Activity logged for each change
- Progress shown during bulk operation

#### Performance Optimization:

Tasks:
- [ ] Index inventory by location_id, product_id
- [ ] Cache low stock items (1-min TTL)
- [ ] Paginate inventory list (50 per page)
- [ ] Lazy load product details
- [ ] Load-test with 10k+ products

**Sprint 4 Deliverables**:
- ✅ Inventory dashboard complete and functional
- ✅ Stock adjustment working
- ✅ Low stock alerts visible
- ✅ Dark mode complete
- ✅ Search on 3 screens
- ✅ Bulk operations complete
- ✅ All integration complete
- ✅ 100+ tests passing
- ✅ Performance benchmarks met

**Acceptance Criteria**:
- [ ] Inventory reflects POS sales in real-time
- [ ] Low stock items highlighted and searchable
- [ ] Dark mode looks professional
- [ ] Search is fast and accurate
- [ ] Bulk operations work reliably
- [ ] All tests passing (>95%)
- [ ] Documentation complete

---

## File Structure & File Locations

```
lib/
├── models/
│   ├── role_model.dart              (NEW - Sprint 1)
│   ├── user_model.dart              (NEW - Sprint 1)
│   ├── activity_log_model.dart      (NEW - Sprint 1)
│   ├── inventory_model.dart         (NEW - Sprint 1)
│   ├── stock_movement_model.dart    (NEW - Sprint 1)
│   └── cache_model.dart             (NEW - Sprint 1)
│
├── services/
│   ├── access_control_service.dart  (NEW - Sprint 2)
│   ├── user_service.dart            (NEW - Sprint 2)
│   ├── role_service.dart            (NEW - Sprint 2)
│   ├── cache_service.dart           (NEW - Sprint 2)
│   ├── audit_service.dart           (NEW - Sprint 3)
│   ├── inventory_service.dart       (NEW - Sprint 4)
│   └── theme_service.dart           (MODIFY - Sprint 4)
│
├── screens/
│   ├── user_management_screen.dart  (NEW - Sprint 2)
│   ├── role_management_screen.dart  (NEW - Sprint 2)
│   ├── activity_log_screen.dart     (NEW - Sprint 3)
│   ├── inventory_dashboard_screen.dart (NEW - Sprint 4)
│   └── backend_home_screen.dart     (MODIFY - all sprints)
│
├── widgets/
│   ├── user_list_widget.dart        (NEW - Sprint 2)
│   ├── activity_log_list_widget.dart (NEW - Sprint 3)
│   ├── inventory_list_widget.dart   (NEW - Sprint 4)
│   ├── permission_guard.dart        (NEW - Sprint 2)
│   ├── low_stock_alert_widget.dart  (NEW - Sprint 4)
│   └── audit_dashboard_widget.dart  (NEW - Sprint 3)
│
├── dialogs/
│   ├── add_user_dialog.dart         (NEW - Sprint 2)
│   ├── edit_user_dialog.dart        (NEW - Sprint 2)
│   ├── delete_user_dialog.dart      (NEW - Sprint 2)
│   ├── activity_detail_dialog.dart  (NEW - Sprint 3)
│   ├── stock_adjustment_dialog.dart (NEW - Sprint 4)
│   └── stock_take_dialog.dart       (NEW - Sprint 4)
│
└── config/
    ├── permissions.dart             (NEW - Sprint 2)
    └── appwrite_setup.dart          (NEW - Sprint 1)

test/
├── services/
│   ├── access_control_service_test.dart  (NEW - Sprint 2)
│   ├── user_service_test.dart            (NEW - Sprint 2)
│   ├── role_service_test.dart            (NEW - Sprint 2)
│   ├── audit_service_test.dart           (NEW - Sprint 3)
│   └── inventory_service_test.dart       (NEW - Sprint 4)
│
├── widgets/
│   └── [widget tests]
│
├── integration/
│   ├── phase1_integration_test.dart (NEW - Sprint 4)
│   └── rbac_workflow_test.dart      (NEW - Sprint 2)
│
└── fixtures/
    └── test_data.dart               (NEW - Sprint 1)
```

---

## Key Code Patterns

### Pattern 1: Permission Guard

```dart
// Wrap screens/features with permission check
PermissionGuard.withPermission(
  permissionKey: 'manage_users',
  builder: (context) => UserManagementScreen(),
  fallback: Center(
    child: Text('You don\'t have permission to access this'),
  ),
)
```

### Pattern 2: Activity Logging

```dart
// After any operation that modifies data
await AuditService().logActivity(
  userId: currentUserId,
  action: 'product_updated',
  resourceType: 'product',
  resourceId: product.id,
  before: oldProduct.toMap(),
  after: newProduct.toMap(),
  notes: 'Updated price from ${oldProduct.price} to ${newProduct.price}',
);
```

### Pattern 3: Stock Movement

```dart
// Record sale from POS
await InventoryService().recordSale(
  locationId: location.id,
  productId: product.id,
  quantity: cartItem.quantity,
  transactionId: transaction.id,
);
```

---

## Weekly Check-ins

Every Friday, 30-minute meeting:
- Review completed tasks vs planned
- Identify blockers
- Adjust plan if needed
- Plan next week
- Demo new features

---

## Success Metrics

### Phase 1 Complete When:

✅ **Functional**:
- User management fully working
- RBAC enforced across backend
- Activity logging on all operations
- Inventory dashboard live
- Dark mode available
- Search functional
- Bulk operations working

✅ **Quality**:
- >95% test coverage
- All critical path tests passing
- Performance benchmarks met
- Zero critical bugs
- Documentation complete

✅ **User Experience**:
- Intuitive interface
- Fast response times (<500ms)
- Clear error messages
- Helpful documentation

---

## Immediate Next Steps (This Week)

1. **Kickoff Meeting** (1 hour)
   - Introduce team to plan
   - Assign roles and responsibilities
   - Answer questions

2. **Setup & Preparation** (4 hours)
   - Setup development environment
   - Clone/branch code
   - Setup Appwrite project
   - Create sprint board

3. **Design Review** (2 hours)
   - Review database schemas
   - Review architecture decisions
   - Get team approval

4. **Begin Sprint 1** (3 hours)
   - Create Appwrite collections
   - Start creating Dart models
   - Load sample test data

---

*Ready to implement!*  
*Start Date: February 1, 2026*  
*Lead: [Assign someone]*  
*Questions? Review BACKEND_EXPANSION_ROADMAP.md for context*
