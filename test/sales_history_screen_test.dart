import 'package:extropos/screens/sales_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesHistoryScreen Widget Tests', () {
    testWidgets('SalesHistoryScreen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SalesHistoryScreen(),
        ),
      );

      // Wait for the screen to load (with timeout handling)
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify the screen title is displayed
      expect(find.text('Sales History'), findsOneWidget);

      // Verify search field is present
      expect(find.byType(TextField), findsOneWidget);

      // Verify date range picker button is present
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('SalesHistoryScreen search functionality', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SalesHistoryScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test customer');
      await tester.pumpAndSettle();

      // The screen should handle the search without crashing
      expect(find.text('Sales History'), findsOneWidget);
    });

    testWidgets('SalesHistoryScreen date range picker', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SalesHistoryScreen(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Tap the filter button to open date range picker
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should not crash and screen should still be visible
      expect(find.text('Sales History'), findsOneWidget);
    });
  });
}