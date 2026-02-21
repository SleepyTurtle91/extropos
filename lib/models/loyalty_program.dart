// Loyalty program models and structures

class LoyaltyProgram {
  final String id;
  final String name;
  bool isEnabled;

  /// Points system: points earned per RM spent
  double pointsPerRMSpent;

  /// Redemption value: e.g., 100 points = RM 10 (0.10 per point)
  double redemptionValue;

  /// Loyalty tiers (Silver, Gold, Platinum, etc.)
  Map<String, LoyaltyTier> tiers;

  /// Award points on tax amount
  bool awardOnTax;

  /// Category exemptions (categories that don't earn points)
  List<String> exemptCategories;

  /// Minimum points to redeem
  int minPointsToRedeem;

  /// Points expiry in months (0 = no expiry)
  int pointsExpiryMonths;

  LoyaltyProgram({
    required this.id,
    required this.name,
    this.isEnabled = true,
    this.pointsPerRMSpent = 1.0,
    this.redemptionValue = 0.10,
    this.tiers = const {},
    this.awardOnTax = false,
    this.exemptCategories = const [],
    this.minPointsToRedeem = 100,
    this.pointsExpiryMonths = 0,
  });

  /// Get tier by name
  LoyaltyTier? getTier(String tierName) => tiers[tierName];

  /// Check if category is exempt from points
  bool isCategoryExempt(String categoryId) => exemptCategories.contains(categoryId);

  /// Calculate points earned from amount
  double calculatePointsEarned(double amount) {
    return amount * pointsPerRMSpent;
  }

  /// Calculate RM value of points
  double calculatePointValue(double points) {
    return points * redemptionValue;
  }

  factory LoyaltyProgram.defaultMalaysian() {
    return LoyaltyProgram(
      id: 'loyalty_default',
      name: 'Standard Loyalty Program',
      isEnabled: true,
      pointsPerRMSpent: 1.0, // 1 point per RM
      redemptionValue: 0.10, // 1 point = RM 0.10
      awardOnTax: false,
      minPointsToRedeem: 100,
      pointsExpiryMonths: 24, // 2 years
      tiers: {
        'bronze': LoyaltyTier(
          id: 'bronze',
          name: 'Bronze',
          minSpend: 0.0,
          discountPercentage: 0.0,
          benefits: ['1x points earning'],
        ),
        'silver': LoyaltyTier(
          id: 'silver',
          name: 'Silver',
          minSpend: 500.0,
          discountPercentage: 0.5,
          benefits: ['1.25x points earning', '0.5% discount'],
        ),
        'gold': LoyaltyTier(
          id: 'gold',
          name: 'Gold',
          minSpend: 2000.0,
          discountPercentage: 1.0,
          benefits: ['1.5x points earning', '1% discount', 'Free item voucher/month'],
        ),
        'platinum': LoyaltyTier(
          id: 'platinum',
          name: 'Platinum',
          minSpend: 5000.0,
          discountPercentage: 2.0,
          benefits: ['2x points earning', '2% discount', 'VIP support'],
        ),
      },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isEnabled': isEnabled,
      'pointsPerRMSpent': pointsPerRMSpent,
      'redemptionValue': redemptionValue,
      'tiers': tiers.map((k, v) => MapEntry(k, v.toJson())),
      'awardOnTax': awardOnTax,
      'exemptCategories': exemptCategories,
      'minPointsToRedeem': minPointsToRedeem,
      'pointsExpiryMonths': pointsExpiryMonths,
    };
  }

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
      pointsPerRMSpent: (json['pointsPerRMSpent'] ?? 1.0).toDouble(),
      redemptionValue: (json['redemptionValue'] ?? 0.10).toDouble(),
      tiers: (json['tiers'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, LoyaltyTier.fromJson(v))),
      awardOnTax: json['awardOnTax'] ?? false,
      exemptCategories: List<String>.from(json['exemptCategories'] ?? []),
      minPointsToRedeem: json['minPointsToRedeem'] ?? 100,
      pointsExpiryMonths: json['pointsExpiryMonths'] ?? 0,
    );
  }
}

