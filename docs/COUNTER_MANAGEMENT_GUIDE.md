# POS Counter Management Guide

## Overview

The Backend app now includes a **POS Counter Management** system that allows you to register and manage multiple POS terminals/branches for your business. This ensures proper tenant isolation and prevents data leaking between different customers.

## Architecture

```text
┌─────────────────────────────────────────────────────────┐
│                    BACKEND APP                          │
│              (Business Owner's PC)                      │
│                                                         │
│  ┌─────────────────────────────────────────┐          │
│  │      POS Counters Management            │          │
│  ├─────────────────────────────────────────┤          │
│  │  ✓ Counter 1: Main Branch               │          │
│  │    License: EXTRO-LIFE-ABC1-2345-WXYZ   │          │
│  │    Status: Active                       │          │
│  │                                         │          │
│  │  ✓ Counter 2: Bangsar Outlet           │          │
│  │    License: EXTRO-LIFE-XYZ2-6789-ABCD   │          │
│  │    Status: Active                       │          │
│  │                                         │          │
│  │  ✗ Counter 3: KLCC Branch              │          │
│  │    License: EXTRO-LIFE-DEF3-1234-EFGH   │          │
│  │    Status: Inactive (disabled)          │          │
│  └─────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
                        │
                        │ RabbitMQ Sync
                        ▼
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
┌───────────────┐              ┌───────────────┐
│  POS Counter 1│              │  POS Counter 2│
│  Main Branch  │              │ Bangsar Outlet│
│  ✓ Connected  │              │  ✓ Connected  │
└───────────────┘              └───────────────┘

Counter 3 (Inactive) = No sync messages sent

```text


## Multi-Tenant Isolation


Each **Backend app** represents **one customer/business**:


- **Customer A (Restaurant Chain)**

  - Backend A → Manages 5 POS counters

  - License keys: EXTRO-LIFE-R001, R002, R003, R004, R005


- **Customer B (Retail Store)**

  - Backend B → Manages 3 POS counters

  - License keys: EXTRO-LIFE-S001, S002, S003

**Data Isolation:**


- Customer A's Backend only syncs with R001-R005

- Customer B's Backend only syncs with S001-S003

- ✅ No cross-contamination of data


## Features



### 1. Add New Counter


**Steps:**

1. Open Backend app
2. Menu → **POS Counters**
3. Click **+ Add Counter** (bottom right)

4. Fill in:

   - **Counter Name**: "Main Branch" or "Outlet Bangsar"

   - **License Key**: From the POS device (Settings → About)

   - **Description** (optional): "Located at Pavilion KL"

5. Click **Add Counter**

**Validation:**


- Counter name is required

- License key must be valid format (EXTRO-XXXX-XXXX-XXXX-XXXX)

- Duplicate license keys are rejected


### 2. Edit Counter Details


**Steps:**

1. Find counter in list
2. Click **⋮** (menu) → **Edit**

3. Update name or description
4. Click **Save**

