import 'dart:convert';

import 'package:extropos/models/isar/inventory_model.dart';
import 'package:extropos/models/isar/product_model.dart';
import 'package:extropos/models/isar/transaction_model.dart';

/// Extension methods for IsarProduct to work with JSON fields.
extension IsarProductExtensions on IsarProduct {
  /// Get parsed variants from variantsJson.
  /// 
  /// Returns empty list if variantsJson is null or invalid.
  List<Map<String, dynamic>> getVariants() {
    if (variantsJson == null || variantsJson!.isEmpty) return [];
    
    try {
      final decoded = jsonDecode(variantsJson!);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Failed to decode variants: $e');
      return [];
    }
  }
  
  /// Get parsed modifier group IDs from modifierGroupIdsJson.
  List<String> getModifierGroupIds() {
    if (modifierGroupIdsJson == null || modifierGroupIdsJson!.isEmpty) return [];
    
    try {
      final decoded = jsonDecode(modifierGroupIdsJson!);
      if (decoded is List) {
        return decoded.cast<String>();
      }
      return [];
    } catch (e) {
      print('Failed to decode modifier group IDs: $e');
      return [];
    }
  }
  
  /// Check if product is currently in stock.
  bool isInStock() {
    return quantity > 0;
  }
  
  /// Check if product needs restocking based on quantity.
  /// 
  /// Uses a threshold of 5 units by default.
  bool needsRestock({double threshold = 5.0}) {
    return quantity < threshold;
  }
  
  /// Calculate profit margin if costPerUnit is available.
  /// 
  /// Returns null if costPerUnit is not set.
  double? getProfitMargin() {
    if (costPerUnit == null || costPerUnit == 0) return null;
    return ((price - costPerUnit!) / price) * 100;
  }
  
  /// Get inventory value (quantity * costPerUnit).
  double? getInventoryValue() {
    if (costPerUnit == null) return null;
    return quantity * costPerUnit!;
  }
  
  /// Get display name with SKU if available.
  String getDisplayName() {
    if (sku != null && sku!.isNotEmpty) {
      return '$name ($sku)';
    }
    return name;
  }
  
  /// Check if product has variants.
  bool hasVariants() {
    return getVariants().isNotEmpty;
  }
  
  /// Check if product has modifiers.
  bool hasModifiers() {
    return getModifierGroupIds().isNotEmpty;
  }
}

/// Extension methods for IsarTransaction to work with JSON fields.
extension IsarTransactionExtensions on IsarTransaction {
  /// Get parsed line items from itemsJson.
  List<Map<String, dynamic>> getItems() {
    try {
      final decoded = jsonDecode(itemsJson);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Failed to decode items: $e');
      return [];
    }
  }
  
  /// Get parsed payment splits from paymentsJson.
  /// 
  /// Returns empty list if no payment splits.
  List<Map<String, dynamic>> getPayments() {
    if (paymentsJson == null || paymentsJson!.isEmpty) return [];
    
    try {
      final decoded = jsonDecode(paymentsJson!);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Failed to decode payments: $e');
      return [];
    }
  }
  
  /// Get total number of items in transaction.
  int getTotalItemCount() {
    final items = getItems();
    return items.fold<int>(0, (sum, item) {
      final quantity = item['quantity'] as num?;
      return sum + (quantity?.toInt() ?? 0);
    });
  }
  
  /// Get net total (after refunds).
  double getNetTotal() {
    return totalAmount - refundAmount;
  }
  
  /// Check if transaction has been refunded (partial or full).
  bool isRefunded() {
    return refundStatus != 'none';
  }
  
  /// Check if transaction is fully refunded.
  bool isFullyRefunded() {
    return refundStatus == 'full';
  }
  
  /// Check if transaction is partially refunded.
  bool isPartiallyRefunded() {
    return refundStatus == 'partial';
  }
  
  /// Get refund percentage (0-100).
  double getRefundPercentage() {
    if (totalAmount == 0) return 0.0;
    return (refundAmount / totalAmount) * 100;
  }
  
  /// Get transaction date as DateTime.
  DateTime getTransactionDateTime() {
    return DateTime.fromMillisecondsSinceEpoch(transactionDate);
  }
  
  /// Check if transaction is from today.
  bool isToday() {
    final txDate = getTransactionDateTime();
    final now = DateTime.now();
    return txDate.year == now.year &&
           txDate.month == now.month &&
           txDate.day == now.day;
  }
  
