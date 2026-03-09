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
      expect(find.text('Pending Orders'), findsOneWidget);
      expect(find.text('Submit Selected'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceSubmissionScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows warning when no orders selected', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceSubmissionScreen(),
        ),
      );

      await tester.tap(find.text('Submit Selected'));
      await tester.pump();

      expect(find.text('Please select orders to submit'), findsOneWidget);
    });

    testWidgets('has order list view', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceSubmissionScreen(),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}