**Note:** License key cannot be changed (it's the unique identifier)


### 3. Enable/Disable Sync


**Steps:**

1. Click **⋮** (menu) → **Disable** (or Enable)

2. Counter status changes immediately

**Effect:**


- **Active (green)**: Receives all sync updates

- **Inactive (gray)**: No sync messages sent (temporarily disabled)

**Use Cases:**


- Temporarily disable a branch during maintenance

- Test sync with specific counters only

- Disable counters that are offline/not in use


### 4. Copy License Key


**Steps:**

1. Click **⋮** (menu) → **Copy License**

2. License key copied to clipboard


### 5. Remove Counter


**Steps:**

1. Click **⋮** (menu) → **Remove**

2. Confirm deletion
3. Counter removed permanently

**Warning:** This cannot be undone. Re-add the counter if needed.


## Stats Dashboard


The top of the screen shows:


```text
┌────────────────┬────────────────┬────────────────┐
│ Total Counters │     Active     │    Inactive    │
│       5        │       3        │       2        │
└────────────────┴────────────────┴────────────────┘

```text


- **Total Counters**: All registered POS terminals

- **Active**: Currently receiving sync updates

- **Inactive**: Disabled (not syncing)


## Sync Workflow



### When You Edit a Product/Category in Backend


1. **Backend checks active counters**

   ```dart
   final activeFrontends = await RabbitMQConfigService.instance.getActiveFrontends();
   ```

1. **Backend publishes to each active counter**

   ```dart
   for (final frontend in activeFrontends) {
     await RabbitMQPublisherService.instance.publishProductUpdate(
       licenseKey: frontend.licenseKey,
       productData: {...},
     );
   }
   ```

2. **Each POS receives its message**

   - Counter 1 receives: `license.EXTRO-LIFE-ABC1.product_update`

   - Counter 2 receives: `license.EXTRO-LIFE-XYZ2.product_update`

   - Counter 3 (inactive) receives: Nothing

3. **POS updates locally**

   - Product/category saved to local SQLite

   - UI refreshes immediately

## Best Practices

### Naming Conventions

✅ **Good Counter Names:**

- "Main Branch - Ground Floor"

- "Outlet Bangsar - Counter A"

- "KLCC Branch"

- "Mobile POS - Tablet 1"

❌ **Bad Counter Names:**

- "POS" (too generic)

- "Counter" (not descriptive)

- "Test" (unclear purpose)

### Descriptions

Use descriptions for:

- Physical location: "Located at Pavilion KL, Level 3"

- Device info: "Samsung Galaxy Tab S8, Serial: ABC123"

- Notes: "Temporary popup store, ends Dec 2025"

### Status Management

- **Active**: Counter is operational and should receive updates

- **Inactive**: Counter is offline, under maintenance, or temporarily closed

**Tip:** Don't delete counters unless permanently decommissioned. Use Inactive status for temporary situations.

## Troubleshooting

### "This license key is already registered"

**Cause:** License key already exists in another counter

**Solution:**

- Check if it's a duplicate entry

- Edit existing counter instead

- Use a different license key for new counter

### Counter not receiving sync updates

**Checklist:**

1. ✅ Counter status is **Active** (green icon)

2. ✅ Backend RabbitMQ is **Connected** (Settings → RabbitMQ Sync)

3. ✅ POS device RabbitMQ is **Connected** (POS Settings → Cloud Services → RabbitMQ Sync)

4. ✅ Both using same RabbitMQ server (check Host/Port)
5. ✅ License key matches exactly (case-sensitive)

### How to verify sync is working

1. **Check RabbitMQ connections:**

   ```bash
   docker exec rabbitmq rabbitmqctl list_connections
   ```

   Should show: Backend (1) + Each Active POS (N)

2. **Test with product update:**

   - Backend → Items Management → Edit product → Save

   - POS → Should update within 2 seconds

3. **Monitor RabbitMQ Management UI:**

   - <http://192.168.1.234:15672>

   - Check message flow in real-time

## Migration from Old System

If you were using the old **Target POS Terminals** screen:

### Old System (License Keys Only)

```text
EXTRO-LIFE-ABC1-2345-WXYZ
EXTRO-LIFE-XYZ2-6789-ABCD
EXTRO-LIFE-DEF3-1234-EFGH

```text


### New System (Registered Frontends)



```text
Counter 1: Main Branch
  License: EXTRO-LIFE-ABC1-2345-WXYZ
  Status: Active

Counter 2: Bangsar Outlet
  License: EXTRO-LIFE-XYZ2-6789-ABCD
  Status: Active

Counter 3: KLCC Branch
  License: EXTRO-LIFE-DEF3-1234-EFGH
  Status: Active

```text

**Migration:** Re-add your counters with meaningful names. The old list is preserved for backward compatibility.


## API Reference



### RabbitMQConfigService Methods



```dart
// Get all registered frontends
Future<List<RegisteredFrontend>> getRegisteredFrontends()

// Add new frontend
Future<void> addRegisteredFrontend(RegisteredFrontend frontend)

// Update frontend
Future<void> updateRegisteredFrontend(RegisteredFrontend frontend)

// Remove frontend
Future<void> removeRegisteredFrontend(String licenseKey)

// Get active frontends only
Future<List<RegisteredFrontend>> getActiveFrontends()

// Toggle active status
Future<void> toggleFrontendStatus(String licenseKey)

// Get by license key
Future<RegisteredFrontend?> getFrontendByLicenseKey(String licenseKey)

// Get counts
Future<int> getFrontendCount()
Future<int> getActiveFrontendCount()

```text


### RegisteredFrontend Model



```dart
class RegisteredFrontend {
  final String licenseKey;        // EXTRO-LIFE-ABC1-2345-WXYZ
  final String counterName;       // "Main Branch"
  final String? description;      // Optional notes
  final DateTime registeredAt;    // Auto-set on creation
  final bool isActive;            // true = syncing, false = disabled
}

```text


## Security Notes


- License keys are stored in SharedPreferences (not encrypted)

- Only active counters receive sync messages

- Each POS can only decrypt messages for its own license key

- Tenant isolation is enforced at the routing level (RabbitMQ topic exchange)


## Support


For issues or questions:

1. Check logs: Backend console output
2. Verify RabbitMQ: <http://192.168.1.234:15672>
3. Test connectivity: `./docker/test-connectivity.sh`
4. Review docs: `docs/RABBITMQ_*.md`
