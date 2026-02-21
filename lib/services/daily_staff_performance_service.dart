import 'package:extropos/services/database_helper.dart';
import 'package:flutter/foundation.dart';

/// Service for generating daily staff performance reports
class DailyStaffPerformanceService {
  static final DailyStaffPerformanceService _instance =
      DailyStaffPerformanceService._internal();
  factory DailyStaffPerformanceService() => _instance;
  static DailyStaffPerformanceService get instance => _instance;
  DailyStaffPerformanceService._internal();

  /// Generate daily staff performance report for a specific date
  Future<Map<String, dynamic>> generateDailyReport(DateTime date) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final startOfDay = DateTime(date.year, date.month, date.day);

      // Get all user activities for the day
      final activities = await db.rawQuery(
        '''
        SELECT
          ual.*,
          u.full_name,
          u.name as username
        FROM user_activity_log ual
        LEFT JOIN users u ON ual.user_id = u.id
        WHERE DATE(ual.timestamp) = DATE(?)
        ORDER BY ual.user_id, ual.timestamp
      ''',
        [startOfDay.toIso8601String()],
      );

      // Group activities by user
      final userActivities = <String, List<Map<String, dynamic>>>{};
      for (final activity in activities) {
        final userId = activity['user_id'] as String;
        userActivities.putIfAbsent(userId, () => []).add(activity);
      }

      // Process each user's data
      final staffData = <Map<String, dynamic>>[];
      double totalGrossSales = 0;
      double totalDiscounts = 0;
      double totalNetSales = 0;
      int totalTransactions = 0;
      final paymentMethodTotals = <String, double>{};
      final taxBreakdown = <double, double>{}; // tax_rate -> total_tax
      int totalVoids = 0;
      int totalOverrides = 0;
      double totalRefunds = 0;

      for (final entry in userActivities.entries) {
        final userId = entry.key;
        final userActivityList = entry.value;
        final userName =
            userActivityList.first['full_name'] as String? ?? 'Unknown';

        // Calculate login/logout times
        final signIns = userActivityList
            .where((a) => a['activity_type'] == 'sign_in')
            .toList();
        final signOuts = userActivityList
            .where((a) => a['activity_type'] == 'sign_out')
            .toList();

        final firstSignIn = signIns.isNotEmpty
            ? DateTime.parse(signIns.first['timestamp'] as String)
            : null;
        final lastSignOut = signOuts.isNotEmpty
            ? DateTime.parse(signOuts.last['timestamp'] as String)
            : null;

        // Calculate sales data
        final transactions = userActivityList
            .where((a) => a['activity_type'] == 'transaction')
            .toList();
        double grossSales = 0;
        double discounts = 0;
        double netSales = 0;
        int transactionCount = transactions.length;
        final userPaymentMethods = <String, double>{};
        final userTaxBreakdown = <double, double>{};

        for (final tx in transactions) {
          final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
          final discount = (tx['discount_amount'] as num?)?.toDouble() ?? 0;
          final taxAmount = (tx['tax_amount'] as num?)?.toDouble() ?? 0;
          final taxRate = (tx['tax_rate'] as num?)?.toDouble() ?? 0;
          final paymentMethod = tx['payment_method'] as String? ?? 'Unknown';

          grossSales += amount + discount; // Gross = net + discount
          discounts += discount;
          netSales += amount;

          userPaymentMethods[paymentMethod] =
              (userPaymentMethods[paymentMethod] ?? 0) + amount;
          userTaxBreakdown[taxRate] =
              (userTaxBreakdown[taxRate] ?? 0) + taxAmount;
        }

        // Count voids, overrides, refunds
        final voids = userActivityList
            .where((a) => a['activity_type'] == 'void')
            .length;
        final overrides = userActivityList
            .where((a) => a['activity_type'] == 'override')
            .length;
        final refunds = userActivityList
            .where((a) => a['activity_type'] == 'refund')
            .fold<double>(
              0,
              (sum, a) => sum + ((a['amount'] as num?)?.toDouble() ?? 0),
            );

        // Add to totals
        totalGrossSales += grossSales;
        totalDiscounts += discounts;
        totalNetSales += netSales;
        totalTransactions += transactionCount;
        totalVoids += voids;
        totalOverrides += overrides;
        totalRefunds += refunds;

        // Merge payment methods
        userPaymentMethods.forEach((method, amount) {
          paymentMethodTotals[method] =
              (paymentMethodTotals[method] ?? 0) + amount;
        });

        // Merge tax breakdown
        userTaxBreakdown.forEach((rate, amount) {
          taxBreakdown[rate] = (taxBreakdown[rate] ?? 0) + amount;
        });

        staffData.add({
          'userId': userId,
          'userName': userName,
          'loginTime': firstSignIn?.toIso8601String(),
          'logoutTime': lastSignOut?.toIso8601String(),
          'grossSales': grossSales,
          'discounts': discounts,
          'netSales': netSales,
          'transactionCount': transactionCount,
          'paymentMethods': userPaymentMethods,
          'taxBreakdown': userTaxBreakdown,
          'voids': voids,
          'overrides': overrides,
          'refunds': refunds,
        });
      }

      return {
        'businessDate': date.toIso8601String(),
        'staffData': staffData,
        'summary': {
          'totalGrossSales': totalGrossSales,
          'totalDiscounts': totalDiscounts,
          'totalNetSales': totalNetSales,
          'totalTransactions': totalTransactions,
          'paymentMethodTotals': paymentMethodTotals,
          'taxBreakdown': taxBreakdown,
          'totalVoids': totalVoids,
          'totalOverrides': totalOverrides,
          'totalRefunds': totalRefunds,
        },
      };
    } catch (e) {
      debugPrint('Error generating daily staff performance report: $e');
      return {'error': e.toString()};
    }
  }
}
