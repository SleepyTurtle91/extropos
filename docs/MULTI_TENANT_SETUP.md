# Multi-Tenant Setup Guide for FlutterPOS

## Overview

FlutterPOS now supports **multi-tenancy** using Appwrite Teams for data isolation. This allows you to run FlutterPOS as a **SaaS application** where multiple businesses/stores can use the same backend infrastructure while keeping their data completely isolated.

## Architecture: Teams-Based Isolation

### Core Concept

- Each **store/business** = One Appwrite **Team**

- All users belonging to a store are **members** of that store's Team

- Documents are created with **Team-based permissions** (`Role.team(teamId)`)

- Appwrite automatically enforces data isolation at the database level

### Data Model

```text
┌─────────────────────────────────────────────────────────────┐
│                    Appwrite Project                         │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ Database: extropos_db                               │   │
│  │                                                      │   │
│  │  Collections:                                        │   │
│  │  • stores (team_id, store_name, admin_user_id)      │   │
│  │  • products (store_id, name, price) [Team perms]    │   │
│  │  • categories (store_id, name) [Team perms]         │   │
│  │  • business_info (store_id, ...) [Team perms]       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Team: Store1 │  │ Team: Store2 │  │ Team: Store3 │     │
│  │ Members: 5   │  │ Members: 3   │  │ Members: 8   │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘

```text


## Implementation Status



### ✅ Completed (Client-Side)


The following methods are **fully implemented** in `lib/services/appwrite_sync_service.dart`:


#### 1. Team Management



```dart
// Create a new team for a store
Future<String> createStoreTeam(String storeName)

// Join an existing team
Future<void> joinStoreTeam(String teamId)

// Get all teams user belongs to
Future<List<Map<String, dynamic>>> getUserTeams()

// Set current active team
Future<void> setStoreTeamId(String teamId)

```text


#### 2. Document Creation with Isolation



```dart
// Create product with team-based permissions
Future<String> createProduct({
  required String name,
  required double price,
  required String storeId,
  String? storeTeamId,
})

```text

**Example Usage:**


```dart
final appwrite = AppwriteSyncService.instance;

// Create product (only team members can read/write)
final productId = await appwrite.createProduct(
  name: 'Espresso',
  price: 3.50,
  storeId: 'store_abc123',
  storeTeamId: 'team_xyz789', // Optional, uses stored teamId if null
);

```text

**Generated Permissions:**


```dart
permissions: [
  Permission.read(Role.team('team_xyz789')),
  Permission.write(Role.team('team_xyz789')),
]

```text


#### 3. Data Retrieval with Filtering



```dart
// List products for a specific store
Future<List<Map<String, dynamic>>> listStoreProducts({
  required String storeId,
})

```text

**Example Usage:**


```dart
// Fetch products (automatically filtered by team permissions)
final products = await appwrite.listStoreProducts(
  storeId: 'store_abc123',
);

for (final product in products) {
  print('${product['name']}: \$${product['price']}');
}

```text


#### 4. Store Metadata Management



```dart
// Create store record linking team to metadata
Future<String> createStoreRecord({
  required String teamId,
  required String storeName,
  String? tenantId,
})

// Complete tenant onboarding (team + store record)

Future<Map<String, String>> onboardNewTenant({
  required String storeName,
})

```text


### ⏳ Pending (Server-Side Function)


The following logic should be implemented as an **Appwrite Function** (Dart runtime) for security:


#### Server Function: Tenant Registration


**Purpose:** Securely create a new tenant (store) with admin user during activation.

**File:** `appwrite-functions/tenant-registration/main.dart`


```dart
import 'dart:async';
import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';

/// Appwrite Function: Tenant Registration
/// 
/// Securely creates a new tenant (store) with team, admin user, and metadata
/// 
/// Input (JSON):
/// {
///   "tenant_id": "unique_store_id",
///   "store_name": "My Restaurant",
///   "admin_email": "admin@example.com",
///   "admin_password": "securePassword123"
/// }
/// 
/// Output (JSON):
/// {
///   "success": true,
///   "user_id": "...",
///   "team_id": "...",
///   "store_id": "..."
/// }

Future<dynamic> main(final context) async {
  // 1. Initialize Appwrite Server SDK
  final client = Client()
      .setEndpoint(Platform.environment['APPWRITE_ENDPOINT']!)
      .setProject(Platform.environment['APPWRITE_PROJECT_ID']!)
      .setKey(Platform.environment['APPWRITE_API_KEY']!);

  final account = Account(client);
  final teams = Teams(client);
  final databases = Databases(client);

  try {
    // 2. Parse input
    final payload = jsonDecode(context.req.body);
    final tenantId = payload['tenant_id'] as String;
    final storeName = payload['store_name'] as String;
    final adminEmail = payload['admin_email'] as String;
    final adminPassword = payload['admin_password'] as String;

    // 3. Create Team
    final team = await teams.create(
      teamId: ID.unique(),
      name: storeName,
    );
    final teamId = team.$id;

    // 4. Create Admin User
    final user = await account.create(
      userId: ID.unique(),
      email: adminEmail,
      password: adminPassword,
      name: 'Admin',
    );
    final userId = user.$id;

    // 5. Add Admin to Team with 'owner' role
    await teams.createMembership(
      teamId: teamId,
      email: adminEmail,
      userId: userId,
      roles: ['owner'],
      url: '', // No invite URL needed for server-side creation
    );

    // 6. Create Store Metadata Document
    const databaseId = 'extropos_db';
    const storesCollectionId = 'stores';

    final storeDoc = await databases.createDocument(
      databaseId: databaseId,
      collectionId: storesCollectionId,
      documentId: ID.unique(),
      data: {
        'tenant_id': tenantId,
        'team_id': teamId,
        'store_name': storeName,
        'admin_user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      },
      permissions: [
        // Only team members can read/write
        Permission.read(Role.team(teamId)),
        Permission.write(Role.team(teamId)),
      ],
    );

    // 7. Return success response
    return context.res.json({
      'success': true,
      'user_id': userId,
      'team_id': teamId,
      'store_id': storeDoc.$id,
    });
  } catch (e) {
    // Error handling
    return context.res.json({
      'success': false,
      'error': e.toString(),
    }, 400);
  }
}

```text

