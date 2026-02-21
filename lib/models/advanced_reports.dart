/// Base class for all report types
abstract class BaseReport {
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
}

/// Enhanced Sales & Revenue Reports
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

/// Inventory & Cost Reports
class InventoryReport extends BaseReport {
  final List<InventoryItemData> inventoryItems;
  final Map<String, double> stockValueByCategory;
  final List<String> lowStockItems;
  final List<String> outOfStockItems;
  final double totalInventoryValue;
  final double inventoryTurnoverRate;

  InventoryReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.inventoryItems,
    required this.stockValueByCategory,
    required this.lowStockItems,
    required this.outOfStockItems,
    required this.totalInventoryValue,
    required this.inventoryTurnoverRate,
  });
}

class InventoryItemData {
  final String itemId;
  final String itemName;
  final String category;
  final int currentStock;
  final int reorderPoint;
  final double costOfGoodsSold;
  final double grossMarginReturnOnInvestment;
  final int daysSinceLastSale;
  final String
  stockStatus; // 'in_stock', 'low_stock', 'out_of_stock', 'overstocked'

  InventoryItemData({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.currentStock,
    required this.reorderPoint,
    required this.costOfGoodsSold,
    required this.grossMarginReturnOnInvestment,
    required this.daysSinceLastSale,
    required this.stockStatus,
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

/// Employee Performance Reports
class EmployeePerformanceReport extends BaseReport {
  final List<EmployeeData> employeePerformance;
  final Map<String, double> departmentPerformance;
  final String topPerformer;
  final String needsImprovement;

  EmployeePerformanceReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.employeePerformance,
    required this.departmentPerformance,
    required this.topPerformer,
    required this.needsImprovement,
  });
}

class EmployeeData {
  final String employeeId;
  final String employeeName;
  final double totalSales;
  final int transactionCount;
  final double averageTransactionValue;
  final double totalDiscountsGiven;
  final double tipsAccrued;
  final double laborCostPercentage;
  final int hoursWorked;
  final Map<String, int> voidedTransactions;
  final Map<String, double> refundsProcessed;

  EmployeeData({
    required this.employeeId,
    required this.employeeName,
    required this.totalSales,
    required this.transactionCount,
    required this.averageTransactionValue,
    required this.totalDiscountsGiven,
    required this.tipsAccrued,
    required this.laborCostPercentage,
    required this.hoursWorked,
    required this.voidedTransactions,
    required this.refundsProcessed,
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

/// Customer & Loyalty Reports
class CustomerReport extends BaseReport {
  final List<TopCustomerData> topCustomers;
  final Map<String, int> customerSegments;
  final List<InactiveCustomerData> inactiveCustomers;
  final int totalActiveCustomers;
  final double averageCustomerLifetimeValue;

  CustomerReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.topCustomers,
    required this.customerSegments,
    required this.inactiveCustomers,
    required this.totalActiveCustomers,
    required this.averageCustomerLifetimeValue,
  });
}

class TopCustomerData {
  final String customerId;
  final String customerName;
  final double totalSpent;
  final int visitCount;
  final double averageOrderValue;
  final DateTime lastVisit;
  final List<String> favoriteProducts;

  TopCustomerData({
    required this.customerId,
    required this.customerName,
    required this.totalSpent,
    required this.visitCount,
    required this.averageOrderValue,
    required this.lastVisit,
    required this.favoriteProducts,
  });
}

class InactiveCustomerData {
  final String customerId;
  final String customerName;
  final DateTime lastVisit;
  final double lastOrderValue;
  final int daysSinceLastVisit;
  final String segment;

