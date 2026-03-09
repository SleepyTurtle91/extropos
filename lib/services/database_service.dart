import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:extropos/features/auth/services/shift_service.dart';
import 'package:extropos/models/advanced_reports.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_display_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/merchant_model.dart';
import 'package:extropos/models/modifier_group_model.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/models/printer_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/receipt_settings_model.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/models/table_model.dart';
import 'package:extropos/models/user_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:extropos/services/error_handler.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/services/offline_sync_service.dart';
import 'package:extropos/services/pin_store.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

part 'database_service_parts/database_service_entities.dart';
part 'database_service_parts/database_service_infrastructure.dart';
part 'database_service_parts/database_service_products_categories.dart';
part 'database_service_parts/database_service_products_items.dart';
part 'database_service_parts/database_service_products.dart';
part 'database_service_parts/database_service_reports_advanced.dart';
part 'database_service_parts/database_service_reports_financial.dart';
part 'database_service_parts/database_service_reports_scheduled.dart';
part 'database_service_parts/database_service_sales.dart';

/// Service layer for database operations
/// Provides clean CRUD methods for all entities
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  DatabaseService._init();

  /// Get sales history for display in the Sales History screen
  /// Returns orders with transaction details, payment methods, and item counts
  Future<List<Map<String, dynamic>>> getSalesHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Build WHERE clause
    final whereConditions = <String>[];
    final whereArgs = <dynamic>[];

    // Only show completed orders
    whereConditions.add('o.status = ?');
    whereArgs.add('completed');

    // Date range filter
    if (startDate != null) {
      whereConditions.add('o.completed_at >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      // Add one day to include the end date fully
      final endDateNext = endDate.add(const Duration(days: 1));
      whereConditions.add('o.completed_at < ?');
      whereArgs.add(endDateNext.toIso8601String());
    }

    // Search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      whereConditions.add('''
        (LOWER(o.order_number) LIKE ? OR
         LOWER(o.customer_name) LIKE ? OR
         LOWER(o.customer_phone) LIKE ? OR
         LOWER(pm.name) LIKE ?)
      ''');
      final searchPattern = '%$searchLower%';
      whereArgs.addAll([searchPattern, searchPattern, searchPattern, searchPattern]);
    }

    final whereClause = whereConditions.isNotEmpty ? 'WHERE ${whereConditions.join(' AND ')}' : '';

    // Build query with JOINs to get payment method names and item counts
    final query = '''
      SELECT
        o.id,
        o.order_number,
        o.customer_name,
        o.customer_phone,
        o.customer_email,
        o.subtotal,
        o.tax,
        o.discount,
        o.total,
        o.completed_at as date,
        o.created_at,
        pm.name as payment_method,
        COUNT(oi.id) as items_count,
        o.status
      FROM orders o
      LEFT JOIN transactions t ON o.id = t.order_id
      LEFT JOIN payment_methods pm ON t.payment_method_id = pm.id
      LEFT JOIN order_items oi ON o.id = oi.order_id
      $whereClause
      GROUP BY o.id, o.order_number, o.customer_name, o.customer_phone, o.customer_email,
               o.subtotal, o.tax, o.discount, o.total, o.completed_at, o.created_at,
               pm.name, o.status
      ORDER BY o.completed_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''';

    final result = await db.rawQuery(query, whereArgs);

    // Convert date strings to DateTime objects
    return result.map((row) {
      final map = Map<String, dynamic>.from(row);
      if (map['date'] != null) {
        map['date'] = DateTime.parse(map['date'] as String);
      }
      if (map['created_at'] != null) {
        map['created_at'] = DateTime.parse(map['created_at'] as String);
      }
      return map;
    }).toList();
  }

  /// Get detailed information for a specific order (for receipt preview)
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    final db = await DatabaseHelper.instance.database;

    // Get order details
    final orderResult = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (orderResult.isEmpty) return null;

    final order = Map<String, dynamic>.from(orderResult.first);

    // Get order items with details
    final itemsResult = await db.rawQuery('''
      SELECT
        oi.item_name,
        oi.quantity,
        oi.item_price,
        oi.subtotal,
        oi.notes
      FROM order_items oi
      WHERE oi.order_id = ?
      ORDER BY oi.created_at ASC
    ''', [orderId]);

    // Get transaction details
    final transactionResult = await db.query(
      'transactions',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'transaction_date DESC',
      limit: 1,
    );

    final transaction = transactionResult.isNotEmpty
        ? Map<String, dynamic>.from(transactionResult.first)
        : null;

    // Get payment method name
    String? paymentMethodName;
    if (transaction != null) {
      final paymentMethodResult = await db.query(
        'payment_methods',
        where: 'id = ?',
        whereArgs: [transaction['payment_method_id']],
        limit: 1,
      );
      if (paymentMethodResult.isNotEmpty) {
        paymentMethodName = paymentMethodResult.first['name'] as String?;
      }
    }

    // Convert date strings to DateTime
    if (order['completed_at'] != null) {
      order['date'] = DateTime.parse(order['completed_at'] as String);
    }

    return {
      'id': order['order_number'] ?? order['id'],
      'date': order['date'],
      'total': (order['total'] as num?)?.toDouble() ?? 0.0,
      'subtotal': (order['subtotal'] as num?)?.toDouble() ?? 0.0,
      'tax': (order['tax'] as num?)?.toDouble() ?? 0.0,
      'discount': (order['discount'] as num?)?.toDouble() ?? 0.0,
      'payment_method': paymentMethodName ?? 'Unknown',
      'customer_name': order['customer_name'],
      'customer_phone': order['customer_phone'],
      'customer_email': order['customer_email'],
      'status': order['status'],
      'items': itemsResult.map((item) => {
        'name': item['item_name'],
        'quantity': (item['quantity'] as num?)?.toInt() ?? 0,
        'price': (item['item_price'] as num?)?.toDouble() ?? 0.0,
        'total': (item['subtotal'] as num?)?.toDouble() ?? 0.0,
        'notes': item['notes'],
      }).toList(),
    };
  }

  /// Search for an order by order number (for refund processing)
  Future<Map<String, dynamic>?> getOrderByOrderNumber(String orderNumber) async {
    final db = await DatabaseHelper.instance.database;

    // Get order details by order number
    final orderResult = await db.query(
      'orders',
      where: 'order_number = ? AND status = ?',
      whereArgs: [orderNumber, 'completed'],
      limit: 1,
    );

    if (orderResult.isEmpty) return null;

    final order = Map<String, dynamic>.from(orderResult.first);

    // Get order items with details
    final itemsResult = await db.rawQuery('''
      SELECT
        oi.item_name,
        oi.quantity,
        oi.item_price,
        oi.subtotal,
        oi.notes
      FROM order_items oi
      WHERE oi.order_id = ?
      ORDER BY oi.created_at ASC
    ''', [order['id']]);

    // Get transaction details
    final transactionResult = await db.query(
      'transactions',
      where: 'order_id = ?',
      whereArgs: [order['id']],
      orderBy: 'transaction_date DESC',
      limit: 1,
    );

    final transaction = transactionResult.isNotEmpty
        ? Map<String, dynamic>.from(transactionResult.first)
        : null;

    // Get payment method name
    String? paymentMethodName;
    if (transaction != null) {
      final paymentMethodResult = await db.query(
        'payment_methods',
        where: 'id = ?',
        whereArgs: [transaction['payment_method_id']],
        limit: 1,
      );
      if (paymentMethodResult.isNotEmpty) {
        paymentMethodName = paymentMethodResult.first['name'] as String?;
      }
    }

    // Convert date strings to DateTime
    if (order['completed_at'] != null) {
      order['date'] = DateTime.parse(order['completed_at'] as String);
    }

    return {
      'id': order['order_number'] ?? order['id'],
      'order_id': order['id'], // Keep the internal ID for refund processing
      'date': order['date'],
      'total': (order['total'] as num?)?.toDouble() ?? 0.0,
      'subtotal': (order['subtotal'] as num?)?.toDouble() ?? 0.0,
      'tax': (order['tax'] as num?)?.toDouble() ?? 0.0,
      'discount': (order['discount'] as num?)?.toDouble() ?? 0.0,
      'payment_method': paymentMethodName ?? 'Unknown',
      'payment_method_id': transaction?['payment_method_id'],
      'customer_name': order['customer_name'],
      'customer_phone': order['customer_phone'],
      'customer_email': order['customer_email'],
      'status': order['status'],
      'can_refund': true, // For now, assume all completed orders can be refunded
      'items': itemsResult.map((item) => {
        'name': item['item_name'],
        'quantity': (item['quantity'] as num?)?.toInt() ?? 0,
        'price': (item['item_price'] as num?)?.toDouble() ?? 0.0,
        'total': (item['subtotal'] as num?)?.toDouble() ?? 0.0,
        'notes': item['notes'],
      }).toList(),
    };
  }

  /// Process a refund for an order
  Future<bool> processRefund({
    required String orderId,
    required double refundAmount,
    required String refundMethodId,
    required String reason,
    required String userId,
  }) async {
    final db = await DatabaseHelper.instance.database;

    try {
      await db.transaction((txn) async {
        final now = DateTime.now();
        final nowIso = now.toIso8601String();
        final uuid = const Uuid();
        final refundId = uuid.v4();

        // Insert refund record (we'll use the transactions table for now, or create a separate refunds table)
        // For simplicity, we'll create a negative transaction
        await txn.insert('transactions', {
          'id': refundId,
          'order_id': orderId,
          'payment_method_id': refundMethodId,
          'amount': -refundAmount, // Negative amount for refund
          'change_amount': 0.0,
          'transaction_date': nowIso,
          'receipt_number': 'REFUND-${orderId.substring(0, 8)}',
          'created_at': nowIso,
        });

        // Update order status to indicate it has been refunded
        await txn.update(
          'orders',
          {
            'status': 'refunded',
            'notes': reason,
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [orderId],
        );

        // TODO: If we had a separate refunds table, we would insert there instead
        // For now, this basic implementation works
      });

      return true;
    } catch (e) {
      // Log error
      return false;
    }
  }

  /// Get database statistics for maintenance screen
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final db = await DatabaseHelper.instance.database;
    
    final stats = <String, dynamic>{};
    
    // Get table counts
    final tables = ['orders', 'order_items', 'transactions', 'products', 'categories'];
    for (final table in tables) {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
      stats['${table}_count'] = result.first['count'] as int? ?? 0;
    }
    
    // Get database file size (approximate)
    final dbPath = await DatabaseHelper.instance.getDatabasePath();
    try {
      final file = File(dbPath);
      if (await file.exists()) {
        stats['database_size_mb'] = (await file.length()) / (1024 * 1024);
      }
    } catch (e) {
      stats['database_size_mb'] = 0.0;
    }
    
    return stats;
  }

  /// Clear application cache (if any)
  Future<void> clearCache() async {
    // For now, this is a placeholder - implement based on your caching strategy
    // Could clear image cache, temp files, etc.
  }

  /// Optimize database performance
  Future<void> optimizeDatabase() async {
    final db = await DatabaseHelper.instance.database;
    
    // Run VACUUM to reclaim space
    await db.execute('VACUUM');
    
    // Run ANALYZE to update query statistics
    await db.execute('ANALYZE');
  }

  /// Export application logs (placeholder)
  Future<String> exportLogs() async {
    // Placeholder - implement log export functionality
    return 'Log export not implemented yet';
  }

  /// Reset application settings to defaults
  Future<void> resetSettings() async {
    // This would reset shared preferences, business info, etc.
    // Implementation depends on your settings management
  }

  /// Update order with e-invoice UUID
  Future<void> updateOrderEInvoiceStatus(String orderId, String uuid) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.update(
      'orders',
      {
        'einvoice_uuid': uuid,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }
}
