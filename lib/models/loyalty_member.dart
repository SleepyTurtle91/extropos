class LoyaltyMember {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime joinDate;
  final String currentTier;
  final int totalPoints;
  final int redeemedPoints;
  final DateTime lastPurchaseDate;
  final double totalSpent;

  LoyaltyMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.joinDate,
    required this.currentTier,
    required this.totalPoints,
    required this.redeemedPoints,
    required this.lastPurchaseDate,
    required this.totalSpent,
  });

  // Calculate available points
  int get availablePoints => totalPoints - redeemedPoints;

  // Check if member is active (purchased in last 6 months)
  bool get isActive {
    final sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));
    return lastPurchaseDate.isAfter(sixMonthsAgo);
  }

  // Get tier level as number for comparisons
  int get tierLevel {
    switch (currentTier) {
      case 'Platinum':
        return 4;
      case 'Gold':
        return 3;
      case 'Silver':
        return 2;
      case 'Bronze':
        return 1;
      default:
        return 0;
    }
  }

  // Copy with method for immutability
  LoyaltyMember copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    DateTime? joinDate,
    String? currentTier,
    int? totalPoints,
    int? redeemedPoints,
    DateTime? lastPurchaseDate,
    double? totalSpent,
  }) {
    return LoyaltyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      joinDate: joinDate ?? this.joinDate,
      currentTier: currentTier ?? this.currentTier,
      totalPoints: totalPoints ?? this.totalPoints,
      redeemedPoints: redeemedPoints ?? this.redeemedPoints,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      totalSpent: totalSpent ?? this.totalSpent,
    );
  }

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'join_date': joinDate.millisecondsSinceEpoch,
      'current_tier': currentTier,
      'total_points': totalPoints,
      'redeemed_points': redeemedPoints,
      'last_purchase_date': lastPurchaseDate.millisecondsSinceEpoch,
      'total_spent': totalSpent,
    };
  }

  // Create from map (database retrieval)
  factory LoyaltyMember.fromMap(Map<String, dynamic> map) {
    return LoyaltyMember(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      joinDate: DateTime.fromMillisecondsSinceEpoch(map['join_date'] ?? 0),
      currentTier: map['current_tier'] ?? 'Bronze',
      totalPoints: map['total_points'] ?? 0,
      redeemedPoints: map['redeemed_points'] ?? 0,
      lastPurchaseDate:
          DateTime.fromMillisecondsSinceEpoch(map['last_purchase_date'] ?? 0),
      totalSpent: (map['total_spent'] ?? 0.0).toDouble(),
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => toMap();

  factory LoyaltyMember.fromJson(Map<String, dynamic> json) =>
      LoyaltyMember.fromMap(json);

  @override
  String toString() =>
      'LoyaltyMember(id: $id, name: $name, tier: $currentTier, points: $totalPoints)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoyaltyMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ phone.hashCode;
}
