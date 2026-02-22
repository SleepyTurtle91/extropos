# Phase 1c Quick Reference: Appwrite Integration

## Quickstart: Using Appwrite Services

### 1. Initialize Appwrite (One-time in main.dart)

```dart
import 'services/appwrite_phase1_service.dart';

void main() async {
  // Initialize Appwrite connection
  final appwrite = AppwritePhase1Service();
  await appwrite.initialize();
  
  // Setup collections (one-time)
  await appwrite.setupCollections();
  
  runApp(const MyApp());
}
```

### 2. Use Appwrite Services

```dart
import 'services/backend_user_service_appwrite.dart';
import 'services/role_service_appwrite.dart';
import 'services/audit_service_appwrite.dart';
import 'services/phase1_inventory_service_appwrite.dart';

// User Management
final userService = BackendUserServiceAppwrite.instance;
final newUser = await userService.createUser(
  email: 'john@example.com',
  displayName: 'John Doe',
  roleId: RoleServiceAppwrite.managerRoleId,
  createdBy: currentUserId,
);

// Role Management
final roleService = RoleServiceAppwrite.instance;
final adminRole = await roleService.getRoleById(RoleServiceAppwrite.adminRoleId);

// Inventory Management
final inventoryService = Phase1InventoryServiceAppwrite.instance;
await inventoryService.createInventoryItem(
  productId: 'prod_001',
  productName: 'Pizza',
  minStockLevel: 10,
  maxStockLevel: 50,
  costPerUnit: 5.50,
);

// Audit Trail (automatic logging)
final auditService = AuditService.instance;
final activities = await auditService.getActivitiesByUser(
  userId: userId,
  limit: 50,
);
```

---

## Service Reference

### BackendUserServiceAppwrite

```dart
// CRUD Operations
Future<BackendUserModel> createUser({
  required String email,
  required String displayName,
  required String roleId,
  String? phone,
  List<String>? locationIds,
  String? createdBy,
  String? createdByName,
})

Future<BackendUserModel?> getUserById(String userId)
Future<BackendUserModel?> getUserByEmail(String email)
Future<List<BackendUserModel>> getAllUsers()
Future<List<BackendUserModel>> getActiveUsers()

Future<BackendUserModel> updateUser({
  required String userId,
  String? displayName,
  String? phone,
  String? roleId,
  List<String>? locationIds,
  String? updatedBy,
})

Future<void> deleteUser({
  required String userId,
  String? deletedBy,
})

Future<void> lockUser({
  required String userId,
  String? lockedBy,
})

Future<void> unlockUser({
  required String userId,
  String? unlockedBy,
})

Future<void> deactivateUser({
  required String userId,
  String? deactivatedBy,
})

void clearCache()
```

### RoleServiceAppwrite

```dart
// System Roles (Immutable)
static const String adminRoleId = 'role_admin'
static const String managerRoleId = 'role_manager'
static const String supervisorRoleId = 'role_supervisor'
static const String viewerRoleId = 'role_viewer'

// CRUD Operations
Future<List<RoleModel>> getAllRoles()
Future<List<RoleModel>> getCustomRoles()
Future<RoleModel?> getRoleById(String roleId)
Future<RoleModel?> getRoleByName(String name)

Future<RoleModel> createCustomRole({
  required String name,
  required List<String> permissions,
  String? createdBy,
})

Future<RoleModel> updateRolePermissions({
  required String roleId,
  required List<String> permissions,
  String? updatedBy,
})

Future<void> deleteRole({
  required String roleId,
  String? deletedBy,
})

// Permission Checking
Future<bool> roleHasPermission({
  required String roleId,
  required String permission,
})

List<String> getAllAvailablePermissions()
List<RoleModel> getSystemRoles()

void clearCache()
```

### AuditServiceAppwrite

