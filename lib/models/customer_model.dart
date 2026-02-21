/// Customer model for tracking customer information and purchase history
class Customer {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final double totalSpent;
  final int visitCount;
  final int loyaltyPoints;
  final DateTime? lastVisit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final bool isActive;

  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.totalSpent = 0.0,
    this.visitCount = 0,
    this.loyaltyPoints = 0,
    this.lastVisit,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.isActive = true,
  });

  /// Create from database map
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0.0,
      visitCount: (map['visit_count'] as int?) ?? 0,
      loyaltyPoints: (map['loyalty_points'] as int?) ?? 0,
      lastVisit: map['last_visit'] != null
          ? DateTime.parse(map['last_visit'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      notes: map['notes'] as String?,
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'total_spent': totalSpent,
      'visit_count': visitCount,
      'loyalty_points': loyaltyPoints,
      'last_visit': lastVisit?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'is_active': isActive ? 1 : 0,
    };
  }

  /// Create a copy with modified fields
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    double? totalSpent,
    int? visitCount,
    int? loyaltyPoints,
    DateTime? lastVisit,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      totalSpent: totalSpent ?? this.totalSpent,
      visitCount: visitCount ?? this.visitCount,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      lastVisit: lastVisit ?? this.lastVisit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Calculate average order value
  double get averageOrderValue {
    if (visitCount == 0) return 0.0;
    return totalSpent / visitCount;
  }

  /// Get customer tier based on total spent
  String get customerTier {
    if (totalSpent >= 10000) return 'VIP';
    if (totalSpent >= 5000) return 'Gold';
    if (totalSpent >= 1000) return 'Silver';
    return 'Bronze';
  }

  /// Check if customer is a regular (visited in last 30 days)
  bool get isRegular {
    if (lastVisit == null) return false;
    final daysSinceLastVisit = DateTime.now().difference(lastVisit!).inDays;
    return daysSinceLastVisit <= 30;
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, phone: $phone, totalSpent: $totalSpent, visitCount: $visitCount, tier: $customerTier}';
  }
}
