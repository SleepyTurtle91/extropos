import 'dart:math';

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/database_helper.dart';

/// Generates realistic sales data for testing the Modern Reports Dashboard
class ReportsTestDataGenerator {
  static final ReportsTestDataGenerator instance =
      ReportsTestDataGenerator._init();
  ReportsTestDataGenerator._init();

  final _random = Random();

  /// Generate sample orders for the last 30 days
  Future<void> generateSalesData({
    int daysBack = 30,
    int ordersPerDay = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final businessInfo = BusinessInfo.instance;

    print(
      'Generating $ordersPerDay orders per day for the last $daysBack days...',
    );

    final now = DateTime.now();
    int totalOrders = 0;

    for (int day = 0; day < daysBack; day++) {
      final date = now.subtract(Duration(days: day));
      final ordersForDay = _random.nextInt(5) + ordersPerDay - 2; // Vary by ±2

      for (int i = 0; i < ordersForDay; i++) {
        final orderId = 'test_order_${date.millisecondsSinceEpoch}_$i';

        // Random time during business hours (9 AM - 9 PM)
        final hour = 9 + _random.nextInt(12);
        final minute = _random.nextInt(60);
        final orderDate = DateTime(
          date.year,
          date.month,
          date.day,
          hour,
          minute,
        );

        // Random order details
        final subtotal = 10.0 + _random.nextDouble() * 90.0; // $10-$100
        final tax = businessInfo.isTaxEnabled
            ? subtotal * businessInfo.taxRate
            : 0.0;
        final serviceCharge = businessInfo.isServiceChargeEnabled
            ? subtotal * businessInfo.serviceChargeRate
            : 0.0;
        final discount = _random.nextDouble() < 0.2
            ? subtotal * 0.1
            : 0.0; // 20% chance of 10% discount
        final total = subtotal + tax + serviceCharge - discount;

        // Random order type and payment method
        final orderTypes = ['retail', 'cafe', 'restaurant'];
        final orderType = orderTypes[_random.nextInt(orderTypes.length)];

        final paymentMethods = ['Cash', 'Card', 'E-Wallet'];
        final paymentMethod =
            paymentMethods[_random.nextInt(paymentMethods.length)];

        final statuses = [
          'completed',
          'completed',
          'completed',
          'cancelled',
        ]; // 75% completed
        final status = statuses[_random.nextInt(statuses.length)];

        // Insert order
        await db.insert('orders', {
          'id': orderId,
          'order_number': 'ORD-${totalOrders + 1}',
          'order_type': orderType,
          'status': status,
          'subtotal': subtotal,
          'tax': tax,
          'service_charge': serviceCharge,
          'discount': discount,
          'total': total,
          'payment_method': paymentMethod,
          'created_at': orderDate.toIso8601String(),
          'updated_at': orderDate.toIso8601String(),
          'table_id': orderType == 'restaurant'
              ? 'table_${_random.nextInt(10) + 1}'
              : null,
          'calling_number': orderType == 'cafe' ? totalOrders + 1 : null,
        });

        // Generate 1-5 order items per order
        final itemCount = 1 + _random.nextInt(5);
        for (int j = 0; j < itemCount; j++) {
          final products = _getSampleProducts();
          final product = products[_random.nextInt(products.length)];
          final quantity = 1 + _random.nextInt(3);
          final itemPrice = product['price'] as double;
          final itemSubtotal = itemPrice * quantity;

          await db.insert('order_items', {
            'id': 'test_item_${orderId}_$j',
            'order_id': orderId,
            'item_id': product['id'],
            'item_name': product['name'],
            'category_id': product['category_id'],
            'category_name': product['category_name'],
            'quantity': quantity,
            'price': itemPrice,
            'subtotal': itemSubtotal,
            'created_at': orderDate.toIso8601String(),
          });
        }

        totalOrders++;
      }

      if (day % 5 == 0) {
        print('Generated orders for ${day + 1}/$daysBack days...');
      }
    }

    print('✅ Successfully generated $totalOrders orders!');
    print('📊 Data distribution:');
    print('   • Date range: ${now.subtract(Duration(days: daysBack))} to $now');
    print('   • Orders per day: ~$ordersPerDay (varies ±2)');
    print('   • Total orders: $totalOrders');
    print('   • ~75% completed, ~25% cancelled');
    print('   • Payment methods: Cash, Card, E-Wallet (equal distribution)');
    print('   • Order types: Retail, Cafe, Restaurant (equal distribution)');
  }

  /// Clear all test data
  Future<void> clearTestData() async {
    final db = await DatabaseHelper.instance.database;

    print('Clearing test data...');

    // Delete test orders and their items
    await db.delete(
      'order_items',
      where: 'id LIKE ?',
      whereArgs: ['test_item_%'],
    );
    await db.delete('orders', where: 'id LIKE ?', whereArgs: ['test_order_%']);

    print('✅ Test data cleared!');
  }

  /// Get sales summary for verification
  Future<void> printSalesSummary() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_orders,
        COALESCE(SUM(total), 0) as total_revenue,
        COALESCE(AVG(total), 0) as avg_order_value,
        COALESCE(SUM(tax), 0) as total_tax,
        COALESCE(SUM(discount), 0) as total_discount
      FROM orders
      WHERE status = 'completed'
    ''');

    final summary = result.first;
    print('📊 Sales Summary:');
    print('   • Total Orders: ${summary['total_orders']}');
    print(
      '   • Total Revenue: \$${(summary['total_revenue'] as double).toStringAsFixed(2)}',
    );
    print(
      '   • Average Order: \$${(summary['avg_order_value'] as double).toStringAsFixed(2)}',
    );
    print(
      '   • Total Tax: \$${(summary['total_tax'] as double).toStringAsFixed(2)}',
    );
    print(
      '   • Total Discounts: \$${(summary['total_discount'] as double).toStringAsFixed(2)}',
    );
  }

  List<Map<String, dynamic>> _getSampleProducts() {
    return [
      // Beverages
      {
        'id': 'prod_coffee',
        'name': 'Coffee',
        'category_id': 'cat_beverages',
        'category_name': 'Beverages',
        'price': 4.50,
      },
      {
        'id': 'prod_tea',
        'name': 'Tea',
        'category_id': 'cat_beverages',
        'category_name': 'Beverages',
        'price': 3.50,
      },
      {
        'id': 'prod_juice',
        'name': 'Fresh Juice',
        'category_id': 'cat_beverages',
        'category_name': 'Beverages',
        'price': 5.00,
      },
      {
        'id': 'prod_smoothie',
        'name': 'Smoothie',
        'category_id': 'cat_beverages',
        'category_name': 'Beverages',
        'price': 6.50,
      },

      // Food
      {
        'id': 'prod_burger',
        'name': 'Burger',
        'category_id': 'cat_food',
        'category_name': 'Food',
        'price': 12.00,
      },
      {
        'id': 'prod_sandwich',
        'name': 'Sandwich',
        'category_id': 'cat_food',
        'category_name': 'Food',
        'price': 8.50,
      },
      {
        'id': 'prod_salad',
        'name': 'Salad Bowl',
        'category_id': 'cat_food',
        'category_name': 'Food',
        'price': 9.00,
      },
      {
        'id': 'prod_pasta',
        'name': 'Pasta',
        'category_id': 'cat_food',
        'category_name': 'Food',
        'price': 14.00,
      },

      // Desserts
      {
        'id': 'prod_cake',
        'name': 'Chocolate Cake',
        'category_id': 'cat_desserts',
        'category_name': 'Desserts',
        'price': 6.50,
      },
      {
        'id': 'prod_cheesecake',
        'name': 'Cheesecake',
        'category_id': 'cat_desserts',
        'category_name': 'Desserts',
        'price': 7.00,
      },
      {
        'id': 'prod_cookie',
        'name': 'Cookie',
        'category_id': 'cat_desserts',
        'category_name': 'Desserts',
        'price': 2.50,
      },
      {
        'id': 'prod_icecream',
        'name': 'Ice Cream',
        'category_id': 'cat_desserts',
        'category_name': 'Desserts',
        'price': 4.00,
      },
    ];
  }
}
