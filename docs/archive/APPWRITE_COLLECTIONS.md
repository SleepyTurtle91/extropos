# FlutterPOS - Appwrite Database & Bucket Configuration

**Version**: 1.0  
**Date**: December 10, 2025  
**API Key**: ✅ Configured  
**Status**: Ready for setup  

---

## Overview

This document explains how to set up Appwrite databases and buckets for FlutterPOS. The app requires:

- **1 Database** (pos_db) with **14 Collections**

- **4 Storage Buckets** for file uploads

---

## Quick Start

```bash

# 1. Make scripts executable

chmod +x setup_appwrite_collections.sh verify_appwrite.sh


# 2. Create all databases and buckets

./setup_appwrite_collections.sh


# 3. Verify everything is set up

./verify_appwrite.sh

```text

---


## Configuration



### API Key


**Stored in**: `lib/config/environment.dart`  
**Value**: `standard_b5f49e190cce961d967a517f80c019d9a7aaa12088ca6bea4de17189188ffeff3d6fb424722fbc5f60ce31154aa7e9143b270a1cc4e9ccd8cf167f53c9db036e9b814992c4f4e113ccd9a0ea337310f0736df5dffdb2df435c1571488f9f545d0a91fcbfbb99eea60c3bb1d817dd2c0908a3703c9541c6cd9fd19c8d1830f5d1`

**Scopes**:


- `databases.read` - Read database structure

- `databases.write` - Create/modify databases

- `collections.read` - Read collections

- `collections.write` - Create/modify collections

- `documents.read` - Read documents

- `documents.write` - Create/modify documents

- `buckets.read` - Read buckets

- `buckets.write` - Create/modify buckets

- `files.read` - Read files

- `files.write` - Upload/delete files

---


## Database Structure



### Database ID



```text
pos_db

```text


### Collections (14 Total)



#### 1. **categories** - Product Categories



```text
Fields:

  - $id (String, Primary Key)

  - name (String, Required)

  - description (String, Optional)

  - icon_code_point (Integer)

  - icon_font_family (String)

  - color_value (Integer)

  - sort_order (Integer)

  - is_active (Boolean)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 2. **items** - Product/Menu Items



```text
Fields:

  - $id (String, Primary Key)

  - name (String, Required)

  - description (String)

  - price (Double, Required)

  - category_id (String, Required, Foreign Key → categories)

  - sku (String, Unique)

  - barcode (String)

  - icon_code_point (Integer)

  - icon_font_family (String)

  - color_value (Integer)

  - is_available (Boolean)

  - is_featured (Boolean)

  - stock (Integer)

  - track_stock (Boolean)

  - low_stock_threshold (Integer)

  - cost (Double)

  - image_url (String)

  - tags (JSON Array)

  - merchant_prices (JSON)

  - sort_order (Integer)

  - printer_override (String)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 3. **orders** - Sales Orders



```text
Fields:

  - $id (String, Primary Key)

  - order_number (String, Required, Unique)

  - table_id (String, Foreign Key → tables)

  - user_id (String, Required, Foreign Key → users)

  - status (String, Required)

  - order_type (String)

  - subtotal (Double)

  - tax (Double)

  - discount (Double)

  - total (Double, Required)

  - merchant_id (String)

  - payment_method_id (String, Foreign Key → payment_methods)

  - notes (String)

  - customer_name (String)

  - customer_phone (String)

  - customer_email (String)

  - special_instructions (String)

  - created_at (DateTime)

  - updated_at (DateTime)

  - completed_at (DateTime)

```text


#### 4. **order_items** - Individual Items in Orders



```text
Fields:

  - $id (String, Primary Key)

  - order_id (String, Required, Foreign Key → orders)

  - item_id (String, Required, Foreign Key → items)

  - item_name (String, Required)

  - item_price (Double, Required)

  - quantity (Integer, Required)

  - subtotal (Double, Required)

  - seat_number (Integer)

  - notes (String)

  - created_at (DateTime)

```text


#### 5. **users** - Staff/Users



```text
Fields:

  - $id (String, Primary Key)

  - username (String, Unique)

  - name (String, Required)

  - email (String, Unique)

  - phone_number (String)

  - role (String, Required) [admin, manager, cashier, waiter, kitchen]

  - pin (String, Hashed)

  - is_active (Boolean)

  - last_login_at (DateTime)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 6. **tables** - Restaurant Tables



```text
Fields:

  - $id (String, Primary Key)

  - name (String, Required)

  - capacity (Integer, Required)

  - status (String) [available, occupied, reserved]

  - section (String)

  - occupied_since (DateTime)

  - customer_name (String)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 7. **payment_methods** - Payment Types



