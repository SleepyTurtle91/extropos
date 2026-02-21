# Appwrite Integration Guide for FlutterPOS

**Status**: ✅ Complete  
**Date**: December 10, 2025  
**Appwrite Version**: 1.8.0

---

## Quick Reference

|Item|Details|
|-----|-------|
|**Endpoint**|<http://localhost:8080/v1>|
|**Project ID**|69392e4c0017357bd3d5|
|**API Key**|standard_b5f49e190cce...|
|**Database**|pos_db (14 collections, 4 buckets)|
|**Console**|<http://localhost:8080>|
|**Email**|<abber8@gmail.com>|
|**Password**|Berneydaniel123|

---

## Collections Overview

### 1. **Core POS Collections**

#### categories

Stores product categories or menu groups.

```dart
// Create category
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'categories',
  documentId: 'cat_001',
  data: {
    'name': 'Beverages',
    'sort_order': 1,
    'is_active': true,
  },
);
```text

**Fields**:


- `id` (string) - Category ID

- `name` (string) - Display name

- `sort_order` (integer) - Display order

- `is_active` (boolean) - Enabled/disabled

---


#### items


Product/menu items with pricing and inventory.

```dart
// Create product
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'items',
  documentId: 'item_001',
  data: {
    'name': 'Nasi Lemak',
    'price': 8.50,
    'category_id': 'cat_001',
    'stock': 50,
    'is_available': true,
  },
);
```text

**Fields**:


- `id` (string) - Item ID

- `name` (string) - Item name

- `price` (number) - Selling price

- `category_id` (string) - Reference to category

- `stock` (integer) - Available quantity

- `is_available` (boolean) - Can be ordered

- `image_id` (string) - Reference to product_images bucket

- `description` (string) - Item description

---


#### orders


Customer orders with totals and payment details.

```dart
// Create order
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'orders',
  documentId: 'order_' + DateTime.now().millisecondsSinceEpoch.toString(),
  data: {
    'table_id': 'table_A1', // Optional for restaurant
    'status': 'pending',
    'subtotal': 25.00,
    'tax': 2.50,
    'service_charge': 2.50,
    'total': 30.00,
    'payment_method': 'cash',
    'created_at': DateTime.now().toIso8601String(),
  },
);
```text

**Fields**:


- `id` (string) - Order ID

- `table_id` (string) - Restaurant table (optional)

- `status` (string) - pending, completed, cancelled

- `subtotal` (number) - Items total before tax/service

- `tax` (number) - Tax amount

- `service_charge` (number) - Service charge

- `total` (number) - Final amount

- `payment_method` (string) - Payment type

- `created_at` (datetime) - Order creation

- `updated_at` (datetime) - Last update

---


#### order_items


Individual items within an order.

```dart
// Add item to order
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'order_items',
  documentId: 'oi_' + uuid.v4(),
  data: {
    'order_id': order_id,
    'item_id': 'item_001',
    'quantity': 2,
    'unit_price': 8.50,
    'discount': 0.00,
    'modifiers': ['extra_chili', 'no_onion'],
  },
);
```text

**Fields**:


- `id` (string) - Order item ID

- `order_id` (string) - Reference to orders

- `item_id` (string) - Reference to items

- `quantity` (integer) - Quantity ordered

- `unit_price` (number) - Price at time of order

- `discount` (number) - Applied discount

- `modifiers` (array) - Applied modifiers

---


### 2. **Management Collections**



#### users


Staff/employee accounts with roles.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'users',
  documentId: 'user_001',
  data: {
    'name': 'John Doe',
    'role': 'cashier', // cashier, manager, admin, kitchen
    'is_active': true,
    'created_at': DateTime.now().toIso8601String(),
  },
);
```text

---


#### tables


Restaurant table definitions.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'tables',
  documentId: 'table_A1',
  data: {
    'name': 'Table A1',
    'capacity': 4,
    'status': 'available', // available, occupied
    'section': 'Main Hall',
  },
);
```text

---


#### customers


Customer/guest information.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'customers',
  documentId: 'cust_001',
  data: {
    'name': 'Ahmed Al-Marri',
    'phone': '+971501234567',
    'email': 'ahmed@example.com',
    'total_spent': 150.00,
    'is_vip': false,
  },
);
```text

---


#### payment_methods


Payment type configurations.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'payment_methods',
  documentId: 'pm_cash',
  data: {
    'name': 'Cash',
    'type': 'cash',
    'is_active': true,
    'requires_account': false,
  },
);
```text

---


### 3. **Operations Collections**



#### transactions


