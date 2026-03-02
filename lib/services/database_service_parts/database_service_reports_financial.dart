part of '../database_service.dart';

extension DatabaseServiceReportsFinancial on DatabaseService {
  Future<DayClosingReport> generateDayClosingReport(ReportPeriod period) async {
    final sessionData = await _getBusinessSessionData(period);
    final cashReconciliation = await _getCashReconciliationData(period);
    final shiftSummaries = await _getShiftSummaries(period);

    return DayClosingReport(
      sessionData: sessionData,
      cashReconciliation: cashReconciliation,
      shiftSummaries: shiftSummaries,
      reportDate: DateTime.now(),
      generatedBy: LockManager.instance.currentUser?.fullName ?? 'System',
    );
  }

  Future<ProfitLossReport> generateProfitLossReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double totalRevenue = 0.0;
    double costOfGoodsSold = 0.0;
    double operatingExpenses = 0.0;
    Map<String, double> revenueBreakdown = {};
    Map<String, double> expenseBreakdown = {};

    for (final orderMap in orderMaps) {
      final subtotal = orderMap['subtotal'] as double;
      final tax = orderMap['tax'] as double;
      final discount = orderMap['discount'] as double? ?? 0.0;

      totalRevenue += subtotal + tax - discount;

      costOfGoodsSold += subtotal * 0.3;

      operatingExpenses += (subtotal + tax) * 0.05;
    }

    final grossProfit = totalRevenue - costOfGoodsSold;
    final netProfit = grossProfit - operatingExpenses;
    final profitMargin = totalRevenue > 0
        ? (netProfit / totalRevenue) * 100
        : 0.0;

    final profitLossItems = <ProfitLossItem>[];

