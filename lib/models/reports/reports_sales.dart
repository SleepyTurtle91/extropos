/// Auto-generated from advanced_reports.dart - Do not edit manually
///
/// Reports Sales
library;
import 'package:extropos/models/reports/reports_data.dart' show TablePerformanceData, PaymentMethodData, BusinessSessionData, ProfitLossItem, ABCItem;
import 'package:extropos/models/reports/reports_finance.dart' show CashReconciliation;
import 'package:extropos/models/reports/reports_staff.dart' show ShiftSummary;

import 'package:extropos/models/reports/reports_base.dart';

class SalesSummaryReport extends BaseReport {
  final double grossSales;
  final double netSales;
  final double totalDiscounts;
  final double totalRefunds;
  final double taxCollected;
  final double averageTransactionValue;
  final int totalTransactions;
  final Map<String, double> taxBreakdown;
  final Map<String, double> hourlySales;
  final Map<String, double> dailySales;

  SalesSummaryReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.grossSales,
    required this.netSales,
    required this.totalDiscounts,
    required this.totalRefunds,
    required this.taxCollected,
    required this.averageTransactionValue,
    required this.totalTransactions,
    required this.taxBreakdown,
    required this.hourlySales,
    required this.dailySales,
  });

  double get salesPerHour =>
      totalTransactions > 0 ? grossSales / (totalTransactions / 24) : 0;
  double get salesPerDay =>
      grossSales / (endDate.difference(startDate).inDays + 1);
}

class ProductSalesReport extends BaseReport {
  final List<ProductSalesData> productSales;
  final Map<String, int> topSellingProducts;
  final Map<String, double> worstSellingProducts;
  final double totalUnitsSold;
  final double totalRevenue;

  ProductSalesReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.productSales,
    required this.topSellingProducts,
    required this.worstSellingProducts,
    required this.totalUnitsSold,
    required this.totalRevenue,
  });
}

class ProductSalesData {
  final String productId;
  final String productName;
  final String category;
  final int unitsSold;
  final double totalRevenue;
  final double averagePrice;
  final double profitMargin; // Requires COGS data
  final double returnRate;
  final int returnCount;

  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.category,
    required this.unitsSold,
    required this.totalRevenue,
    required this.averagePrice,
    this.profitMargin = 0.0,
    this.returnRate = 0.0,
    this.returnCount = 0,
  });
}

class CategorySalesReport extends BaseReport {
  final Map<String, CategorySalesData> categorySales;
  final String topPerformingCategory;
  final String lowestPerformingCategory;

  CategorySalesReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.categorySales,
    required this.topPerformingCategory,
    required this.lowestPerformingCategory,
  });
}

class CategorySalesData {
  final String categoryId;
  final String categoryName;
  final double revenue;
  final double grossProfit;
  final int transactionCount;
  final double averageTransactionValue;
  final Map<String, int> topProducts;

  CategorySalesData({
    required this.categoryId,
    required this.categoryName,
    required this.revenue,
    required this.grossProfit,
    required this.transactionCount,
    required this.averageTransactionValue,
    required this.topProducts,
  });
}

class PaymentMethodReport extends BaseReport {
  final Map<String, PaymentMethodData> paymentBreakdown;
  final String mostUsedMethod;
  final String highestRevenueMethod;
  final double totalProcessed;

  PaymentMethodReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.paymentBreakdown,
    required this.mostUsedMethod,
    required this.highestRevenueMethod,
    required this.totalProcessed,
  });
}

class DayClosingReport {
  final BusinessSessionData sessionData;
  final CashReconciliation cashReconciliation;
  final List<ShiftSummary> shiftSummaries;
  final DateTime reportDate;
  final String generatedBy;

  DayClosingReport({
    required this.sessionData,
    required this.cashReconciliation,
    required this.shiftSummaries,
    required this.reportDate,
    required this.generatedBy,
  });

  double get totalSales => sessionData.totalSales;
  double get totalRefunds => sessionData.totalRefunds;
  double get netSales => sessionData.netSales;
  double get cashExpected => cashReconciliation.expectedCash;
  double get cashActual => cashReconciliation.actualCash;
  double get cashVariance => cashReconciliation.variance;
}

class ProfitLossReport extends BaseReport {
  final double totalRevenue;
  final double costOfGoodsSold;
  final double grossProfit;
  final double operatingExpenses;
  final double netProfit;
  final double profitMargin;
  final Map<String, double> revenueBreakdown;
  final Map<String, double> expenseBreakdown;
  final List<ProfitLossItem> profitLossItems;

  ProfitLossReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.totalRevenue,
    required this.costOfGoodsSold,
    required this.grossProfit,
    required this.operatingExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.revenueBreakdown,
    required this.expenseBreakdown,
    required this.profitLossItems,
  });
}

class CashFlowTransaction {
  final DateTime date;
  final String type; // 'inflow' or 'outflow'
  final String category;
  final double amount;
  final String description;

  CashFlowTransaction({
    required this.date,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
  });
}

class ABCAnalysisReport extends BaseReport {
  final List<ABCItem> abcItems;
  final Map<String, List<ABCItem>> categorizedItems;
  final double totalRevenue;
  final double aCategoryRevenue;
  final double bCategoryRevenue;
  final double cCategoryRevenue;

  ABCAnalysisReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.abcItems,
    required this.categorizedItems,
    required this.totalRevenue,
    required this.aCategoryRevenue,
    required this.bCategoryRevenue,
    required this.cCategoryRevenue,
  });
}

class ForecastItem {
  final String itemId;
  final String itemName;
  final List<double> historicalSales;
  final List<double> forecastedSales;
  final double confidenceLevel;

  ForecastItem({
    required this.itemId,
    required this.itemName,
    required this.historicalSales,
    required this.forecastedSales,
    required this.confidenceLevel,
  });
}

class TablePerformanceReport extends BaseReport {
  final List<TablePerformanceData> tableData;
  final Map<String, double> revenueByTable;
  final Map<String, int> occupancyByTable;
  final double averageTableTurnover;
  final double averageRevenuePerTable;
  final int totalTables;
  final int occupiedTables;

  TablePerformanceReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.tableData,
    required this.revenueByTable,
    required this.occupancyByTable,
    required this.averageTableTurnover,
    required this.averageRevenuePerTable,
    required this.totalTables,
    required this.occupiedTables,
  });
}

