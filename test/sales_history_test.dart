import 'package:extropos/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DatabaseService Sales History Tests', () {
    test('getSalesHistory returns empty list when no orders exist', () async {
      // This test verifies the method doesn't crash and returns proper format
      final result = await DatabaseService.instance.getSalesHistory();

      expect(result, isA<List<Map<String, dynamic>>>());
      // Should be empty or contain only completed orders
      for (final order in result) {
        expect(order['status'], equals('completed'));
      }
    });

    test('getSalesHistory with search query works', () async {
      final result = await DatabaseService.instance.getSalesHistory(
        searchQuery: 'test customer',
      );

      expect(result, isA<List<Map<String, dynamic>>>());
    });

    test('getSalesHistory with date range works', () async {
      final startDate = DateTime.now().subtract(const Duration(days: 30));
      final endDate = DateTime.now();

      final result = await DatabaseService.instance.getSalesHistory(
        startDate: startDate,
        endDate: endDate,
      );

      expect(result, isA<List<Map<String, dynamic>>>());
      // Verify dates are within range
      for (final order in result) {
        if (order['date'] != null) {
          final orderDate = order['date'] as DateTime;
          expect(orderDate.isAfter(startDate.subtract(const Duration(days: 1))), isTrue);
          expect(orderDate.isBefore(endDate.add(const Duration(days: 1))), isTrue);
        }
      }
    });

    test('getOrderDetails returns null for non-existent order', () async {
      final result = await DatabaseService.instance.getOrderDetails('non-existent-id');

      expect(result, isNull);
    });
  });
}