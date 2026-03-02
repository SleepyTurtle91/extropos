/// Auto-generated from advanced_reports.dart - Do not edit manually
///
/// Reports Data
library;

import 'package:extropos/models/reports/reports_base.dart';
import 'package:extropos/models/reports/reports_inventory.dart' show ProductBundle;
import 'package:extropos/models/reports/reports_sales.dart' show ForecastItem;

class PaymentMethodData {
  final String methodId;
  final String methodName;
  final double totalAmount;
  final int transactionCount;
  final double averageTransaction;
  final double percentageOfTotal;

  PaymentMethodData({
    required this.methodId,
    required this.methodName,
    required this.totalAmount,
    required this.transactionCount,
    required this.averageTransaction,
    required this.percentageOfTotal,
  });
}

class ShrinkageReport extends BaseReport {
  final List<ShrinkageData> shrinkageItems;
  final double totalShrinkageValue;
  final double totalShrinkagePercentage;
  final Map<String, double> shrinkageByCategory;
  final Map<String, double> shrinkageByReason;

  ShrinkageReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.shrinkageItems,
    required this.totalShrinkageValue,
    required this.totalShrinkagePercentage,
    required this.shrinkageByCategory,
    required this.shrinkageByReason,
  });
}

class ShrinkageData {
  final String itemId;
  final String itemName;
  final int expectedQuantity;
  final int actualQuantity;
  final int variance;
  final double varianceValue;
  final String reason; // 'theft', 'damage', 'waste', 'unknown'
  final DateTime lastCountDate;

  ShrinkageData({
    required this.itemId,
    required this.itemName,
    required this.expectedQuantity,
    required this.actualQuantity,
    required this.variance,
    required this.varianceValue,
    required this.reason,
    required this.lastCountDate,
  });
}

class LaborCostReport extends BaseReport {
  final double totalLaborCost;
  final double laborCostPercentage;
  final Map<String, double> laborCostByDepartment;
  final Map<String, double> laborCostByShift;
  final List<LaborEfficiencyData> efficiencyData;

  LaborCostReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.totalLaborCost,
    required this.laborCostPercentage,
    required this.laborCostByDepartment,
    required this.laborCostByShift,
    required this.efficiencyData,
  });
}

class LaborEfficiencyData {
  final String shift;
  final String department;
  final int scheduledHours;
  final int actualHours;
  final double salesDuringShift;
  final double laborCostEfficiency;

  LaborEfficiencyData({
    required this.shift,
    required this.department,
    required this.scheduledHours,
    required this.actualHours,
    required this.salesDuringShift,
    required this.laborCostEfficiency,
  });
}

class BasketAnalysisReport extends BaseReport {
  final Map<String, List<String>> frequentlyBoughtTogether;
  final Map<String, double> productAffinityScores;
  final List<ProductBundle> recommendedBundles;
  final Map<String, Map<String, double>> purchasePatterns;

  BasketAnalysisReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.frequentlyBoughtTogether,
    required this.productAffinityScores,
    required this.recommendedBundles,
    required this.purchasePatterns,
  });
}

class LoyaltyProgramReport extends BaseReport {
  final int totalMembers;
  final int activeMembers;
  final double totalPointsIssued;
  final double totalPointsRedeemed;
  final double redemptionRate;
  final double revenueFromLoyaltyMembers;
  final Map<String, double> pointsByTier;

  LoyaltyProgramReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.totalMembers,
    required this.activeMembers,
    required this.totalPointsIssued,
    required this.totalPointsRedeemed,
    required this.redemptionRate,
    required this.revenueFromLoyaltyMembers,
    required this.pointsByTier,
  });
}

class ReportFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? employeeId;
  final String? categoryId;
  final String? paymentMethodId;
  final String? locationId;
  final int? limit;
  final bool? includeInactive;

  ReportFilter({
    this.startDate,
    this.endDate,
    this.employeeId,
    this.categoryId,
    this.paymentMethodId,
    this.locationId,
    this.limit,
    this.includeInactive,
  });

  ReportFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? employeeId,
    String? categoryId,
    String? paymentMethodId,
    String? locationId,
    int? limit,
    bool? includeInactive,
  }) {
    return ReportFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      employeeId: employeeId ?? this.employeeId,
      categoryId: categoryId ?? this.categoryId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      locationId: locationId ?? this.locationId,
      limit: limit ?? this.limit,
      includeInactive: includeInactive ?? this.includeInactive,
    );
  }
}

class ReportSchedule {
  final String id;
  final String reportType;
  final ReportFilter filter;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final List<String> recipients;
  final ExportFormat format;
  final bool isActive;

  ReportSchedule({
    required this.id,
    required this.reportType,
    required this.filter,
    required this.frequency,
    required this.recipients,
    required this.format,
    this.isActive = true,
  });
}

class BusinessSessionData {
  final DateTime sessionStart;
  final DateTime sessionEnd;
  final double openingFloat;
  final double totalSales;
  final double totalRefunds;
  final double totalDiscounts;
  final double totalTax;
  final double totalServiceCharge;
  final int totalTransactions;
  final Map<String, double> paymentMethodBreakdown;

  BusinessSessionData({
    required this.sessionStart,
    required this.sessionEnd,
    required this.openingFloat,
    required this.totalSales,
    required this.totalRefunds,
    required this.totalDiscounts,
    required this.totalTax,
    required this.totalServiceCharge,
    required this.totalTransactions,
    required this.paymentMethodBreakdown,
  });

  double get netSales => totalSales - totalRefunds - totalDiscounts;
  double get grossRevenue => netSales + totalTax + totalServiceCharge;
}

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
}

class ABCItem {
  final String itemId;
  final String itemName;
  final double revenue;
  final double percentageOfTotal;
  final String category; // 'A', 'B', or 'C'
  final int rank;

  ABCItem({
    required this.itemId,
    required this.itemName,
    required this.revenue,
    required this.percentageOfTotal,
    required this.category,
    required this.rank,
  });
}

class DemandForecastingReport extends BaseReport {
  final List<ForecastItem> forecastItems;
  final Map<String, List<double>> historicalData;
  final Map<String, List<double>> forecastData;
  final double forecastAccuracy;
  final String forecastingMethod;

  DemandForecastingReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.forecastItems,
    required this.historicalData,
    required this.forecastData,
    required this.forecastAccuracy,
    required this.forecastingMethod,
  });
}

class MenuEngineeringReport extends BaseReport {
  final List<MenuItem> menuItems;
  final Map<String, List<MenuItem>> categorizedItems;
  final int starsCount;
  final int plowhorsesCount;
  final int puzzlesCount;
  final int dogsCount;

  MenuEngineeringReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.menuItems,
    required this.categorizedItems,
    required this.starsCount,
    required this.plowhorsesCount,
    required this.puzzlesCount,
    required this.dogsCount,
  });
}

class MenuItem {
  final String itemId;
  final String itemName;
  final double popularity; // Percentage of orders containing this item
  final double profitability; // Profit margin percentage
  final String category; // 'star', 'plowhorse', 'puzzle', 'dog'
  final int unitsSold;
  final double revenue;
  final double cost;
  final double profit;

  MenuItem({
    required this.itemId,
    required this.itemName,
    required this.popularity,
    required this.profitability,
    required this.category,
    required this.unitsSold,
    required this.revenue,
    required this.cost,
    required this.profit,
  });
}

class TablePerformanceData {
  final String tableId;
  final String tableName;
  final int capacity;
  final double totalRevenue;
  final int totalOrders;
  final Duration averageOccupancyTime;
  final double revenuePerHour;
  final int turnoverCount;

  TablePerformanceData({
    required this.tableId,
    required this.tableName,
    required this.capacity,
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOccupancyTime,
    required this.revenuePerHour,
    required this.turnoverCount,
  });
}

