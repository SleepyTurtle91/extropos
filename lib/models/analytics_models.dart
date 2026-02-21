/// Analytics data models for reporting and dashboard displays
/// Used by Advanced Reports Screen and Analytics Dashboard
library;

/// Sales summary for a time period
class SalesSummary {
  final double totalRevenue;
  final double totalTax;
  final double totalServiceCharge;
  final double totalDiscount;
  final int orderCount;
  final int itemsSold;
  final double averageOrderValue;
  final DateTime startDate;
  final DateTime endDate;

  SalesSummary({
    required this.totalRevenue,
    required this.totalTax,
    required this.totalServiceCharge,
    required this.totalDiscount,
    required this.orderCount,
    required this.itemsSold,
    required this.averageOrderValue,
    required this.startDate,
    required this.endDate,
  });

  factory SalesSummary.fromMap(Map<String, dynamic> map) {
    final orderCount = map['order_count'] as int? ?? 0;
    final totalRevenue = (map['total_revenue'] as num?)?.toDouble() ?? 0.0;

    return SalesSummary(
      totalRevenue: totalRevenue,
      totalTax: (map['total_tax'] as num?)?.toDouble() ?? 0.0,
      totalServiceCharge:
          (map['total_service_charge'] as num?)?.toDouble() ?? 0.0,
      totalDiscount: (map['total_discount'] as num?)?.toDouble() ?? 0.0,
      orderCount: orderCount,
      itemsSold: map['items_sold'] as int? ?? 0,
      averageOrderValue: orderCount > 0 ? totalRevenue / orderCount : 0.0,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
    );
  }

  // Getter aliases for UI compatibility with different report formats
  double get grossSales => totalRevenue;
  double get netSales => totalRevenue - totalTax - totalDiscount;
  int get transactionCount => orderCount;
  double get averageTransactionValue => averageOrderValue;

  Map<String, dynamic> toJson() => {
    'total_revenue': totalRevenue,
    'total_tax': totalTax,
    'total_service_charge': totalServiceCharge,
    'total_discount': totalDiscount,
    'order_count': orderCount,
    'items_sold': itemsSold,
    'average_order_value': averageOrderValue,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
  };
}

/// Category performance data
class CategoryPerformance {
  final String categoryId;
  final String categoryName;
  final double revenue;
  final int itemsSold;
  final int orderCount;
  final double averageItemPrice;

  CategoryPerformance({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
    required this.itemsSold,
    required this.orderCount,
    required this.averageItemPrice,
  });

  factory CategoryPerformance.fromMap(Map<String, dynamic> map) {
    final itemsSold = map['items_sold'] as int? ?? 0;
    final revenue = (map['revenue'] as num?)?.toDouble() ?? 0.0;

    return CategoryPerformance(
      categoryId: map['category_id'] as String? ?? '',
      categoryName: map['category_name'] as String? ?? 'Unknown',
      revenue: revenue,
      itemsSold: itemsSold,
      orderCount: map['order_count'] as int? ?? 0,
      averageItemPrice: itemsSold > 0 ? revenue / itemsSold : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'category_id': categoryId,
    'category_name': categoryName,
    'revenue': revenue,
    'items_sold': itemsSold,
    'order_count': orderCount,
    'average_item_price': averageItemPrice,
  };
}

/// Product performance data
class ProductPerformance {
  final String itemId;
  final String itemName;
  final String categoryName;
  final double revenue;
  final int quantitySold;
  final int orderCount;
  final double averagePrice;

  ProductPerformance({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.revenue,
    required this.quantitySold,
    required this.orderCount,
    required this.averagePrice,
  });

  factory ProductPerformance.fromMap(Map<String, dynamic> map) {
    final quantitySold = map['quantity_sold'] as int? ?? 0;
    final revenue = (map['revenue'] as num?)?.toDouble() ?? 0.0;

    return ProductPerformance(
      itemId: map['item_id'] as String? ?? '',
      itemName: map['item_name'] as String? ?? 'Unknown',
      categoryName: map['category_name'] as String? ?? 'Unknown',
      revenue: revenue,
      quantitySold: quantitySold,
      orderCount: map['order_count'] as int? ?? 0,
      averagePrice: quantitySold > 0 ? revenue / quantitySold : 0.0,
    );
  }

  // Getter aliases for UI compatibility
  String get productName => itemName;
  int get unitsSold => quantitySold;

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'item_name': itemName,
    'category_name': categoryName,
    'revenue': revenue,
    'quantity_sold': quantitySold,
    'order_count': orderCount,
    'average_price': averagePrice,
  };
}

/// Payment method breakdown
class PaymentMethodStats {
  final String paymentMethodId;
  final String paymentMethodName;
  final double totalAmount;
  final int transactionCount;
  final double percentage;

  PaymentMethodStats({
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.totalAmount,
    required this.transactionCount,
    required this.percentage,
  });

  factory PaymentMethodStats.fromMap(
    Map<String, dynamic> map,
    double grandTotal,
  ) {
    final totalAmount = (map['total_amount'] as num?)?.toDouble() ?? 0.0;

    return PaymentMethodStats(
      paymentMethodId: map['payment_method_id'] as String? ?? '',
      paymentMethodName: map['payment_method_name'] as String? ?? 'Unknown',
      totalAmount: totalAmount,
      transactionCount: map['transaction_count'] as int? ?? 0,
      percentage: grandTotal > 0 ? (totalAmount / grandTotal) * 100 : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_method_id': paymentMethodId,
    'payment_method_name': paymentMethodName,
    'total_amount': totalAmount,
    'transaction_count': transactionCount,
    'percentage': percentage,
  };
}

/// Hourly sales trend data point
class HourlySales {
  final int hour;
  final double revenue;
  final int orderCount;

  HourlySales({
    required this.hour,
    required this.revenue,
    required this.orderCount,
  });

  factory HourlySales.fromMap(Map<String, dynamic> map) {
    return HourlySales(
      hour: map['hour'] as int? ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      orderCount: map['order_count'] as int? ?? 0,
    );
  }

  String get hourLabel {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }

  Map<String, dynamic> toJson() => {
    'hour': hour,
    'revenue': revenue,
    'order_count': orderCount,
  };
}

/// Daily sales trend data point
class DailySales {
  final DateTime date;
  final double revenue;
  final int orderCount;

  DailySales({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  factory DailySales.fromMap(Map<String, dynamic> map) {
    return DailySales(
      date: DateTime.parse(map['date'] as String),
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
      orderCount: map['order_count'] as int? ?? 0,
    );
  }

  String get dateLabel {
    return '${date.month}/${date.day}';
  }

  // Getter alias for UI compatibility
  double get totalSales => revenue;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'revenue': revenue,
    'order_count': orderCount,
  };
}