  InactiveCustomerData({
    required this.customerId,
    required this.customerName,
    required this.lastVisit,
    required this.lastOrderValue,
    required this.daysSinceLastVisit,
    required this.segment,
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

class ProductBundle {
  final String bundleId;
  final List<String> products;
  final double bundleRevenue;
  final double averageBundleValue;
  final int frequency;

  ProductBundle({
    required this.bundleId,
    required this.products,
    required this.bundleRevenue,
    required this.averageBundleValue,
    required this.frequency,
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

/// Report Configuration and Filtering
enum ReportType {
  salesSummary,
  productSales,
  categorySales,
  paymentMethod,
  inventory,
  shrinkage,
  employeePerformance,
  laborCost,
  customerAnalysis,
  basketAnalysis,
  loyaltyProgram,
  dayClosing,
  profitLoss,
  cashFlow,
  taxSummary,
  inventoryValuation,
  abcAnalysis,
  demandForecasting,
  menuEngineering,
  tablePerformance,
  dailyStaffPerformance,
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

/// Export and Scheduling
enum ExportFormat { csv, pdf, excel }

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

// Day Closing Report Classes
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

class CashReconciliation {
  final double openingFloat;
  final double cashSales;
  final double cashRefunds;
  final double paidOuts;
  final double paidIns;
  final double expectedCash;
  final double actualCash;
  final String notes;

  CashReconciliation({
    required this.openingFloat,
    required this.cashSales,
    required this.cashRefunds,
    required this.paidOuts,
    required this.paidIns,
    required this.expectedCash,
    required this.actualCash,
    required this.notes,
  });

  double get variance => actualCash - expectedCash;
  bool get isBalanced => variance.abs() < 0.01; // Within 1 cent tolerance
}

class ShiftSummary {
  final String employeeId;
  final String employeeName;
  final DateTime shiftStart;
  final DateTime? shiftEnd;
  final double salesDuringShift;
  final int transactionsDuringShift;
  final double cashHandled;
  final Duration shiftDuration;

  ShiftSummary({
    required this.employeeId,
    required this.employeeName,
    required this.shiftStart,
    this.shiftEnd,
    required this.salesDuringShift,
    required this.transactionsDuringShift,
    required this.cashHandled,
    required this.shiftDuration,
  });

  bool get isActive => shiftEnd == null;
}

/// Profit & Loss Report
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

/// Cash Flow Report
class CashFlowReport extends BaseReport {
  final double openingCash;
  final double closingCash;
  final double cashInflows;
  final double cashOutflows;
  final double netCashFlow;
  final Map<String, double> inflowBreakdown;
  final Map<String, double> outflowBreakdown;
  final List<CashFlowTransaction> transactions;

  CashFlowReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.openingCash,
    required this.closingCash,
    required this.cashInflows,
    required this.cashOutflows,
    required this.netCashFlow,
    required this.inflowBreakdown,
    required this.outflowBreakdown,
    required this.transactions,
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

/// Tax Summary Report
class TaxSummaryReport extends BaseReport {
  final double totalTaxCollected;
  final double totalTaxPaid;
  final Map<String, double> taxBreakdown;
  final List<TaxItem> taxItems;
  final double taxLiability;

  TaxSummaryReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.totalTaxCollected,
    required this.totalTaxPaid,
    required this.taxBreakdown,
    required this.taxItems,
    required this.taxLiability,
  });
}

class TaxItem {
  final String taxType;
  final double rate;
  final double amount;
  final DateTime date;

  TaxItem({
    required this.taxType,
    required this.rate,
    required this.amount,
    required this.date,
  });
}

/// Inventory Valuation Report
class InventoryValuationReport extends BaseReport {
  final double totalInventoryValue;
  final double totalCostValue;
  final double totalRetailValue;
  final Map<String, double> valuationByCategory;
  final List<InventoryValuationItem> valuationItems;
  final double inventoryTurnoverRatio;

  InventoryValuationReport({
    required super.id,
    required super.generatedAt,
    required super.startDate,
    required super.endDate,
    required super.periodLabel,
    required this.totalInventoryValue,
    required this.totalCostValue,
    required this.totalRetailValue,
    required this.valuationByCategory,
    required this.valuationItems,
    required this.inventoryTurnoverRatio,
  });
}

class InventoryValuationItem {
  final String itemId;
  final String itemName;
  final int quantity;
  final double costPrice;
  final double retailPrice;
  final double totalCostValue;
  final double totalRetailValue;
  final double profitMargin;

  InventoryValuationItem({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.costPrice,
    required this.retailPrice,
    required this.totalCostValue,
    required this.totalRetailValue,
    required this.profitMargin,
  });
}

/// ABC Analysis Report (Pareto Analysis)
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

/// Demand Forecasting Report
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

/// Menu Engineering Report
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

/// Table Performance Report (Restaurant Mode)
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
