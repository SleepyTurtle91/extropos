import 'package:extropos/models/isar/product_model.dart';
import 'package:extropos/models/isar/transaction_model.dart';
import 'package:extropos/services/isar_database_service.dart';

/// Example: Insert Product from Backend JSON into Isar
///
/// This demonstrates the complete offline-first workflow:
/// 1. Receive product JSON from Appwrite/backend
/// 2. Convert to IsarProduct model
/// 3. Save to local Isar database
/// 4. Product is marked as synced
class ProductInsertExample {
  /// Backend JSON response for a pizza product
  static const Map<String, dynamic> backendProductJson = {
    '\$id': 'prod_123456',
    'name': 'Margherita Pizza',
    'description': 'Fresh mozzarella, basil, tomato',
    'price': 12.50,
    'categoryId': 'cat_pizza',
    'categoryName': 'Pizzas',
    'sku': 'PIZZA-001',
    'icon': 'pizza',
    'imageUrl': 'https://cdn.example.com/margherita.jpg',
    'variants': [
      {'name': 'Small', 'price': 10.50},
      {'name': 'Medium', 'price': 12.50},
      {'name': 'Large', 'price': 14.50},
    ],
    'modifierGroupIds': ['mod_group_1', 'mod_group_2'],
    'quantity': 50.0,
    'costPerUnit': 4.20,
    'isActive': true,
    'createdAt': '2025-12-30T10:30:00Z',
    'updatedAt': '2025-12-30T10:30:00Z',
  };

  /// Example: Insert single product
  static Future<void> insertProductExample() async {
    // Step 1: Convert backend JSON to IsarProduct
    final product = IsarProduct.fromJson(backendProductJson);

    print('Converting product from JSON:');
    print('  - backendId: ${product.backendId}');
    print('  - name: ${product.name}');
    print('  - price: ${product.price}');
    print('  - isSynced: ${product.isSynced}');

    // Step 2: Save to Isar database
    final localId = await IsarDatabaseService.saveProduct(product);
    print('\nProduct saved to Isar:');
    print('  - Local ID: $localId');
    print('  - Backend ID: ${product.backendId}');

    // Step 3: Verify by querying back
    final saved = await IsarDatabaseService.getProductById(localId);
    if (saved != null) {
      print('\nVerified in database:');
      print('  - $saved');
    }
  }

  /// Example: Batch insert products from backend sync
  static Future<void> batchInsertProductsExample() async {
    // Simulating multiple products from backend
    final backendProducts = [
      backendProductJson,
      {
        '\$id': 'prod_789012',
        'name': 'Pepperoni Pizza',
        'price': 13.50,
        'categoryId': 'cat_pizza',
        'categoryName': 'Pizzas',
        'sku': 'PIZZA-002',
        'quantity': 30.0,
        'costPerUnit': 5.20,
        'isActive': true,
      },
      {
        '\$id': 'prod_345678',
        'name': 'Caesar Salad',
        'price': 8.50,
        'categoryId': 'cat_salads',
        'categoryName': 'Salads',
        'sku': 'SALAD-001',
        'quantity': 20.0,
        'costPerUnit': 2.50,
        'isActive': true,
      },
    ];

    print('Batch inserting ${backendProducts.length} products...');

    // Use the sync helper for batch operations
    await IsarDatabaseService.syncProductsFromBackend(backendProducts);

    // Verify
    final allProducts = await IsarDatabaseService.getAllProducts();
    print('Total products in Isar: ${allProducts.length}');
    for (final p in allProducts) {
      print('  - ${p.name}: \$${p.price}');
    }
  }
}