Payment transaction records.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'transactions',
  documentId: 'txn_' + uuid.v4(),
  data: {
    'order_id': order_id,
    'amount': 30.00,
    'method': 'card',
    'status': 'completed', // completed, pending, failed
    'reference': 'TXN123456',
    'timestamp': DateTime.now().toIso8601String(),
  },
);
```text

---


#### printers


Printer configurations.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'printers',
  documentId: 'printer_1',
  data: {
    'name': 'Receipt Printer',
    'type': 'receipt', // receipt, kitchen, bar, label
    'connection_type': 'usb', // usb, network, bluetooth
    'is_default': true,
    'is_active': true,
  },
);
```text

---


#### customer_displays


External customer display settings.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'customer_displays',
  documentId: 'display_1',
  data: {
    'name': 'Main Display',
    'resolution': '1920x1080',
    'is_active': true,
  },
);
```text

---


#### receipt_settings


Receipt printing configuration.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'receipt_settings',
  documentId: 'settings_1',
  data: {
    'header_text': 'ExtroPOS',
    'header_centered': true,
    'footer_text': 'Thank you!',
    'paper_width': 80,
  },
);
```text

---


### 4. **Advanced Collections**



#### modifier_groups


Modifier categories (toppings, sizes, extras).

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'modifier_groups',
  documentId: 'mg_size',
  data: {
    'name': 'Size',
    'is_required': true,
    'max_selections': 1,
    'sort_order': 1,
  },
);
```text

---


#### modifier_items


Individual modifiers.

```dart
final doc = await databases.createDocument(
  databaseId: 'pos_db',
  collectionId: 'modifier_items',
  documentId: 'mi_small',
  data: {
    'group_id': 'mg_size',
    'name': 'Small',
    'price_adjustment': 0.00,
    'sort_order': 1,
  },
);
```text

---


## Storage Buckets



### 1. **receipt_images**


Stores thermal receipt printout images.

```dart
// Upload receipt image
final file = InputFile.fromBytes(
  bytes: receiptBytes,
  filename: 'receipt_${DateTime.now().millisecondsSinceEpoch}.png',
);

final response = await storage.createFile(
  bucketId: 'receipt_images',
  fileId: 'unique_id_${DateTime.now().millisecondsSinceEpoch}',
  file: file,
);
```text

---


### 2. **product_images**


Product/menu item photos.

```dart
// Upload product image
final file = InputFile.fromPath(
  path: '/path/to/product.jpg',
);

final response = await storage.createFile(
  bucketId: 'product_images',
  fileId: 'item_001_image',
  file: file,
);
```text

---


### 3. **logo_images**


Business logo and branding assets.

```dart
// Upload logo
final file = InputFile.fromPath(
  path: '/path/to/logo.png',
);

final response = await storage.createFile(
  bucketId: 'logo_images',
  fileId: 'business_logo',
  file: file,
);
```text

---


### 4. **reports**


Generated reports (CSV, PDF).

```dart
// Upload CSV report
final file = InputFile.fromBytes(
  bytes: csvData,
  filename: 'sales_report_${DateTime.now().toIso8601String()}.csv',
);

final response = await storage.createFile(
  bucketId: 'reports',
  fileId: 'report_${DateTime.now().millisecondsSinceEpoch}',
  file: file,
);
```text

---


## Code Examples



### Initialize Appwrite Client


```dart
import 'package:appwrite/appwrite.dart';
import 'package:flutterpos/config/environment.dart';

class AppwriteService {
  late Client _client;
  late Databases _databases;
  late Storage _storage;
  late Account _account;
  
  AppwriteService() {
    _client = Client()
        .setEndpoint(Environment.appwritePublicEndpoint)
        .setProject(Environment.appwriteProjectId);
    
    _databases = Databases(_client);
    _storage = Storage(_client);
    _account = Account(_client);
  }
  
