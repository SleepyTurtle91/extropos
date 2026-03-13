part of '../database_service.dart';

extension DatabaseServiceReportsDashboard on DatabaseService {
  /// Get sales summary for reports dashboard
  Future<SalesSummary?> getSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? staffId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause = 'o.status = \'completed\' AND o.completed_at >= ? AND o.completed_at < ?';
    List<dynamic> whereArgs = [startDate.toIso8601String(), endDate.add(const Duration(days: 1)).toIso8601String()];

    if (categoryId != null) {
      whereClause += ' AND EXISTS (SELECT 1 FROM order_items oi JOIN items i ON oi.item_id = i.id WHERE oi.order_id = o.id AND i.category_id = ?)';
      whereArgs.add(categoryId);
    }
    if (staffId != null) {
      whereClause += ' AND o.created_by = (SELECT id FROM users WHERE name = ?)';
      whereArgs.add(staffId);
    }

    final result = await db.rawQuery('''
      SELECT COUNT(DISTINCT o.id) as order_count, SUM(o.total_amount) as total_revenue,
             SUM(o.tax_amount) as total_tax, SUM(o.service_charge_amount) as total_service_charge,
             SUM(o.discount_amount) as total_discount, SUM(oi.quantity) as items_sold
      FROM orders o LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE $whereClause
    ''', whereArgs);

    if (result.isEmpty || result.first['order_count'] == null) return null;

    final row = result.first;
    final orderCount = row['order_count'] as int? ?? 0;
    final totalRevenue = (row['total_revenue'] as num?)?.toDouble() ?? 0.0;

    return SalesSummary(
      totalRevenue: totalRevenue,
      totalTax: (row['total_tax'] as num?)?.toDouble() ?? 0.0,
      totalServiceCharge: (row['total_service_charge'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (row['total_discount'] as num?)?.toDouble() ?? 0.0,
      orderCount: orderCount,
      itemsSold: (row['items_sold'] as num?)?.toInt() ?? 0,
      averageOrderValue: orderCount > 0 ? totalRevenue / orderCount : 0.0,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get top performing products for reports
  Future<List<ProductPerformance>> getTopProducts({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? staffId,
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause = 'o.status = \'completed\' AND o.completed_at >= ? AND o.completed_at < ?';
    List<dynamic> whereArgs = [startDate.toIso8601String(), endDate.add(const Duration(days: 1)).toIso8601String()];

    if (categoryId != null) { whereClause += ' AND p.category_id = ?'; whereArgs.add(categoryId); }
    if (staffId != null) { whereClause += ' AND o.created_by = (SELECT id FROM users WHERE name = ?)'; whereArgs.add(staffId); }
    whereArgs.add(limit);

    final results = await db.rawQuery('''
      SELECT p.id as item_id, p.name as item_name, c.name as category_name,
             SUM(oi.quantity) as quantity_sold, SUM(oi.total_price) as revenue,
             COUNT(DISTINCT o.id) as order_count, AVG(oi.unit_price) as average_price
      FROM products p LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN order_items oi ON p.id = oi.product_id
      LEFT JOIN orders o ON oi.order_id = o.id
      WHERE $whereClause GROUP BY p.id, p.name, c.name ORDER BY revenue DESC LIMIT ?
    ''', whereArgs);

    return results.map((row) => ProductPerformance(
      itemId: row['item_id'] as String? ?? '',
      itemName: row['item_name'] as String? ?? 'Unknown Product',
      categoryName: row['category_name'] as String? ?? 'Uncategorized',
      revenue: (row['revenue'] as num?)?.toDouble() ?? 0.0,
      quantitySold: (row['quantity_sold'] as num?)?.toInt() ?? 0,
      orderCount: (row['order_count'] as num?)?.toInt() ?? 0,
      averagePrice: (row['average_price'] as num?)?.toDouble() ?? 0.0,
    )).toList();
  }

  /// Get daily sales data for charts
  Future<List<DailySales>> getDailySales({
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? staffId,
  }) async {
    final db = await DatabaseHelper.instance.database;
    String whereClause = 'o.status = \'completed\' AND o.completed_at >= ? AND o.completed_at < ?';
    List<dynamic> whereArgs = [startDate.toIso8601String(), endDate.add(const Duration(days: 1)).toIso8601String()];

    if (categoryId != null) {
      whereClause += ' AND EXISTS (SELECT 1 FROM order_items oi JOIN items i ON oi.item_id = i.id WHERE oi.order_id = o.id AND i.category_id = ?)';
      whereArgs.add(categoryId);
    }
    if (staffId != null) {
      whereClause += ' AND o.created_by = (SELECT id FROM users WHERE name = ?)';
      whereArgs.add(staffId);
    }

    final results = await db.rawQuery('''
      SELECT strftime('%Y-%m-%d', o.completed_at) as sale_date, SUM(o.total_amount) as revenue,
             COUNT(DISTINCT o.id) as order_count
      FROM orders o WHERE $whereClause GROUP BY strftime('%Y-%m-%d', o.completed_at) ORDER BY sale_date
    ''', whereArgs);

    return results.map((row) {
      final dateStr = row['sale_date'] as String?;
      return DailySales(
        date: dateStr != null ? DateTime.parse(dateStr) : DateTime.now(),
        revenue: (row['revenue'] as num?)?.toDouble() ?? 0.0,
        orderCount: (row['order_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<void> updateOrderEInvoiceStatus(String orderId, String uuid) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('orders', {'einvoice_uuid': uuid, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [orderId]);
  }
}
