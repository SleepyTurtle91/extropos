part of '../database_service.dart';

/// Reports domain: Scheduled Reports, Forecasting, and Basic Sales Reporting
extension DatabaseServiceReportsScheduled on DatabaseService {
  // ==================== BASIC SALES REPORTING ====================

  Future<SalesReport> generateSalesReport(ReportPeriod period) async {
    try {
      final db = await DatabaseHelper.instance.database;

      final List<Map<String, dynamic>> orderMaps = await db.query(
        'orders',
        where: 'created_at >= ? AND created_at <= ?',
        whereArgs: [
          period.startDate.toIso8601String(),
          period.endDate.toIso8601String(),
        ],
      );

      double netSales = 0.0;
      double taxAmount = 0.0;
      double serviceChargeAmount = 0.0;
      int transactionCount = orderMaps.length;
      final Set<String> uniqueCustomers = {};
      final Map<String, int> productsSold = {};
      final Map<String, double> categoryRevenue = {};
      final Map<String, double> paymentMethodBreakdown = {};
      final Map<int, double> hourlySales = {};

      final businessInfo = BusinessInfo.instance;

      for (final orderMap in orderMaps) {
        final orderId = orderMap['id'].toString();
        final createdAt = DateTime.parse(orderMap['created_at'] as String);
        final paymentMethod = orderMap['payment_method'] as String? ?? 'Cash';
        final customerId = orderMap['customer_id'] as String?;
        if (customerId != null && customerId.isNotEmpty) {
          uniqueCustomers.add(customerId);
        }

        final List<Map<String, dynamic>> itemMaps = await db.query(
          'order_items',
          where: 'order_id = ?',
          whereArgs: [orderId],
        );

        double orderTotal = 0.0;

        for (final itemMap in itemMaps) {
          final itemId = itemMap['item_id'] as String;
          final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 0;
          final unitPrice = (itemMap['item_price'] as num?)?.toDouble() ?? 0.0;
          final lineTotal = quantity * unitPrice;

          orderTotal += lineTotal;

          final itemDetailsMaps = await db.query(
            'items',
            columns: ['name', 'category_id'],
            where: 'id = ?',
            whereArgs: [itemId],
          );

          if (itemDetailsMaps.isNotEmpty) {
            final itemName = itemDetailsMaps.first['name'] as String;
            final categoryId = itemDetailsMaps.first['category_id'] as String?;

            productsSold[itemName] = (productsSold[itemName] ?? 0) + quantity;

            if (categoryId != null) {
              final categoryMaps = await db.query(
                'categories',
                columns: ['name'],
                where: 'id = ?',
                whereArgs: [categoryId],
              );
              if (categoryMaps.isNotEmpty) {
                final categoryName = categoryMaps.first['name'] as String;
                categoryRevenue[categoryName] =
                    (categoryRevenue[categoryName] ?? 0.0) + lineTotal;
              }
            }
          }
        }

        netSales += orderTotal;

        final orderServiceCharge = businessInfo.isServiceChargeEnabled
            ? orderTotal * businessInfo.serviceChargeRate
            : 0.0;
        final orderTax = businessInfo.isTaxEnabled
            ? orderTotal * businessInfo.taxRate
            : 0.0;

        serviceChargeAmount += orderServiceCharge;
        taxAmount += orderTax;

        paymentMethodBreakdown[paymentMethod] =
            (paymentMethodBreakdown[paymentMethod] ?? 0.0) + orderTotal;

        final hour = createdAt.hour;
        hourlySales[hour] = (hourlySales[hour] ?? 0.0) + orderTotal;
      }

      final grossSales = netSales + taxAmount + serviceChargeAmount;
      final averageTicket =
          transactionCount > 0 ? grossSales / transactionCount : 0.0;

      return SalesReport(
        id: 'report_${period.startDate.millisecondsSinceEpoch}_${period.endDate.millisecondsSinceEpoch}',
        startDate: period.startDate,
        endDate: period.endDate,
        reportType: period.label,
        grossSales: grossSales,
        netSales: netSales,
        taxAmount: taxAmount,
        serviceChargeAmount: serviceChargeAmount,
        transactionCount: transactionCount,
        uniqueCustomers: uniqueCustomers.length,
        averageTicket: averageTicket,
        averageTransactionTime: 0,
        topCategories: categoryRevenue,
        paymentMethods: paymentMethodBreakdown,
        generatedAt: DateTime.now(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Database error in generateSalesReport: $e',
        error: e,
        stackTrace: stackTrace,
      );
      ErrorHandler.logError(
        e,
        severity: ErrorSeverity.high,
        category: ErrorCategory.database,
        message: 'Failed to generate sales report from database',
      );
      return SalesReport(
        id: 'error_report',
        startDate: period.startDate,
        endDate: period.endDate,
        reportType: period.label,
        grossSales: 0.0,
        netSales: 0.0,
        taxAmount: 0.0,
        serviceChargeAmount: 0.0,
        transactionCount: 0,
        uniqueCustomers: 0,
        averageTicket: 0.0,
        averageTransactionTime: 0,
        topCategories: {},
        paymentMethods: {},
        generatedAt: DateTime.now(),
      );
    }
  }

  // ==================== SCHEDULED REPORTS ====================
  Future<void> saveScheduledReport(dynamic scheduledReport) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('scheduled_reports', {
      'id': scheduledReport.id,
      'name': scheduledReport.name,
      'report_type': scheduledReport.reportType.name,
      'period_type': null,
      'period_start': scheduledReport.period.startDate.toIso8601String(),
      'period_end': scheduledReport.period.endDate.toIso8601String(),
      'period_label': scheduledReport.period.label,
      'frequency': scheduledReport.frequency.name,
      'recipient_emails': jsonEncode(scheduledReport.recipientEmails),
      'export_formats': jsonEncode(
        scheduledReport.exportFormats.map((f) => f.name).toList(),
      ),
      'custom_filters': scheduledReport.customFilters != null
          ? jsonEncode(scheduledReport.customFilters)
          : null,
      'is_active': scheduledReport.isActive ? 1 : 0,
      'next_run': scheduledReport.nextRun?.toIso8601String(),
      'last_run': scheduledReport.lastRun?.toIso8601String(),
      'created_at': scheduledReport.createdAt.toIso8601String(),
      'updated_at': scheduledReport.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<dynamic>> getScheduledReports({bool activeOnly = false}) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_reports',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'next_run ASC',
    );

    return maps;
  }

  Future<Map<String, dynamic>?> getScheduledReportById(String id) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scheduled_reports',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return maps.isEmpty ? null : maps.first;
  }

