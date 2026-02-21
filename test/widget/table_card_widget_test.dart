import 'package:extropos/models/table_model.dart';
import 'package:extropos/screens/table_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('TableCard shows selection overlay when isSelected==true', (tester) async {
    final table = RestaurantTable(id: 't1', name: 'T1', capacity: 4, status: TableStatus.available);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TableCard(table: table, onTap: () {}, isSelected: true))));
    await tester.pumpAndSettle();

    // CircleAvatar with Icon check should exist
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