  // Service methods here
}
```text


### Fetch All Categories


```dart
Future<List<Map<String, dynamic>>> getCategories() async {
  try {
    final response = await _databases.listDocuments(
      databaseId: 'pos_db',
      collectionId: 'categories',
      queries: [
        Query.equal('is_active', true),
        Query.orderAsc('sort_order'),
      ],
    );
    
    return response.documents.map((doc) => doc.data).toList();
  } catch (e) {
    print('Error fetching categories: $e');
    return [];
  }
}
```text


### Create Order


```dart
Future<String> createOrder({
  required List<Map<String, dynamic>> items,
  required double subtotal,
  required double tax,
  required double serviceCharge,
  String? tableId,
}) async {
  try {
    final total = subtotal + tax + serviceCharge;
    
    final response = await _databases.createDocument(
      databaseId: 'pos_db',
      collectionId: 'orders',
      documentId: ID.unique(),
      data: {
        'table_id': tableId,
        'status': 'pending',
        'subtotal': subtotal,
        'tax': tax,
        'service_charge': serviceCharge,
        'total': total,
        'payment_method': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    
    // Add order items
    for (var item in items) {
      await _databases.createDocument(
        databaseId: 'pos_db',
        collectionId: 'order_items',
        documentId: ID.unique(),
        data: {
          'order_id': response.$id,
          'item_id': item['item_id'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'discount': item['discount'] ?? 0,
          'modifiers': item['modifiers'] ?? [],
        },
      );
    }
    
    return response.$id;
  } catch (e) {
    print('Error creating order: $e');
    rethrow;
  }
}
```text


### Update Order Status


```dart
Future<void> updateOrderStatus(String orderId, String status) async {
  try {
    await _databases.updateDocument(
      databaseId: 'pos_db',
      collectionId: 'orders',
      documentId: orderId,
      data: {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  } catch (e) {
    print('Error updating order: $e');
    rethrow;
  }
}
```text


### Record Transaction


```dart
Future<void> recordTransaction({
  required String orderId,
  required double amount,
  required String method,
  String? reference,
}) async {
  try {
    await _databases.createDocument(
      databaseId: 'pos_db',
      collectionId: 'transactions',
      documentId: ID.unique(),
      data: {
        'order_id': orderId,
        'amount': amount,
        'method': method,
        'status': 'completed',
        'reference': reference,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    
    // Update order status
    await updateOrderStatus(orderId, 'completed');
  } catch (e) {
    print('Error recording transaction: $e');
    rethrow;
  }
}
```text


### Upload Product Image


```dart
Future<String> uploadProductImage(String itemId, File imageFile) async {
  try {
    final file = InputFile.fromPath(path: imageFile.path);
    
    final response = await _storage.createFile(
      bucketId: 'product_images',
      fileId: ID.unique(),
      file: file,
    );
    
    // Save image ID to item
    await _databases.updateDocument(
      databaseId: 'pos_db',
      collectionId: 'items',
      documentId: itemId,
      data: {'image_id': response.$id},
    );
    
    return response.$id;
  } catch (e) {
    print('Error uploading image: $e');
    rethrow;
  }
}
```text

---


## Testing the Integration



### Test Connection


```bash
./appwrite_setup_summary.sh
```text


### Verify Collections


```bash
curl -X GET "http://localhost:8080/v1/databases/pos_db/collections" \
  -H "X-Appwrite-Project: 69392e4c0017357bd3d5" \
  -H "X-Appwrite-Key: standard_b5f49e190cce..." | python3 -m json.tool | head -50
```text


### Verify Buckets


```bash
curl -X GET "http://localhost:8080/v1/storage/buckets" \
  -H "X-Appwrite-Project: 69392e4c0017357bd3d5" \
  -H "X-Appwrite-Key: standard_b5f49e190cce..." | python3 -m json.tool | head -50
```text

---


## Security Considerations


⚠️ **Current Setup: Development Only**

For production:

1. **API Key Management**

   - Never commit API keys to git

   - Use environment variables

   - Rotate keys regularly

2. **Authentication**

   - Implement OAuth/JWT for users

   - Validate permissions server-side

   - Use API keys with scoped permissions

3. **Data Protection**

   - Enable encryption at rest

   - Use HTTPS for all connections

   - Validate input data

4. **Access Control**

   - Set document permissions

   - Implement role-based access

   - Audit data access

---


## Troubleshooting



### Connection Failed


```bash

# Check Appwrite status

docker ps | grep appwrite


# Check endpoint

curl http://localhost:8080/v1/health/version


# Check API key

# Verify key in lib/config/environment.dart

```text


### Collection Not Found


```bash

# List all collections

curl -X GET "http://localhost:8080/v1/databases/pos_db/collections" \
  -H "X-Appwrite-Project: 69392e4c0017357bd3d5" \
  -H "X-Appwrite-Key: YOUR_API_KEY"
```text


### Permission Denied


- Check API key is correct

- Verify project ID matches

- Check collection permissions

---


## Additional Resources


- **Appwrite Docs**: <https://appwrite.io/docs>

- **Flutter SDK**: <https://github.com/appwrite/sdk-for-flutter>

- **Console**: <http://localhost:8080>

---

**Setup Complete!** You're ready to integrate Appwrite with FlutterPOS.
