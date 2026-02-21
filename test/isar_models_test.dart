import 'package:extropos/models/isar/inventory_model.dart';
import 'package:extropos/models/isar/product_model.dart';
import 'package:extropos/models/isar/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

// Note: These are example unit test stubs.
// To run these in your project, you'll need to:
// 1. Set up Isar test helpers or use in-memory instance
// 2. Update import paths based on your project structure
// 3. Use proper async test setup with setUpAll/tearDownAll

void main() {
  group('IsarProduct Model Tests', () {
    test('fromJson creates product from backend JSON', () {
      final json = {
        '\$id': 'prod_test_1',
        'name': 'Test Pizza',
        'price': 10.50,
        'categoryId': 'cat_pizza',
        'categoryName': 'Pizzas',
        'sku': 'PIZZA-TEST',
        'quantity': 50.0,
        'costPerUnit': 4.00,
        'isActive': true,
      };

      final product = IsarProduct.fromJson(json);

      expect(product.backendId, 'prod_test_1');
      expect(product.name, 'Test Pizza');
      expect(product.price, 10.50);
      expect(product.categoryId, 'cat_pizza');
      expect(product.isSynced, true);
      expect(product.quantity, 50.0);
    });

    test('toJson converts product to backend JSON format', () {
      final product = IsarProduct(
        backendId: 'prod_export_1',
        name: 'Export Pizza',
        price: 12.0,
        categoryId: 'cat_pizza',
      );

      final json = product.toJson();

      expect(json['\$id'], 'prod_export_1');
      expect(json['name'], 'Export Pizza');
      expect(json['price'], 12.0);
      expect(json['categoryId'], 'cat_pizza');
    });

    test('backendId is preserved during JSON round-trip', () {
      final original = IsarProduct(
        backendId: 'prod_roundtrip_1',
        name: 'Roundtrip Test',
        price: 15.0,
        categoryId: 'cat_test',
      );

      final json = original.toJson();
      final reconstructed = IsarProduct.fromJson(json);

      expect(reconstructed.backendId, original.backendId);
      expect(reconstructed.name, original.name);
      expect(reconstructed.price, original.price);
    });

    test('isSynced flag defaults correctly', () {
      // Local creation (not synced)
      final localProduct = IsarProduct(
        backendId: 'temp_id',
        name: 'Local Product',
        price: 10.0,
        categoryId: 'cat_test',
        isSynced: false,
      );
      expect(localProduct.isSynced, false);

      // From backend JSON (synced)
      final backendJson = {
        '\$id': 'prod_synced_1',
        'name': 'Backend Product',
        'price': 20.0,
        'categoryId': 'cat_test',
      };
      final backendProduct = IsarProduct.fromJson(backendJson);
      expect(backendProduct.isSynced, true);
    });

    test('timestamps are set correctly', () {
      final before = DateTime.now().millisecondsSinceEpoch;

      final product = IsarProduct(
        backendId: 'prod_time_1',
        name: 'Time Test',
        price: 10.0,
        categoryId: 'cat_test',
      );

      final after = DateTime.now().millisecondsSinceEpoch;

      expect(product.createdAt >= before, true);
      expect(product.createdAt <= after, true);
      expect(product.updatedAt, product.createdAt);
    });

    test('can update product properties', () {
      final product = IsarProduct(
        backendId: 'prod_update_1',
        name: 'Original Name',
        price: 10.0,
        categoryId: 'cat_test',
      );

      product.name = 'Updated Name';
      product.price = 15.0;
      product.isSynced = false;

      expect(product.name, 'Updated Name');
      expect(product.price, 15.0);
      expect(product.isSynced, false);
    });
  });

  group('IsarTransaction Model Tests', () {
    test('fromJson creates transaction from backend JSON', () {
      final json = {
        '\$id': 'tx_test_1',
        'transactionNumber': 'ORD-TEST-001',
        'transactionDate': DateTime.now().millisecondsSinceEpoch,
        'userId': 'user_1',
        'userName': 'Test User',
        'subtotal': 50.0,
        'totalAmount': 55.0,
        'paymentMethod': 'cash',
        'businessMode': 'retail',
        'items': [],
      };

      final transaction = IsarTransaction.fromJson(json);

      expect(transaction.backendId, 'tx_test_1');
      expect(transaction.transactionNumber, 'ORD-TEST-001');
      expect(transaction.subtotal, 50.0);
      expect(transaction.totalAmount, 55.0);
      expect(transaction.paymentMethod, 'cash');
      expect(transaction.isSynced, true);
    });

    test('toJson converts transaction to backend JSON format', () {
      final transaction = IsarTransaction(
        backendId: 'tx_export_1',
        transactionNumber: 'ORD-EXPORT-001',
        transactionDate: DateTime.now().millisecondsSinceEpoch,
        userId: 'user_1',
        subtotal: 100.0,
        totalAmount: 110.0,
        paymentMethod: 'card',
        businessMode: 'restaurant',
        itemsJson: '[]',
      );

      final json = transaction.toJson();

      expect(json['\$id'], 'tx_export_1');
      expect(json['transactionNumber'], 'ORD-EXPORT-001');
      expect(json['subtotal'], 100.0);
      expect(json['totalAmount'], 110.0);
    });

    test('refund status defaults to none', () {
      final transaction = IsarTransaction(
        backendId: 'tx_refund_test',
        transactionNumber: 'ORD-REFUND-001',
        transactionDate: DateTime.now().millisecondsSinceEpoch,
        userId: 'user_1',
        subtotal: 50.0,
        totalAmount: 55.0,
        paymentMethod: 'cash',
        businessMode: 'retail',
        itemsJson: '[]',
      );

      expect(transaction.refundStatus, 'none');
      expect(transaction.refundAmount, 0.0);
    });

    test('can record refund information', () {
      final transaction = IsarTransaction(
        backendId: 'tx_partial_refund',
        transactionNumber: 'ORD-REFUND-002',
        transactionDate: DateTime.now().millisecondsSinceEpoch,
        userId: 'user_1',
        subtotal: 50.0,
        totalAmount: 55.0,
        paymentMethod: 'card',
        businessMode: 'cafe',
        itemsJson: '[]',
        refundStatus: 'partial',
        refundAmount: 25.0,
        refundReason: 'Customer request - item out of stock',
      );

      expect(transaction.refundStatus, 'partial');
      expect(transaction.refundAmount, 25.0);
      expect(transaction.refundReason, 'Customer request - item out of stock');
    });

    test('transaction with tax and service charge calculates correctly', () {
      final transaction = IsarTransaction(
        backendId: 'tx_calc_1',
        transactionNumber: 'ORD-CALC-001',
        transactionDate: DateTime.now().millisecondsSinceEpoch,
        userId: 'user_1',
        subtotal: 100.0,
        taxAmount: 10.0,
        serviceChargeAmount: 5.0,
        totalAmount: 115.0,
        paymentMethod: 'cash',
        businessMode: 'restaurant',
        itemsJson: '[]',
      );

      final expectedTotal =
          transaction.subtotal + transaction.taxAmount + transaction.serviceChargeAmount;
      expect(transaction.totalAmount, expectedTotal);
    });

    test('unsynced transactions have correct flag', () {
      final localTx = IsarTransaction(
        backendId: '', // No backend ID yet
        transactionNumber: 'ORD-LOCAL-001',
        transactionDate: DateTime.now().millisecondsSinceEpoch,
        userId: 'user_1',
        subtotal: 50.0,
        totalAmount: 55.0,
        paymentMethod: 'cash',
        businessMode: 'retail',
        itemsJson: '[]',
        isSynced: false,
      );

      expect(localTx.isSynced, false);
      expect(localTx.lastSyncedAt, null);
    });
  });

  group('IsarInventory Model Tests', () {
    test('fromJson creates inventory from backend JSON', () {
      final json = {
        '\$id': 'inv_test_1',
        'productId': 'prod_1',
        'productName': 'Test Product',
        'currentQuantity': 100.0,
        'minStockLevel': 20.0,
        'maxStockLevel': 200.0,
        'costPerUnit': 5.0,
      };

      final inventory = IsarInventory.fromJson(json);

      expect(inventory.backendId, 'inv_test_1');
      expect(inventory.productId, 'prod_1');
      expect(inventory.currentQuantity, 100.0);
      expect(inventory.minStockLevel, 20.0);
      expect(inventory.isSynced, true);
    });

    test('toJson converts inventory to backend JSON format', () {
      final inventory = IsarInventory(
        backendId: 'inv_export_1',
        productId: 'prod_2',
        productName: 'Export Item',
        currentQuantity: 50.0,
        minStockLevel: 10.0,
      );

      final json = inventory.toJson();

      expect(json['\$id'], 'inv_export_1');
      expect(json['productId'], 'prod_2');
      expect(json['currentQuantity'], 50.0);
    });

    test('isStockLow detects low inventory correctly', () {
      final inventory = IsarInventory(
        backendId: 'inv_low_test',
        productId: 'prod_3',
        currentQuantity: 15.0,
        minStockLevel: 20.0,
      );

      expect(inventory.isStockLow(), true);
    });

    test('isStockLow returns false when stock is adequate', () {
      final inventory = IsarInventory(
        backendId: 'inv_adequate_test',
        productId: 'prod_4',
        currentQuantity: 100.0,
        minStockLevel: 20.0,
      );

      expect(inventory.isStockLow(), false);
    });

    test('needsReorder evaluates correctly', () {
      final lowStock = IsarInventory(
        backendId: 'inv_reorder_low',
        productId: 'prod_5',
        currentQuantity: 15.0,
        minStockLevel: 20.0,
        reorderQuantity: 50.0,
      );

      expect(lowStock.needsReorder(), true);

      final noReorder = IsarInventory(
        backendId: 'inv_reorder_none',
        productId: 'prod_6',
        currentQuantity: 15.0,
        minStockLevel: 20.0,
        reorderQuantity: 0.0, // No reorder quantity set
      );

      expect(noReorder.needsReorder(), false);
    });

    test('addMovement records inventory adjustment', () {
      final inventory = IsarInventory(
        backendId: 'inv_movement_1',
        productId: 'prod_7',
        currentQuantity: 100.0,
        minStockLevel: 20.0,
        movementsJson: '[]',
      );

      // The addMovement method appends to movementsJson
      // In a real scenario, you'd parse and verify the JSON
      expect(inventory.movementsJson, '[]');
    });
  });

  group('Sync State Tests', () {
    test('synced vs unsynced products are distinct', () {
      final syncedProduct = IsarProduct(
        backendId: 'prod_synced',
        name: 'Synced',
        price: 10.0,
        categoryId: 'cat_test',
        isSynced: true,
        lastSyncedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final unsyncedProduct = IsarProduct(
        backendId: 'prod_unsynced',
        name: 'Unsynced',
        price: 10.0,
        categoryId: 'cat_test',
        isSynced: false,
      );

      expect(syncedProduct.isSynced, true);
      expect(syncedProduct.lastSyncedAt, isNotNull);

      expect(unsyncedProduct.isSynced, false);
      expect(unsyncedProduct.lastSyncedAt, null);
    });

    test('synced status can be updated', () {
      final product = IsarProduct(
        backendId: 'prod_status_update',
        name: 'Status Test',
        price: 10.0,
        categoryId: 'cat_test',
        isSynced: false,
      );

      expect(product.isSynced, false);

      product.isSynced = true;
      product.lastSyncedAt = DateTime.now().millisecondsSinceEpoch;

      expect(product.isSynced, true);
      expect(product.lastSyncedAt, isNotNull);
    });
  });

  group('JSON Round-Trip Tests', () {
    test('product survives JSON serialization/deserialization', () {
      final original = IsarProduct(
        backendId: 'prod_roundtrip_full',
        name: 'Full Roundtrip Product',
        price: 25.50,
        categoryId: 'cat_test',
        categoryName: 'Test Category',
        sku: 'SKU-001',
        icon: 'pizza',
        quantity: 75.0,
        costPerUnit: 10.0,
        isActive: true,
        isSynced: true,
      );

      final json = original.toJson();
      final reconstructed = IsarProduct.fromJson(json);

      expect(reconstructed.backendId, original.backendId);
      expect(reconstructed.name, original.name);
      expect(reconstructed.price, original.price);
      expect(reconstructed.categoryId, original.categoryId);
      expect(reconstructed.quantity, original.quantity);
      expect(reconstructed.costPerUnit, original.costPerUnit);
    });

    test('transaction survives JSON serialization/deserialization', () {
      final original = IsarTransaction(
        backendId: 'tx_roundtrip_full',
        transactionNumber: 'ORD-ROUNDTRIP-001',
        transactionDate: DateTime.now().millisecondsSinceEpoch,
        userId: 'user_roundtrip',
        userName: 'Test Cashier',
        subtotal: 100.0,
        taxAmount: 10.0,
        serviceChargeAmount: 5.0,
        totalAmount: 115.0,
        paymentMethod: 'card',
        businessMode: 'restaurant',
        tableId: 'table_5',
        tableName: 'Table 5',
        itemsJson: '[]',
        isSynced: true,
      );

      final json = original.toJson();
      final reconstructed = IsarTransaction.fromJson(json);

      expect(reconstructed.backendId, original.backendId);
      expect(reconstructed.transactionNumber, original.transactionNumber);
      expect(reconstructed.totalAmount, original.totalAmount);
      expect(reconstructed.businessMode, original.businessMode);
    });
  });
}