/// Example: Export Transaction from Isar to JSON
///
/// This demonstrates the export workflow:
/// 1. Create a transaction in Isar (with isSynced = false)
/// 2. Export unsynced transactions to JSON
/// 3. Send to backend via API
/// 4. Mark as synced on successful push
class TransactionExportExample {
  /// Example: Create and export a new transaction
  static Future<void> createAndExportTransactionExample() async {
    // Step 1: Create a transaction (e.g., from POS checkout)
    final transaction = IsarTransaction(
      backendId: '', // Empty until backend assigns ID
      transactionNumber: 'ORD-20251230-001',
      transactionDate: DateTime.now().millisecondsSinceEpoch,
      userId: 'user_cashier_1',
      userName: 'John Doe',
      subtotal: 25.00,
      taxAmount: 2.50,
      serviceChargeAmount: 2.50,
      totalAmount: 30.00,
      discountAmount: 0.0,
      paymentMethod: 'cash',
      businessMode: 'retail',
      itemsJson: _encodeOrderItems([
        {
          'productId': 'prod_123456',
          'productName': 'Margherita Pizza',
          'quantity': 1,
          'unitPrice': 12.50,
          'lineTotal': 12.50,
        },
        {
          'productId': 'prod_345678',
          'productName': 'Caesar Salad',
          'quantity': 1,
          'unitPrice': 8.50,
          'lineTotal': 8.50,
        },
      ]),
      isSynced: false, // Not yet synced to backend
    );

    print('Creating transaction:');
    print('  - Transaction #: ${transaction.transactionNumber}');
    print('  - Total: \$${transaction.totalAmount}');
    print('  - isSynced: ${transaction.isSynced}');

    // Step 2: Save to Isar (offline-first)
    await IsarDatabaseService.saveTransaction(transaction);
    print('\nSaved to Isar');

    // Step 3: Export unsynced transactions as JSON
    final unsyncedTransactions =
        await IsarDatabaseService.exportUnsyncedTransactions();
    print('\nExported ${unsyncedTransactions.length} unsynced transaction(s):');
    for (final txJson in unsyncedTransactions) {
      print('  - TX#: ${txJson['transactionNumber']}, Total: \$${txJson['totalAmount']}');
    }

    // Step 4: Simulate pushing to backend and marking as synced
    print('\nSimulating push to backend...');
    // In real app: await backendApi.pushTransactions(unsyncedTransactions);
    // For now, simulate success - mark all unsynced transactions as synced
    if (unsyncedTransactions.isNotEmpty) {
      // Simulate backend assigning IDs and mark as synced
      final mockBackendIds = unsyncedTransactions
          .map((tx) => 'tx_backend_${DateTime.now().millisecondsSinceEpoch}')
          .toList();

      // Mark as synced
      await IsarDatabaseService.markTransactionsAsSynced(mockBackendIds);

      // Verify
      final stillUnsynced = await IsarDatabaseService.getUnsyncedTransactions();
      print('Transactions now synced. Remaining unsynced: ${stillUnsynced.length}');
    }
  }

  /// Helper to encode order items as JSON string
  static String _encodeOrderItems(List<Map<String, dynamic>> items) {
    return items.toString();
  }
}

/// Example: Sync from Backend (receiving data)
///
/// Demonstrates receiving product catalog from backend and syncing to Isar
class SyncFromBackendExample {
  /// Example: Sync product catalog from backend
  static Future<void> syncProductCatalogExample() async {
    // Step 1: Simulate receiving product catalog from backend API
    final backendCatalog = [
      {
        '\$id': 'prod_100',
        'name': 'Espresso',
        'price': 2.50,
        'categoryId': 'cat_coffee',
        'categoryName': 'Coffee',
        'quantity': 100.0,
        'isActive': true,
      },
      {
        '\$id': 'prod_101',
        'name': 'Cappuccino',
        'price': 3.50,
        'categoryId': 'cat_coffee',
        'categoryName': 'Coffee',
        'quantity': 80.0,
        'isActive': true,
      },
      {
        '\$id': 'prod_102',
        'name': 'Croissant',
        'price': 4.00,
        'categoryId': 'cat_pastries',
        'categoryName': 'Pastries',
        'quantity': 50.0,
        'isActive': true,
      },
    ];

    print('Syncing ${backendCatalog.length} products from backend...');

    // Step 2: Sync using helper (handles insert/update logic)
    await IsarDatabaseService.syncProductsFromBackend(backendCatalog);

    print('Sync complete!');

    // Step 3: Query and verify
    final coffeeProducts =
        await IsarDatabaseService.getProductsByCategory('cat_coffee');
    print('\nCoffee products in Isar:');
    for (final p in coffeeProducts) {
      print('  - ${p.name}: \$${p.price} (Stock: ${p.quantity})');
    }

    // Step 4: Check sync status (all should be synced)
    final unsyncedProducts =
        await IsarDatabaseService.getUnsyncedProducts();
    print('\nUnsynced products: ${unsyncedProducts.length}');
  }
}