**To Deploy:**


```bash

# Install Appwrite CLI

npm install -g appwrite


# Login to your Appwrite instance

appwrite login


# Deploy function

cd appwrite-functions/tenant-registration
appwrite functions createDeployment \
  --functionId tenant-registration \
  --activate true \
  --code . \
  --runtime dart-3.0

```text


## Appwrite Database Setup



### Collections to Create



#### 1. `stores` Collection



```javascript
// Attributes
{
  "tenant_id": { type: "string", size: 255, required: true },
  "team_id": { type: "string", size: 255, required: true },
  "store_name": { type: "string", size: 255, required: true },
  "admin_user_id": { type: "string", size: 255, required: true },
  "created_at": { type: "datetime", required: true }
}

// Indexes
{
  "team_id_idx": { type: "key", attributes: ["team_id"] },
  "tenant_id_idx": { type: "key", attributes: ["tenant_id"], unique: true }
}

// Permissions
[
  Permission.read(Role.any()),  // Anyone can read store metadata
  Permission.create(Role.users()), // Any authenticated user can create
  Permission.update(Role.team("team_id")), // Only team members can update
  Permission.delete(Role.team("team_id"))  // Only team members can delete
]

```text


#### 2. Update `products` Collection



```javascript
// Add attribute
{
  "store_id": { type: "string", size: 255, required: true }
}

// Add index
{
  "store_id_idx": { type: "key", attributes: ["store_id"] }
}

// Set Document Permissions (not collection permissions)
// Documents created via createProduct() automatically get team permissions

```text


#### 3. Update `categories`, `business_info`, etc


- Add `store_id` attribute

- Add `store_id` index

- Documents created with team permissions


### Collection-Level vs Document-Level Permissions


**IMPORTANT:** Multi-tenancy uses **Document-Level Permissions**, not Collection-Level.


```dart
// ❌ WRONG: Collection-level permissions (affects ALL documents)
Collection Settings → Permissions → [Permission.read(Role.team(...))]

// ✅ CORRECT: Document-level permissions (per document)
databases.createDocument(
  // ...
  permissions: [
    Permission.read(Role.team(teamId)),
    Permission.write(Role.team(teamId)),
  ],
)

```text


## Usage Workflows



### Workflow 1: New Tenant Registration (SaaS Onboarding)



```dart
// Client-side (Backend app)
final appwrite = AppwriteSyncService.instance;

// 1. Call server function to create tenant (includes user creation)
final response = await http.post(
  Uri.parse('https://syd.cloud.appwrite.io/v1/functions/tenant-registration/executions'),
  headers: {
    'X-Appwrite-Project': '689965770017299bd5a5',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'tenant_id': 'store_${DateTime.now().millisecondsSinceEpoch}',
    'store_name': 'My Coffee Shop',
    'admin_email': 'owner@coffeeshop.com',
    'admin_password': 'securePass123!',
  }),
);

final result = jsonDecode(response.body);

// 2. Login with new credentials
await appwrite.login(
  'owner@coffeeshop.com',
  'securePass123!',
);

// 3. Set team context
await appwrite.setStoreTeamId(result['team_id']);

// Done! All subsequent operations are isolated to this team

```text


### Workflow 2: Existing User Joins Store



```dart
// User already has Appwrite account, joins an existing store

// 1. Login
await appwrite.login('user@example.com', 'password123');

// 2. Join team (requires team ID from store admin)
await appwrite.joinStoreTeam('team_abc123');

// 3. Team is now active
print('Active team: ${appwrite.storeTeamId}');

```text


### Workflow 3: Single Business Multi-Device (Current Use Case)



