import 'package:extropos/services/utils/rounding_service.dart';
import 'package:test/test.dart';

/// Comprehensive test suite for [RoundingService].
///
/// Validates BNM cash-rounding rules (BNM/GP8 Circular, 2008).
/// All sen-ending scenarios are covered plus edge cases.
void main() {
  group('RoundingService.roundCash — BNM sen rounding table', () {
    // Last-digit 0 → stays at .x0
    test('ends in 0 → no change (RM 1.00)', () {
      expect(RoundingService.roundCash(1.00), closeTo(1.00, 0.001));
    });

    test('ends in 0 → no change (RM 5.20)', () {
      expect(RoundingService.roundCash(5.20), closeTo(5.20, 0.001));
    });

    // Last-digit 1 → round DOWN to .x0
    test('ends in 1 → round down (RM 1.01 → 1.00)', () {
      expect(RoundingService.roundCash(1.01), closeTo(1.00, 0.001));
    });

    test('ends in 1 → round down (RM 3.31 → 3.30)', () {
      expect(RoundingService.roundCash(3.31), closeTo(3.30, 0.001));
    });

    // Last-digit 2 → round DOWN to .x0
    test('ends in 2 → round down (RM 1.02 → 1.00)', () {
      expect(RoundingService.roundCash(1.02), closeTo(1.00, 0.001));
    });

    test('ends in 2 → round down (RM 9.82 → 9.80)', () {
      expect(RoundingService.roundCash(9.82), closeTo(9.80, 0.001));
    });

    // Last-digit 3 → round UP to .x5
    test('ends in 3 → round up (RM 1.03 → 1.05)', () {
      expect(RoundingService.roundCash(1.03), closeTo(1.05, 0.001));
    });

    test('ends in 3 → round up (RM 10.73 → 10.75)', () {
      expect(RoundingService.roundCash(10.73), closeTo(10.75, 0.001));
    });

    // Last-digit 4 → round UP to .x5
    test('ends in 4 → round up (RM 1.04 → 1.05)', () {
      expect(RoundingService.roundCash(1.04), closeTo(1.05, 0.001));
    });

    test('ends in 4 → round up (RM 24.94 → 24.95)', () {
      expect(RoundingService.roundCash(24.94), closeTo(24.95, 0.001));
    });

    // Last-digit 5 → stays at .x5
    test('ends in 5 → no change (RM 1.05)', () {
      expect(RoundingService.roundCash(1.05), closeTo(1.05, 0.001));
    });

    test('ends in 5 → no change (RM 7.45)', () {
      expect(RoundingService.roundCash(7.45), closeTo(7.45, 0.001));
    });

    // Last-digit 6 → round DOWN to .x5
    test('ends in 6 → round down (RM 1.06 → 1.05)', () {
      expect(RoundingService.roundCash(1.06), closeTo(1.05, 0.001));
    });

    test('ends in 6 → round down (RM 5.16 → 5.15)', () {
      expect(RoundingService.roundCash(5.16), closeTo(5.15, 0.001));
    });

    // Last-digit 7 → round DOWN to .x5
    test('ends in 7 → round down (RM 1.07 → 1.05)', () {
      expect(RoundingService.roundCash(1.07), closeTo(1.05, 0.001));
    });

    test('ends in 7 → round down (RM 100.27 → 100.25)', () {
      expect(RoundingService.roundCash(100.27), closeTo(100.25, 0.001));
    });

    // Last-digit 8 → round UP to next .x0
    test('ends in 8 → round up (RM 1.08 → 1.10)', () {
      expect(RoundingService.roundCash(1.08), closeTo(1.10, 0.001));
    });

    test('ends in 8 → round up (RM 5.98 → 6.00)', () {
      expect(RoundingService.roundCash(5.98), closeTo(6.00, 0.001));
    });

    // Last-digit 9 → round UP to next .x0
    test('ends in 9 → round up (RM 1.09 → 1.10)', () {
      expect(RoundingService.roundCash(1.09), closeTo(1.10, 0.001));
    });

    test('ends in 9 → round up (RM 49.99 → 50.00)', () {
      expect(RoundingService.roundCash(49.99), closeTo(50.00, 0.001));
    });

    // ── Edge cases ──────────────────────────────────────────────────────────

    test('zero amount → stays zero', () {
      expect(RoundingService.roundCash(0.0), closeTo(0.0, 0.001));
    });

    test('large amount round-up (RM 999.98 → 1000.00)', () {
      expect(RoundingService.roundCash(999.98), closeTo(1000.00, 0.001));
    });

    test('floating-point stability: RM 12.346 rounds correctly', () {
      // 12.346 in floating point can be 12.345999... or 12.346 — both round to 12.35
      // 1234.6 sen → last digit 4 → +1 → 1235 → 12.35
      expect(RoundingService.roundCash(12.346), closeTo(12.35, 0.001));
    });

    test('result always ends in 0 or 5 sen', () {
      for (double base = 0.00; base < 2.00; base += 0.01) {
        final rounded = RoundingService.roundCash(base);
        final sen = (rounded * 100).round();
        expect(
          sen % 5,
          0,
          reason: 'RM ${base.toStringAsFixed(2)} → RM ${rounded.toStringAsFixed(2)} is not a multiple of 5 sen',
        );
      }
    });
  });

  group('RoundingService.cashRoundingAdjustment', () {
    test('no adjustment when already rounded to .x0', () {
      expect(RoundingService.cashRoundingAdjustment(5.00), closeTo(0.00, 0.001));
    });

    test('negative adjustment for round-down (ends in 2)', () {
      expect(RoundingService.cashRoundingAdjustment(1.02), closeTo(-0.02, 0.001));
    });

    test('positive adjustment for round-up (ends in 3)', () {
      expect(RoundingService.cashRoundingAdjustment(1.03), closeTo(0.02, 0.001));
    });
  });

  group('RoundingService.isAlreadyRounded', () {
    test('RM 1.00 is already rounded', () {
      expect(RoundingService.isAlreadyRounded(1.00), isTrue);
    });

    test('RM 1.05 is already rounded', () {
      expect(RoundingService.isAlreadyRounded(1.05), isTrue);
    });

    test('RM 1.03 is NOT rounded', () {
      expect(RoundingService.isAlreadyRounded(1.03), isFalse);
    });

    test('RM 10.50 is already rounded', () {
      expect(RoundingService.isAlreadyRounded(10.50), isTrue);
    });
  });

  group('RoundingService.formatRM', () {
    test('formats whole ringgit', () {
      expect(RoundingService.formatRM(5.00), 'RM 5.00');
    });

    test('formats 5-sen step', () {
      expect(RoundingService.formatRM(12.35), 'RM 12.35');
    });
  });
}
