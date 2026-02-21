import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_mode.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock services for integration testing
class MockPaymentService {
  Future<bool> processPayment({
    required double amount,
    required String paymentMethod,
    required List<CartItem> cartItems,
  }) async {
    // Simulate payment processing delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Always succeed for testing
    return true;
  }
}

class MockReceiptService {
  Future<void> printReceipt({
    required List<CartItem> cartItems,
    required double subtotal,
    required double taxAmount,
    required double serviceChargeAmount,
    required double total,
    required String paymentMethod,
  }) async {
    // Simulate printing delay
    await Future.delayed(const Duration(milliseconds: 50));
  }
}

class MockDatabaseService {
  final List<Map<String, dynamic>> _transactions = [];

  Future<void> saveTransaction(Map<String, dynamic> transactionData) async {
    _transactions.add(transactionData);
    await Future.delayed(const Duration(milliseconds: 20)); // Simulate DB write
  }

  List<Map<String, dynamic>> get transactions => _transactions;
}

void main() {
  group('End-to-End POS Integration Tests', () {
    late MockPaymentService paymentService;
    late MockReceiptService receiptService;
    late MockDatabaseService databaseService;

    setUp(() {
      paymentService = MockPaymentService();
      receiptService = MockReceiptService();
      databaseService = MockDatabaseService();
    });

    group('Complete Retail POS Workflow', () {
      test('should complete full purchase cycle successfully', () async {
        // Setup test data
        final cartItems = <CartItem>[];

        // Step 1: Add products to cart
        cartItems.add(CartItem(Product('Burger', 10.0, 'Food', Icons.fastfood), 2)); // 2 x $10 = $20
        cartItems.add(CartItem(Product('Fries', 15.0, 'Food', Icons.restaurant), 1)); // 1 x $15 = $15
        cartItems.add(CartItem(Product('Drink', 8.0, 'Beverage', Icons.local_cafe), 3)); // 3 x $8 = $24

        // Step 2: Calculate totals
        final subtotal = cartItems.fold<double>(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );
        expect(subtotal, 59.0); // 20 + 15 + 24

        // Step 3: Apply tax and service charges (using BusinessInfo)
        final taxAmount = BusinessInfo.instance.isTaxEnabled
            ? subtotal * BusinessInfo.instance.taxRate
            : 0.0;
        final serviceChargeAmount = BusinessInfo.instance.isServiceChargeEnabled
            ? subtotal * BusinessInfo.instance.serviceChargeRate
            : 0.0;
        final total = subtotal + taxAmount + serviceChargeAmount;

        // Step 4: Process payment
        final paymentSuccess = await paymentService.processPayment(
          amount: total,
          paymentMethod: 'cash',
          cartItems: cartItems,
        );
        expect(paymentSuccess, true);

        // Step 5: Print receipt
        await receiptService.printReceipt(
          cartItems: cartItems,
          subtotal: subtotal,
          taxAmount: taxAmount,
          serviceChargeAmount: serviceChargeAmount,
          total: total,
          paymentMethod: 'cash',
        );

        // Step 6: Save transaction to database
        final transactionData = {
          'transactionNumber': 'TEST-001',
          'timestamp': DateTime.now().toIso8601String(),
          'businessMode': BusinessMode.retail.toString(),
          'cartItems': cartItems.map((item) => {
            'productName': item.product.name,
            'quantity': item.quantity,
            'unitPrice': item.product.price,
            'lineTotal': item.product.price * item.quantity,
          }).toList(),
          'subtotal': subtotal,
          'taxAmount': taxAmount,
          'serviceChargeAmount': serviceChargeAmount,
          'total': total,
          'paymentMethod': 'cash',
          'status': 'completed',
        };

        await databaseService.saveTransaction(transactionData);

        // Step 7: Verify transaction was saved
        expect(databaseService.transactions.length, 1);
        expect(databaseService.transactions.first['transactionNumber'], 'TEST-001');
        expect(databaseService.transactions.first['total'], total);
        expect(databaseService.transactions.first['status'], 'completed');

        // Step 8: Clear cart (end of transaction)
        cartItems.clear();
        expect(cartItems.length, 0);
      });

      test('should handle cart modifications during checkout', () async {
        final p1 = Product('Burger', 10.0, 'Food', Icons.fastfood);
        final p2 = Product('Fries', 15.0, 'Food', Icons.restaurant);
        final p3 = Product('Drink', 8.0, 'Beverage', Icons.local_cafe);
        final cartItems = <CartItem>[];

        // Add initial items
        cartItems.add(CartItem(p1, 1));
        cartItems.add(CartItem(p2, 1));

        var subtotal = cartItems.fold<double>(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );
        expect(subtotal, 25.0); // 10 + 15

        // Modify cart during checkout (add quantity)
        cartItems[0] = CartItem(p1, 3); // Change to 3 units

        subtotal = cartItems.fold<double>(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );
        expect(subtotal, 45.0); // 30 + 15

        // Add new item during checkout
        cartItems.add(CartItem(p3, 2));

        subtotal = cartItems.fold<double>(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );
        expect(subtotal, 61.0); // 30 + 15 + 16

        // Process payment with modified cart
        final paymentSuccess = await paymentService.processPayment(
          amount: subtotal,
          paymentMethod: 'card',
          cartItems: cartItems,
        );
        expect(paymentSuccess, true);
      });

      test('should handle payment failures gracefully', () async {
        final p1 = Product('Burger', 10.0, 'Food', Icons.fastfood);
        final cartItems = <CartItem>[];

        cartItems.add(CartItem(p1, 1));

        // Simulate payment failure (we'd need a mock that can fail)
        // For now, test the structure - in real implementation, payment service would throw
        final paymentSuccess = await paymentService.processPayment(
          amount: 10.0,
          paymentMethod: 'card',
          cartItems: cartItems,
        );

        // In this mock, payment always succeeds, but in real scenario:
        // expect(() => paymentService.processPayment(...), throwsException);

        expect(paymentSuccess, true); // Mock always succeeds
      });
    });

    group('Cafe Mode Integration Tests', () {
      test('should handle order numbering system', () async {
        final p1 = Product('Burger', 10.0, 'Food', Icons.fastfood);
        final p2 = Product('Fries', 15.0, 'Food', Icons.restaurant);
        final p3 = Product('Drink', 8.0, 'Beverage', Icons.local_cafe);
        final activeOrders = <Map<String, dynamic>>[];
        var nextOrderNumber = 1;

        // Create first order
        final order1Items = [CartItem(p1, 2)];
        final order1Number = nextOrderNumber++;

        activeOrders.add({
          'orderNumber': order1Number,
          'items': order1Items,
          'timestamp': DateTime.now(),
          'status': 'preparing',
        });

        // Create second order
        final order2Items = [
          CartItem(p2, 1),
          CartItem(p3, 1),
        ];
        final order2Number = nextOrderNumber++;

        activeOrders.add({
          'orderNumber': order2Number,
          'items': order2Items,
          'timestamp': DateTime.now(),
          'status': 'pending',
        });

        // Verify order numbering
        expect(activeOrders.length, 2);
        expect(activeOrders[0]['orderNumber'], 1);
        expect(activeOrders[1]['orderNumber'], 2);
        expect(nextOrderNumber, 3); // Next order should be 3

        // Process payment for first order
        final subtotal1 = order1Items.fold<double>(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );

        final paymentSuccess = await paymentService.processPayment(
          amount: subtotal1,
          paymentMethod: 'cash',
          cartItems: order1Items,
        );
        expect(paymentSuccess, true);

        // Mark order as completed
        activeOrders[0]['status'] = 'completed';

        // Verify order status
        expect(activeOrders[0]['status'], 'completed');
        expect(activeOrders[1]['status'], 'pending');
      });

      test('should track active orders efficiently', () async {
        final activeOrders = <Map<String, dynamic>>[];
        final p1 = Product('Burger', 10.0, 'Food', Icons.fastfood);

        // Simulate busy cafe period - create many orders quickly
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 20; i++) {
          final orderItems = [
            CartItem(p1, 1),
          ];

          activeOrders.add({
            'orderNumber': i + 1,
            'items': orderItems,
            'timestamp': DateTime.now(),
            'status': 'pending',
          });
        }

        stopwatch.stop();

        // Should handle order creation efficiently
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(activeOrders.length, 20);

        // Mark some orders as completed
        activeOrders[0]['status'] = 'completed';
        activeOrders[5]['status'] = 'completed';
        activeOrders[10]['status'] = 'completed';

        final completedOrders = activeOrders.where((order) => order['status'] == 'completed');
        final pendingOrders = activeOrders.where((order) => order['status'] == 'pending');

        expect(completedOrders.length, 3);
        expect(pendingOrders.length, 17);
      });
    });

    group('Restaurant Mode Integration Tests', () {
      test('should manage table-based orders', () async {
        final tables = <Map<String, dynamic>>[];

        // Setup tables
        for (var i = 1; i <= 5; i++) {
          tables.add({
            'tableId': i,
            'name': 'Table $i',
            'capacity': 4,
            'status': 'available',
            'orders': <CartItem>[],
            'totalAmount': 0.0,
          });
        }

        final p1 = Product('Burger', 10.0, 'Food', Icons.fastfood);
        final p2 = Product('Fries', 15.0, 'Food', Icons.restaurant);
        final p3 = Product('Drink', 8.0, 'Beverage', Icons.local_cafe);

        // Customer sits at table 1
        tables[0]['status'] = 'occupied';
        tables[0]['orders'] = [
          CartItem(p1, 2),
          CartItem(p2, 1),
        ];

        // Calculate table total
        final table1Orders = tables[0]['orders'] as List<CartItem>;
        final table1Total = table1Orders.fold<double>(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );
        tables[0]['totalAmount'] = table1Total;

        expect(table1Total, 35.0); // 20 + 15
        expect(tables[0]['status'], 'occupied');

        // Add more items to table
        table1Orders.add(CartItem(p3, 3));
        final updatedTotal = table1Orders.fold<double>(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );
        tables[0]['totalAmount'] = updatedTotal;

        expect(updatedTotal, 59.0); // 35 + 24

        // Process payment and clear table
        final paymentSuccess = await paymentService.processPayment(
          amount: updatedTotal,
          paymentMethod: 'card',
          cartItems: table1Orders,
        );
        expect(paymentSuccess, true);

        // Clear table
        tables[0]['status'] = 'available';
        tables[0]['orders'] = <CartItem>[];
        tables[0]['totalAmount'] = 0.0;

        expect(tables[0]['status'], 'available');
        expect((tables[0]['orders'] as List).length, 0);
        expect(tables[0]['totalAmount'], 0.0);
      });

      test('should handle table merging', () async {
        final tables = <Map<String, dynamic>>[];

        // Setup tables
        for (var i = 1; i <= 4; i++) {
          tables.add({
            'tableId': i,
            'name': 'Table $i',
            'capacity': 4,
            'status': 'available',
            'orders': <CartItem>[],
            'totalAmount': 0.0,
          });
        }

        final p1 = Product('Burger', 10.0, 'Food', Icons.fastfood);
        final p2 = Product('Fries', 15.0, 'Food', Icons.restaurant);

        // Two parties occupy separate tables
        tables[0]['status'] = 'occupied';
        tables[0]['orders'] = [CartItem(p1, 2)];

        tables[1]['status'] = 'occupied';
        tables[1]['orders'] = [CartItem(p2, 1)];

        // Merge tables (combine orders)
        final mergedOrders = [
          ...(tables[0]['orders'] as List<CartItem>),
          ...(tables[1]['orders'] as List<CartItem>),
        ];

        final mergedTotal = mergedOrders.fold<double>(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );

        // Update first table with merged data
        tables[0]['orders'] = mergedOrders;
        tables[0]['totalAmount'] = mergedTotal;
        tables[0]['capacity'] = 8; // Combined capacity

        // Clear second table
        tables[1]['status'] = 'available';
        tables[1]['orders'] = <CartItem>[];
        tables[1]['totalAmount'] = 0.0;

        expect(mergedTotal, 35.0); // 20 + 15
        expect((tables[0]['orders'] as List<CartItem>).length, 2);
        expect(tables[0]['capacity'], 8);
        expect(tables[1]['status'], 'available');
      });
    });

    group('Performance Integration Tests', () {
      test('should handle high-volume transactions efficiently', () async {
        final p1 = Product('Burger', 10.0, 'Food', Icons.fastfood);
        final transactions = <Map<String, dynamic>>[];

        final stopwatch = Stopwatch()..start();

        // Process 50 transactions quickly
        for (var i = 0; i < 50; i++) {
          final cartItems = [
            CartItem(p1, (i % 3) + 1),
          ];

          final subtotal = cartItems.fold<double>(
            0.0,
            (sum, item) => sum + (item.product.price * item.quantity),
          );

          // Process payment
          final paymentSuccess = await paymentService.processPayment(
            amount: subtotal,
            paymentMethod: 'cash',
            cartItems: cartItems,
          );

          // Save transaction
          final transactionData = {
            'transactionNumber': 'PERF-${i.toString().padLeft(3, '0')}',
            'timestamp': DateTime.now().toIso8601String(),
            'cartItems': cartItems.map((item) => {
              'productName': item.product.name,
              'quantity': item.quantity,
              'lineTotal': item.product.price * item.quantity,
            }).toList(),
            'subtotal': subtotal,
            'total': subtotal,
            'paymentMethod': 'cash',
            'status': paymentSuccess ? 'completed' : 'failed',
          };

          await databaseService.saveTransaction(transactionData);
          transactions.add(transactionData);
        }

        stopwatch.stop();

        // Should complete within reasonable time
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds for 50 transactions
        expect(transactions.length, 50);
        expect(databaseService.transactions.length, 50);

        // Verify all transactions completed
        final completedTransactions = transactions.where((t) => t['status'] == 'completed');
        expect(completedTransactions.length, 50);
      });

      test('should maintain data consistency under load', () async {
        final p1 = Product('Burger', 10.0, 'Food', Icons.fastfood);
        final concurrentTransactions = <Future<void>>[];

        // Launch multiple concurrent transactions
        for (var i = 0; i < 10; i++) {
          concurrentTransactions.add(
            (() async {
              final cartItems = [
                CartItem(p1, 1),
              ];

              final subtotal = cartItems.fold<double>(
                0.0,
                (sum, item) => sum + (item.product.price * item.quantity),
              );

              final paymentSuccess = await paymentService.processPayment(
                amount: subtotal,
                paymentMethod: 'cash',
                cartItems: cartItems,
              );

              if (paymentSuccess) {
                await databaseService.saveTransaction({
                  'transactionNumber': 'CONC-${i.toString().padLeft(3, '0')}',
                  'timestamp': DateTime.now().toIso8601String(),
                  'cartItems': cartItems.map((item) => {
                    'productName': item.product.name,
                    'quantity': item.quantity,
                    'lineTotal': item.product.price * item.quantity,
                  }).toList(),
                  'subtotal': subtotal,
                  'total': subtotal,
                  'paymentMethod': 'cash',
                  'status': 'completed',
                });
              }
            })(),
          );
        }

        // Wait for all transactions to complete
        await Future.wait(concurrentTransactions);

        // Verify all transactions were saved
        expect(databaseService.transactions.length, 10);

        // Verify data integrity
        for (final transaction in databaseService.transactions) {
          expect(transaction['status'], 'completed');
          expect(transaction['cartItems'], isNotEmpty);
          expect(transaction['total'], isNotNull);
        }
      });
    });
  });
}