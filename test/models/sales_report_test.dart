import 'package:extropos/models/sales_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesReport Model', () {
    late SalesReport report;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
      report = SalesReport(
        id: '1',
        startDate: testDate,
        endDate: testDate.add(const Duration(days: 7)),
        reportType: 'weekly',
        grossSales: 1000.0,
        netSales: 850.0,
        taxAmount: 100.0,
        serviceChargeAmount: 50.0,
        transactionCount: 25,
        uniqueCustomers: 20,
        averageTicket: 40.0,
        averageTransactionTime: 2.5,
        topCategories: {
          'Food': 500.0,
          'Beverages': 300.0,
          'Desserts': 200.0,
        },
        paymentMethods: {
          'Cash': 600.0,
          'Card': 300.0,
          'E-wallet': 100.0,
        },
        generatedAt: testDate,
      );
    });

    test('SalesReport initialization with all fields', () {
      expect(report.id, equals('1'));
      expect(report.grossSales, equals(1000.0));
      expect(report.netSales, equals(850.0));
      expect(report.taxAmount, equals(100.0));
      expect(report.transactionCount, equals(25));
    });

    test('copyWith creates new instance with updated fields', () {
      final updated = report.copyWith(
        grossSales: 1200.0,
        transactionCount: 30,
      );

      expect(updated.grossSales, equals(1200.0));
      expect(updated.transactionCount, equals(30));
      expect(updated.id, equals(report.id)); // Unchanged
      expect(updated == report, isFalse); // Different instances
    });

    test('totalDeductions calculates correctly', () {
      expect(report.totalDeductions, equals(150.0)); // tax + service charge
    });

    test('taxPercentage calculates correctly', () {
      final percentage = (report.taxAmount / report.grossSales * 100);
      expect(report.taxPercentage, closeTo(percentage, 0.1));
    });

    test('serviceChargePercentage calculates correctly', () {
      final percentage = (report.serviceChargeAmount / report.grossSales * 100);
      expect(report.serviceChargePercentage, closeTo(percentage, 0.1));
    });

    test('discountPercentage calculates correctly', () {
      final discountAmount = report.grossSales - report.netSales;
      final percentage = (discountAmount / report.grossSales * 100);
      expect(report.discountPercentage, closeTo(percentage, 0.1));
    });

    test('totalRevenue equals netSales', () {
      expect(report.totalRevenue, equals(report.netSales));
    });

    test('topPaymentMethod returns highest payment method', () {
      expect(report.topPaymentMethod, equals('Cash'));
    });

    test('topCategory returns highest category', () {
      expect(report.topCategory, equals('Food'));
    });

    test('toMap converts model to map', () {
      final map = report.toMap();

      expect(map['id'], equals('1'));
      expect(map['grossSales'], equals(1000.0));
      expect(map['taxAmount'], equals(100.0));
      expect(map['transactionCount'], equals(25));
    });

    test('fromMap creates model from map', () {
      final map = {
        'id': '2',
        'startDate': testDate.millisecondsSinceEpoch,
        'endDate': testDate.add(const Duration(days: 7)).millisecondsSinceEpoch,
        'reportType': 'daily',
        'grossSales': 500.0,
        'netSales': 450.0,
        'taxAmount': 50.0,
        'serviceChargeAmount': 25.0,
        'transactionCount': 10,
        'uniqueCustomers': 8,
        'averageTicket': 50.0,
        'averageTransactionTime': 3.0,
        'topCategories': '{"Category1": 300.0, "Category2": 150.0}',
        'paymentMethods': '{"Cash": 350.0, "Card": 100.0}',
        'generatedAt': testDate.millisecondsSinceEpoch,
      };

      final created = SalesReport.fromMap(map);

      expect(created.id, equals('2'));
      expect(created.grossSales, equals(500.0));
      expect(created.transactionCount, equals(10));
    });

    test('toJson converts model to JSON', () {
      final json = report.toJson();

      expect(json['id'], equals('1'));
      expect(json['grossSales'], equals(1000.0));
      expect(json['reportType'], equals('weekly'));
    });

    test('fromJson creates model from JSON', () {
      final json = {
        'id': '3',
        'startDate': testDate.toIso8601String(),
        'endDate': testDate.add(const Duration(days: 30)).toIso8601String(),
        'reportType': 'monthly',
        'grossSales': 5000.0,
        'netSales': 4500.0,
        'taxAmount': 500.0,
        'serviceChargeAmount': 250.0,
        'transactionCount': 100,
        'uniqueCustomers': 80,
        'averageTicket': 50.0,
        'averageTransactionTime': 2.5,
        'topCategories': {
          'Pizza': 2500.0,
          'Pasta': 1500.0,
          'Drinks': 500.0,
        },
        'paymentMethods': {
          'Cash': 3000.0,
          'Card': 1500.0,
          'E-wallet': 500.0,
        },
        'generatedAt': testDate.toIso8601String(),
      };

      final created = SalesReport.fromJson(json);

      expect(created.id, equals('3'));
      expect(created.grossSales, equals(5000.0));
      expect(created.reportType, equals('monthly'));
    });

    group('Edge Cases', () {
      test('handles zero gross sales', () {
        final zeroReport = report.copyWith(grossSales: 0.0);
        expect(zeroReport.taxPercentage, isNotNaN);
      });

      test('handles zero customers', () {
        final noCustomers = report.copyWith(uniqueCustomers: 0);
        expect(noCustomers.averageTicket, equals(40.0)); // Still has average
      });

      test('handles empty payment methods map', () {
        final emptyPayments = report.copyWith(paymentMethods: {});
        expect(emptyPayments.topPaymentMethod, isNull);
      });

      test('handles empty categories map', () {
        final emptyCategories = report.copyWith(topCategories: {});
        expect(emptyCategories.topCategory, isNull);
      });

      test('handles negative net sales (refunds)', () {
        final withRefund = report.copyWith(netSales: -50.0);
        expect(withRefund.netSales, equals(-50.0));
        expect(withRefund.discountPercentage, isNotNaN);
      });
    });

    group('Date Handling', () {
      test('calculates date range correctly', () {
        final duration = report.endDate.difference(report.startDate);
        expect(duration.inDays, equals(7));
      });

      test('handles single-day report', () {
        final dailyReport = report.copyWith(
          endDate: report.startDate,
          reportType: 'daily',
        );
        final duration = dailyReport.endDate.difference(dailyReport.startDate);
        expect(duration.inDays, equals(0));
      });

      test('handles month-long report', () {
        final monthlyReport = report.copyWith(
          endDate: report.startDate.add(const Duration(days: 30)),
          reportType: 'monthly',
        );
        final duration = monthlyReport.endDate.difference(monthlyReport.startDate);
        expect(duration.inDays, greaterThan(29));
      });
    });

    group('Calculation Accuracy', () {
      test('gross = net + deductions + tax + service charge (approximately)', () {
        final calculated = report.netSales + report.taxAmount + report.serviceChargeAmount;
        expect(report.grossSales, greaterThanOrEqualTo(calculated - 1)); // Allow 1 rounding error
      });

      test('average ticket = gross sales / transaction count', () {
        final expected = report.grossSales / report.transactionCount;
        expect(report.averageTicket, closeTo(expected, 1.0));
      });

      test('total deductions = tax + service charge', () {
        final expected = report.taxAmount + report.serviceChargeAmount;
        expect(report.totalDeductions, closeTo(expected, 0.1));
      });
    });

    group('Serialization Round-trip', () {
      test('map serialization maintains data integrity', () {
        final original = report;
        final map = original.toMap();
        final restored = SalesReport.fromMap(map);

        expect(restored.id, equals(original.id));
        expect(restored.grossSales, equals(original.grossSales));
        expect(restored.netSales, equals(original.netSales));
        expect(restored.transactionCount, equals(original.transactionCount));
      });

      test('JSON serialization maintains data integrity', () {
        final original = report;
        final json = original.toJson();
        final restored = SalesReport.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.grossSales, equals(original.grossSales));
        expect(restored.reportType, equals(original.reportType));
      });
    });

    group('Report Type Validation', () {
      test('accepts daily report type', () {
        final daily = report.copyWith(reportType: 'daily');
        expect(daily.reportType, equals('daily'));
      });

      test('accepts weekly report type', () {
        final weekly = report.copyWith(reportType: 'weekly');
        expect(weekly.reportType, equals('weekly'));
      });

      test('accepts monthly report type', () {
        final monthly = report.copyWith(reportType: 'monthly');
        expect(monthly.reportType, equals('monthly'));
      });

      test('accepts custom report type', () {
        final custom = report.copyWith(reportType: 'custom');
        expect(custom.reportType, equals('custom'));
      });
    });

    group('Category and Payment Distribution', () {
      test('top categories sorted correctly', () {
        final report1 = SalesReport(
          id: '1',
          startDate: testDate,
          endDate: testDate,
          reportType: 'daily',
          grossSales: 1000.0,
          netSales: 1000.0,
          taxAmount: 0.0,
          serviceChargeAmount: 0.0,
          transactionCount: 10,
          uniqueCustomers: 5,
          averageTicket: 100.0,
          averageTransactionTime: 1.0,
          topCategories: {
            'C': 100.0,
            'A': 600.0,
            'B': 300.0,
          },
          paymentMethods: {'Cash': 1000.0},
          generatedAt: testDate,
        );

        expect(report1.topCategory, equals('A')); // Highest value
      });

      test('top payment method sorted correctly', () {
        final report1 = SalesReport(
          id: '1',
          startDate: testDate,
          endDate: testDate,
          reportType: 'daily',
          grossSales: 1000.0,
          netSales: 1000.0,
          taxAmount: 0.0,
          serviceChargeAmount: 0.0,
          transactionCount: 10,
          uniqueCustomers: 5,
          averageTicket: 100.0,
          averageTransactionTime: 1.0,
          topCategories: {'Food': 1000.0},
          paymentMethods: {
            'E-wallet': 200.0,
            'Card': 500.0,
            'Cash': 300.0,
          },
          generatedAt: testDate,
        );

        expect(report1.topPaymentMethod, equals('Card')); // Highest value
      });
    });
  });
}
