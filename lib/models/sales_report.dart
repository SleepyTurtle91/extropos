import 'dart:convert';

class SalesReport {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final String reportType;          // 'daily', 'weekly', 'monthly'
  final double grossSales;           // Total before deductions
  final double netSales;             // After discounts
  final double taxAmount;
  final double serviceChargeAmount;
  final int transactionCount;
  final int uniqueCustomers;
  final double averageTicket;
  final double averageTransactionTime;
  final Map<String, double> topCategories;  // Category -> revenue
  final Map<String, double> paymentMethods; // Payment method -> amount
  final DateTime generatedAt;

  SalesReport({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.reportType,
    required this.grossSales,
    required this.netSales,
    required this.taxAmount,
    required this.serviceChargeAmount,
    required this.transactionCount,
    required this.uniqueCustomers,
    required this.averageTicket,
    required this.averageTransactionTime,
    required this.topCategories,
    required this.paymentMethods,
    required this.generatedAt,
  });

  /// Computed: Total deductions
  double get totalDeductions => taxAmount + serviceChargeAmount;

  /// Computed: Discount percentage
  double get discountPercentage => grossSales > 0 ? ((grossSales - netSales) / grossSales) * 100 : 0;

  /// Computed: Tax percentage
  double get taxPercentage => grossSales > 0 ? (taxAmount / grossSales) * 100 : 0;

  /// Computed: Service charge percentage
  double get serviceChargePercentage => grossSales > 0 ? (serviceChargeAmount / grossSales) * 100 : 0;

  /// Computed: Total includes tax and service charge
  double get totalRevenue => netSales;

  /// Computed: Peak payment method
  String? get topPaymentMethod {
    if (paymentMethods.isEmpty) return null;
    return paymentMethods.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Computed: Peak category
  String? get topCategory {
    if (topCategories.isEmpty) return null;
    return topCategories.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'reportType': reportType,
      'grossSales': grossSales,
      'netSales': netSales,
      'taxAmount': taxAmount,
      'serviceChargeAmount': serviceChargeAmount,
      'transactionCount': transactionCount,
      'uniqueCustomers': uniqueCustomers,
      'averageTicket': averageTicket,
      'averageTransactionTime': averageTransactionTime,
      'topCategories': topCategories,
      'paymentMethods': paymentMethods,
      'generatedAt': generatedAt.millisecondsSinceEpoch,
    };
  }

  /// Deserialization
  static Map<String, double> _parseMapStringDouble(dynamic value) {
    if (value == null) return {};
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
      } catch (_) {}
    }
    return {};
  }

  static DateTime _parseDate(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {}
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static SalesReport fromMap(Map<String, dynamic> map) {
    return SalesReport(
      id: map['id']?.toString() ?? '',
      startDate: _parseDate(map['startDate']),
      endDate: _parseDate(map['endDate']),
      reportType: map['reportType']?.toString() ?? '',
      grossSales: (map['grossSales'] as num).toDouble(),
      netSales: (map['netSales'] as num).toDouble(),
      taxAmount: (map['taxAmount'] as num).toDouble(),
      serviceChargeAmount: (map['serviceChargeAmount'] as num).toDouble(),
      transactionCount: map['transactionCount'] as int,
      uniqueCustomers: map['uniqueCustomers'] as int,
      averageTicket: (map['averageTicket'] as num).toDouble(),
      averageTransactionTime: (map['averageTransactionTime'] as num).toDouble(),
      topCategories: _parseMapStringDouble(map['topCategories']),
      paymentMethods: _parseMapStringDouble(map['paymentMethods']),
      generatedAt: _parseDate(map['generatedAt']),
    );
  }

  /// JSON serialization
  Map<String, dynamic> toJson() => toMap();

  /// JSON deserialization
  static SalesReport fromJson(dynamic json) {
    if (json is String && json.isNotEmpty) {
      return fromMap(jsonDecode(json) as Map<String, dynamic>);
    }
    return fromMap(json as Map<String, dynamic>);
  }

  /// Copy with modifications
  SalesReport copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    String? reportType,
    double? grossSales,
    double? netSales,
    double? taxAmount,
    double? serviceChargeAmount,
    int? transactionCount,
    int? uniqueCustomers,
    double? averageTicket,
    double? averageTransactionTime,
    Map<String, double>? topCategories,
    Map<String, double>? paymentMethods,
    DateTime? generatedAt,
  }) {
    return SalesReport(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reportType: reportType ?? this.reportType,
      grossSales: grossSales ?? this.grossSales,
      netSales: netSales ?? this.netSales,
      taxAmount: taxAmount ?? this.taxAmount,
      serviceChargeAmount: serviceChargeAmount ?? this.serviceChargeAmount,
      transactionCount: transactionCount ?? this.transactionCount,
      uniqueCustomers: uniqueCustomers ?? this.uniqueCustomers,
      averageTicket: averageTicket ?? this.averageTicket,
      averageTransactionTime: averageTransactionTime ?? this.averageTransactionTime,
      topCategories: topCategories ?? this.topCategories,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

class ReportPeriod {
  final String label;
  final DateTime startDate;
  final DateTime endDate;

  ReportPeriod({
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  static ReportPeriod today() {
    final now = DateTime.now();
    return ReportPeriod(
      label: 'Today',
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static ReportPeriod thisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return ReportPeriod(
      label: 'This Week',
      startDate: DateTime(weekStart.year, weekStart.month, weekStart.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static ReportPeriod thisMonth() {
    final now = DateTime.now();
    return ReportPeriod(
      label: 'This Month',
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static ReportPeriod lastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayOfLastMonth = DateTime(now.year, now.month, 0);
    return ReportPeriod(
      label: 'Last Month',
      startDate: lastMonth,
      endDate: DateTime(
        lastDayOfLastMonth.year,
        lastDayOfLastMonth.month,
        lastDayOfLastMonth.day,
        23,
        59,
        59,
      ),
    );
  }

  static ReportPeriod yesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return ReportPeriod(
      label: 'Yesterday',
      startDate: DateTime(yesterday.year, yesterday.month, yesterday.day),
      endDate: DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
        59,
      ),
    );
  }

  static ReportPeriod lastWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final thisWeekStart = now.subtract(Duration(days: weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(days: 1));
    return ReportPeriod(
      label: 'Last Week',
      startDate: DateTime(
        lastWeekStart.year,
        lastWeekStart.month,
        lastWeekStart.day,
      ),
      endDate: DateTime(
        lastWeekEnd.year,
        lastWeekEnd.month,
        lastWeekEnd.day,
        23,
        59,
        59,
      ),
    );
  }

  static ReportPeriod thisYear() {
    final now = DateTime.now();
    return ReportPeriod(
      label: 'This Year',
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  static ReportPeriod lastYear() {
    final now = DateTime.now();
    return ReportPeriod(
      label: 'Last Year',
      startDate: DateTime(now.year - 1, 1, 1),
      endDate: DateTime(now.year - 1, 12, 31, 23, 59, 59),
    );
  }
}
