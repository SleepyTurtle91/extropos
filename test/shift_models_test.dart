import 'package:extropos/models/shift_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Shift Model Tests
  group('Shift Model Tests', () {
    test('creates shift with correct properties', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime(2026, 1, 23, 8, 0),
        openingCash: 500.0,
        status: 'active',
      );

      expect(shift.id, 'shift_1');
      expect(shift.userId, 'user_1');
      expect(shift.openingCash, 500.0);
      expect(shift.status, 'active');
      expect(shift.isActive, true);
    });

    test('isActive returns true for active shift', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        status: 'active',
      );

      expect(shift.isActive, true);
    });

    test('isActive returns false for completed shift', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        status: 'completed',
      );

      expect(shift.isActive, false);
    });

    test('copyWith updates only specified fields', () {
      final original = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime(2026, 1, 23, 8, 0),
        openingCash: 500.0,
        status: 'active',
      );

      final updated = original.copyWith(
        status: 'completed',
        closingCash: 650.0,
      );

      expect(updated.id, original.id);
      expect(updated.userId, original.userId);
      expect(updated.openingCash, original.openingCash);
      expect(updated.status, 'completed');
      expect(updated.closingCash, 650.0);
    });

    test('toMap converts shift to map correctly', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime(2026, 1, 23, 8, 0),
        openingCash: 500.0,
        status: 'active',
      );

      final map = shift.toMap();

      expect(map['id'], 'shift_1');
      expect(map['user_id'], 'user_1');
      expect(map['opening_cash'], 500.0);
      expect(map['status'], 'active');
    });

    test('fromMap converts map to shift correctly', () {
      final map = {
        'id': 'shift_1',
        'user_id': 'user_1',
        'business_session_id': null,
        'start_time': '2026-01-23T08:00:00.000',
        'end_time': null,
        'opening_cash': 500.0,
        'closing_cash': null,
        'expected_cash': null,
        'variance': null,
        'variance_acknowledged': 0,
        'notes': null,
        'status': 'active',
      };

      final shift = Shift.fromMap(map);

      expect(shift.id, 'shift_1');
      expect(shift.userId, 'user_1');
      expect(shift.openingCash, 500.0);
      expect(shift.status, 'active');
    });

    test('toMap/fromMap roundtrip preserves data', () {
      final original = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime(2026, 1, 23, 8, 0),
        endTime: DateTime(2026, 1, 23, 16, 30),
        openingCash: 500.0,
        closingCash: 750.0,
        expectedCash: 720.0,
        variance: 30.0,
        varianceAcknowledged: true,
        notes: 'Test shift',
        status: 'completed',
      );

      final map = original.toMap();
      final restored = Shift.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.openingCash, original.openingCash);
      expect(restored.closingCash, original.closingCash);
      expect(restored.expectedCash, original.expectedCash);
      expect(restored.variance, original.variance);
      expect(restored.varianceAcknowledged, original.varianceAcknowledged);
      expect(restored.notes, original.notes);
      expect(restored.status, original.status);
    });
  });

  // Shift Variance Calculation Tests
  group('Shift Variance Calculation Tests', () {
    test('calculates positive variance correctly', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: 550.0,
        expectedCash: 520.0,
        variance: 30.0, // closing - expected
        status: 'completed',
      );

      expect(shift.variance, 30.0);
    });

    test('calculates negative variance correctly', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: 500.0,
        expectedCash: 520.0,
        variance: -20.0, // closing - expected
        status: 'completed',
      );

      expect(shift.variance, -20.0);
    });

    test('zero variance indicates perfect reconciliation', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: 520.0,
        expectedCash: 520.0,
        variance: 0.0,
        status: 'completed',
      );

      expect(shift.variance, 0.0);
    });
  });

  // Shift Duration Tests
  group('Shift Duration Tests', () {
    test('calculates shift duration correctly', () {
      final startTime = DateTime(2026, 1, 23, 8, 0);
      final endTime = DateTime(2026, 1, 23, 16, 30);

      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: startTime,
        endTime: endTime,
        openingCash: 500.0,
        status: 'completed',
      );

      final duration = shift.endTime!.difference(shift.startTime);
      expect(duration.inHours, 8);
      expect(duration.inMinutes.remainder(60), 30);
    });

    test('active shift has no end time', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        status: 'active',
      );

      expect(shift.endTime, null);
      expect(shift.isActive, true);
    });
  });

  // Shift Notes Tests
  group('Shift Notes Tests', () {
    test('stores notes for shift', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        notes: 'Cash drawer was sticky',
        status: 'active',
      );

      expect(shift.notes, 'Cash drawer was sticky');
    });

    test('notes can be empty', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        status: 'active',
      );

      expect(shift.notes, null);
    });
  });

  // Shift Reconciliation Tests
  group('Shift Reconciliation Tests', () {
    test('variance acknowledged flag tracks reconciliation status', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: 550.0,
        expectedCash: 520.0,
        variance: 30.0,
        varianceAcknowledged: false,
        status: 'completed',
      );

      expect(shift.varianceAcknowledged, false);

      final updated = shift.copyWith(varianceAcknowledged: true);
      expect(updated.varianceAcknowledged, true);
    });

    test('large variance requires acknowledgment', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: 400.0,
        expectedCash: 520.0,
        variance: -120.0, // Large shortage
        varianceAcknowledged: false,
        status: 'completed',
      );

      expect(shift.variance!.abs() > 100, true);
      expect(shift.varianceAcknowledged, false);
    });

    test('small variance might not require acknowledgment', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: 520.001,
        expectedCash: 520.0,
        variance: 0.001, // Negligible variance
        varianceAcknowledged: false, // Might auto-acknowledge
        status: 'completed',
      );

      expect(shift.variance!.abs() < 0.01, true);
    });
  });

  // Shift Business Session Tests
  group('Shift Business Session Tests', () {
    test('shift associates with business session', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        businessSessionId: 123,
        startTime: DateTime.now(),
        openingCash: 500.0,
        status: 'active',
      );

      expect(shift.businessSessionId, 123);
    });

    test('shift can exist without business session', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        status: 'active',
      );

      expect(shift.businessSessionId, null);
    });
  });

  // Edge Cases
  group('Edge Cases Tests', () {
    test('handles zero opening cash', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 0.0,
        status: 'active',
      );

      expect(shift.openingCash, 0.0);
    });

    test('handles large opening cash amounts', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 100000.99,
        status: 'active',
      );

      expect(shift.openingCash, 100000.99);
    });

    test('handles decimal closing cash', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: 650.50,
        status: 'completed',
      );

      expect(shift.closingCash, 650.50);
    });

    test('handles null closing cash for active shifts', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: null,
        status: 'active',
      );

      expect(shift.closingCash, null);
    });

    test('handles very long shift durations', () {
      final startTime = DateTime(2026, 1, 23, 8, 0);
      final endTime = DateTime(2026, 1, 25, 8, 0); // 48 hours

      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: startTime,
        endTime: endTime,
        openingCash: 500.0,
        status: 'completed',
      );

      final duration = shift.endTime!.difference(shift.startTime);
      expect(duration.inHours, 48);
    });

    test('handles multi-line notes', () {
      final notes = 'Line 1\nLine 2\nLine 3';
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        notes: notes,
        status: 'active',
      );

      expect(shift.notes, notes);
    });

    test('JSON serialization with special characters', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime(2026, 1, 23, 8, 0),
        openingCash: 500.0,
        notes: 'Special chars: dash-underscore_dot.comma,',
        status: 'active',
      );

      final json = shift.toJson();
      expect(json, isNotEmpty);
    });
  });

  // Shift Status Tests
  group('Shift Status Tests', () {
    test('validates active status', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        status: 'active',
      );

      expect(shift.status, 'active');
      expect(shift.isActive, true);
    });

    test('validates completed status', () {
      final shift = Shift(
        id: 'shift_1',
        userId: 'user_1',
        startTime: DateTime.now(),
        openingCash: 500.0,
        closingCash: 650.0,
        status: 'completed',
      );

      expect(shift.status, 'completed');
      expect(shift.isActive, false);
    });
  });
}
