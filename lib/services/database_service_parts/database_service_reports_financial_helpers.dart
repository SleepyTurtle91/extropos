part of '../database_service.dart';

extension DatabaseServiceReportsFinancialHelpers on DatabaseService {
  Future<BusinessSessionData> _getBusinessSessionData(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.rawQuery(
      '''
      SELECT SUM(total_amount) as total_sales, SUM(total_refunds) as total_refunds, SUM(total_discounts) as total_discounts,
      SUM(total_tax) as total_tax, SUM(total_service_charge) as total_service_charge, COUNT(*) as total_transactions, payment_method
      FROM orders WHERE created_at >= ? AND created_at <= ? AND status IN ('completed', 'refunded')
      GROUP BY payment_method
    ''',
      [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
    );

    double totalSales = 0, totalRefunds = 0, totalDiscounts = 0, totalTax = 0, totalServiceCharge = 0;
    int totalTransactions = 0;
    final paymentBreakdown = <String, double>{};

    for (final row in result) {
      totalSales += (row['total_sales'] as num?)?.toDouble() ?? 0;
      totalRefunds += (row['total_refunds'] as num?)?.toDouble() ?? 0;
      totalDiscounts += (row['total_discounts'] as num?)?.toDouble() ?? 0;
      totalTax += (row['total_tax'] as num?)?.toDouble() ?? 0;
      totalServiceCharge += (row['total_service_charge'] as num?)?.toDouble() ?? 0;
      totalTransactions += (row['total_transactions'] as int?) ?? 0;
      paymentBreakdown[row['payment_method'] as String? ?? 'Unknown'] = (row['total_sales'] as num?)?.toDouble() ?? 0;
    }

    final session = await db.query('business_sessions', where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [period.startDate.toIso8601String(), period.endDate.toIso8601String()], limit: 1);
    final openingFloat = session.isNotEmpty ? (session.first['opening_float'] as num?)?.toDouble() ?? 0 : 0;

    return BusinessSessionData(
      sessionStart: period.startDate,
      sessionEnd: period.endDate,
      openingFloat: openingFloat.toDouble(),
      totalSales: totalSales,
      totalRefunds: totalRefunds,
      totalDiscounts: totalDiscounts,
      totalTax: totalTax,
      totalServiceCharge: totalServiceCharge,
      totalTransactions: totalTransactions,
      paymentMethodBreakdown: paymentBreakdown,
    );
  }

  Future<CashReconciliation> _getCashReconciliationData(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    final session = await db.query('business_sessions', where: 'start_time >= ? AND start_time <= ?',
        whereArgs: [period.startDate.toIso8601String(), period.endDate.toIso8601String()], limit: 1);
    final openingFloat = session.isNotEmpty ? (session.first['opening_float'] as num?)?.toDouble() ?? 0 : 0;

    final cashRes = await db.rawQuery(
      '''
      SELECT SUM(CASE WHEN status = 'completed' AND payment_method = 'Cash' THEN total_amount ELSE 0 END) as cash_sales,
      SUM(CASE WHEN status = 'refunded' AND payment_method = 'Cash' THEN total_refunds ELSE 0 END) as cash_refunds
      FROM orders WHERE created_at >= ? AND created_at <= ?
    ''',
      [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
    );

    final cashSales = (cashRes.first['cash_sales'] as num? ?? 0).toDouble();
    final cashRefunds = (cashRes.first['cash_refunds'] as num? ?? 0).toDouble();
    double paidOuts = 0, paidIns = 0;

    try {
      final po = await db.rawQuery("SELECT SUM(amount) as val FROM cash_adjustments WHERE type = 'paid_out' AND created_at BETWEEN ? AND ?",
          [period.startDate.toIso8601String(), period.endDate.toIso8601String()]);
      final pi = await db.rawQuery("SELECT SUM(amount) as val FROM cash_adjustments WHERE type = 'paid_in' AND created_at BETWEEN ? AND ?",
          [period.startDate.toIso8601String(), period.endDate.toIso8601String()]);
      paidOuts = (po.first['val'] as num? ?? 0).toDouble();
      paidIns = (pi.first['val'] as num? ?? 0).toDouble();
    } catch (_) {}

    return CashReconciliation(
      openingFloat: openingFloat.toDouble(),
      cashSales: cashSales,
      cashRefunds: cashRefunds,
      paidOuts: paidOuts,
      paidIns: paidIns,
      expectedCash: openingFloat + cashSales - cashRefunds - paidOuts + paidIns,
      actualCash: 0.0,
      notes: 'Auto-calculated',
    );
  }

  Future<List<ShiftSummary>> _getShiftSummaries(ReportPeriod period) async {
    final db = await DatabaseHelper.instance.database;
    try {
      final res = await db.rawQuery(
        '''
        SELECT u.name, s.user_id, s.start_time, s.end_time, s.total_sales, s.cash_handled,
        (SELECT COUNT(*) FROM orders o WHERE o.created_at >= s.start_time AND (s.end_time IS NULL OR o.created_at <= s.end_time)) as tx_count
        FROM shifts s LEFT JOIN users u ON s.user_id = u.id WHERE s.start_time BETWEEN ? AND ?
      ''',
        [period.startDate.toIso8601String(), period.endDate.toIso8601String()],
      );

      return res.map((row) {
        final start = DateTime.parse(row['start_time'] as String);
        final end = row['end_time'] != null ? DateTime.parse(row['end_time'] as String) : null;
        return ShiftSummary(
          employeeId: row['user_id'] as String? ?? '',
          employeeName: row['name'] as String? ?? 'Unknown',
          shiftStart: start,
          shiftEnd: end,
          salesDuringShift: (row['total_sales'] as num? ?? 0).toDouble(),
          transactionsDuringShift: (row['tx_count'] as num? ?? 0).toInt(),
          cashHandled: (row['cash_handled'] as num? ?? 0).toDouble(),
          shiftDuration: end?.difference(start) ?? DateTime.now().difference(start),
        );
      }).toList();
    } catch (_) { return []; }
  }
}
