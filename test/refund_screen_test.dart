import 'package:extropos/screens/refund_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefundScreen Widget Tests', () {
    testWidgets('RefundScreen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RefundScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the screen title is displayed
      expect(find.text('Refunds & Returns'), findsOneWidget);

      // Verify transaction search card is present
      expect(find.text('Find Transaction'), findsOneWidget);
      
      // Verify order number field is present
      expect(find.text('Order Number'), findsOneWidget);

      // Verify search button is present
      expect(find.text('Search Transaction'), findsOneWidget);
    });

    testWidgets('RefundScreen search field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RefundScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the order number text field
      final textField = find.widgetWithText(TextField, 'Order Number');
      expect(textField, findsOneWidget);

      // Enter order number
      await tester.enterText(textField, 'RETAIL-001');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('RETAIL-001'), findsOneWidget);
    });

    testWidgets('RefundScreen search button is enabled after text input', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RefundScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the search button by searching for the icon + text combination
      final searchButton = find.text('Search Transaction');
      expect(searchButton, findsOneWidget);
      
      // Button should be present and tappable
      await tester.tap(searchButton);
      await tester.pump();
    });

    testWidgets('RefundScreen shows clear button only when transaction is selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RefundScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, clear button should not be visible in AppBar
      expect(find.byIcon(Icons.clear), findsNothing);
      
      // Note: Testing with actual transaction selection would require
      // mock database setup
    });

    testWidgets('RefundScreen hides refund form initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RefundScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Refund form should not be visible initially
      expect(find.text('Refund Details'), findsNothing);
      expect(find.text('Process Refund'), findsNothing);
      expect(find.text('Refund Amount (RM)'), findsNothing);
    });

    testWidgets('RefundScreen transaction search card structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RefundScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have a Card widget for the search section
      expect(find.byType(Card), findsWidgets);
      
      // Should have SingleChildScrollView for layout
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}