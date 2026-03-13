part of '../database_service.dart';

extension DatabaseServiceReportsTax on DatabaseService {
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
      final tax = (orderMap['tax'] as num?)?.toDouble() ?? 0.0;
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
}