class LoyaltyTier {
  final String id;
  final String name;

  /// Minimum total spend to reach this tier
  final double minSpend;

  /// Discount percentage for purchases at this tier
  final double discountPercentage;

  /// Benefits/perks for this tier
  final List<String> benefits;

  LoyaltyTier({
    required this.id,
    required this.name,
    required this.minSpend,
    required this.discountPercentage,
    required this.benefits,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'minSpend': minSpend,
      'discountPercentage': discountPercentage,
      'benefits': benefits,
    };
  }

  factory LoyaltyTier.fromJson(Map<String, dynamic> json) {
    return LoyaltyTier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      minSpend: (json['minSpend'] ?? 0.0).toDouble(),
      discountPercentage: (json['discountPercentage'] ?? 0.0).toDouble(),
      benefits: List<String>.from(json['benefits'] ?? []),
    );
  }
}

/// Customer loyalty tracking
class LoyaltyCustomer {
  final String customerId;

  /// Total accumulated points (not redeemed)
  double accumulatedPoints;

  /// Current loyalty tier (e.g., 'silver', 'gold')
  String currentTier;

  /// Total spend across all transactions
  double totalSpent;

  /// Date customer joined loyalty program
  final DateTime joinDate;

  /// Last transaction date
  DateTime? lastPurchaseDate;

  /// Transaction history for this customer
  List<LoyaltyTransaction> transactions;

  LoyaltyCustomer({
    required this.customerId,
    this.accumulatedPoints = 0.0,
    this.currentTier = 'bronze',
    this.totalSpent = 0.0,
    required this.joinDate,
    this.lastPurchaseDate,
    this.transactions = const [],
  });

  /// Add points earned
  void addPoints(double points, String reason, {String? transactionId}) {
    accumulatedPoints += points;
    transactions.add(
      LoyaltyTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'earn',
        points: points,
        description: reason,
        date: DateTime.now(),
        transactionId: transactionId,
      ),
    );
  }

  /// Redeem points
  bool redeemPoints(double points, {required String reason}) {
    if (points > accumulatedPoints) return false;

    accumulatedPoints -= points;
    transactions.add(
      LoyaltyTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'redeem',
        points: points,
        description: reason,
        date: DateTime.now(),
      ),
    );
    return true;
  }

  /// Adjust points (admin action)
  void adjustPoints(double points, String reason) {
    accumulatedPoints += points;
    transactions.add(
      LoyaltyTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'adjust',
        points: points,
        description: reason,
        date: DateTime.now(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'accumulatedPoints': accumulatedPoints,
      'currentTier': currentTier,
      'totalSpent': totalSpent,
      'joinDate': joinDate.millisecondsSinceEpoch,
      'lastPurchaseDate': lastPurchaseDate?.millisecondsSinceEpoch,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory LoyaltyCustomer.fromJson(Map<String, dynamic> json) {
    return LoyaltyCustomer(
      customerId: json['customerId'] ?? '',
      accumulatedPoints: (json['accumulatedPoints'] ?? 0.0).toDouble(),
      currentTier: json['currentTier'] ?? 'bronze',
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      joinDate: DateTime.fromMillisecondsSinceEpoch(json['joinDate'] ?? 0),
      lastPurchaseDate: json['lastPurchaseDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastPurchaseDate'])
          : null,
      transactions: (json['transactions'] as List? ?? [])
          .map((t) => LoyaltyTransaction.fromJson(t))
          .toList(),
    );
  }
}

/// Individual loyalty transaction
class LoyaltyTransaction {
  final String id;
  final String type; // 'earn', 'redeem', 'adjust'
  final double points;
  final String description;
  final DateTime date;
  final String? transactionId; // Link to POS transaction

  LoyaltyTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.description,
    required this.date,
    this.transactionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'points': points,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'transactionId': transactionId,
    };
  }

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'earn',
      points: (json['points'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] ?? 0),
      transactionId: json['transactionId'],
    );
  }
}
