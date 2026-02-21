import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/employee_performance_models.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

class EmployeePerformanceService {
  static final EmployeePerformanceService instance =
      EmployeePerformanceService._();
  EmployeePerformanceService._();

  /// Get employee performance summary for a date range
  Future<List<EmployeePerformance>> getEmployeePerformance({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final results = await db.rawQuery(
      '''
      SELECT 
        u.id as user_id,
        u.name as user_name,
        u.role as user_role,
        COALESCE(SUM(o.total), 0) as total_sales,
        COUNT(o.id) as order_count,
        COALESCE(SUM(oi.quantity), 0) as items_sold,
        COALESCE(AVG(o.total), 0) as average_order_value
      FROM users u
      LEFT JOIN orders o ON u.id = o.user_id 
        AND o.created_at >= ? 
        AND o.created_at <= ?
        AND o.status NOT IN ('cancelled', 'voided')
      LEFT JOIN order_items oi ON o.id = oi.order_id
      WHERE u.is_active = 1
      GROUP BY u.id, u.name, u.role
      ORDER BY total_sales DESC
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return results.map((row) {
      final totalSales = (row['total_sales'] as num).toDouble();
      final commission = CommissionTier.calculateTotalCommission(totalSales);

      return EmployeePerformance(
        userId: row['user_id'] as String,
        userName: row['user_name'] as String,
        userRole: row['user_role'] as String,
        totalSales: totalSales,
        orderCount: row['order_count'] as int,
        itemsSold: row['items_sold'] as int,
        averageOrderValue: (row['average_order_value'] as num).toDouble(),
        commission: commission,
        startDate: startDate,
        endDate: endDate,
      );
    }).toList();
  }

  /// Get employee rankings (leaderboard)
  Future<List<EmployeeRanking>> getEmployeeLeaderboard({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final performances = await getEmployeePerformance(
      startDate: startDate,
      endDate: endDate,
    );

    // Sort by total sales descending
    performances.sort((a, b) => b.totalSales.compareTo(a.totalSales));

    final rankings = <EmployeeRanking>[];
    for (int i = 0; i < performances.length && i < limit; i++) {
      final perf = performances[i];
      rankings.add(
        EmployeeRanking(
          rank: i + 1,
          userId: perf.userId,
          userName: perf.userName,
          userRole: perf.userRole,
          totalSales: perf.totalSales,
          orderCount: perf.orderCount,
          commission: perf.commission,
        ),
      );
    }

    return rankings;
  }

  /// Get shift report for a specific employee and time range
  Future<ShiftReport?> getShiftReport({
    required String userId,
    required DateTime shiftStart,
    required DateTime shiftEnd,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Get user name
    final userResult = await db.query(
      'users',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (userResult.isEmpty) return null;
    final userName = userResult.first['name'] as String;

    // Get sales data
    final salesResult = await db.rawQuery(
      '''
      SELECT 
        COALESCE(SUM(CASE WHEN status NOT IN ('cancelled', 'voided', 'refunded') THEN total ELSE 0 END), 0) as total_sales,
        COUNT(CASE WHEN status NOT IN ('cancelled', 'voided') THEN 1 END) as order_count,
        COUNT(CASE WHEN status = 'refunded' THEN 1 END) as refund_count,
        COALESCE(SUM(CASE WHEN status = 'refunded' THEN total ELSE 0 END), 0) as refund_amount,
        COUNT(CASE WHEN status = 'voided' THEN 1 END) as void_count,
        COALESCE(AVG(CASE WHEN status NOT IN ('cancelled', 'voided', 'refunded') THEN total END), 0) as average_order_value
      FROM orders
      WHERE user_id = ?
        AND created_at >= ?
        AND created_at <= ?
    ''',
      [userId, shiftStart.toIso8601String(), shiftEnd.toIso8601String()],
    );

    // Get items sold
    final itemsResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(oi.quantity), 0) as items_sold
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE o.user_id = ?
        AND o.created_at >= ?
        AND o.created_at <= ?
        AND o.status NOT IN ('cancelled', 'voided')
    ''',
      [userId, shiftStart.toIso8601String(), shiftEnd.toIso8601String()],
    );

    // Get payment method breakdown
    final paymentResult = await db.rawQuery(
      '''
      SELECT 
        pm.name as payment_method,
        COALESCE(SUM(o.total), 0) as total
      FROM orders o
      JOIN payment_methods pm ON o.payment_method_id = pm.id
      WHERE o.user_id = ?
        AND o.created_at >= ?
        AND o.created_at <= ?
        AND o.status NOT IN ('cancelled', 'voided', 'refunded')
      GROUP BY pm.name
    ''',
      [userId, shiftStart.toIso8601String(), shiftEnd.toIso8601String()],
    );

    // Calculate payment method totals
    double cashSales = 0.0;
    double cardSales = 0.0;
    double otherSales = 0.0;

    for (final row in paymentResult) {
      final method = (row['payment_method'] as String).toLowerCase();
      final total = (row['total'] as num).toDouble();

      if (method.contains('cash')) {
        cashSales += total;
      } else if (method.contains('card') ||
          method.contains('credit') ||
          method.contains('debit')) {
        cardSales += total;
      } else {
        otherSales += total;
      }
    }

    final sales = salesResult.first;
    final items = itemsResult.first;

    return ShiftReport(
      userId: userId,
      userName: userName,
      shiftStart: shiftStart,
      shiftEnd: shiftEnd,
      totalSales: (sales['total_sales'] as num).toDouble(),
      orderCount: (sales['order_count'] as int?) ?? 0,
      itemsSold: (items['items_sold'] as int?) ?? 0,
      cashSales: cashSales,
      cardSales: cardSales,
      otherSales: otherSales,
      refundCount: (sales['refund_count'] as int?) ?? 0,
      refundAmount: (sales['refund_amount'] as num).toDouble(),
      voidCount: (sales['void_count'] as int?) ?? 0,
      averageOrderValue: (sales['average_order_value'] as num).toDouble(),
      shiftDuration: shiftEnd.difference(shiftStart),
    );
  }

  /// Get hourly sales breakdown for an employee on a specific date
  Future<List<HourlyEmployeeSales>> getHourlyEmployeeSales({
    required String userId,
    required DateTime date,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final results = await db.rawQuery(
      '''
      SELECT 
        CAST(strftime('%H', created_at) AS INTEGER) as hour,
        COALESCE(SUM(total), 0) as revenue,
        COUNT(*) as order_count
      FROM orders
      WHERE user_id = ?
        AND created_at >= ?
        AND created_at <= ?
        AND status NOT IN ('cancelled', 'voided')
      GROUP BY hour
      ORDER BY hour
    ''',
      [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );

    // Fill in missing hours with zero values
    final hourlyData = <HourlyEmployeeSales>[];
    final dataMap = {for (var row in results) row['hour'] as int: row};

    for (int hour = 0; hour < 24; hour++) {
      if (dataMap.containsKey(hour)) {
        final row = dataMap[hour]!;
        hourlyData.add(
          HourlyEmployeeSales(
            userId: userId,
            hour: hour,
            revenue: (row['revenue'] as num).toDouble(),
            orderCount: row['order_count'] as int,
          ),
        );
      } else {
        hourlyData.add(
          HourlyEmployeeSales(
            userId: userId,
            hour: hour,
            revenue: 0.0,
            orderCount: 0,
          ),
        );
      }
    }

    return hourlyData;
  }

  /// Get top performing employee for a period
  Future<EmployeePerformance?> getTopPerformer({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final performances = await getEmployeePerformance(
      startDate: startDate,
      endDate: endDate,
    );

    if (performances.isEmpty) return null;

    // Already sorted by total_sales DESC in SQL
    return performances.first;
  }

  /// Export employee performance report to CSV
  Future<String> exportEmployeePerformanceCsv({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final performances = await getEmployeePerformance(
      startDate: startDate,
      endDate: endDate,
    );

    final sb = StringBuffer();
    final dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    final now = DateTime.now();
    final bizName = BusinessInfo.instance.businessName;
    final currency = BusinessInfo.instance.currencySymbol;

    // Metadata
    sb.writeln('meta_key,meta_value');
    sb.writeln('report_type,Employee Performance Report');
    sb.writeln('generated_at,${dateFormatter.format(now)}');
    sb.writeln('business_name,${_escapeCsv(bizName)}');
    sb.writeln('period_start,${dateFormatter.format(startDate)}');
    sb.writeln('period_end,${dateFormatter.format(endDate)}');
    sb.writeln('currency,$currency');
    sb.writeln();

    // Column headers
    sb.writeln(
      'Employee Name,Role,Total Sales,Orders,Items Sold,Avg Order Value,Commission,Commission Tier',
    );

    // Data rows
    for (final perf in performances) {
      final tier = CommissionTier.getTierForSales(perf.totalSales);
      sb.writeln(
        '${_escapeCsv(perf.userName)},${_escapeCsv(perf.userRole)},${perf.totalSales.toStringAsFixed(2)},${perf.orderCount},${perf.itemsSold},${perf.averageOrderValue.toStringAsFixed(2)},${perf.commission.toStringAsFixed(2)},${tier?.tierName ?? 'None'}',
      );
    }

    return sb.toString();
  }

  String _escapeCsv(String input) {
    final s = input.replaceAll('\r', '').replaceAll('\n', ' ');
    if (s.contains(',') || s.contains('"')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Save CSV file to device
  Future<String> saveEmployeePerformanceCsv({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final csv = await exportEmployeePerformanceCsv(
      startDate: startDate,
      endDate: endDate,
    );

    final dateFormatter = DateFormat('yyyyMMdd');
    final filename =
        'employee_performance_${dateFormatter.format(startDate)}_to_${dateFormatter.format(endDate)}.csv';

    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final file = File('${downloadsDir.path}/$filename');
      await file.writeAsString(csv);
      return file.path;
    } else {
      // Desktop platforms
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }
      final file = File('${directory.path}/$filename');
      await file.writeAsString(csv);
      return file.path;
    }
  }

  /// Compare employee performance period over period
  Future<Map<String, dynamic>> compareEmployeePerformance({
    required String userId,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
  }) async {
    final currentPerfs = await getEmployeePerformance(
      startDate: currentStart,
      endDate: currentEnd,
    );

    final previousPerfs = await getEmployeePerformance(
      startDate: previousStart,
      endDate: previousEnd,
    );

    final currentPerf = currentPerfs.firstWhere(
      (p) => p.userId == userId,
      orElse: () => EmployeePerformance(
        userId: userId,
        userName: 'Unknown',
        userRole: '',
        totalSales: 0,
        orderCount: 0,
        itemsSold: 0,
        averageOrderValue: 0,
        commission: 0,
        startDate: currentStart,
        endDate: currentEnd,
      ),
    );

    final previousPerf = previousPerfs.firstWhere(
      (p) => p.userId == userId,
      orElse: () => EmployeePerformance(
        userId: userId,
        userName: 'Unknown',
        userRole: '',
        totalSales: 0,
        orderCount: 0,
        itemsSold: 0,
        averageOrderValue: 0,
        commission: 0,
        startDate: previousStart,
        endDate: previousEnd,
      ),
    );

    double salesChange = 0.0;
    double orderChange = 0.0;
    double aovChange = 0.0;

    if (previousPerf.totalSales > 0) {
      salesChange =
          ((currentPerf.totalSales - previousPerf.totalSales) /
              previousPerf.totalSales) *
          100;
    }

    if (previousPerf.orderCount > 0) {
      orderChange =
          ((currentPerf.orderCount - previousPerf.orderCount) /
              previousPerf.orderCount) *
          100;
    }

    if (previousPerf.averageOrderValue > 0) {
      aovChange =
          ((currentPerf.averageOrderValue - previousPerf.averageOrderValue) /
              previousPerf.averageOrderValue) *
          100;
    }

    return {
      'current': currentPerf,
      'previous': previousPerf,
      'sales_change_percent': salesChange,
      'order_change_percent': orderChange,
      'aov_change_percent': aovChange,
    };
  }
}
