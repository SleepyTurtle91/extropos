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

      expect(find.text('Customer Display Management'), findsOneWidget);
      expect(find.text('Available Displays'), findsOneWidget);
      expect(find.text('Display Controls'), findsOneWidget);
    });

    testWidgets('shows test message dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ViceCustomerDisplayScreen(),
        ),
      );

      // Tap the test message button (assuming it exists)
      final testButton = find.byType(ElevatedButton).first;
      await tester.tap(testButton);
      await tester.pump();

      expect(find.text('Test Message'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('has discover displays button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ViceCustomerDisplayScreen(),
        ),
      );

      expect(find.text('Discover Displays'), findsOneWidget);
    });
  });
}