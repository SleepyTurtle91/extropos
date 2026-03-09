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

      // Wait for loading to complete
      await tester.pumpAndSettle();

      expect(find.text('System Maintenance'), findsOneWidget);
      expect(find.text('System Information'), findsOneWidget);
      expect(find.text('Maintenance Actions'), findsOneWidget);
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

      await tester.pumpAndSettle();

      expect(find.text('Clear Cache'), findsOneWidget);
      expect(find.text('Optimize Database'), findsOneWidget);
      expect(find.text('Export Logs'), findsOneWidget);
    });

    testWidgets('has action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('shows confirmation dialog for destructive actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Settings'));
      await tester.pump();

      expect(find.text('Reset Settings'), findsOneWidget);
      expect(find.text('This will reset all user settings to defaults'), findsOneWidget);
    });

    testWidgets('has scrollable content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const MaintenanceScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}