  /// Get formatted transaction date (YYYY-MM-DD).
  String getFormattedDate() {
    final date = getTransactionDateTime();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// Check if transaction has multiple payment methods.
  bool hasSplitPayments() {
    return getPayments().isNotEmpty;
  }
  
  /// Get business mode as readable string.
  String getBusinessModeDisplay() {
    switch (businessMode.toLowerCase()) {
      case 'retail':
        return 'Retail';
      case 'cafe':
        return 'Cafe';
      case 'restaurant':
        return 'Restaurant';
      default:
        return businessMode;
    }
  }
}

/// Extension methods for IsarInventory to work with JSON fields.
extension IsarInventoryExtensions on IsarInventory {
  /// Get parsed stock movements from movementsJson.
  List<Map<String, dynamic>> getMovements() {
    try {
      final decoded = jsonDecode(movementsJson);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Failed to decode movements: $e');
      return [];
    }
  }
  
  /// Get latest stock movement.
  Map<String, dynamic>? getLatestMovement() {
    final movements = getMovements();
    if (movements.isEmpty) return null;
    return movements.last;
  }
  
  /// Calculate total inventory value (currentQuantity * costPerUnit).
  double calculateInventoryValue() {
    if (costPerUnit == null) return 0.0;
    return currentQuantity * costPerUnit!;
  }
  
  /// Get stock status as enum.
  StockStatus getStockStatus() {
    if (currentQuantity == 0) return StockStatus.outOfStock;
    if (isStockLow()) return StockStatus.low;
    if (needsReorder()) return StockStatus.reorderPoint;
    if (currentQuantity >= maxStockLevel && maxStockLevel > 0) return StockStatus.overstock;
    return StockStatus.normal;
  }
  
  /// Get stock status as readable string.
  String getStockStatusDisplay() {
    switch (getStockStatus()) {
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.low:
        return 'Low Stock';
      case StockStatus.reorderPoint:
        return 'Reorder Point';
      case StockStatus.overstock:
        return 'Overstock';
      case StockStatus.normal:
        return 'Normal';
    }
  }
  
  /// Get percentage of stock remaining (0-100).
  /// 
  /// Returns null if maxStockLevel is not set.
  double? getStockPercentage() {
    if (maxStockLevel == 0) return null;
    return (currentQuantity / maxStockLevel) * 100;
  }
  
  /// Get total quantity added (from all positive movements).
  double getTotalQuantityAdded() {
    final movements = getMovements();
    return movements.fold<double>(0.0, (sum, movement) {
      final quantity = movement['quantity'] as num?;
      if (quantity != null && quantity > 0) {
        return sum + quantity.toDouble();
      }
      return sum;
    });
  }
  
  /// Get total quantity removed (from all negative movements).
  double getTotalQuantityRemoved() {
    final movements = getMovements();
    return movements.fold<double>(0.0, (sum, movement) {
      final quantity = movement['quantity'] as num?;
      if (quantity != null && quantity < 0) {
        return sum + quantity.abs().toDouble();
      }
      return sum;
    });
  }
  
  /// Get movement count by type (e.g., 'sale', 'restock', 'adjustment').
  Map<String, int> getMovementCountsByType() {
    final movements = getMovements();
    final counts = <String, int>{};
    
    for (final movement in movements) {
      final type = movement['type'] as String?;
      if (type != null) {
        counts[type] = (counts[type] ?? 0) + 1;
      }
    }
    
    return counts;
  }
  
  /// Get total quantity change by type.
  Map<String, double> getTotalQuantityChangeByType() {
    final movements = getMovements();
    final totals = <String, double>{};
    
    for (final movement in movements) {
      final type = movement['type'] as String?;
      final quantity = (movement['quantity'] as num?)?.toDouble();
      
      if (type != null && quantity != null) {
        totals[type] = (totals[type] ?? 0.0) + quantity;
      }
    }
    
    return totals;
  }
  
  /// Check if inventory value is calculated.
  bool hasInventoryValue() {
    return inventoryValue != null && costPerUnit != null;
  }
  
  /// Get days until reorder needed (estimated).
  /// 
  /// Returns null if not enough data or not applicable.
  /// [averageDailySales] should be provided for accurate estimate.
  int? getDaysUntilReorder({double? averageDailySales}) {
    if (averageDailySales == null || averageDailySales <= 0) return null;
    if (currentQuantity <= minStockLevel) return 0;
    
    final quantityUntilReorder = currentQuantity - minStockLevel;
    return (quantityUntilReorder / averageDailySales).floor();
  }
}

/// Stock status enum for inventory.
enum StockStatus {
  outOfStock,
  low,
  reorderPoint,
  normal,
  overstock,
}