```dart
// Logging (Automatic on all operations)
Future<ActivityLogModel> logActivity({
  required String userId,
  required String action,
  required String resourceType,
  required String resourceId,
  Map<String, dynamic>? changesBefore,
  Map<String, dynamic>? changesAfter,
  bool success = true,
  String? ipAddress,
  String? userAgent,
})

// Querying
Future<List<ActivityLogModel>> getAllActivities({
  int limit = 100,
  int offset = 0,
})

Future<List<ActivityLogModel>> getActivitiesByUser({
  required String userId,
  int limit = 50,
})

Future<List<ActivityLogModel>> getActivitiesByAction({
  required String action,
  int limit = 50,
})

Future<List<ActivityLogModel>> getActivitiesByResource({
  required String resourceType,
  String? resourceId,
  int limit = 50,
})

Future<List<ActivityLogModel>> getActivitiesByDateRange({
  required DateTime startDate,
  required DateTime endDate,
  int limit = 100,
})

Future<List<ActivityLogModel>> getFailedActivities({
  int limit = 50,
})

// Statistics
Future<Map<String, dynamic>> getStatistics({
  required DateTime startDate,
  required DateTime endDate,
})

List<ActivityLogModel> getCachedActivities({int limit = 50})
void clearCache()
```

### Phase1InventoryServiceAppwrite

```dart
// CRUD Operations
Future<List<InventoryModel>> getAllInventory()
Future<List<InventoryModel>> getLowStockItems()
Future<InventoryModel?> getInventoryByProductId(String productId)

Future<InventoryModel> createInventoryItem({
  required String productId,
  required String productName,
  required double minStockLevel,
  required double maxStockLevel,
  String? sku,
  double initialQuantity = 0.0,
  double? costPerUnit,
  String? createdBy,
})

// Stock Movements (SALE, RESTOCK, ADJUSTMENT, RETURN, DAMAGE, STOCKTAKE)
Future<InventoryModel> addStockMovement({
  required String productId,
  required String movementType,
  required double quantity,
  required String reason,
  required String userId,
  double? newQuantity,
})

Future<InventoryModel> adjustStock({
  required String productId,
  required double newQuantity,
  required String reason,
  required String userId,
})

Future<InventoryModel> performStockTake({
  required String productId,
  required double countedQuantity,
  required String userId,
  String? notes,
})

// History & Analytics
Future<List<StockMovementModel>> getMovementHistory({
  required String productId,
  int limit = 50,
})

Future<double> calculateInventoryValue()

Future<Map<String, dynamic>> getInventoryStatistics()

void clearCache()
```

---

## Available Permissions

```
Permissions: 15 total

User Management:
- VIEW_USERS
- CREATE_USERS
- EDIT_USERS
- DELETE_USERS

Role Management:
- MANAGE_ROLES
- VIEW_ROLES
- ASSIGN_ROLES
- MANAGE_PERMISSIONS

Activity Logs:
- VIEW_ACTIVITY_LOGS

Inventory:
- MANAGE_INVENTORY
- VIEW_INVENTORY
- EDIT_INVENTORY
- MANAGE_STOCK

Reporting:
- VIEW_REPORTS

System:
- SYSTEM_ADMIN
```

---

## System Roles Reference

| Role | Permissions | Use Case |
|------|-------------|----------|
| **Admin** | All 15 | Full system access, system configuration |
| **Manager** | 8 (Users, Inventory, Reports) | Business management |
| **Supervisor** | 4 (View, Inventory, Stock, Reports) | Limited inventory access |
| **Viewer** | 4 (View-only across all) | Read-only access |

---

## Appwrite Collections

### backend_users
```json
{
  "email": "string (unique)",
  "displayName": "string",
  "phone": "string",
  "roleId": "string",
  "isActive": "boolean",
  "isLocked": "boolean",
  "failedLoginAttempts": "integer",
  "lastLoginAt": "integer"
}
```

### roles
```json
{
  "name": "string (unique)",
  "permissions": "string (JSON array)",
  "isSystemRole": "boolean",
  "createdAt": "integer",
  "updatedAt": "integer"
}
```

### activity_logs
```json
{
  "userId": "string",
  "action": "string",
  "resourceType": "string",
  "resourceId": "string",
  "changesBefore": "string (JSON)",
  "changesAfter": "string (JSON)",
  "success": "boolean",
  "timestamp": "integer",
  "ipAddress": "string",
  "userAgent": "string"
}
```

### inventory_items
```json
{
  "productId": "string",
  "productName": "string",
  "sku": "string",
  "currentQuantity": "float",
  "minStockLevel": "float",
  "maxStockLevel": "float",
  "costPerUnit": "float",
  "movements": "string (JSON array)",
  "createdAt": "integer",
  "updatedAt": "integer"
}
```

