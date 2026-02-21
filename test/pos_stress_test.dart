/// POS App Stress Test - Automated Testing with Sales Data Recording
/// 
/// This test suite performs comprehensive stress testing on the POS system:
/// - Rapid transaction processing
/// - Concurrent operations
/// - Data integrity under load
/// - Sales data recording
/// - Performance metrics
library;

import 'dart:io';
import 'dart:math';

import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/cart_service.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/services/training_mode_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Model to record transaction data
class RecordedTransaction {
  final String transactionId;
  final DateTime timestamp;
  final List<CartItem> items;
  final double totalAmount;
  final double taxAmount;
  final String paymentMethod;
  final bool success;
  final String? errorMessage;
  final Duration processingTime;

  RecordedTransaction({
    required this.transactionId,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    required this.taxAmount,
    required this.paymentMethod,
    required this.success,
    this.errorMessage,
    required this.processingTime,
  });

  @override
  String toString() => '''
Transaction #$transactionId
├─ Time: $timestamp
├─ Items: ${items.length} item(s) (${items.fold(0, (sum, item) => sum + item.quantity)} total)
├─ Subtotal: RM${(totalAmount - taxAmount).toStringAsFixed(2)}
├─ Tax: RM${taxAmount.toStringAsFixed(2)}
├─ Total: RM${totalAmount.toStringAsFixed(2)}
├─ Payment: $paymentMethod
├─ Status: ${success ? '✓ Success' : '✗ Failed'}
├─ Processing Time: ${processingTime.inMilliseconds}ms
${errorMessage != null ? '└─ Error: $errorMessage' : ''}
''';
}

/// Stress test statistics
class StressTestStats {
  int totalTransactions = 0;
  int successfulTransactions = 0;
  int failedTransactions = 0;
  double totalRevenue = 0.0;
  double totalTax = 0.0;
  int totalItemsSold = 0;
  Duration totalProcessingTime = Duration.zero;
  Duration fastestTransaction = Duration(hours: 24);
  Duration slowestTransaction = Duration.zero;
  List<Exception> errors = [];

  double get successRate => totalTransactions > 0 
      ? (successfulTransactions / totalTransactions) * 100 
      : 0.0;

  double get averageProcessingTime => totalTransactions > 0
      ? totalProcessingTime.inMilliseconds / totalTransactions
      : 0.0;

