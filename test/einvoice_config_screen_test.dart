import 'package:extropos/screens/einvoice_config_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EInvoiceConfigScreen', () {
    testWidgets('renders config screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceConfigScreen(),
        ),
      );

      expect(find.text('E-Invoice Configuration'), findsOneWidget);
      expect(find.text('Enable E-Invoicing'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('has form fields for configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceConfigScreen(),
        ),
      );

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Client ID'), findsOneWidget);
      expect(find.text('Client Secret'), findsOneWidget);
    });

    testWidgets('has switches for settings', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceConfigScreen(),
        ),
      );

      expect(find.byType(Switch), findsWidgets);
      expect(find.text('Production Mode'), findsOneWidget);
    });

    testWidgets('has test connection button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceConfigScreen(),
        ),
      );

      final listView = find.byType(ListView);
      for (int i = 0; i < 8 && find.text('Test Connection').evaluate().isEmpty; i++) {
        await tester.drag(listView, const Offset(0, -350));
        await tester.pump();
      }

      expect(find.text('Test Connection'), findsOneWidget);
    });

    testWidgets('has scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const EInvoiceConfigScreen(),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}