```text
Fields:

  - $id (String, Primary Key)

  - name (String, Required) [Cash, Card, Check, etc.]

  - is_active (Boolean)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 8. **customers** - Customer Records



```text
Fields:

  - $id (String, Primary Key)

  - name (String, Required)

  - phone (String, Unique)

  - email (String, Unique)

  - total_spent (Double)

  - visit_count (Integer)

  - loyalty_points (Integer)

  - last_visit (DateTime)

  - notes (String)

  - is_active (Boolean)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 9. **transactions** - Payment History



```text
Fields:

  - $id (String, Primary Key)

  - order_id (String, Required, Foreign Key → orders)

  - payment_method_id (String, Required, Foreign Key → payment_methods)

  - amount (Double, Required)

  - change_amount (Double)

  - transaction_date (DateTime, Required)

  - receipt_number (String)

  - created_at (DateTime)

```text


#### 10. **printers** - Printer Configuration



```text
Fields:

  - $id (String, Primary Key)

  - name (String, Required)

  - type (String) [receipt, kitchen, label]

  - connection_type (String) [network, usb, bluetooth]

  - ip_address (String)

  - port (Integer)

  - device_id (String)

  - device_name (String)

  - is_default (Boolean)

  - is_active (Boolean)

  - paper_size (String) [mm58, mm80]

  - status (String) [online, offline]

  - has_permission (Boolean)

  - categories (JSON Array)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 11. **customer_displays** - Customer-Facing Displays



```text
Fields:

  - $id (String, Primary Key)

  - name (String, Required)

  - connection_type (String) [network, hdmi]

  - ip_address (String)

  - port (Integer)

  - usb_device_id (String)

  - bluetooth_address (String)

  - platform_specific_id (String)

  - device_name (String)

  - is_default (Boolean)

  - is_active (Boolean)

  - status (String) [online, offline]

  - has_permission (Boolean)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 12. **receipt_settings** - Receipt Configuration



```text
Fields:

  - $id (String, Primary Key)

  - header_text (String)

  - footer_text (String)

  - show_logo (Boolean)

  - show_date_time (Boolean)

  - company_name (String)

  - company_address (String)

  - company_phone (String)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 13. **modifier_groups** - Modifier Groups (e.g., Size, Extras)



```text
Fields:

  - $id (String, Primary Key)

  - name (String, Required)

  - type (String) [single, multiple]

  - is_required (Boolean)

  - display_order (Integer)

  - created_at (DateTime)

  - updated_at (DateTime)

```text


#### 14. **modifier_items** - Individual Modifiers



```text
Fields:

  - $id (String, Primary Key)

  - modifier_group_id (String, Required, Foreign Key → modifier_groups)

  - name (String, Required)

  - price_adjustment (Double)

  - display_order (Integer)

  - created_at (DateTime)

  - updated_at (DateTime)

```text

---


## Storage Buckets (4 Total)



### 1. **receipt_images** - Printed Receipt Images


- **Permission**: Public

- **Max Size**: 10MB per file

- **Allowed Types**: image/jpeg, image/png, application/pdf

- **Usage**: Store receipt scans and proof of payment


### 2. **product_images** - Product/Item Images


- **Permission**: Public

- **Max Size**: 5MB per file

- **Allowed Types**: image/jpeg, image/png, image/webp

- **Usage**: Product photos in menu


### 3. **logo_images** - Business Logos


- **Permission**: Public

- **Max Size**: 2MB per file

- **Allowed Types**: image/jpeg, image/png, image/svg+xml

- **Usage**: Receipt headers, customer displays


### 4. **reports** - Exported Reports


- **Permission**: Private

- **Max Size**: 50MB per file

- **Allowed Types**: application/pdf, text/csv, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet

- **Usage**: Daily/monthly report exports

---


## Indexes (Recommended)


For better query performance, create these indexes:


```text
orders collection:

  - order_number (Unique)

  - created_at (Descending)

  - status

items collection:

  - category_id

  - is_available

  - created_at

users collection:

  - username (Unique)

  - email (Unique)

  - role

customers collection:

  - phone (Unique)

  - email (Unique)

  - created_at (Descending)