  double get averageTransactionValue => successfulTransactions > 0
      ? totalRevenue / successfulTransactions
      : 0.0;

  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('        POS APP STRESS TEST REPORT');
    buffer.writeln('═══════════════════════════════════════════════════════');
    buffer.writeln('');
    buffer.writeln('TEST EXECUTION SUMMARY');
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('Total Transactions:         $totalTransactions');
    buffer.writeln('Successful Transactions:    $successfulTransactions');
    buffer.writeln('Failed Transactions:        $failedTransactions');
    buffer.writeln('Success Rate:               ${successRate.toStringAsFixed(2)}%');
    buffer.writeln('');
    buffer.writeln('REVENUE METRICS');
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('Total Revenue:              RM${totalRevenue.toStringAsFixed(2)}');
    buffer.writeln('Total Tax Collected:        RM${totalTax.toStringAsFixed(2)}');
    buffer.writeln('Average Transaction Value:  RM${averageTransactionValue.toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('SALES VOLUME');
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('Total Items Sold:           $totalItemsSold units');
    buffer.writeln('Average Items per Order:    ${(totalItemsSold / max(totalTransactions, 1)).toStringAsFixed(2)}');
    buffer.writeln('');
    buffer.writeln('PERFORMANCE METRICS');
    buffer.writeln('─────────────────────────────────────────────────────');
    buffer.writeln('Average Processing Time:    ${averageProcessingTime.toStringAsFixed(2)}ms');
    buffer.writeln('Fastest Transaction:        ${fastestTransaction.inMilliseconds}ms');
    buffer.writeln('Slowest Transaction:        ${slowestTransaction.inMilliseconds}ms');
    buffer.writeln('Total Processing Time:      ${totalProcessingTime.inSeconds}s');
    buffer.writeln('');
    
    if (errors.isNotEmpty) {
      buffer.writeln('ERRORS ENCOUNTERED (${errors.length})');
      buffer.writeln('─────────────────────────────────────────────────────');
      for (int i = 0; i < errors.length && i < 10; i++) {
        buffer.writeln('${i + 1}. ${errors[i]}');
      }
      if (errors.length > 10) {
        buffer.writeln('... and ${errors.length - 10} more errors');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('═══════════════════════════════════════════════════════');
    
    return buffer.toString();
  }
}

void main() {
  // Initialize sqflite FFI for tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Mock SharedPreferences
  SharedPreferences.setMockInitialValues({});

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;
  late List<Product> testProducts;
  final stats = StressTestStats();
  final recordedTransactions = <RecordedTransaction>[];

  setUpAll(() async {
    // Create temporary test database
    testDir = await Directory.systemTemp.createTemp('extropos_stress_test_');
    final dbFile = p.join(testDir.path, 'extropos_stress.db');
    DatabaseHelper.overrideDatabaseFilePath(dbFile);
    await DatabaseHelper.instance.resetDatabase();

    // Insert test products for stress testing
    final productNames = [
      'Coffee',
      'Espresso',
      'Latte',
      'Cappuccino',
      'Americano',
      'Croissant',
      'Muffin',
      'Sandwich',
      'Donut',
      'Juice',
    ];

    testProducts = [];
    for (int i = 0; i < productNames.length; i++) {
      final item = Item(
        id: 'product-$i',
        name: productNames[i],
        description: 'Test product ${productNames[i]}',
        price: (i + 1) * 5.0,
        categoryId: 'test-category',
        icon: Icons.shopping_cart,
        color: Colors.blue,
      );
      await DatabaseService.instance.insertItem(item);
      testProducts.add(Product(
        productNames[i],
        (i + 1) * 5.0,
        'Test Category',
        Icons.shopping_cart,
      ));
    }

    print('✓ Setup complete: ${testProducts.length} products loaded');
  });

  tearDownAll(() async {
    // Cleanup with retry
    try {
      // Close database connection
      await DatabaseHelper.instance.database;
      await Future.delayed(Duration(milliseconds: 500));
      
      // Try to delete with retry
      for (int i = 0; i < 3; i++) {
        try {
          await testDir.delete(recursive: true);
          break;
        } catch (e) {
          if (i < 2) {
            await Future.delayed(Duration(milliseconds: 500));
          }
        }
      }
    } catch (e) {
      print('Warning: Cleanup had issues: $e');
    }
    print('✓ Cleanup complete');
  });

  setUp(() {
    PaymentService.instance.forceCardSuccess = true;
    TrainingModeService.instance.toggleTrainingMode(true);
  });

  tearDown(() {
    TrainingModeService.instance.toggleTrainingMode(false);
  });

  group('POS Stress Test Suite', () {
    test('STRESS: Rapid sequential transactions (50 orders)', () async {
      print('\n📊 Starting rapid sequential transaction test...');
      print('Target: 50 transactions in rapid succession');
      print('');

      final random = Random();

      for (int tx = 0; tx < 50; tx++) {
        final stopwatch = Stopwatch()..start();
        final cartService = CartService();

        try {
          // Simulate random cart with 1-5 items
          final itemCount = random.nextInt(5) + 1;
          double subtotal = 0.0;

          for (int i = 0; i < itemCount; i++) {
            final product = testProducts[random.nextInt(testProducts.length)];
            final quantity = random.nextInt(3) + 1;
            cartService.addProduct(product, quantity: quantity);
            subtotal += product.price * quantity;
          }

          // Simulate tax (10%)
          final tax = subtotal * 0.1;
          final total = subtotal + tax;

          // Process payment
          final paymentMethods = ['Cash', 'Card', 'E-Wallet'];
          final method = paymentMethods[random.nextInt(paymentMethods.length)];

          final result = await PaymentService.instance.processCashPayment(
            totalAmount: total,
            amountPaid: total + random.nextDouble() * 10,
            cartItems: cartService.items,
          );

          stopwatch.stop();

          final transaction = RecordedTransaction(
            transactionId: '${tx + 1}',
            timestamp: DateTime.now(),
            items: cartService.items,
            totalAmount: total,
            taxAmount: tax,
            paymentMethod: method,
            success: result.success,
            errorMessage: result.errorMessage,
            processingTime: stopwatch.elapsed,
          );

          recordedTransactions.add(transaction);

          if (result.success) {
            stats.successfulTransactions++;
            stats.totalRevenue += total;
            stats.totalTax += tax;
            stats.totalItemsSold += cartService.items.fold(
              0,
              (sum, item) => sum + item.quantity,
            );
          } else {
            stats.failedTransactions++;
            if (result.errorMessage != null) {
              stats.errors.add(Exception(result.errorMessage!));
            }
          }

          // Update timing stats
          if (stopwatch.elapsed < stats.fastestTransaction) {
            stats.fastestTransaction = stopwatch.elapsed;
          }
          if (stopwatch.elapsed > stats.slowestTransaction) {
            stats.slowestTransaction = stopwatch.elapsed;
          }
          stats.totalProcessingTime += stopwatch.elapsed;

          // Progress indicator
          if ((tx + 1) % 10 == 0) {
            print('  ✓ Completed ${tx + 1}/50 transactions');
          }
        } catch (e) {
          stats.failedTransactions++;
          stats.errors.add(e as Exception);
          print('  ✗ Transaction ${tx + 1} failed: $e');
        }
      }

      stats.totalTransactions = 50;

      // Print transaction sample
      print('\n📋 Sample Transactions (First 5):');
      for (int i = 0; i < min(5, recordedTransactions.length); i++) {
        print(recordedTransactions[i].toString());
      }

      expect(stats.successfulTransactions, greaterThan(40));
      expect(stats.totalRevenue, greaterThan(0.0));
      print('\n✓ Test passed: ${stats.successRate.toStringAsFixed(2)}% success rate');
    });

    test('STRESS: Concurrent transactions (10 parallel)', () async {
      print('\n📊 Starting concurrent transaction test...');
      print('Target: 10 transactions running in parallel');
      print('');

      final random = Random();
      final futures = <Future<void>>[];

      final stopwatch = Stopwatch()..start();

      for (int tx = 0; tx < 10; tx++) {
        final txNum = tx + 51; // Continue from previous test
        futures.add(
          Future(() async {
            try {
              final cartService = CartService();

              // Simulate random cart
              final itemCount = random.nextInt(4) + 1;
              double subtotal = 0.0;

              for (int i = 0; i < itemCount; i++) {
                final product =
                    testProducts[random.nextInt(testProducts.length)];
                final quantity = random.nextInt(2) + 1;
                cartService.addProduct(product, quantity: quantity);
                subtotal += product.price * quantity;
              }

              final tax = subtotal * 0.1;
              final total = subtotal + tax;

              final txStopwatch = Stopwatch()..start();

              final result = await PaymentService.instance.processCashPayment(
                totalAmount: total,
                amountPaid: total + 5.0,
                cartItems: cartService.items,
              );

              txStopwatch.stop();

              if (result.success) {
                stats.successfulTransactions++;
                stats.totalRevenue += total;
                stats.totalTax += tax;
                stats.totalItemsSold += cartService.items.fold(
                  0,
                  (sum, item) => sum + item.quantity,
                );
              } else {
                stats.failedTransactions++;
              }

              recordedTransactions.add(
                RecordedTransaction(
                  transactionId: '$txNum',
                  timestamp: DateTime.now(),
                  items: cartService.items,
                  totalAmount: total,
                  taxAmount: tax,
                  paymentMethod: 'Card',
                  success: result.success,
                  errorMessage: result.errorMessage,
                  processingTime: txStopwatch.elapsed,
                ),
              );
            } catch (e) {
              stats.failedTransactions++;
              stats.errors.add(e as Exception);
            }
          }),
        );
      }

      await Future.wait(futures);
      stopwatch.stop();

      stats.totalTransactions += 10;

      print('✓ All 10 concurrent transactions completed');
      print('  Total concurrent execution time: ${stopwatch.elapsed.inMilliseconds}ms');
      expect(stats.failedTransactions, lessThan(3));
      print('✓ Test passed: Concurrent operations stable');
    });

    test('STRESS: High-volume rapid-fire (100 transactions)', () async {
      print('\n📊 Starting high-volume rapid-fire test...');
      print('Target: 100 transactions with minimal delay');
      print('');

      final random = Random();

      for (int tx = 0; tx < 100; tx++) {
        final cartService = CartService();

        try {
          // Quick random items
          for (int i = 0; i < random.nextInt(3) + 1; i++) {
            final product = testProducts[random.nextInt(testProducts.length)];
            cartService.addProduct(product, quantity: 1);
          }

          final subtotal = cartService.getSubtotal();
          final tax = subtotal * 0.1;
          final total = subtotal + tax;

          final result = await PaymentService.instance.processCashPayment(
            totalAmount: total,
            amountPaid: total,
            cartItems: cartService.items,
          );

          if (result.success) {
            stats.successfulTransactions++;
            stats.totalRevenue += total;
            stats.totalTax += tax;
            stats.totalItemsSold += cartService.items.fold(
              0,
              (sum, item) => sum + item.quantity,
            );
          } else {
            stats.failedTransactions++;
          }

          stats.totalTransactions++;

          if ((tx + 1) % 25 == 0) {
            print('  ✓ Completed ${tx + 1}/100 transactions');
          }
        } catch (e) {
          stats.failedTransactions++;
          stats.errors.add(e as Exception);
        }
      }

      expect(stats.totalTransactions, 160); // 50 + 10 + 100
      expect(stats.successfulTransactions, greaterThan(150));
      print('\n✓ Test passed: Processed 100 rapid transactions');
    });

    test('DATA INTEGRITY: Cart operations under load', () async {
      print('\n🧪 Starting data integrity test...');
      print('Verifying cart consistency during stress conditions');
      print('');

      final cartService = CartService();
      
      // Add and manipulate items rapidly
      for (int i = 0; i < 50; i++) {
        final product = testProducts[i % testProducts.length];
        cartService.addProduct(product, quantity: 2);
      }

      expect(cartService.itemCount, greaterThan(0));
      expect(cartService.getSubtotal(), greaterThan(0.0));

      // Verify consistency
      final subtotalBefore = cartService.getSubtotal();
      cartService.incrementQuantity(0);
      final subtotalAfter = cartService.getSubtotal();
      expect(subtotalAfter, greaterThan(subtotalBefore));

      print('✓ Cart integrity verified under load');
    });

    test('FINAL: Generate Sales Report', () async {
      print('\n');
      print(stats.generateReport());
      
      // Save report to file
      final reportFile = File(
        p.join(testDir.path, 'stress_test_report.txt'),
      );
      await reportFile.writeAsString(stats.generateReport());
      print('\n📁 Report saved to: ${reportFile.path}');

      // Save detailed transactions
      final txFile = File(
        p.join(testDir.path, 'transactions.txt'),
      );
      final txBuffer = StringBuffer();
      txBuffer.writeln('DETAILED TRANSACTION LOG');
      txBuffer.writeln('═' * 60);
      txBuffer.writeln('Total Transactions: ${recordedTransactions.length}');
      txBuffer.writeln('');
      for (final tx in recordedTransactions) {
        txBuffer.writeln(tx.toString());
      }
      await txFile.writeAsString(txBuffer.toString());
      print('📁 Transaction log saved to: ${txFile.path}');

      expect(stats.totalTransactions, equals(160));
      expect(stats.successRate, greaterThan(90.0));
    });
  });
}
