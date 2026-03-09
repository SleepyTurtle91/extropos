import 'package:extropos/screens/my_invois_queue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyInvoisQueueScreen', () {
    testWidgets('renders queue screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisQueueScreen(),
        ),
      );

      // Screen title should be in the AppBar
      expect(find.text('MyInvois Queue'), findsOneWidget);
      
      // Refresh icon should be in the AppBar actions
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisQueueScreen(),
        ),
      );

      // Should show loading indicator during initial load
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows status summary section immediately', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisQueueScreen(),
        ),
      );

      // Need at least one pump to render the widget tree
      await tester.pump();

      // Status summary should be visible with configuration status
      // The text is case-sensitive and uses "e-invoice" or "E-Invoice"
      final hasEInvoice = find.textContaining('e-invoice', findRichText: true).evaluate().isNotEmpty ||
                          find.textContaining('E-Invoice', findRichText: true).evaluate().isNotEmpty ||
                          find.textContaining('not configured', findRichText: true).evaluate().isNotEmpty;
      
      expect(hasEInvoice, isTrue, reason: 'Status summary should contain e-invoice related text');
    });

    testWidgets('shows loading indicator or content after pump', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisQueueScreen(),
        ),
      );

      // Initially or after brief pump: either loading or loaded state
      await tester.pump(const Duration(milliseconds: 100));
      
      // Should find EITHER loading indicator OR empty state OR invoices list
      final hasLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
      final hasEmptyState = find.text('No submitted e-invoices found').evaluate().isNotEmpty;
      final hasRefreshIndicator = find.byType(RefreshIndicator).evaluate().isNotEmpty;
      
      // At least one of these should be true
      expect(hasLoading || hasEmptyState || hasRefreshIndicator, isTrue,
        reason: 'Screen should show loading, empty state, or invoice list');
    });
  });
}