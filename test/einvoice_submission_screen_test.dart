import 'package:extropos/screens/einvoice_submission_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EInvoiceSubmissionScreen', () {
    testWidgets('renders submission screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceSubmissionScreen(),
        ),
      );

      expect(find.text('E-Invoice Submission'), findsOneWidget);

      final hasExpectedBody =
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('No pending orders to submit').evaluate().isNotEmpty ||
          find.byType(CheckboxListTile).evaluate().isNotEmpty;
      expect(hasExpectedBody, isTrue);
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceSubmissionScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('hides submit button when no orders are selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceSubmissionScreen(),
        ),
      );

      expect(find.textContaining('Submit '), findsNothing);
    });

    testWidgets('shows order area states', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceSubmissionScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      final hasList = find.byType(ListView).evaluate().isNotEmpty;
      final hasEmptyState = find.text('No pending orders to submit').evaluate().isNotEmpty;
      final isLoading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

      expect(hasList || hasEmptyState || isLoading, isTrue);
    });
  });
}