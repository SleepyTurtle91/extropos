library;

/// Employee performance summary for a given period
class EmployeePerformance {
  final String userId;
  final String userName;
  final String userRole;
  final double totalSales;
  final int orderCount;
  final int itemsSold;
  final double averageOrderValue;
  final double commission;
  final DateTime startDate;
  final DateTime endDate;

  EmployeePerformance({
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.totalSales,
    required this.orderCount,
    required this.itemsSold,
    required this.averageOrderValue,
    required this.commission,
    required this.startDate,
    required this.endDate,
  });

  factory EmployeePerformance.fromMap(Map<String, dynamic> map) {
    return EmployeePerformance(
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userRole: map['user_role'] as String,
      totalSales: (map['total_sales'] as num).toDouble(),
      orderCount: map['order_count'] as int,
      itemsSold: map['items_sold'] as int,
      averageOrderValue: (map['average_order_value'] as num).toDouble(),
      commission: (map['commission'] as num).toDouble(),
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'total_sales': totalSales,
      'order_count': orderCount,
      'items_sold': itemsSold,
      'average_order_value': averageOrderValue,
      'commission': commission,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }
}

/// Shift report for a specific employee and shift
class ShiftReport {
  final String userId;
  final String userName;
  final DateTime shiftStart;
  final DateTime shiftEnd;
  final double totalSales;
  final int orderCount;
  final int itemsSold;
  final double cashSales;
  final double cardSales;
  final double otherSales;
  final int refundCount;
  final double refundAmount;
  final int voidCount;
  final double averageOrderValue;
  final Duration shiftDuration;

  ShiftReport({
    required this.userId,
    required this.userName,
    required this.shiftStart,
    required this.shiftEnd,
    required this.totalSales,
    required this.orderCount,
    required this.itemsSold,
    required this.cashSales,
    required this.cardSales,
    required this.otherSales,
    required this.refundCount,
    required this.refundAmount,
    required this.voidCount,
    required this.averageOrderValue,
    required this.shiftDuration,
  });

  factory ShiftReport.fromMap(Map<String, dynamic> map) {
    final start = DateTime.parse(map['shift_start'] as String);
    final end = DateTime.parse(map['shift_end'] as String);
    return ShiftReport(
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      shiftStart: start,
      shiftEnd: end,
      totalSales: (map['total_sales'] as num).toDouble(),
      orderCount: map['order_count'] as int,
      itemsSold: map['items_sold'] as int,
      cashSales: (map['cash_sales'] as num).toDouble(),
      cardSales: (map['card_sales'] as num).toDouble(),
      otherSales: (map['other_sales'] as num).toDouble(),
      refundCount: map['refund_count'] as int,
      refundAmount: (map['refund_amount'] as num).toDouble(),
      voidCount: map['void_count'] as int,
      averageOrderValue: (map['average_order_value'] as num).toDouble(),
      shiftDuration: end.difference(start),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'user_name': userName,
      'shift_start': shiftStart.toIso8601String(),
      'shift_end': shiftEnd.toIso8601String(),
      'total_sales': totalSales,
      'order_count': orderCount,
      'items_sold': itemsSold,
      'cash_sales': cashSales,
      'card_sales': cardSales,
      'other_sales': otherSales,
      'refund_count': refundCount,
      'refund_amount': refundAmount,
      'void_count': voidCount,
      'average_order_value': averageOrderValue,
      'shift_duration_minutes': shiftDuration.inMinutes,
    };
  }
}

/// Hourly breakdown of employee sales
class HourlyEmployeeSales {
  final String userId;
  final int hour; // 0-23
  final double revenue;
  final int orderCount;

  HourlyEmployeeSales({
    required this.userId,
    required this.hour,
    required this.revenue,
    required this.orderCount,
  });

  String get hourLabel {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }

  factory HourlyEmployeeSales.fromMap(Map<String, dynamic> map) {
    return HourlyEmployeeSales(
      userId: map['user_id'] as String,
      hour: map['hour'] as int,
      revenue: (map['revenue'] as num).toDouble(),
      orderCount: map['order_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'hour': hour,
      'revenue': revenue,
      'order_count': orderCount,
    };
  }
}

/// Employee ranking for leaderboard
class EmployeeRanking {
  final int rank;
  final String userId;
  final String userName;
  final String userRole;
  final double totalSales;
  final int orderCount;
  final double commission;
  final String avatarUrl;

  EmployeeRanking({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.totalSales,
    required this.orderCount,
    required this.commission,
    this.avatarUrl = '',
  });

  factory EmployeeRanking.fromMap(Map<String, dynamic> map, int rank) {
    return EmployeeRanking(
      rank: rank,
      userId: map['user_id'] as String,
      userName: map['user_name'] as String,
      userRole: map['user_role'] as String,
      totalSales: (map['total_sales'] as num).toDouble(),
      orderCount: map['order_count'] as int,
      commission: (map['commission'] as num).toDouble(),
      avatarUrl: map['avatar_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'user_name': userName,
      'user_role': userRole,
      'total_sales': totalSales,
      'order_count': orderCount,
      'commission': commission,
      'avatar_url': avatarUrl,
    };
  }
}

/// Commission tier configuration
class CommissionTier {
  final double minSales;
  final double maxSales;
  final double rate; // Percentage as decimal (e.g., 0.05 for 5%)
  final String tierName;

  const CommissionTier({
    required this.minSales,
    required this.maxSales,
    required this.rate,
    required this.tierName,
  });

  bool appliesTo(double sales) {
    return sales >= minSales &&
        (maxSales == double.infinity || sales < maxSales);
  }

  double calculateCommission(double sales) {
    if (!appliesTo(sales)) return 0.0;
    return sales * rate;
  }

  // Default commission tiers
  static const List<CommissionTier> defaultTiers = [
    CommissionTier(
      minSales: 0,
      maxSales: 1000,
      rate: 0.02, // 2%
      tierName: 'Bronze',
    ),
    CommissionTier(
      minSales: 1000,
      maxSales: 5000,
      rate: 0.03, // 3%
      tierName: 'Silver',
    ),
    CommissionTier(
      minSales: 5000,
      maxSales: 10000,
      rate: 0.05, // 5%
      tierName: 'Gold',
    ),
    CommissionTier(
      minSales: 10000,
      maxSales: double.infinity,
      rate: 0.07, // 7%
      tierName: 'Platinum',
    ),
  ];

  static double calculateTotalCommission(
    double sales, [
    List<CommissionTier>? tiers,
  ]) {
    final activeTiers = tiers ?? defaultTiers;
    for (final tier in activeTiers) {
      if (tier.appliesTo(sales)) {
        return tier.calculateCommission(sales);
      }
    }
    return 0.0;
  }

  static CommissionTier? getTierForSales(
    double sales, [
    List<CommissionTier>? tiers,
  ]) {
    final activeTiers = tiers ?? defaultTiers;
    for (final tier in activeTiers) {
      if (tier.appliesTo(sales)) {
        return tier;
      }
    }
    return null;
  }
}
