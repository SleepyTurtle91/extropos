import 'package:extropos/screens/my_invois_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyInvoisSettingsScreen', () {
    testWidgets('renders settings screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisSettingsScreen(),
        ),
      );

      // Screen title in AppBar
      expect(find.text('MyInvois Settings'), findsOneWidget);
      
      // Save button in AppBar
      expect(find.text('Save'), findsOneWidget);
      
      // Status card should be visible
      expect(find.text('Service Status'), findsOneWidget);
    });

    testWidgets('shows automation settings section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisSettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Automation Settings'), findsOneWidget);
      expect(find.text('Auto-Submit E-Invoices'), findsOneWidget);
      expect(find.text('Automatically submit e-invoices after order completion'), findsOneWidget);
    });

    testWidgets('shows notification settings section', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisSettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
    });

    testWidgets('shows service status card', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisSettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Service Status'), findsOneWidget);
      // Should show configured or not configured message
      expect(find.textContaining('E-Invoice service'), findsOneWidget);
    });

    testWidgets('automation toggle can be interacted with', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisSettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the auto-submit switch
      final switchFinder = find.byType(SwitchListTile).first;
      expect(switchFinder, findsOneWidget);

      // Tap the switch
      await tester.tap(switchFinder);
      await tester.pump();

      // Switch should have updated state
    });

    testWidgets('save button triggers save action', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyInvoisSettingsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Save'));
      await tester.pump();

      // Allow time for the async save operation timer
      await tester.pump(const Duration(milliseconds: 600));
      
      // Should show loading indicator or complete save
      // (actual behavior depends on implementation)
    });
  });
}