```dart
// One business owner, multiple POS terminals

// Device 1 (First time setup):
await appwrite.register(
  email: 'owner@restaurant.com',
  password: 'password123',
  name: 'Restaurant Owner',
);

final result = await appwrite.onboardNewTenant(
  storeName: 'My Restaurant',
);

// Device 2, 3, 4... (Same business):
await appwrite.login('owner@restaurant.com', 'password123');
// Team ID automatically loaded from backend
// All devices sync to same team's data

```text


## Migration Path



### Current State (Single Business)


- Users: `businessId` stored in SharedPreferences

- Documents: No team permissions, filtered by `businessId`


### Migrated State (Multi-Tenant Ready)


- Users: `storeTeamId` stored in SharedPreferences

- Documents: Team permissions enforced by Appwrite

- Backward compatible: `businessId` still works for filtering


### Migration Steps


1. **Keep existing code working:**

   - All existing sync methods use `businessId` filtering

   - No breaking changes

2. **Opt-in to multi-tenancy:**

   ```dart
   // Enable multi-tenant mode for a user
   await appwrite.onboardNewTenant(storeName: 'Store Name');
   ```

1. **Update document creation to use team permissions:**

   ```dart
   // Old way (still works)
   await databases.createDocument(
     // ... no permissions, filtered by businessId
   );

   // New way (team-isolated)
   await appwrite.createProduct(
     name: 'Product',
     price: 10.0,
     storeId: appwrite.businessId!,
   );
   ```

## Security Considerations

### ✅ Implemented

- Team-based document permissions

- Automatic permission enforcement by Appwrite

- Users can only access their team's data

- Server-side user creation (prevents client-side manipulation)

### ⚠️ Important Notes

- **Never expose API keys to client apps**

- **Always use Appwrite Functions for sensitive operations**:

  - User creation during tenant registration

  - Team creation with admin rights

  - Bulk permission updates

- **Validate tenant_id from license keys** (prevents unauthorized tenant creation)

### 🔒 Best Practices

1. **Server Function for Registration:** User creation MUST happen server-side

2. **License Validation:** Verify activation keys before creating tenants

3. **Rate Limiting:** Enable Appwrite rate limiting for registration endpoints

4. **Audit Logs:** Track team creation and membership changes

5. **Backup Strategy:** Separate backups per team for disaster recovery

## Testing Multi-Tenancy

### Test Scenario 1: Data Isolation

```dart
// Create two separate stores
final team1 = await appwrite.createStoreTeam('Store 1');
final team2 = await appwrite.createStoreTeam('Store 2');

// User A joins Store 1
await appwrite.setStoreTeamId(team1);
await appwrite.createProduct(
  name: 'Store 1 Product',
  price: 10.0,
  storeId: 'store1',
);

// User B joins Store 2
await appwrite.setStoreTeamId(team2);
await appwrite.createProduct(
  name: 'Store 2 Product',
  price: 20.0,
  storeId: 'store2',
);

// Verify isolation
final store1Products = await appwrite.listStoreProducts(storeId: 'store1');
final store2Products = await appwrite.listStoreProducts(storeId: 'store2');

// User A cannot see User B's products (enforced by Appwrite)
print(store1Products.length); // 1
print(store2Products.length); // 0 (if User A is querying)

```text


### Test Scenario 2: Team Membership



```dart
// Check user's teams
final teams = await appwrite.getUserTeams();
for (final team in teams) {
  print('${team['name']}: ${team['total_members']} members');
}

```text


## FAQ


**Q: Can I use this for a single business?**  

A: Yes! Single business is just multi-tenancy with one tenant. Create one team, all devices join it.

**Q: How do I switch between stores in the app?**  

A: Call `appwrite.setStoreTeamId(teamId)` to change the active team. All subsequent operations use that team's permissions.

**Q: What happens if I don't set a team ID?**  

A: Operations requiring team permissions will throw an exception. Always set a team after login.

**Q: Can one user belong to multiple teams?**  

A: Yes! A manager can belong to multiple stores. Use `getUserTeams()` to list them and `setStoreTeamId()` to switch.

**Q: How do I delete a tenant?**  

A: Via Appwrite console or server function. Delete the team, which cascades to all team-permission documents.


## Next Steps


1. ✅ **Client methods implemented** (this guide)

2. ⏳ **Create Appwrite Function** for tenant registration

3. ⏳ **Set up collections** in Appwrite console

4. ⏳ **Update sync methods** to use team permissions

5. ⏳ **Add team selection UI** in Backend app

6. ⏳ **Test multi-tenant isolation**


## References


- [Appwrite Teams Documentation](https://appwrite.io/docs/server/teams)

- [Appwrite Permissions](https://appwrite.io/docs/permissions)

- [Appwrite Functions (Dart)](https://appwrite.io/docs/functions-dart)

- FlutterPOS Appwrite Service: `lib/services/appwrite_sync_service.dart`
