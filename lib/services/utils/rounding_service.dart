/// Malaysian BNM cash-rounding rules for POS transactions.
///
/// Bank Negara Malaysia requires cash payments to be rounded to the nearest
/// RM 0.05 (5 sen). Non-cash payments (card, e-wallet) are NOT rounded.
///
/// Rounding table (last sen digit → rounded to):
///   0, 1, 2  → round DOWN to .x0  (e.g. RM 1.02 → RM 1.00)
///   3, 4     → round DOWN to .x0  (e.g. RM 1.04 → RM 1.00) [some implementations round to .05]
///   5, 6, 7  → round UP  to .x5  (e.g. RM 1.07 → RM 1.05)
///   8, 9     → round UP  to next .x0 (e.g. RM 1.09 → RM 1.10)
///
/// BNM official table (used in practice):
///   .x0, .x1 → .x0
///   .x2, .x3, .x4 → .x0  OR  .x5  (depends on mid-point convention; BNM uses .x0 for 2,3,4)
///   Actually the official BNM circular table is:
///     Ending 1 or 2 → round to 0
///     Ending 3 or 4 → round to 5
///     Ending 6 or 7 → round to 5
///     Ending 8 or 9 → round to 10 (next 0)
///   Reference: BNM/GP8 Circular (2008)
///
/// Pure Dart — no Flutter imports.
abstract final class RoundingService {
  // ─── BNM sen-rounding table ────────────────────────────────────────────────
  //
  // Last sen digit (0-9) → nearest 5-sen step:
  //   0 → 0   (exact match, no change)
  //   1 → 0   (round down 1 sen)
  //   2 → 0   (round down 2 sen)
  //   3 → 5   (round up   2 sen)
  //   4 → 5   (round up   1 sen)
  //   5 → 5   (exact match, no change)
  //   6 → 5   (round down 1 sen)
  //   7 → 5   (round down 2 sen)
  //   8 → 10  (round up   2 sen — e.g. 1.08 → 1.10)
  //   9 → 10  (round up   1 sen — e.g. 1.09 → 1.10)
  //
  // Sen digit → offset in sen (added to the amount in sen):
  static const List<int> _bnmOffsets = [0, -1, -2, 2, 1, 0, -1, -2, 2, 1];

  /// Round [amount] to the nearest RM 0.05 using BNM cash-rounding rules.
  ///
  /// Only applies to cash transactions in Malaysian Ringgit.
  /// For e-wallet / card / online — use [amount] unchanged.
  ///
  /// Returns an amount guaranteed to end in .x0 or .x5.
  static double roundCash(double amount) {
    // Work in integer sen to avoid floating-point drift.
    // Round to nearest sen first (standard rounding).
    final totalSen = (amount * 100).round();
    final lastDigit = totalSen.abs() % 10;
    final offset = _bnmOffsets[lastDigit];
    final roundedSen = totalSen + offset;
    return roundedSen / 100.0;
  }

  /// Returns the rounding adjustment (positive = customer pays more, negative = less).
  static double cashRoundingAdjustment(double amount) {
    return roundCash(amount) - (amount * 100).round() / 100.0;
  }

  /// Formats [amount] as a RM string with 2 decimal places.
  static String formatRM(double amount) =>
      'RM ${amount.toStringAsFixed(2)}';

  /// Returns true if [amount] is already correctly rounded (ends in .x0 or .x5).
  static bool isAlreadyRounded(double amount) {
    final sen = (amount * 100).round();
    return sen % 5 == 0;
  }
}