    return ProfitLossReport(
      id: 'profit_loss_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalRevenue: totalRevenue,
      costOfGoodsSold: costOfGoodsSold,
      grossProfit: grossProfit,
      operatingExpenses: operatingExpenses,
      netProfit: netProfit,
      profitMargin: profitMargin,
      revenueBreakdown: revenueBreakdown,
      expenseBreakdown: expenseBreakdown,
      profitLossItems: profitLossItems,
    );
  }

  Future<CashFlowReport> generateCashFlowReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final openingCash = 1000.0;

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double cashInflows = 0.0;
    double cashOutflows = 0.0;
    Map<String, double> inflowBreakdown = {};
    Map<String, double> outflowBreakdown = {};
    final transactions = <CashFlowTransaction>[];

    for (final orderMap in orderMaps) {
      final subtotal = orderMap['subtotal'] as double;
      final tax = orderMap['tax'] as double;
      final paymentMethod = orderMap['payment_method'] as String? ?? 'cash';

      final amount = subtotal + tax;
      cashInflows += amount;

      inflowBreakdown[paymentMethod] =
          (inflowBreakdown[paymentMethod] ?? 0.0) + amount;

      transactions.add(
        CashFlowTransaction(
          date: DateTime.parse(orderMap['created_at'] as String),
          type: 'inflow',
          category: 'Sales',
          amount: amount,
          description: 'Sale transaction',
        ),
      );
    }

    final netCashFlow = cashInflows - cashOutflows;
    final closingCash = openingCash + netCashFlow;

    return CashFlowReport(
      id: 'cash_flow_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      openingCash: openingCash,
      closingCash: closingCash,
      cashInflows: cashInflows,
      cashOutflows: cashOutflows,
      netCashFlow: netCashFlow,
      inflowBreakdown: inflowBreakdown,
      outflowBreakdown: outflowBreakdown,
      transactions: transactions,
    );
  }

  Future<TaxSummaryReport> generateTaxSummaryReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> orderMaps = await db.query(
      'orders',
      where: 'created_at >= ? AND created_at <= ? AND status = ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double totalTaxCollected = 0.0;
    Map<String, double> taxBreakdown = {};
    final taxItems = <TaxItem>[];

    for (final orderMap in orderMaps) {
      final tax = orderMap['tax'] as double;
      final date = DateTime.parse(orderMap['created_at'] as String);

      totalTaxCollected += tax;

      final taxRate = BusinessInfo.instance.isTaxEnabled
          ? BusinessInfo.instance.taxRate * 100
          : 0.0;
      final taxKey = '${taxRate.toStringAsFixed(1)}%';

      taxBreakdown[taxKey] = (taxBreakdown[taxKey] ?? 0.0) + tax;

      if (tax > 0) {
        taxItems.add(
          TaxItem(taxType: 'Sales Tax', rate: taxRate, amount: tax, date: date),
        );
      }
    }

    return TaxSummaryReport(
      id: 'tax_summary_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalTaxCollected: totalTaxCollected,
      totalTaxPaid: 0.0,
      taxBreakdown: taxBreakdown,
      taxItems: taxItems,
      taxLiability: totalTaxCollected,
    );
  }

  Future<InventoryValuationReport> generateInventoryValuationReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> productMaps = await db.query('products');

    double totalCostValue = 0.0;
    double totalRetailValue = 0.0;
    Map<String, double> valuationByCategory = {};
    final valuationItems = <InventoryValuationItem>[];

    for (final productMap in productMaps) {
      final costPrice =
          (productMap['cost_price'] as double?) ??
          ((productMap['price'] as double) * 0.7);
      final retailPrice = productMap['price'] as double;
      final stock = productMap['stock'] as int? ?? 0;
      final category = productMap['category'] as String? ?? 'Uncategorized';

      final itemCostValue = costPrice * stock;
      final itemRetailValue = retailPrice * stock;
      final profitMargin = retailPrice > 0
          ? ((retailPrice - costPrice) / retailPrice) * 100
          : 0.0;

      totalCostValue += itemCostValue;
      totalRetailValue += itemRetailValue;

      valuationByCategory[category] =
          (valuationByCategory[category] ?? 0.0) + itemRetailValue;

      valuationItems.add(
        InventoryValuationItem(
          itemId: productMap['id'] as String,
          itemName: productMap['name'] as String,
          quantity: stock,
          costPrice: costPrice,
          retailPrice: retailPrice,
          totalCostValue: itemCostValue,
          totalRetailValue: itemRetailValue,
          profitMargin: profitMargin,
        ),
      );
    }

    final inventoryTurnoverRatio = totalCostValue > 0
        ? totalRetailValue / totalCostValue
        : 0.0;

    return InventoryValuationReport(
      id: 'inventory_valuation_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalInventoryValue: totalRetailValue,
      totalCostValue: totalCostValue,
      totalRetailValue: totalRetailValue,
      valuationByCategory: valuationByCategory,
      valuationItems: valuationItems,
      inventoryTurnoverRatio: inventoryTurnoverRatio,
    );
  }

  Future<ABCAnalysisReport> generateABCAnalysisReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> orderItemMaps = await db.rawQuery(
      '''
      SELECT oi.product_id, p.name, SUM(oi.quantity * oi.price) as revenue
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY oi.product_id, p.name
      ORDER BY revenue DESC
    ''',
      [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    double totalRevenue = 0.0;
    for (final item in orderItemMaps) {
      totalRevenue += item['revenue'] as double;
    }

    final abcItems = <ABCItem>[];
    double cumulativePercentage = 0.0;

    for (int i = 0; i < orderItemMaps.length; i++) {
      final item = orderItemMaps[i];
      final revenue = item['revenue'] as double;
      final percentage = totalRevenue > 0
          ? (revenue / totalRevenue) * 100
          : 0.0;
      cumulativePercentage += percentage;

      String category;
      if (cumulativePercentage <= 80) {
        category = 'A';
      } else if (cumulativePercentage <= 95) {
        category = 'B';
      } else {
        category = 'C';
      }

      abcItems.add(
        ABCItem(
          itemId: item['product_id'] as String,
          itemName: item['name'] as String,
          revenue: revenue,
          percentageOfTotal: percentage,
          category: category,
          rank: i + 1,
        ),
      );
    }

    final categorizedItems = <String, List<ABCItem>>{};
    for (final item in abcItems) {
      categorizedItems.putIfAbsent(item.category, () => []).add(item);
    }

    final aCategoryRevenue = abcItems
        .where((item) => item.category == 'A')
        .fold(0.0, (sum, item) => sum + item.revenue);

    final bCategoryRevenue = abcItems
        .where((item) => item.category == 'B')
        .fold(0.0, (sum, item) => sum + item.revenue);

    final cCategoryRevenue = abcItems
        .where((item) => item.category == 'C')
        .fold(0.0, (sum, item) => sum + item.revenue);

    return ABCAnalysisReport(
      id: 'abc_analysis_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      abcItems: abcItems,
      categorizedItems: categorizedItems,
      totalRevenue: totalRevenue,
      aCategoryRevenue: aCategoryRevenue,
      bCategoryRevenue: bCategoryRevenue,
      cCategoryRevenue: cCategoryRevenue,
    );
  }

  Future<DemandForecastingReport> generateDemandForecastingReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final historicalStart = period.startDate.subtract(const Duration(days: 30));

    final List<Map<String, dynamic>> historicalData = await db.rawQuery(
      '''
      SELECT DATE(o.created_at) as date, SUM(oi.quantity) as total_quantity
      FROM order_items oi
      JOIN orders o ON oi.order_id = o.id
      WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY DATE(o.created_at)
      ORDER BY date
    ''',
      [
        historicalStart.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    final forecastItems = <ForecastItem>[];
    final historicalDataMap = <String, List<double>>{};
    final forecastDataMap = <String, List<double>>{};

    for (final data in historicalData) {
      final quantity = data['total_quantity'] as double;

      final forecastQuantity = quantity * 1.05;

      forecastItems.add(
        ForecastItem(
          itemId: 'total_sales',
          itemName: 'Total Sales',
          historicalSales: [quantity],
          forecastedSales: [forecastQuantity],
          confidenceLevel: 0.8,
        ),
      );

      historicalDataMap['total'] = [quantity];
      forecastDataMap['total'] = [forecastQuantity];
    }

    return DemandForecastingReport(
      id: 'demand_forecasting_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      forecastItems: forecastItems,
      historicalData: historicalDataMap,
      forecastData: forecastDataMap,
      forecastAccuracy: 0.85,
      forecastingMethod: 'Simple Moving Average',
    );
  }

  Future<MenuEngineeringReport> generateMenuEngineeringReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> productData = await db.rawQuery(
      '''
      SELECT
        p.id,
        p.name,
        SUM(oi.quantity) as units_sold,
        SUM(oi.quantity * oi.price) as revenue,
        COUNT(DISTINCT oi.order_id) as order_count,
        (SELECT COUNT(*) FROM orders o WHERE o.created_at >= ? AND o.created_at <= ? AND o.status = ?) as total_orders
      FROM products p
      LEFT JOIN order_items oi ON p.id = oi.product_id
      LEFT JOIN orders o ON oi.order_id = o.id AND o.created_at >= ? AND o.created_at <= ? AND o.status = ?
      GROUP BY p.id, p.name
    ''',
      [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
        'completed',
      ],
    );

    final menuItems = <MenuItem>[];
    final totalOrders =
        productData.isNotEmpty ? productData.first['total_orders'] as int : 0;

    for (final product in productData) {
      final unitsSold = product['units_sold'] as int? ?? 0;
      final revenue = product['revenue'] as double? ?? 0.0;
      final orderCount = product['order_count'] as int? ?? 0;

      final popularity =
          totalOrders > 0 ? (orderCount / totalOrders) * 100 : 0.0;
      final costPrice = product['cost_price'] as double? ?? revenue * 0.3;
      final cost = costPrice * unitsSold;
      final profit = revenue - cost;
      final profitability = revenue > 0 ? (profit / revenue) * 100 : 0.0;

      String category;
      if (popularity >= 70 && profitability >= 30) {
        category = 'star';
      } else if (popularity >= 70 && profitability < 30) {
        category = 'plowhorse';
      } else if (popularity < 70 && profitability >= 30) {
        category = 'puzzle';
      } else {
        category = 'dog';
      }

      menuItems.add(
        MenuItem(
          itemId: product['id'] as String,
          itemName: product['name'] as String,
          popularity: popularity,
          profitability: profitability,
          category: category,
          unitsSold: unitsSold,
          revenue: revenue,
          cost: cost,
          profit: profit,
        ),
      );
    }

    final categorizedItems = <String, List<MenuItem>>{};
    for (final item in menuItems) {
      categorizedItems.putIfAbsent(item.category, () => []).add(item);
    }

    return MenuEngineeringReport(
      id: 'menu_engineering_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      menuItems: menuItems,
      categorizedItems: categorizedItems,
      starsCount: categorizedItems['star']?.length ?? 0,
      plowhorsesCount: categorizedItems['plowhorse']?.length ?? 0,
      puzzlesCount: categorizedItems['puzzle']?.length ?? 0,
      dogsCount: categorizedItems['dog']?.length ?? 0,
    );
  }

  Future<TablePerformanceReport> generateTablePerformanceReport(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final List<Map<String, dynamic>> tableMaps = await db.query(
      'restaurant_tables',
    );

    final tableData = <TablePerformanceData>[];
    final revenueByTable = <String, double>{};
    final occupancyByTable = <String, int>{};

    for (final tableMap in tableMaps) {
      final tableId = tableMap['id'] as String;
      final tableName = tableMap['name'] as String;
      final capacity = tableMap['capacity'] as int;

      final List<Map<String, dynamic>> orderMaps = await db.rawQuery(
        '''
        SELECT SUM(subtotal + tax) as revenue, COUNT(*) as order_count
        FROM orders
        WHERE table_id = ? AND created_at >= ? AND created_at <= ? AND status = ?
      ''',
        [
          tableId,
          period.startDate.toIso8601String(),
          period.endDate.toIso8601String(),
          'completed',
        ],
      );

      final revenue = orderMaps.isNotEmpty
          ? orderMaps.first['revenue'] as double? ?? 0.0
          : 0.0;
      final orderCount = orderMaps.isNotEmpty
          ? orderMaps.first['order_count'] as int? ?? 0
          : 0;

      final averageOccupancyTime = orderCount > 0
          ? Duration(minutes: (orderCount * 60) ~/ capacity)
          : Duration.zero;

      final revenuePerHour = averageOccupancyTime.inHours > 0
          ? revenue / averageOccupancyTime.inHours
          : 0.0;

      tableData.add(
        TablePerformanceData(
          tableId: tableId,
          tableName: tableName,
          capacity: capacity,
          totalRevenue: revenue,
          totalOrders: orderCount,
          averageOccupancyTime: averageOccupancyTime,
          revenuePerHour: revenuePerHour,
          turnoverCount: orderCount,
        ),
      );

      revenueByTable[tableName] = revenue;
      occupancyByTable[tableName] = orderCount;
    }

    final totalRevenue = tableData.fold(
      0.0,
      (sum, table) => sum + table.totalRevenue,
    );
    final totalOrders = tableData.fold(
      0,
      (sum, table) => sum + table.totalOrders,
    );
    final averageTableTurnover =
        tableData.isNotEmpty ? totalOrders / tableData.length : 0.0;
    final averageRevenuePerTable =
        tableData.isNotEmpty ? totalRevenue / tableData.length : 0.0;

    return TablePerformanceReport(
      id: 'table_performance_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      tableData: tableData,
      revenueByTable: revenueByTable,
      occupancyByTable: occupancyByTable,
      averageTableTurnover: averageTableTurnover,
      averageRevenuePerTable: averageRevenuePerTable,
      totalTables: tableMaps.length,
      occupiedTables: tableData.where((table) => table.totalOrders > 0).length,
    );
  }

  Future<BusinessSessionData> _getBusinessSessionData(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.rawQuery(
      '''
      SELECT
        SUM(total_amount) as total_sales,
        SUM(total_refunds) as total_refunds,
        SUM(total_discounts) as total_discounts,
        SUM(total_tax) as total_tax,
        SUM(total_service_charge) as total_service_charge,
        COUNT(*) as total_transactions,
        payment_method
      FROM orders
      WHERE created_at >= ? AND created_at <= ?
        AND status IN ('completed', 'refunded')
      GROUP BY payment_method
    ''',
      [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
    );

    double totalSales = 0;
    double totalRefunds = 0;
    double totalDiscounts = 0;
    double totalTax = 0;
    double totalServiceCharge = 0;
    int totalTransactions = 0;
    final paymentMethodBreakdown = <String, double>{};

    for (final row in result) {
      totalSales += (row['total_sales'] as num?)?.toDouble() ?? 0;
      totalRefunds += (row['total_refunds'] as num?)?.toDouble() ?? 0;
      totalDiscounts += (row['total_discounts'] as num?)?.toDouble() ?? 0;
      totalTax += (row['total_tax'] as num?)?.toDouble() ?? 0;
      totalServiceCharge +=
          (row['total_service_charge'] as num?)?.toDouble() ?? 0;
      totalTransactions += (row['total_transactions'] as int?) ?? 0;

      final paymentMethod = row['payment_method'] as String? ?? 'Unknown';
      final amount = (row['total_sales'] as num?)?.toDouble() ?? 0;
      paymentMethodBreakdown[paymentMethod] =
          (paymentMethodBreakdown[paymentMethod] ?? 0) + amount;
    }

    final sessionResult = await db.query(
      'business_sessions',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
      ],
      orderBy: 'start_time ASC',
      limit: 1,
    );

    final openingFloat = sessionResult.isNotEmpty
        ? (sessionResult.first['opening_float'] as num?)?.toDouble() ?? 0
        : 0;

    return BusinessSessionData(
      sessionStart: period.startDate,
      sessionEnd: period.endDate,
      openingFloat: openingFloat.toDouble(),
      totalSales: totalSales.toDouble(),
      totalRefunds: totalRefunds.toDouble(),
      totalDiscounts: totalDiscounts.toDouble(),
      totalTax: totalTax.toDouble(),
      totalServiceCharge: totalServiceCharge.toDouble(),
      totalTransactions: totalTransactions,
      paymentMethodBreakdown: paymentMethodBreakdown,
    );
  }

  Future<CashReconciliation> _getCashReconciliationData(
    ReportPeriod period,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final sessionResult = await db.query(
      'business_sessions',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [
        period.startDate.toIso8601String(),
        period.endDate.toIso8601String(),
      ],
      orderBy: 'start_time ASC',
      limit: 1,
    );

    final openingFloat = sessionResult.isNotEmpty
        ? (sessionResult.first['opening_float'] as num?)?.toDouble() ?? 0
        : 0;

    final cashResult = await db.rawQuery(
      '''
      SELECT
        SUM(CASE WHEN status = 'completed' AND payment_method = 'Cash' THEN total_amount ELSE 0 END) as cash_sales,
        SUM(CASE WHEN status = 'refunded' AND payment_method = 'Cash' THEN total_refunds ELSE 0 END) as cash_refunds
      FROM orders
      WHERE created_at >= ? AND created_at <= ?
    ''',
      [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
    );

    final cashSales =
        ((cashResult.first['cash_sales'] as num?)?.toDouble() ?? 0).toDouble();
    final cashRefunds =
        ((cashResult.first['cash_refunds'] as num?)?.toDouble() ?? 0)
            .toDouble();

    double paidOuts = 0;
    double paidIns = 0;

    try {
      final paidOutResult = await db.rawQuery(
        '''
        SELECT SUM(amount) as total_paid_outs
        FROM cash_adjustments
        WHERE type = 'paid_out' AND created_at >= ? AND created_at <= ?
      ''',
        [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
      );

      final paidInResult = await db.rawQuery(
        '''
        SELECT SUM(amount) as total_paid_ins
        FROM cash_adjustments
        WHERE type = 'paid_in' AND created_at >= ? AND created_at <= ?
      ''',
        [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
      );

      paidOuts =
          ((paidOutResult.first['total_paid_outs'] as num?)?.toDouble() ?? 0)
              .toDouble();
      paidIns =
          ((paidInResult.first['total_paid_ins'] as num?)?.toDouble() ?? 0)
              .toDouble();
    } catch (e) {
      // Tables might not exist, use 0
    }

    final expectedCash =
        openingFloat + cashSales - cashRefunds - paidOuts + paidIns;
    final actualCash = 0.0;

    return CashReconciliation(
      openingFloat: openingFloat.toDouble(),
      cashSales: cashSales.toDouble(),
      cashRefunds: cashRefunds.toDouble(),
      paidOuts: paidOuts.toDouble(),
      paidIns: paidIns.toDouble(),
      expectedCash: expectedCash.toDouble(),
      actualCash: actualCash.toDouble(),
      notes: 'Auto-calculated from transactions',
    );
  }

  Future<List<ShiftSummary>> _getShiftSummaries(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;

    try {
      final result = await db.rawQuery(
        '''
        SELECT
          u.name as employee_name,
          s.user_id,
          s.start_time,
          s.end_time,
          s.total_sales,
          s.cash_handled,
          (SELECT COUNT(*) FROM orders o WHERE o.created_at >= s.start_time AND (s.end_time IS NULL OR o.created_at <= s.end_time)) as transaction_count
        FROM shifts s
        LEFT JOIN users u ON s.user_id = u.id
        WHERE s.start_time >= ? AND s.start_time <= ?
        ORDER BY s.start_time ASC
      ''',
        [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
      );

      return result.map((row) {
        final startTime = DateTime.parse(row['start_time'] as String);
        final endTime = row['end_time'] != null
            ? DateTime.parse(row['end_time'] as String)
            : null;
        final duration =
            endTime?.difference(startTime) ??
            DateTime.now().difference(startTime);

        return ShiftSummary(
          employeeId: row['user_id'] as String? ?? '',
          employeeName: row['employee_name'] as String? ?? 'Unknown',
          shiftStart: startTime,
          shiftEnd: endTime,
          salesDuringShift: (row['total_sales'] as num?)?.toDouble() ?? 0,
          transactionsDuringShift:
              (row['transaction_count'] as num?)?.toInt() ?? 0,
          cashHandled: (row['cash_handled'] as num?)?.toDouble() ?? 0,
          shiftDuration: duration,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