  Future<void> updateScheduledReport(dynamic scheduledReport) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'scheduled_reports',
      {
        'name': scheduledReport.name,
        'report_type': scheduledReport.reportType.name,
        'period_start': scheduledReport.period.startDate.toIso8601String(),
        'period_end': scheduledReport.period.endDate.toIso8601String(),
        'period_label': scheduledReport.period.label,
        'frequency': scheduledReport.frequency.name,
        'recipient_emails': jsonEncode(scheduledReport.recipientEmails),
        'export_formats': jsonEncode(
          scheduledReport.exportFormats.map((f) => f.name).toList(),
        ),
        'custom_filters': scheduledReport.customFilters != null
            ? jsonEncode(scheduledReport.customFilters)
            : null,
        'is_active': scheduledReport.isActive ? 1 : 0,
        'next_run': scheduledReport.nextRun?.toIso8601String(),
        'last_run': scheduledReport.lastRun?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [scheduledReport.id],
    );
  }

  Future<void> deleteScheduledReport(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('scheduled_reports', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getReportsDueForExecution() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toIso8601String();

    return await db.query(
      'scheduled_reports',
      where: 'is_active = 1 AND next_run <= ?',
      whereArgs: [now],
      orderBy: 'next_run ASC',
    );
  }

  Future<void> saveExecutionHistory(Map<String, dynamic> history) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'report_execution_history',
      history,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getExecutionHistory(
    String scheduledReportId, {
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'report_execution_history',
      where: 'scheduled_report_id = ?',
      whereArgs: [scheduledReportId],
      orderBy: 'executed_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getRecentExecutions({
    int limit = 20,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'report_execution_history',
      orderBy: 'executed_at DESC',
      limit: limit,
    );
  }

  Future<void> saveForecastModel(Map<String, dynamic> model) async {
    final db = await DatabaseHelper.instance.database;

    await db.update(
      'forecast_models',
      {'is_active': 0},
      where: 'is_active = ?',
      whereArgs: [1],
    );

    await db.insert(
      'forecast_models',
      model,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getActiveForecastModel() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'forecast_models',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'generated_at DESC',
      limit: 1,
    );

    return maps.isEmpty ? null : maps.first;
  }

  Future<List<Map<String, dynamic>>> getForecastModelHistory({
    int limit = 10,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'forecast_models',
      orderBy: 'generated_at DESC',
      limit: limit,
    );
  }

  Future<void> saveCustomReportTemplate(Map<String, dynamic> template) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'custom_report_templates',
      template,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getUserCustomTemplates(
    String userId,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'custom_report_templates',
      where: 'created_by = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getSharedCustomTemplates() async {
    final db = await DatabaseHelper.instance.database;
    return await db.query(
      'custom_report_templates',
      where: 'is_shared = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
  }

  Future<void> deleteCustomReportTemplate(String id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'custom_report_templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SALES TREND ANALYSIS ====================

  Future<Map<String, double>> getDailyTrendData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        SUM(total_amount) as daily_total
      FROM orders
      WHERE created_at >= ? AND created_at <= ?
      GROUP BY DATE(created_at)
      ORDER BY date ASC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final Map<String, double> trendData = {};
    for (final row in results) {
      final date = row['date'] as String;
      final total = (row['daily_total'] as num?)?.toDouble() ?? 0.0;
      trendData[date] = total;
    }
    return trendData;
  }

  Future<Map<String, double>> getHourlyTrendData(DateTime date) async {
    final db = await DatabaseHelper.instance.database;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

    final results = await db.rawQuery('''
      SELECT 
        CAST(STRFTIME('%H', created_at) AS INTEGER) as hour,
        SUM(total_amount) as hourly_total
      FROM orders
      WHERE created_at >= ? AND created_at <= ?
      GROUP BY hour
      ORDER BY hour ASC
    ''', [dayStart.toIso8601String(), dayEnd.toIso8601String()]);

    final Map<String, double> trendData = {};
    for (final row in results) {
      final hour = (row['hour'] as int?)?.toString().padLeft(2, '0') ?? '00';
      final total = (row['hourly_total'] as num?)?.toDouble() ?? 0.0;
      trendData['$hour:00'] = total;
    }
    return trendData;
  }

  Future<Map<String, int>> getProductTrendData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('''
      SELECT 
        i.name,
        SUM(oi.quantity) as total_qty
      FROM order_items oi
      JOIN items i ON oi.item_id = i.id
      WHERE oi.created_at >= ? AND oi.created_at <= ?
      GROUP BY i.id
      ORDER BY total_qty DESC
      LIMIT 20
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final Map<String, int> trendData = {};
    for (final row in results) {
      final productName = row['name'] as String;
      final quantity = (row['total_qty'] as int?) ?? 0;
      trendData[productName] = quantity;
    }
    return trendData;
  }

  Future<double> getAverageDailySales(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''SELECT AVG(daily_total) as avg_sales FROM (
        SELECT SUM(total_amount) as daily_total
        FROM orders
        WHERE created_at >= ? AND created_at <= ?
        GROUP BY DATE(created_at)
      )''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return (result.first['avg_sales'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, double>> getCategoryTrendData(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.rawQuery('''
      SELECT 
        c.name,
        SUM(oi.item_price * oi.quantity) as category_sales
      FROM order_items oi
      JOIN items i ON oi.item_id = i.id
      JOIN categories c ON i.category_id = c.id
      WHERE oi.created_at >= ? AND oi.created_at <= ?
      GROUP BY c.id
      ORDER BY category_sales DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final Map<String, double> trendData = {};
    for (final row in results) {
      final categoryName = row['name'] as String;
      final sales = (row['category_sales'] as num?)?.toDouble() ?? 0.0;
      trendData[categoryName] = sales;
    }
    return trendData;
  }

  Future<double> getMedianTransactionValue(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''SELECT AVG(mid_value) as median_value FROM (
        SELECT total_amount as mid_value
        FROM orders
        WHERE created_at >= ? AND created_at <= ?
        ORDER BY total_amount ASC
        LIMIT 1 OFFSET (
          SELECT COUNT(*) / 2 FROM orders
          WHERE created_at >= ? AND created_at <= ?
        )
      )''',
      [
        startDate.toIso8601String(),
        endDate.toIso8601String(),
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
    );

    return (result.first['median_value'] as num?)?.toDouble() ?? 0.0;
  }

  Future<int> getTotalTransactionCount(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM orders WHERE created_at >= ? AND created_at <= ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getUniqueCustomerCount(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT customer_id) as count FROM orders WHERE customer_id IS NOT NULL AND created_at >= ? AND created_at <= ?',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return result.first['count'] as int? ?? 0;
  }

  Future<double> getMaxDailySales(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''SELECT MAX(daily_total) as max_sales FROM (
        SELECT SUM(total_amount) as daily_total
        FROM orders
        WHERE created_at >= ? AND created_at <= ?
        GROUP BY DATE(created_at)
      )''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['max_sales'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getMinDailySales(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''SELECT MIN(daily_total) as min_sales FROM (
        SELECT SUM(total_amount) as daily_total
        FROM orders
        WHERE created_at >= ? AND created_at <= ?
        GROUP BY DATE(created_at)
      )''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );
    return (result.first['min_sales'] as num?)?.toDouble() ?? 0.0;
  }
}
