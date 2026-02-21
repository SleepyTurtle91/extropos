import 'package:extropos/models/sales_report.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:intl/intl.dart';

/// Singleton service for generating and managing sales reports
class ReportsService {
  static final ReportsService _instance = ReportsService._internal();

  factory ReportsService() => _instance;

  ReportsService._internal();

  static ReportsService get instance => _instance;

  /// Generate daily sales report
  Future<SalesReport> generateDailyReport(DateTime date) async {
    try {
      final startDate = DateTime(date.year, date.month, date.day);
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final db = await DatabaseHelper.instance.database;

      // Fetch transactions for the day
      final transactions = await db.query(
        'transactions',
        where: 'transaction_date >= ? AND transaction_date <= ?',
        whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      );

      if (transactions.isEmpty) {
        return _createEmptyReport(startDate, endDate, 'daily');
      }

      double grossSales = 0;
      double netSales = 0;
      double taxAmount = 0;
      double serviceChargeAmount = 0;
      final Set<String> uniqueCustomers = {};
      final Map<String, double> categoryRevenue = {};
      final Map<String, double> paymentMethods = {};

      for (final tx in transactions) {
        final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0;
        final tax = (tx['tax_amount'] as num?)?.toDouble() ?? 0;
        final serviceCharge = (tx['service_charge_amount'] as num?)?.toDouble() ?? 0;
        final customerId = tx['customer_id'] as String?;
        final paymentMethod = tx['payment_method'] as String? ?? 'Cash';

        grossSales += amount + tax + serviceCharge;
        netSales += amount;
        taxAmount += tax;
        serviceChargeAmount += serviceCharge;

        if (customerId != null) uniqueCustomers.add(customerId);

        // Track payment methods
        paymentMethods.update(paymentMethod, (v) => v + amount, ifAbsent: () => amount);

        // Parse items JSON for category breakdown (simplified)
        final category = tx['business_mode'] as String? ?? 'General';
        categoryRevenue.update(category, (v) => v + amount, ifAbsent: () => amount);
      }

      final avgTicket = transactions.isNotEmpty ? netSales / transactions.length : 0;

      return SalesReport(
        id: 'report_${startDate.millisecondsSinceEpoch}',
        startDate: startDate,
        endDate: endDate,
        reportType: 'daily',
        grossSales: grossSales,
        netSales: netSales,
        taxAmount: taxAmount,
        serviceChargeAmount: serviceChargeAmount,
        transactionCount: transactions.length,
        uniqueCustomers: uniqueCustomers.length,
        averageTicket: avgTicket.toDouble(),
        averageTransactionTime: 0, // Would need timestamp data
        topCategories: _sortMapByValue(categoryRevenue).cast<String, double>(),
        paymentMethods: _sortMapByValue(paymentMethods).cast<String, double>(),
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error generating daily report: $e');
      rethrow;
    }
  }

  /// Generate weekly sales report
  Future<SalesReport> generateWeeklyReport(DateTime date) async {
    try {
      final weekday = date.weekday;
      final startDate = date.subtract(Duration(days: weekday - 1));
      final endDate = date.add(Duration(days: 7 - weekday));

      final db = await DatabaseHelper.instance.database;

      final transactions = await db.query(
        'transactions',
        where: 'transaction_date >= ? AND transaction_date <= ?',
        whereArgs: [
          DateTime(startDate.year, startDate.month, startDate.day).millisecondsSinceEpoch,
          DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59).millisecondsSinceEpoch,
        ],
      );

      if (transactions.isEmpty) {
        return _createEmptyReport(startDate, endDate, 'weekly');
      }

      double grossSales = 0;
      double netSales = 0;
      double taxAmount = 0;
      double serviceChargeAmount = 0;
      final Set<String> uniqueCustomers = {};
      final Map<String, double> categoryRevenue = {};
      final Map<String, double> paymentMethods = {};

      for (final tx in transactions) {
        final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0;
        final tax = (tx['tax_amount'] as num?)?.toDouble() ?? 0;
        final serviceCharge = (tx['service_charge_amount'] as num?)?.toDouble() ?? 0;
        final customerId = tx['customer_id'] as String?;
        final paymentMethod = tx['payment_method'] as String? ?? 'Cash';

        grossSales += amount + tax + serviceCharge;
        netSales += amount;
        taxAmount += tax;
        serviceChargeAmount += serviceCharge;

        if (customerId != null) uniqueCustomers.add(customerId);

        paymentMethods.update(paymentMethod, (v) => v + amount, ifAbsent: () => amount);
        final category = tx['business_mode'] as String? ?? 'General';
        categoryRevenue.update(category, (v) => v + amount, ifAbsent: () => amount);
      }

      final avgTicket = transactions.isNotEmpty ? netSales / transactions.length : 0;

      return SalesReport(
        id: 'report_${startDate.millisecondsSinceEpoch}',
        startDate: startDate,
        endDate: endDate,
        reportType: 'weekly',
        grossSales: grossSales,
        netSales: netSales,
        taxAmount: taxAmount,
        serviceChargeAmount: serviceChargeAmount,
        transactionCount: transactions.length,
        uniqueCustomers: uniqueCustomers.length,
        averageTicket: avgTicket.toDouble(),
        averageTransactionTime: 0,
        topCategories: _sortMapByValue(categoryRevenue).cast<String, double>(),
        paymentMethods: _sortMapByValue(paymentMethods).cast<String, double>(),
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error generating weekly report: $e');
      rethrow;
    }
  }

  /// Generate monthly sales report
  Future<SalesReport> generateMonthlyReport(DateTime date) async {
    try {
      final startDate = DateTime(date.year, date.month, 1);
      final endDate = DateTime(date.year, date.month + 1, 0, 23, 59, 59);

      final db = await DatabaseHelper.instance.database;

      final transactions = await db.query(
        'transactions',
        where: 'transaction_date >= ? AND transaction_date <= ?',
        whereArgs: [startDate.millisecondsSinceEpoch, endDate.millisecondsSinceEpoch],
      );

      if (transactions.isEmpty) {
        return _createEmptyReport(startDate, endDate, 'monthly');
      }

      double grossSales = 0;
      double netSales = 0;
      double taxAmount = 0;
      double serviceChargeAmount = 0;
      final Set<String> uniqueCustomers = {};
      final Map<String, double> categoryRevenue = {};
      final Map<String, double> paymentMethods = {};

      for (final tx in transactions) {
        final amount = (tx['total_amount'] as num?)?.toDouble() ?? 0;
        final tax = (tx['tax_amount'] as num?)?.toDouble() ?? 0;
        final serviceCharge = (tx['service_charge_amount'] as num?)?.toDouble() ?? 0;
        final customerId = tx['customer_id'] as String?;
        final paymentMethod = tx['payment_method'] as String? ?? 'Cash';

        grossSales += amount + tax + serviceCharge;
        netSales += amount;
        taxAmount += tax;
        serviceChargeAmount += serviceCharge;

        if (customerId != null) uniqueCustomers.add(customerId);

        paymentMethods.update(paymentMethod, (v) => v + amount, ifAbsent: () => amount);
        final category = tx['business_mode'] as String? ?? 'General';
        categoryRevenue.update(category, (v) => v + amount, ifAbsent: () => amount);
      }

      final avgTicket = transactions.isNotEmpty ? netSales / transactions.length : 0;

      return SalesReport(
        id: 'report_${startDate.millisecondsSinceEpoch}',
        startDate: startDate,
        endDate: endDate,
        reportType: 'monthly',
        grossSales: grossSales,
        netSales: netSales,
        taxAmount: taxAmount,
        serviceChargeAmount: serviceChargeAmount,
        transactionCount: transactions.length,
        uniqueCustomers: uniqueCustomers.length,
        averageTicket: avgTicket.toDouble(),
        averageTransactionTime: 0,
        topCategories: _sortMapByValue(categoryRevenue).cast<String, double>(),
        paymentMethods: _sortMapByValue(paymentMethods).cast<String, double>(),
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Error generating monthly report: $e');
      rethrow;
    }
  }

  /// Get sales data for trend analysis
  Future<List<SalesReport>> getDailySalesForDateRange(DateTime start, DateTime end) async {
    try {
      final reports = <SalesReport>[];
      var current = start;

      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final report = await generateDailyReport(current);
        reports.add(report);
        current = current.add(const Duration(days: 1));
      }

      return reports;
    } catch (e) {
      print('❌ Error getting sales trend: $e');
      rethrow;
    }
  }

  /// Helper: Sort map by value descending
  Map<String, dynamic> _sortMapByValue(Map<String, double> map) {
    final sorted = map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Helper: Create empty report
  SalesReport _createEmptyReport(DateTime start, DateTime end, String type) {
    return SalesReport(
      id: 'report_empty_${start.millisecondsSinceEpoch}',
      startDate: start,
      endDate: end,
      reportType: type,
      grossSales: 0,
      netSales: 0,
      taxAmount: 0,
      serviceChargeAmount: 0,
      transactionCount: 0,
      uniqueCustomers: 0,
      averageTicket: 0,
      averageTransactionTime: 0,
      topCategories: {},
      paymentMethods: {},
      generatedAt: DateTime.now(),
    );
  }

  /// Get report statistics
  Map<String, dynamic> getReportStats(SalesReport report) {
    return {
      'period': '${DateFormat('MMM d').format(report.startDate)} - ${DateFormat('MMM d').format(report.endDate)}',
      'grossSales': report.grossSales,
      'netSales': report.netSales,
      'tax': report.taxAmount,
      'serviceCharge': report.serviceChargeAmount,
      'transactions': report.transactionCount,
      'customers': report.uniqueCustomers,
      'avgTicket': report.averageTicket,
      'topCategory': report.topCategory ?? 'N/A',
      'topPayment': report.topPaymentMethod ?? 'N/A',
    };
  }
}
