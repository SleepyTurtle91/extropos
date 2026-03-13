part of '../database_service.dart';

extension DatabaseServiceSalesHistory on DatabaseService {
  /// Get sales history for display in the Sales History screen
  Future<List<Map<String, dynamic>>> getSalesHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    int? limit,
    int? offset,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final whereConditions = <String>['o.status = ?'];
    final whereArgs = <dynamic>['completed'];

    if (startDate != null) {
      whereConditions.add('o.completed_at >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      final endDateNext = endDate.add(const Duration(days: 1));
      whereConditions.add('o.completed_at < ?');
      whereArgs.add(endDateNext.toIso8601String());
    }

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

    final query = '''
      SELECT
        o.id, o.order_number, o.customer_name, o.customer_phone, o.customer_email,
        o.subtotal, o.tax, o.discount, o.total, o.completed_at as date, o.created_at,
        pm.name as payment_method, COUNT(oi.id) as items_count, o.status
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
    return result.map((row) {
      final map = Map<String, dynamic>.from(row);
      if (map['date'] != null) map['date'] = DateTime.parse(map['date'] as String);
      if (map['created_at'] != null) map['created_at'] = DateTime.parse(map['created_at'] as String);
      return map;
    }).toList();
  }

  /// Get detailed information for a specific order (for receipt preview)
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    final db = await DatabaseHelper.instance.database;
    final orderResult = await db.query('orders', where: 'id = ?', whereArgs: [orderId], limit: 1);
    if (orderResult.isEmpty) return null;

    final order = Map<String, dynamic>.from(orderResult.first);
    final itemsResult = await db.rawQuery('''
      SELECT oi.item_name, oi.quantity, oi.item_price, oi.subtotal, oi.notes
      FROM order_items oi WHERE oi.order_id = ? ORDER BY oi.created_at ASC
    ''', [orderId]);

    final transactionResult = await db.query('transactions', where: 'order_id = ?', whereArgs: [orderId], orderBy: 'transaction_date DESC', limit: 1);
    final transaction = transactionResult.isNotEmpty ? Map<String, dynamic>.from(transactionResult.first) : null;

    String? paymentMethodName;
    if (transaction != null) {
      final paymentMethodResult = await db.query('payment_methods', where: 'id = ?', whereArgs: [transaction['payment_method_id']], limit: 1);
      if (paymentMethodResult.isNotEmpty) paymentMethodName = paymentMethodResult.first['name'] as String?;
    }

    if (order['completed_at'] != null) order['date'] = DateTime.parse(order['completed_at'] as String);

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
    final orderResult = await db.query('orders', where: 'order_number = ? AND status = ?', whereArgs: [orderNumber, 'completed'], limit: 1);
    if (orderResult.isEmpty) return null;

    final order = Map<String, dynamic>.from(orderResult.first);
    final itemsResult = await db.rawQuery('''
      SELECT oi.item_name, oi.quantity, oi.item_price, oi.subtotal, oi.notes
      FROM order_items oi WHERE oi.order_id = ? ORDER BY oi.created_at ASC
    ''', [order['id']]);

    final transactionResult = await db.query('transactions', where: 'order_id = ?', whereArgs: [order['id']], orderBy: 'transaction_date DESC', limit: 1);
    final transaction = transactionResult.isNotEmpty ? Map<String, dynamic>.from(transactionResult.first) : null;

    String? paymentMethodName;
    if (transaction != null) {
      final paymentMethodResult = await db.query('payment_methods', where: 'id = ?', whereArgs: [transaction['payment_method_id']], limit: 1);
      if (paymentMethodResult.isNotEmpty) paymentMethodName = paymentMethodResult.first['name'] as String?;
    }

    if (order['completed_at'] != null) order['date'] = DateTime.parse(order['completed_at'] as String);

    return {
      'id': order['order_number'] ?? order['id'],
      'order_id': order['id'],
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
      'can_refund': true,
      'items': itemsResult.map((item) => {
        'name': item['item_name'],
        'quantity': (item['quantity'] as num?)?.toInt() ?? 0,
        'price': (item['item_price'] as num?)?.toDouble() ?? 0.0,
        'total': (item['subtotal'] as num?)?.toDouble() ?? 0.0,
        'notes': item['notes'],
      }).toList(),
    };
  }
}