---

## Common Usage Examples

### Create Admin User

```dart
final userService = BackendUserServiceAppwrite.instance;
await userService.createUser(
  email: 'admin@example.com',
  displayName: 'Admin User',
  roleId: RoleServiceAppwrite.adminRoleId,
  createdBy: 'system',
);
```

### Create Custom Role

```dart
final roleService = RoleServiceAppwrite.instance;
await roleService.createCustomRole(
  name: 'Cashier',
  permissions: [
    'VIEW_USERS',
    'VIEW_INVENTORY',
    'MANAGE_STOCK',
    'VIEW_REPORTS',
  ],
  createdBy: currentUserId,
);
```

### Track Stock Movement

```dart
final inventoryService = Phase1InventoryServiceAppwrite.instance;

// Record a sale
await inventoryService.addStockMovement(
  productId: 'prod_pizza_001',
  movementType: 'SALE',
  quantity: 2,
  reason: 'POS transaction #12345',
  userId: currentUserId,
);

// Restock
await inventoryService.addStockMovement(
  productId: 'prod_pizza_001',
  movementType: 'RESTOCK',
  quantity: 50,
  reason: 'Supplier order #5678',
  userId: currentUserId,
);

// Physical inventory count
await inventoryService.performStockTake(
  productId: 'prod_pizza_001',
  countedQuantity: 48,
  userId: currentUserId,
  notes: 'Monthly stock count - found 2 damaged',
);
```

### View Audit Trail

```dart
final auditService = AuditService.instance;

// Get recent activity
final recentActivity = auditService.getCachedActivities(limit: 20);

// Get user activity
final userActivity = await auditService.getActivitiesByUser(
  userId: userId,
  limit: 50,
);

// Get activity by date range
final weekActivity = await auditService.getActivitiesByDateRange(
  startDate: DateTime.now().subtract(Duration(days: 7)),
  endDate: DateTime.now(),
);

// Get statistics
final stats = await auditService.getStatistics(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);
print('Total activities: ${stats['totalActivities']}');
print('Success rate: ${stats['successRate']}%');
print('Top actions: ${stats['topActions']}');
```

---

## Error Handling

### Try-Catch Pattern

```dart
try {
  final user = await userService.createUser(
    email: email,
    displayName: displayName,
    roleId: roleId,
  );
  // Success - user created
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('User created: ${user.email}')),
  );
} on Exception catch (e) {
  // Error - show to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "User with email X already exists" | Duplicate email | Use unique email |
| "Inventory not found for product" | Product doesn't exist | Create inventory first |
| "Cannot modify system role" | Trying to edit Admin/Manager | Can't modify system roles |
| "Insufficient stock" | Trying to sell more than available | Check stock level first |
| "At least one permission required" | Empty permissions list | Add at least one permission |

---

## Performance Tips

1. **Use Cache**: Services cache results for 5 minutes
2. **Clear Cache When Needed**: Call `service.clearCache()` to force refresh
3. **Batch Operations**: Import multiple services at once to reduce initialization overhead
4. **Limit Queries**: Use `limit` parameter to reduce data transfer
5. **Check Cache First**: Use `getCachedActivities()` for instant access to recent logs

---

## Debugging

### Enable Logging

All services print detailed logs:
```
✅ Success messages (checkmark emoji)
❌ Error messages (X emoji)
📋 Information messages
🔄 Refresh/sync messages
```

### Check Appwrite Status

```dart
final appwrite = AppwritePhase1Service();
print('Initialized: ${appwrite.isInitialized}');
print('Error: ${appwrite.errorMessage}');
```

### Inspect Cache

```dart
final userService = BackendUserServiceAppwrite.instance;
final cachedUsers = userService._userCache; // Access internal cache for debugging
print('Cached users: ${cachedUsers.length}');
```

---

## Version Information

- **Appwrite**: v1 (https://appwrite.extropos.org/v1)
- **Flutter**: 3.x
- **Dart**: 3.x
- **Phase 1c**: Complete ✅

---

**Last Updated**: February 3, 2026
**Status**: Ready for Production

