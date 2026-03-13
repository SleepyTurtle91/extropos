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
    final List<Map<String, dynamic>> orders = await db.query('orders',
        where: 'created_at BETWEEN ? AND ? AND status = ?',
        whereArgs: [period.startDate.toIso8601String(), period.endDate.toIso8601String(), 'completed']);

    double revenue = 0, cogs = 0, expenses = 0;
    for (var o in orders) {
      final sub = o['subtotal'] as double;
      revenue += sub + (o['tax'] as double) - (o['discount'] as double? ?? 0);
      cogs += sub * 0.3;
      expenses += (sub + (o['tax'] as double)) * 0.05;
    }

    final gross = revenue - cogs;
    final net = gross - expenses;

    return ProfitLossReport(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalRevenue: revenue,
      costOfGoodsSold: cogs,
      grossProfit: gross,
      operatingExpenses: expenses,
      netProfit: net,
      profitMargin: revenue > 0 ? (net / revenue) * 100 : 0,
      revenueBreakdown: {},
      expenseBreakdown: {},
      profitLossItems: [],
    );
  }

  Future<CashFlowReport> generateCashFlowReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    final orders = await db.query('orders',
        where: 'created_at BETWEEN ? AND ? AND status = ?',
        whereArgs: [period.startDate.toIso8601String(), period.endDate.toIso8601String(), 'completed']);

    double inflows = 0;
    final txs = <CashFlowTransaction>[];
    for (var o in orders) {
      final amt = (o['subtotal'] as double) + (o['tax'] as double);
      inflows += amt;
      txs.add(CashFlowTransaction(
        date: DateTime.parse(o['created_at'] as String),
        type: 'inflow',
        category: 'Sales',
        amount: amt,
        description: 'Sale',
      ));
    }

    return CashFlowReport(
      id: 'cf_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      openingCash: 1000.0,
      closingCash: 1000.0 + inflows,
      cashInflows: inflows,
      cashOutflows: 0,
      netCashFlow: inflows,
      inflowBreakdown: {},
      outflowBreakdown: {},
      transactions: txs,
    );
  }

  Future<InventoryValuationReport> generateInventoryValuationReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    final products = await db.query('products');

    double costVal = 0, retailVal = 0;
    for (var p in products) {
      final retail = p['price'] as double;
      final stock = p['stock'] as int? ?? 0;
      costVal += (p['cost_price'] as double? ?? retail * 0.7) * stock;
      retailVal += retail * stock;
    }

    return InventoryValuationReport(
      id: 'inv_val_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      totalInventoryValue: retailVal,
      totalCostValue: costVal,
      totalRetailValue: retailVal,
      valuationByCategory: {},
      valuationItems: [],
      inventoryTurnoverRatio: costVal > 0 ? retailVal / costVal : 0,
    );
  }

  Future<TablePerformanceReport> generateTablePerformanceReport(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    final tables = await db.query('restaurant_tables');

    final data = <TablePerformanceData>[];
    for (var t in tables) {
      final id = t['id'] as String;
      final res = await db.rawQuery('SELECT SUM(subtotal + tax) as rev, COUNT(*) as cnt FROM orders WHERE table_id = ? AND created_at BETWEEN ? AND ? AND status = ?',
          [id, period.startDate.toIso8601String(), period.endDate.toIso8601String(), 'completed']);
      
      final rev = (res.first['rev'] as num? ?? 0).toDouble();
      final cnt = (res.first['cnt'] as num? ?? 0).toInt();

      data.add(TablePerformanceData(
        tableId: id,
        tableName: t['name'] as String,
        capacity: t['capacity'] as int,
        totalRevenue: rev,
        totalOrders: cnt,
        averageOccupancyTime: Duration.zero,
        revenuePerHour: 0,
        turnoverCount: cnt,
      ));
    }

    return TablePerformanceReport(
      id: 'table_${DateTime.now().millisecondsSinceEpoch}',
      generatedAt: DateTime.now(),
      startDate: period.startDate,
      endDate: period.endDate,
      periodLabel: period.label,
      tableData: data,
      revenueByTable: {for (var d in data) d.tableName: d.totalRevenue},
      occupancyByTable: {for (var d in data) d.tableName: d.totalOrders},
      averageTableTurnover: data.isNotEmpty ? data.fold(0, (s, d) => s + d.totalOrders) / data.length : 0,
      averageRevenuePerTable: data.isNotEmpty ? data.fold(0.0, (s, d) => s + d.totalRevenue) / data.length : 0,
      totalTables: tables.length,
      occupiedTables: data.where((d) => d.totalOrders > 0).length,
    );
  }
}
