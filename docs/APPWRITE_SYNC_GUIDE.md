# Appwrite Sync Implementation Guide

## Overview

The Appwrite sync service has been created to enable cloud synchronization across POS, Backend, and KDS flavors. This guide explains how to complete the implementation.

## What's Been Created

### 1. `lib/services/appwrite_sync_service.dart`

Complete sync service with:

- User authentication (login/register/logout)

- Bidirectional sync (upload to cloud / download from cloud)

- Real-time subscriptions support

- Conflict resolution (last-write-wins)

- Offline-first architecture

### 2. `lib/screens/sync_management_screen.dart`

UI for managing sync operations:

- Connection status display

- Upload to cloud button

- Download from cloud button

- Last sync time tracking

- Sync progress indicators

## Setup Steps

### Step 1: Create Appwrite Project

1. Go to [cloud.appwrite.io](https://cloud.appwrite.io)
2. Create a new project
3. Note down your **Project ID**
4. Keep the default endpoint: `https://cloud.appwrite.io/v1`

### Step 2: Create Database Structure

In your Appwrite console:

1. Create a new database named `extropos_db`

2. Create the following collections:

#### Collection: `business_info`

Attributes:

- `business_id` (string, required)

- `user_id` (string, required)

- `name` (string, required)

- `address` (string)

- `phone` (string)

- `email` (string)

- `tax_number` (string)

- `currency_symbol` (string)

- `is_tax_enabled` (boolean)

- `tax_rate` (double)

- `is_service_charge_enabled` (boolean)

- `service_charge_rate` (double)

- `receipt_header` (string)

- `receipt_footer` (string)

- `logo_path` (string)

- `updated_at` (datetime)

Indexes:

- `business_id_idx` on `business_id` (key)

#### Collection: `categories`

Attributes:

- `business_id` (string, required)

- `category_id` (string, required)

- `name` (string, required)

- `icon` (string)

- `color` (string)

- `updated_at` (datetime)

Indexes:

- `business_category_idx` on `business_id` + `category_id` (unique)

#### Collection: `products`

Attributes:

- `business_id` (string, required)

- `product_id` (string, required)

- `name` (string, required)

- `price` (double, required)

- `category` (string)

- `icon` (string)

- `updated_at` (datetime)

Indexes:

- `business_product_idx` on `business_id` + `product_id` (unique)

#### Collection: `modifiers`

Attributes:

- `business_id` (string, required)

- `modifier_id` (string, required)

- `name` (string, required)

- `type` (string)

- `options` (string, JSON array)

- `updated_at` (datetime)

#### Collection: `tables`

Attributes:

- `business_id` (string, required)

- `table_id` (string, required)

- `name` (string, required)

- `capacity` (integer)

- `status` (string)

- `updated_at` (datetime)

#### Collection: `users`

Attributes:

- `business_id` (string, required)

- `user_id` (string, required)

- `name` (string, required)

- `role` (string)

- `pin` (string)

- `updated_at` (datetime)

### Step 3: Set Permissions

For each collection, set permissions:

- **Create**: Any authenticated user

- **Read**: Any authenticated user  

- **Update**: Any authenticated user

- **Delete**: Any authenticated user

(You can make this more restrictive based on user roles later)

### Step 4: Fix DatabaseService Methods

The sync service expects these methods in `DatabaseService`. You need to add them:

```dart
// In lib/services/database_service.dart

// Business Info methods
Future<BusinessInfo?> getBusinessInfo() async {
  // Implement: Query business_info table and return BusinessInfo model
}

Future<void> updateBusinessInfo({
  required String name,
  String? address,
  String? phone,
  String? email,
  String? taxNumber,
  String? currencySymbol,
  bool? isTaxEnabled,
  double? taxRate,
  bool? isServiceChargeEnabled,
  double? serviceChargeRate,
  String? receiptHeader,
  String? receiptFooter,
  String? logoPath,
}) async {
  // Implement: Update business_info table
}

// Product methods
Future<List<Product>> getProducts() async {
  // Implement: Query products table and return list
}

Future<void> updateProduct({
  required String id,
  String? name,
  double? price,
  String? category,
  String? icon,
}) async {
  // Implement: Update product by ID
}

Future<void> insertProduct({
  required String id,
  required String name,
  required double price,
  String? category,
  String? icon,
}) async {
  // Implement: Insert new product
}

```text


### Step 5: Integrate into Backend Flavor


Add to `lib/screens/backend_home_screen.dart`:


```dart
ListTile(
  leading: const Icon(Icons.cloud_sync, color: Color(0xFF2563EB)),
  title: const Text('Cloud Sync'),
  subtitle: const Text('Sync data with Appwrite'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SyncManagementScreen(),
      ),
    );
  },
),

```text


### Step 6: Initialize in main_backend.dart



```dart
// In lib/main_backend.dart, in the runApp() section:

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization ...
  
  // Initialize Appwrite
  await AppwriteSyncService.instance.initialize();
  
  runApp(const MyApp());
}

```text


### Step 7: Configure in App


1. Build and run the Backend flavor
2. Navigate to "Cloud Sync" menu
3. Click the settings icon (top-right)
4. Enter your Appwrite endpoint and project ID
5. Create an account or login
6. Return to sync screen
7. Click "Upload to Cloud" to sync data


## Usage Workflow



### Initial Setup (One Time)


1. Configure Appwrite credentials
2. Register/Login
3. Upload initial data to cloud


### Daily Operations


**On POS/KDS devices:**


- Periodically click "Download from Cloud" to get latest products/categories

**On Backend device:**


- Make changes to products/categories

- Click "Upload to Cloud" to push changes

- Other devices can then download the updates


### Automatic Sync (Future Enhancement)


You can add automatic sync by:

1. Calling `syncToCloud()` after database changes
2. Using real-time subscriptions via `subscribeToUpdates()`
3. Implementing background sync with timers


## Security Notes


1. **Never hardcode credentials** - always enter via settings screen

2. **Use HTTPS only** for production

3. **Set proper collection permissions** based on user roles

4. **Encrypt sensitive data** (like PINs) before uploading


## Troubleshooting



### "Not logged in" error


- Go to settings and login again

- Check if session expired


### Sync fails


- Verify internet connection

- Check Appwrite console for errors

- Ensure collections exist with correct attributes

- Check permissions on collections


### Data not appearing


- Verify `business_id` matches across devices

- Check last sync time

- Try manual sync (Upload then Download)


## Next Steps


1. Fix DatabaseService methods to match sync service expectations
2. Test sync between Backend and POS flavors
3. Add sync button to POS settings for easy updates
4. Implement real-time subscriptions for live updates
5. Add conflict resolution UI for merge conflicts


## Files Created


- `/lib/services/appwrite_sync_service.dart` - Main sync logic

- `/lib/screens/sync_management_screen.dart` - Sync UI

- `/docs/APPWRITE_SYNC_GUIDE.md` - This file


## Dependencies


Already added to `pubspec.yaml`:


```yaml
dependencies:
  appwrite: ^20.3.1

```text

No additional dependencies needed!
