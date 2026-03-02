/// Auto-generated from advanced_reports.dart - Do not edit manually
///
/// Reports Inventory
library;

import 'package:extropos/models/reports/reports_base.dart';

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

