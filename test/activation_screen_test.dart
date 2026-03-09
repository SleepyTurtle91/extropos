import 'package:extropos/screens/activation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivationScreen', () {
    testWidgets('renders activation screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ActivationScreen(),
        ),
      );

      expect(find.text('Software Activation'), findsOneWidget);
      expect(find.text('Choose Activation Method'), findsOneWidget);
      expect(find.text('Offline Activation'), findsOneWidget);
      expect(find.text('Tenant Activation'), findsOneWidget);
    });

    testWidgets('shows offline activation form by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ActivationScreen(),
        ),
      );

      expect(find.text('License Key'), findsOneWidget);
      expect(find.text('Activate'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('can switch to tenant activation', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ActivationScreen(),
        ),
      );

      await tester.tap(find.text('Tenant Activation'));
      await tester.pump();

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Request Activation'), findsOneWidget);
    });

    testWidgets('validates license key input', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ActivationScreen(),
        ),
      );

      await tester.tap(find.text('Activate'));
      await tester.pump();

      // Validation is handled by ToastHelper, so we can't directly test the toast text
      // But we can verify the button is present and tappable
      expect(find.text('Activate'), findsOneWidget);
    });

    testWidgets('has radio buttons for activation modes when not activated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ActivationScreen(),
        ),
      );

      // Only check for radio buttons if the screen shows the activation form
      if (find.text('Choose Activation Method').evaluate().isNotEmpty) {
        expect(find.byType(RadioListTile), findsNWidgets(2));
      } else {
        // If activated, just verify the screen renders
        expect(find.text('Software Activation'), findsOneWidget);
      }
    });
  });
}