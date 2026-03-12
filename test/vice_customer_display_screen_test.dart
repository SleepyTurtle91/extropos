import 'package:extropos/screens/vice_customer_display_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViceCustomerDisplayScreen', () {
    testWidgets('renders display screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ViceCustomerDisplayScreen(),
        ),
      );

      expect(find.text('Customer Display'), findsOneWidget);
      expect(find.byTooltip('Discover Displays'), findsOneWidget);
      expect(find.byTooltip('Refresh'), findsOneWidget);
    });

    testWidgets('shows loading or empty state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ViceCustomerDisplayScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));

      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasEmptyState = find.text('No customer displays found').evaluate().isNotEmpty;
      final hasList = find.byType(ListView).evaluate().isNotEmpty;

      expect(hasLoading || hasEmptyState || hasList, isTrue);
    });

    testWidgets('has discover displays button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ViceCustomerDisplayScreen(),
        ),
      );

      expect(find.byTooltip('Discover Displays'), findsOneWidget);
    });
  });
}