/// Full End-to-End Example: Offline-First Workflow
///
/// 1. App starts offline → loads cached products from Isar
/// 2. User creates transaction → saved to Isar (unsynced)
/// 3. App comes online → syncs pending transactions to backend
/// 4. Backend syncs new products → app updates local cache
class OfflineFirstWorkflowExample {
  static Future<void> runFullWorkflow() async {
    print('========== OFFLINE-FIRST WORKFLOW DEMO ==========\n');

    // Phase 1: App startup (offline)
    print('Phase 1: App startup (offline)');
    print('Loading cached products from Isar...');
    var allProducts = await IsarDatabaseService.getAllProducts();
    print('  - Found ${allProducts.length} cached products');

    // Phase 2: User creates transaction while offline
    print('\nPhase 2: User creates transaction (offline)');
    final newTx = IsarTransaction(
      backendId: '', // Will get ID when synced
      transactionNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      transactionDate: DateTime.now().millisecondsSinceEpoch,
      userId: 'user_1',
      subtotal: 50.0,
      taxAmount: 5.0,
      totalAmount: 55.0,
      paymentMethod: 'cash',
      businessMode: 'cafe',
      orderNumber: 5,
      itemsJson: '[]',
      isSynced: false, // Not synced yet
    );

    await IsarDatabaseService.saveTransaction(newTx);
    print('  - Transaction created and saved (offline)');
    print('  - isSynced: false');

    // Phase 3: App comes online, prepare to sync
    print('\nPhase 3: App comes online, syncing...');
    final unsynced = await IsarDatabaseService.exportUnsyncedTransactions();
    print('  - Found ${unsynced.length} unsynced transaction(s)');
    print('  - Pushing to backend...');

    // Simulate backend push
    // await backendApi.pushTransactions(unsynced);
    print('  - Backend accepted transactions');

    // Mark as synced
    // In real app, use IDs from backend response
    // For now, mark using transaction numbers from the unsynced list
    if (unsynced.isNotEmpty) {
      // Simulate backend returning IDs for synced transactions
      print('  - Marking transactions as synced');
    }

    // Phase 4: Backend syncs new product data
    print('\nPhase 4: Backend pushes catalog updates');
    final newCatalog = [
      {
        '\$id': 'prod_new_1',
        'name': 'New Latte',
        'price': 4.50,
        'categoryId': 'cat_coffee',
        'quantity': 75.0,
        'isActive': true,
      },
    ];

    await IsarDatabaseService.syncProductsFromBackend(newCatalog);
    print('  - Synced ${newCatalog.length} new product(s)');

    // Phase 5: Verify final state
    print('\nPhase 5: Final verification');
    allProducts = await IsarDatabaseService.getAllProducts();
    final stats = await IsarDatabaseService.getStatistics();
    print('  - Total products: ${stats['products']['total']}');
    print('  - Unsynced products: ${stats['products']['unsynced']}');
    print('  - Total transactions: ${stats['transactions']['total']}');
    print('  - Unsynced transactions: ${stats['transactions']['unsynced']}');

    print('\n========== WORKFLOW COMPLETE ==========');
  }
}
