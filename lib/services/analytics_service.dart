import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/services/database_helper.dart';

/// Service for generating analytics and reports
/// Provides aggregated data for charts and statistics
class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._init();
  AnalyticsService._init();

  /// Get sales summary for a date range
  Future<SalesSummary> getSalesSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(total), 0) as total_revenue,
        COALESCE(SUM(tax), 0) as total_tax,
        COALESCE(SUM(CASE 
          WHEN order_type = 'restaurant' 
          THEN subtotal * 0.10 
          ELSE 0 
        END), 0) as total_service_charge,
        COALESCE(SUM(discount), 0) as total_discount,
        COUNT(*) as order_count
      FROM orders
      WHERE created_at >= ? 
        AND created_at <= ?
        AND status NOT IN ('cancelled', 'voided')
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final itemsResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(oi.quantity), 0) as items_sold
      FROM order_items oi
      INNER JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ? 
        AND o.created_at <= ?
        AND o.status NOT IN ('cancelled', 'voided')
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return SalesSummary.fromMap({
      ...result.first,
      'items_sold': itemsResult.first['items_sold'],
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    });
  }

  /// Get category performance for a date range
  Future<List<CategoryPerformance>> getCategoryPerformance({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        i.category_id,
        c.name as category_name,
        COALESCE(SUM(oi.subtotal), 0) as revenue,
        COALESCE(SUM(oi.quantity), 0) as items_sold,
        COUNT(DISTINCT o.id) as order_count
      FROM order_items oi
      INNER JOIN orders o ON oi.order_id = o.id
      INNER JOIN items i ON oi.item_id = i.id
      LEFT JOIN categories c ON i.category_id = c.id
      WHERE o.created_at >= ? 
        AND o.created_at <= ?
        AND o.status NOT IN ('cancelled', 'voided')
      GROUP BY i.category_id, c.name
      ORDER BY revenue DESC
      LIMIT ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String(), limit],
    );

    return results.map((r) => CategoryPerformance.fromMap(r)).toList();
  }

  /// Get top selling products for a date range
  Future<List<ProductPerformance>> getTopProducts({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        oi.item_id,
        oi.item_name,
        COALESCE(c.name, 'Uncategorized') as category_name,
        COALESCE(SUM(oi.subtotal), 0) as revenue,
        COALESCE(SUM(oi.quantity), 0) as quantity_sold,
        COUNT(DISTINCT o.id) as order_count
      FROM order_items oi
      INNER JOIN orders o ON oi.order_id = o.id
      LEFT JOIN items i ON oi.item_id = i.id
      LEFT JOIN categories c ON i.category_id = c.id
      WHERE o.created_at >= ? 
        AND o.created_at <= ?
        AND o.status NOT IN ('cancelled', 'voided')
      GROUP BY oi.item_id, oi.item_name, c.name
      ORDER BY revenue DESC
      LIMIT ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String(), limit],
    );

    return results.map((r) => ProductPerformance.fromMap(r)).toList();
  }

  /// Get payment method breakdown for a date range
  Future<List<PaymentMethodStats>> getPaymentMethodStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Get grand total first
    final grandTotalResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(total), 0) as grand_total
      FROM orders
      WHERE created_at >= ? 
        AND created_at <= ?
        AND status NOT IN ('cancelled', 'voided')
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final grandTotal =
        (grandTotalResult.first['grand_total'] as num?)?.toDouble() ?? 0.0;

    final results = await db.rawQuery(
      '''
      SELECT 
        o.payment_method_id,
        COALESCE(pm.name, 'Unknown') as payment_method_name,
        COALESCE(SUM(o.total), 0) as total_amount,
        COUNT(*) as transaction_count
      FROM orders o
      LEFT JOIN payment_methods pm ON o.payment_method_id = pm.id
      WHERE o.created_at >= ? 
        AND o.created_at <= ?
        AND o.status NOT IN ('cancelled', 'voided')
      GROUP BY o.payment_method_id, pm.name
      ORDER BY total_amount DESC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return results
        .map((r) => PaymentMethodStats.fromMap(r, grandTotal))
        .toList();
  }

  /// Get hourly sales trend for a specific date
  Future<List<HourlySales>> getHourlySales(DateTime date) async {
    final db = await DatabaseHelper.instance.database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final results = await db.rawQuery(
      '''
      SELECT 
        CAST(strftime('%H', created_at) AS INTEGER) as hour,
        COALESCE(SUM(total), 0) as revenue,
        COUNT(*) as order_count
      FROM orders
      WHERE created_at >= ? 
        AND created_at < ?
        AND status NOT IN ('cancelled', 'voided')
      GROUP BY hour
      ORDER BY hour ASC
    ''',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    // Fill in missing hours with zero values
    final hourlyMap = <int, HourlySales>{};
    for (final result in results) {
      final sales = HourlySales.fromMap(result);
      hourlyMap[sales.hour] = sales;
    }

    // Create complete 24-hour list
    return List.generate(24, (hour) {
      return hourlyMap[hour] ??
          HourlySales(hour: hour, revenue: 0.0, orderCount: 0);
    });
  }

  /// Get daily sales trend for a date range
  Future<List<DailySales>> getDailySales({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        DATE(created_at) as date,
        COALESCE(SUM(total), 0) as revenue,
        COUNT(*) as order_count
      FROM orders
      WHERE created_at >= ? 
        AND created_at <= ?
        AND status NOT IN ('cancelled', 'voided')
      GROUP BY date
      ORDER BY date ASC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return results.map((r) => DailySales.fromMap(r)).toList();
  }

  /// Get business mode distribution (retail vs cafe vs restaurant)
  Future<Map<String, double>> getOrderTypeDistribution({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        order_type,
        COALESCE(SUM(total), 0) as revenue
      FROM orders
      WHERE created_at >= ? 
        AND created_at <= ?
        AND status NOT IN ('cancelled', 'voided')
      GROUP BY order_type
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    final distribution = <String, double>{};
    for (final result in results) {
      final orderType = result['order_type'] as String? ?? 'unknown';
      final revenue = (result['revenue'] as num?)?.toDouble() ?? 0.0;
      distribution[orderType] = revenue;
    }

    return distribution;
  }

  /// Get average order value trend over time
  Future<List<Map<String, dynamic>>> getAverageOrderValueTrend({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        DATE(created_at) as date,
        AVG(total) as avg_order_value,
        COUNT(*) as order_count
      FROM orders
      WHERE created_at >= ? 
        AND created_at <= ?
        AND status NOT IN ('cancelled', 'voided')
      GROUP BY date
      ORDER BY date ASC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return results
        .map(
          (r) => {
            'date': DateTime.parse(r['date'] as String),
            'avg_order_value':
                (r['avg_order_value'] as num?)?.toDouble() ?? 0.0,
            'order_count': r['order_count'] as int? ?? 0,
          },
        )
        .toList();
  }

  /// Export analytics data to CSV format
  Future<String> exportAnalyticsCsv({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final summary = await getSalesSummary(
      startDate: startDate,
      endDate: endDate,
    );
    final categories = await getCategoryPerformance(
      startDate: startDate,
      endDate: endDate,
      limit: 100,
    );
    final products = await getTopProducts(
      startDate: startDate,
      endDate: endDate,
      limit: 100,
    );
    final paymentMethods = await getPaymentMethodStats(
      startDate: startDate,
      endDate: endDate,
    );

    final sb = StringBuffer();

    // Header with metadata
    sb.writeln('ExtroPOS Analytics Report');
    sb.writeln('Generated: ${DateTime.now().toIso8601String()}');
    sb.writeln(
      'Period: ${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
    );
    sb.writeln();

    // Summary section
    sb.writeln('SUMMARY');
    sb.writeln('Total Revenue,${summary.totalRevenue.toStringAsFixed(2)}');
    sb.writeln('Total Tax,${summary.totalTax.toStringAsFixed(2)}');
    sb.writeln(
      'Total Service Charge,${summary.totalServiceCharge.toStringAsFixed(2)}',
    );
    sb.writeln('Total Discount,${summary.totalDiscount.toStringAsFixed(2)}');
    sb.writeln('Order Count,${summary.orderCount}');
    sb.writeln('Items Sold,${summary.itemsSold}');
    sb.writeln(
      'Average Order Value,${summary.averageOrderValue.toStringAsFixed(2)}',
    );
    sb.writeln();

    // Category performance
    sb.writeln('CATEGORY PERFORMANCE');
    sb.writeln('Category,Revenue,Items Sold,Orders,Avg Item Price');
    for (final cat in categories) {
      sb.writeln(
        '${cat.categoryName},${cat.revenue.toStringAsFixed(2)},${cat.itemsSold},${cat.orderCount},${cat.averageItemPrice.toStringAsFixed(2)}',
      );
    }
    sb.writeln();

    // Top products
    sb.writeln('TOP PRODUCTS');
    sb.writeln('Product,Category,Revenue,Quantity Sold,Orders,Avg Price');
    for (final prod in products) {
      sb.writeln(
        '${prod.itemName},${prod.categoryName},${prod.revenue.toStringAsFixed(2)},${prod.quantitySold},${prod.orderCount},${prod.averagePrice.toStringAsFixed(2)}',
      );
    }
    sb.writeln();

    // Payment methods
    sb.writeln('PAYMENT METHODS');
    sb.writeln('Payment Method,Amount,Transactions,Percentage');
    for (final pm in paymentMethods) {
      sb.writeln(
        '${pm.paymentMethodName},${pm.totalAmount.toStringAsFixed(2)},${pm.transactionCount},${pm.percentage.toStringAsFixed(2)}%',
      );
    }

    return sb.toString();
  }
}