```text

---


## Usage in Flutter Code



### Import



```dart
import 'package:appwrite/appwrite.dart';
import 'lib/config/environment.dart';

// Use credentials from environment
final client = Client()
    .setEndpoint(Environment.appwritePublicEndpoint)
    .setProject(Environment.appwriteProjectId);

final databases = Databases(client);
final storage = Storage(client);

```text


### Create Document (Category)



```dart
Future<void> createCategory(String name, String description) async {
  try {
    final response = await databases.createDocument(
      databaseId: Environment.posDatabase,
      collectionId: Environment.categoriesCollection,
      documentId: ID.unique(),
      data: {
        'name': name,
        'description': description,
        'is_active': true,
        'sort_order': 0,
      },
    );
    print('Category created: ${response.$id}');
  } catch (e) {
    print('Error: $e');
  }
}

```text


### Query Documents (List Items)



```dart
Future<List<Item>> getItems() async {
  try {
    final response = await databases.listDocuments(
      databaseId: Environment.posDatabase,
      collectionId: Environment.itemsCollection,
      queries: [
        Query.equal('is_available', true),
        Query.orderDesc('created_at'),
      ],
    );
    
    return response.documents.map((doc) {
      return Item.fromMap(doc.data);
    }).toList();
  } catch (e) {
    print('Error: $e');
    return [];
  }
}

```text


### Upload File (Product Image)



```dart
Future<void> uploadProductImage(File imageFile, String itemId) async {
  try {
    final response = await storage.createFile(
      bucketId: Environment.productImagesBucket,
      fileId: ID.unique(),
      file: InputFile(path: imageFile.path),
    );
    
    // Save file ID to item document
    await databases.updateDocument(
      databaseId: Environment.posDatabase,
      collectionId: Environment.itemsCollection,
      documentId: itemId,
      data: {'image_id': response.$id},
    );
  } catch (e) {
    print('Error: $e');
  }
}

```text


### Get File URL



```dart
String getProductImageUrl(String fileId) {
  return '${Environment.appwritePublicEndpoint}/storage/buckets/${Environment.productImagesBucket}/files/$fileId/view?project=${Environment.appwriteProjectId}';
}

```text

---


## Security Rules



### For Development


- Buckets are **public** (easier for testing)

- Collections allow **public read/write** (via API key only)


### For Production


Update permissions in Appwrite Console:

1. Make buckets **private**
2. Restrict collection access to authenticated users
3. Use roles-based access control (RBAC)
4. Use Document-level security rules

---


## Backup Strategy



```bash

# Backup database (recommended weekly)

docker exec appwrite-mysql mysqldump -u root -proot appwrite > backup.sql


# Backup files

docker cp appwrite:/storage backup_storage/

```text

---


## Troubleshooting



### Collections Already Exist


- The setup script checks for existing collections

- Safe to run multiple times

- Use Appwrite Console to modify existing collections


### API Key Issues


- Verify key has correct scopes

- Check API key permissions in Appwrite Console

- Generate new key if needed: Console → Settings → API Keys


### Connection Errors


- Ensure Appwrite is running: `docker ps | grep appwrite`

- Verify endpoint: `curl http://localhost:8080/v1/health/version`

- Check firewall rules for port 8080

---


## Monitoring



### View Collection Statistics



```bash

# In Appwrite Console

Projects → Your Project → Databases → pos_db → Collections

```text


### Monitor Storage Usage



```bash

# Check bucket sizes

Appwrite Console → Storage → Buckets

```text

---


## Next Steps


- ✅ **Run setup script**

  ```bash
  ./setup_appwrite_collections.sh
  ```

- ✅ **Verify configuration**

  ```bash
  ./verify_appwrite.sh
  ```

- ⏳ **Add sample data** (optional)

  - Use Appwrite Console

  - Or create seed data script

- ⏳ **Update Flutter code**

  - Replace SQLite calls with Appwrite

  - Implement sync logic

- ⏳ **Test integration**

  - Run flutter tests

  - Verify data sync

---

## Files

|File|Purpose|
|-----|--------|
|`lib/config/environment.dart`|API key + database/bucket IDs|

|`setup_appwrite_collections.sh`|Create databases/collections/buckets|
|`verify_appwrite.sh`|Verify setup is complete|
|`APPWRITE_COLLECTIONS.md`|This documentation|

---

**Status**: Ready to configure! Run `./setup_appwrite_collections.sh`
