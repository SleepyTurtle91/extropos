import 'package:extropos/models/analytics_models.dart';
import 'package:extropos/models/sales_report.dart';
import 'package:extropos/widgets/kpi_card.dart';
import 'package:extropos/widgets/report_date_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Modern Reports Dashboard Tests', () {
    test('SalesSummary getter aliases work correctly', () {
      final summary = SalesSummary(
        totalRevenue: 1000.0,
        totalTax: 100.0,
        totalServiceCharge: 50.0,
        totalDiscount: 25.0,
        orderCount: 10,
        itemsSold: 50,
        averageOrderValue: 100.0,
        startDate: DateTime(2025, 12, 23),
        endDate: DateTime(2025, 12, 23),
      );

      // Test getter aliases
      expect(summary.grossSales, equals(1000.0));
      expect(summary.netSales, equals(875.0)); // 1000 - 100 - 25
      expect(summary.transactionCount, equals(10));
      expect(summary.averageTransactionValue, equals(100.0));
    });

    test('ProductPerformance getter aliases work correctly', () {
      final product = ProductPerformance(
        itemId: '1',
        itemName: 'Test Product',
        categoryName: 'Test Category',
        revenue: 500.0,
        quantitySold: 10,
        orderCount: 5,
        averagePrice: 50.0,
      );

      // Test getter aliases
      expect(product.productName, equals('Test Product'));
      expect(product.unitsSold, equals(10));
    });

    test('DailySales getter aliases work correctly', () {
      final dailySales = DailySales(
        date: DateTime(2025, 12, 23),
        revenue: 1500.0,
        orderCount: 15,
      );

      // Test getter aliases
      expect(dailySales.totalSales, equals(1500.0));
      expect(dailySales.dateLabel, equals('12/23'));
    });

    test('ReportPeriod today() creates correct date range', () {
      final today = ReportPeriod.today();
      final now = DateTime.now();

      expect(today.label, equals('Today'));
      expect(today.startDate.year, equals(now.year));
      expect(today.startDate.month, equals(now.month));
      expect(today.startDate.day, equals(now.day));
      expect(today.startDate.hour, equals(0));
      expect(today.startDate.minute, equals(0));
      expect(today.endDate.hour, equals(23));
      expect(today.endDate.minute, equals(59));
    });

    test('ReportPeriod yesterday() creates correct date range', () {
      final yesterday = ReportPeriod.yesterday();
      final expectedDate = DateTime.now().subtract(const Duration(days: 1));

      expect(yesterday.label, equals('Yesterday'));
      expect(yesterday.startDate.year, equals(expectedDate.year));
      expect(yesterday.startDate.month, equals(expectedDate.month));
      expect(yesterday.startDate.day, equals(expectedDate.day));
    });

    test('ReportPeriod thisWeek() creates correct date range', () {
      final thisWeek = ReportPeriod.thisWeek();
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));

      expect(thisWeek.label, equals('This Week'));
      expect(thisWeek.startDate.day, equals(weekStart.day));
      expect(thisWeek.endDate.day, equals(now.day));
    });

    test('ReportPeriod thisMonth() creates correct date range', () {
      final thisMonth = ReportPeriod.thisMonth();
      final now = DateTime.now();

      expect(thisMonth.label, equals('This Month'));
      expect(thisMonth.startDate.day, equals(1));
      expect(thisMonth.startDate.month, equals(now.month));
      expect(thisMonth.endDate.day, equals(now.day));
    });

    testWidgets('KPICard displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KPICard(
              title: 'Test KPI',
              value: '\$1,234.56',
              icon: Icons.attach_money,
              color: Colors.green,
              isLoading: false,
            ),
          ),
        ),
      );

      expect(find.text('Test KPI'), findsOneWidget);
      expect(find.text('\$1,234.56'), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('KPICard shows loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KPICard(
              title: 'Test KPI',
              value: '\$1,234.56',
              icon: Icons.attach_money,
              color: Colors.green,
              isLoading: true,
            ),
          ),
        ),
      );

      // When loading, the value should not be visible
      expect(find.text('\$1,234.56'), findsNothing);
    });

    testWidgets('KPICardGrid creates responsive layout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KPICardGrid(
              cards: [
                KPICard(
                  title: 'KPI 1',
                  value: '\$100',
                  icon: Icons.trending_up,
                  color: Colors.blue,
                ),
                KPICard(
                  title: 'KPI 2',
                  value: '\$200',
                  icon: Icons.trending_down,
                  color: Colors.red,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('KPI 1'), findsOneWidget);
      expect(find.text('KPI 2'), findsOneWidget);
    });

    testWidgets('ReportDateSelector displays all predefined periods', (
      WidgetTester tester,
    ) async {
      // ignore: unused_local_variable
      ReportPeriod? selectedPeriod;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportDateSelector(
              selectedPeriod: ReportPeriod.today(),
              onPeriodChanged: (period) {
                selectedPeriod = period;
              },
            ),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('Last Month'), findsOneWidget);

      // Custom might be off-screen in a horizontal scrollable
      // Scroll to make it visible
      await tester.drag(find.byType(ListView), const Offset(-500, 0));
      await tester.pump();
      expect(find.text('Custom'), findsWidgets);
    });

    testWidgets('ReportDateSelector triggers callback on selection', (
      WidgetTester tester,
    ) async {
      ReportPeriod? selectedPeriod;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportDateSelector(
              selectedPeriod: ReportPeriod.today(),
              onPeriodChanged: (period) {
                selectedPeriod = period;
              },
            ),
          ),
        ),
      );

      // Tap on "Yesterday" chip
      await tester.tap(find.text('Yesterday'));
      await tester.pump();

      expect(selectedPeriod, isNotNull);
      expect(selectedPeriod!.label, equals('Yesterday'));
    });

    test('SalesSummary calculates net sales correctly', () {
      final summary = SalesSummary(
        totalRevenue: 5000.0,
        totalTax: 500.0,
        totalServiceCharge: 250.0,
        totalDiscount: 100.0,
        orderCount: 50,
        itemsSold: 150,
        averageOrderValue: 100.0,
        startDate: DateTime(2025, 12, 1),
        endDate: DateTime(2025, 12, 23),
      );

      // Net sales should be: 5000 - 500 - 100 = 4400
      expect(summary.netSales, equals(4400.0));
    });

    test('ProductPerformance averagePrice calculation is correct', () {
      final product = ProductPerformance(
        itemId: '1',
        itemName: 'Burger',
        categoryName: 'Food',
        revenue: 1000.0,
        quantitySold: 50,
        orderCount: 25,
        averagePrice: 20.0,
      );

      expect(product.averagePrice, equals(20.0));
      expect(product.revenue / product.quantitySold, equals(20.0));
    });

    test('ReportPeriod custom range works', () {
      final customPeriod = ReportPeriod(
        label: 'Custom Range',
        startDate: DateTime(2025, 12, 1),
        endDate: DateTime(2025, 12, 23),
      );

      expect(customPeriod.label, equals('Custom Range'));
      expect(customPeriod.startDate.day, equals(1));
      expect(customPeriod.endDate.day, equals(23));
    });
  });

  group('Edge Cases', () {
    test('SalesSummary with zero orders handles division by zero', () {
      final summary = SalesSummary(
        totalRevenue: 0.0,
        totalTax: 0.0,
        totalServiceCharge: 0.0,
        totalDiscount: 0.0,
        orderCount: 0,
        itemsSold: 0,
        averageOrderValue: 0.0,
        startDate: DateTime(2025, 12, 23),
        endDate: DateTime(2025, 12, 23),
      );

      expect(summary.grossSales, equals(0.0));
      expect(summary.netSales, equals(0.0));
      expect(summary.averageTransactionValue, equals(0.0));
    });

    test('ProductPerformance with zero quantity handles division by zero', () {
      final product = ProductPerformance(
        itemId: '1',
        itemName: 'Test Product',
        categoryName: 'Test Category',
        revenue: 0.0,
        quantitySold: 0,
        orderCount: 0,
        averagePrice: 0.0,
      );

      expect(product.averagePrice, equals(0.0));
    });

    test('SalesSummary with negative discount/tax', () {
      final summary = SalesSummary(
        totalRevenue: 1000.0,
        totalTax: -50.0, // Should not happen, but test defensive code
        totalServiceCharge: 0.0,
        totalDiscount: -25.0, // Should not happen
        orderCount: 10,
        itemsSold: 50,
        averageOrderValue: 100.0,
        startDate: DateTime(2025, 12, 23),
        endDate: DateTime(2025, 12, 23),
      );

      // Net sales: 1000 - (-50) - (-25) = 1075
      expect(summary.netSales, equals(1075.0));
    });
  });

  group('Performance Tests', () {
    test('Multiple SalesSummary calculations are fast', () {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        final summary = SalesSummary(
          totalRevenue: 1000.0 + i,
          totalTax: 100.0,
          totalServiceCharge: 50.0,
          totalDiscount: 25.0,
          orderCount: 10 + i,
          itemsSold: 50 + i,
          averageOrderValue: 100.0,
          startDate: DateTime(2025, 12, 23),
          endDate: DateTime(2025, 12, 23),
        );

        // Access all getters
        summary.grossSales;
        summary.netSales;
        summary.transactionCount;
        summary.averageTransactionValue;
      }

      stopwatch.stop();
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1000),
      ); // Should be very fast
    });
  });
}
