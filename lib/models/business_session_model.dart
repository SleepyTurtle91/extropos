/// Business session model for tracking opening and closing of business days
class BusinessSession {
  final int? id;
  final DateTime openDate;
  final DateTime? closeDate;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final String? notes;
  final bool isOpen;

  BusinessSession({
    this.id,
    required this.openDate,
    this.closeDate,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.notes,
    this.isOpen = true,
  });

  /// Create a new business session when opening
  factory BusinessSession.open(double openingCash, {String? notes}) {
    return BusinessSession(
      openDate: DateTime.now(),
      openingCash: openingCash,
      notes: notes,
      isOpen: true,
    );
  }

  /// Close the current business session
  BusinessSession close(double closingCash, {String? notes}) {
    final now = DateTime.now();
    return BusinessSession(
      id: id,
      openDate: openDate,
      closeDate: now,
      openingCash: openingCash,
      closingCash: closingCash,
      expectedCash: expectedCash,
      notes: notes ?? this.notes,
      isOpen: false,
    );
  }

  /// Calculate cash difference
  double get cashDifference {
    if (closingCash == null) return 0.0;
    final expected = expectedCash ?? openingCash;
    return closingCash! - expected;
  }

  /// Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'open_date': openDate.toIso8601String(),
      'close_date': closeDate?.toIso8601String(),
      'opening_cash': openingCash,
      'closing_cash': closingCash,
      'expected_cash': expectedCash,
      'notes': notes,
      'is_open': isOpen ? 1 : 0,
    };
  }

  /// Create from database map
  factory BusinessSession.fromMap(Map<String, dynamic> map) {
    return BusinessSession(
      id: map['id'],
      openDate: DateTime.parse(map['open_date']),
      closeDate: map['close_date'] != null
          ? DateTime.parse(map['close_date'])
          : null,
      openingCash: map['opening_cash'],
      closingCash: map['closing_cash'],
      expectedCash: map['expected_cash'],
      notes: map['notes'],
      isOpen: map['is_open'] == 1,
    );
  }

  /// Copy with modifications
  BusinessSession copyWith({
    int? id,
    DateTime? openDate,
    DateTime? closeDate,
    double? openingCash,
    double? closingCash,
    double? expectedCash,
    String? notes,
    bool? isOpen,
  }) {
    return BusinessSession(
      id: id ?? this.id,
      openDate: openDate ?? this.openDate,
      closeDate: closeDate ?? this.closeDate,
      openingCash: openingCash ?? this.openingCash,
      closingCash: closingCash ?? this.closingCash,
      expectedCash: expectedCash ?? this.expectedCash,
      notes: notes ?? this.notes,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
