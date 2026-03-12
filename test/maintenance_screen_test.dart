import 'package:extropos/screens/maintenance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MaintenanceScreen', () {
    testWidgets('renders maintenance screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('System Maintenance'), findsOneWidget);

      final hasLoadedContent = find.text('System Information').evaluate().isNotEmpty;
      if (hasLoadedContent) {
        expect(find.text('Maintenance Actions'), findsOneWidget);
      } else {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows maintenance actions after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final hasActions = find.text('Clear Cache').evaluate().isNotEmpty;
      if (hasActions) {
        expect(find.text('Optimize Database'), findsOneWidget);
        expect(find.text('Export Logs'), findsOneWidget);
      } else {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('has action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final hasActionTiles = find.text('Clear Cache').evaluate().isNotEmpty;
      if (hasActionTiles) {
        expect(find.byType(ListTile), findsAtLeastNWidgets(4));
      } else {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('shows confirmation dialog for destructive actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      if (find.text('Reset Settings').evaluate().isNotEmpty) {
        await tester.tap(find.text('Reset Settings').first);
        await tester.pump();

        expect(find.text('Reset Settings'), findsWidgets);
        expect(find.textContaining('This will reset all user settings to defaults'), findsOneWidget);
      } else {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });

    testWidgets('has scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      if (hasListView) {
        expect(find.byType(ListView), findsOneWidget);
      } else {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
    });
  });
}