class LoyaltyTransaction {
  final String id;
  final String memberId;
  final String transactionType; // 'Purchase', 'Reward', 'Adjustment'
  final double amount;
  final int pointsEarned;
  final int pointsRedeemed;
  final DateTime transactionDate;
  final String notes;

  LoyaltyTransaction({
    required this.id,
    required this.memberId,
    required this.transactionType,
    required this.amount,
    required this.pointsEarned,
    required this.pointsRedeemed,
    required this.transactionDate,
    this.notes = '',
  });

  // Get net points change (earned - redeemed)
  int get netPointsChange => pointsEarned - pointsRedeemed;

  // Check if transaction is a purchase
  bool get isPurchase => transactionType == 'Purchase';

  // Check if transaction is a reward redemption
  bool get isRedemption => pointsRedeemed > 0;

  // Copy with method for immutability
  LoyaltyTransaction copyWith({
    String? id,
    String? memberId,
    String? transactionType,
    double? amount,
    int? pointsEarned,
    int? pointsRedeemed,
    DateTime? transactionDate,
    String? notes,
  }) {
    return LoyaltyTransaction(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      transactionType: transactionType ?? this.transactionType,
      amount: amount ?? this.amount,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      pointsRedeemed: pointsRedeemed ?? this.pointsRedeemed,
      transactionDate: transactionDate ?? this.transactionDate,
      notes: notes ?? this.notes,
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'member_id': memberId,
      'transaction_type': transactionType,
      'amount': amount,
      'points_earned': pointsEarned,
      'points_redeemed': pointsRedeemed,
      'transaction_date': transactionDate.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  // Create from map (database retrieval)
  factory LoyaltyTransaction.fromMap(Map<String, dynamic> map) {
    return LoyaltyTransaction(
      id: map['id'] ?? '',
      memberId: map['member_id'] ?? '',
      transactionType: map['transaction_type'] ?? 'Purchase',
      amount: (map['amount'] ?? 0.0).toDouble(),
      pointsEarned: map['points_earned'] ?? 0,
      pointsRedeemed: map['points_redeemed'] ?? 0,
      transactionDate:
          DateTime.fromMillisecondsSinceEpoch(map['transaction_date'] ?? 0),
      notes: map['notes'] ?? '',
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => toMap();

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) =>
      LoyaltyTransaction.fromMap(json);

  @override
  String toString() =>
      'LoyaltyTransaction(id: $id, type: $transactionType, earned: $pointsEarned, redeemed: $pointsRedeemed)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoyaltyTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          memberId == other.memberId;

  @override
  int get hashCode => id.hashCode ^ memberId.hashCode;
}
