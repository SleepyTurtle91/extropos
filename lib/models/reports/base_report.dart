/// Base Report Model
/// Base class for all report types
library;

/// Base class for all reports with common metadata
class BaseReport {
  final String id;
  final DateTime generatedAt;
  final DateTime startDate;
  final DateTime endDate;
  final String periodLabel;

  BaseReport({
    required this.id,
    required this.generatedAt,
    required this.startDate,
    required this.endDate,
    required this.periodLabel,
  });

  /// Get the duration of the report period in days
  int get periodDays => endDate.difference(startDate).inDays + 1;

  /// Check if the report is for today
  bool get isToday {
    final now = DateTime.now();
    return startDate.year == now.year &&
        startDate.month == now.month &&
        startDate.day == now.day;
  }

  /// Check if the report is for this week
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return startDate.isAfter(weekStart) || startDate.isAtSameMomentAs(weekStart);
  }

  /// Check if the report is for this month
  bool get isThisMonth {
    final now = DateTime.now();
    return startDate.year == now.year && startDate.month == now.month;
  }
}

/// Export format options for reports
enum ExportFormat {
  pdf,
  csv,
  excel,
  json,
}

/// Product bundle suggestion for basket analysis
class ProductBundle {
  final List<String> productIds;
  final List<String> productNames;
  final double confidence;
  final int occurrences;
  final double potentialRevenue;

  ProductBundle({
    required this.productIds,
    required this.productNames,
    required this.confidence,
    required this.occurrences,
    required this.potentialRevenue,
  });
}

/// Forecast item for demand forecasting
class ForecastItem {
  final String productId;
  final String productName;
  final DateTime forecastDate;
  final double predictedDemand;
  final double confidence;
  final String trendDirection;

  ForecastItem({
    required this.productId,
    required this.productName,
    required this.forecastDate,
    required this.predictedDemand,
    required this.confidence,
    required this.trendDirection,
  });
}

/// Cash flow transaction record
class CashFlowTransaction {
  final String id;
  final DateTime timestamp;
  final String type; // 'sale', 'refund', 'expense', 'adjustment'
  final double amount;
  final String description;
  final String? category;

  CashFlowTransaction({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.amount,
    required this.description,
    this.category,
  });
}

/// Payment method breakdown data
class PaymentMethodData {
  final String methodName;
  final int transactionCount;
  final double totalAmount;
  final double averageTransactionValue;
  final double percentage;

  PaymentMethodData({
    required this.methodName,
    required this.transactionCount,
    required this.totalAmount,
    required this.averageTransactionValue,
    required this.percentage,
  });
}

/// Business session summary data
class BusinessSessionData {
  final String sessionId;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String openedBy;
  final String? closedBy;
  final double openingCash;
  final double closingCash;
  final double expectedCash;
  final double variance;

  BusinessSessionData({
    required this.sessionId,
    required this.openedAt,
    this.closedAt,
    required this.openedBy,
    this.closedBy,
    required this.openingCash,
    required this.closingCash,
    required this.expectedCash,
    required this.variance,
  });
}

/// Cash reconciliation data
class CashReconciliation {
  final double systemCashTotal;
  final double actualCashCounted;
  final double variance;
  final Map<String, int> denominationCounts;
  final List<String> discrepancyNotes;

  CashReconciliation({
    required this.systemCashTotal,
    required this.actualCashCounted,
    required this.variance,
    required this.denominationCounts,
    required this.discrepancyNotes,
  });

  bool get isBalanced => variance.abs() < 0.01;
}

/// Shift summary data for employees
class ShiftSummary {
  final String shiftId;
  final String employeeId;
  final String employeeName;
  final DateTime startTime;
  final DateTime? endTime;
  final int transactionCount;
  final double totalSales;
  final double averageTransactionValue;
  final int refundCount;

  ShiftSummary({
    required this.shiftId,
    required this.employeeId,
    required this.employeeName,
    required this.startTime,
    this.endTime,
    required this.transactionCount,
    required this.totalSales,
    required this.averageTransactionValue,
    required this.refundCount,
  });

  Duration? get duration => endTime?.difference(startTime);
}

/// Profit/Loss item breakdown
class ProfitLossItem {
  final String category;
  final double revenue;
  final double cost;
  final double profit;
  final double margin;

  ProfitLossItem({
    required this.category,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
  });

  double get marginPercentage => revenue > 0 ? (margin / revenue) * 100 : 0;
}

/// ABC Analysis item
class ABCItem {
  final String productId;
  final String productName;
  final String category;
  final double revenue;
  final double revenuePercentage;
  final double cumulativePercentage;
  final String classification; // 'A', 'B', or 'C'

  ABCItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.revenue,
    required this.revenuePercentage,
    required this.cumulativePercentage,
    required this.classification,
  });

  bool get isClassA => classification == 'A';
  bool get isClassB => classification == 'B';
  bool get isClassC => classification == 'C';
}
