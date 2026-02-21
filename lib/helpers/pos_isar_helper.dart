import 'dart:convert';

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/isar/inventory_model.dart';
import 'package:extropos/models/isar/transaction_model.dart';
import 'package:extropos/services/isar_database_service.dart';

/// POS-specific helper methods for Isar integration.
/// 
/// Provides:
/// - Cart → Transaction conversion
/// - Inventory updates after sale
/// - Refund processing
/// - Daily sales summaries
/// - Revenue calculations
class POSIsarHelper {
  /// Create a transaction from cart items.
  /// 
  /// Automatically calculates subtotal, tax, service charge, and total.
  /// Uses BusinessInfo.instance for tax/service charge rates.
  /// Returns the saved transaction with Isar ID.
  static Future<IsarTransaction> createTransactionFromCart({
    required List<CartItem> cartItems,
    required String userId,
    required String paymentMethod,
    required String businessMode,
    String? tableId,
    int? orderNumber,
    String? customerId,
    double discountAmount = 0.0,
    List<Map<String, dynamic>>? paymentSplits,
  }) async {
    final businessInfo = BusinessInfo.instance;
    
    // Calculate subtotal
    final subtotal = cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    
    // Calculate tax
    final taxAmount = businessInfo.isTaxEnabled ? subtotal * businessInfo.taxRate : 0.0;
    
    // Calculate service charge
    final serviceChargeAmount = businessInfo.isServiceChargeEnabled
        ? subtotal * businessInfo.serviceChargeRate
        : 0.0;
    
    // Calculate total
    final totalAmount = subtotal + taxAmount + serviceChargeAmount - discountAmount;
    
    // Convert cart items to JSON
    final itemsJson = jsonEncode(
      cartItems.map((item) => {
        'productId': item.product.name,  // Use name as identifier (Product model doesn't have backendId)
        'productName': item.product.name,
        'quantity': item.quantity,
        'unitPrice': item.product.price,
        'lineTotal': item.product.price * item.quantity,
      }).toList(),
    );
    
    // Generate transaction number
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final transactionNumber = 'ORD-$dateStr-${now.millisecondsSinceEpoch % 1000}';
    
    // Create transaction
    final transaction = IsarTransaction(
      backendId: '', // Will be assigned by backend
      transactionNumber: transactionNumber,
      transactionDate: now.millisecondsSinceEpoch,
      userId: userId,
      subtotal: subtotal,
      taxAmount: taxAmount,
      serviceChargeAmount: serviceChargeAmount,
      totalAmount: totalAmount,
      discountAmount: discountAmount,
      paymentMethod: paymentMethod,
      businessMode: businessMode,
      tableId: tableId,
      orderNumber: orderNumber,
      customerId: customerId,
      itemsJson: itemsJson,
      paymentsJson: paymentSplits != null ? jsonEncode(paymentSplits) : null,
      isSynced: false, // Mark as unsynced
    );
    
    // Save to database
    await IsarDatabaseService.saveTransaction(transaction);
    
    return transaction;
  }
  
  /// Update inventory after a successful sale.
  /// 
  /// Decrements stock quantities and adds movement records.
  /// Returns list of updated inventory items.
  static Future<List<IsarInventory>> updateInventoryAfterSale({
    required List<CartItem> cartItems,
    required String transactionNumber,
    required String userId,
  }) async {
    final updatedInventory = <IsarInventory>[];
    
    for (final item in cartItems) {
      // Product model doesn't have backendId, use name as identifier
      final productId = item.product.name;
      if (productId.isEmpty) continue;
      
      // Get inventory record
      final inventory = await IsarDatabaseService.getInventoryByProductId(productId);
      if (inventory == null) {
        print('Warning: No inventory record for product $productId');
        continue;
      }
      
      // Add sale movement
      inventory.addMovement(
        type: 'sale',
        quantity: -item.quantity.toDouble(),
        reason: 'Sale: $transactionNumber',
        userId: userId,
      );
      
      // Update current quantity
      inventory.currentQuantity -= item.quantity.toDouble();
      
      // Mark as unsynced
      inventory.isSynced = false;
      inventory.updatedAt = DateTime.now().millisecondsSinceEpoch;
      
      // Save updated inventory
      await IsarDatabaseService.saveInventory(inventory);
      updatedInventory.add(inventory);
    }
    
    return updatedInventory;
  }
  
  /// Process a refund for a transaction.
  /// 
  /// Updates transaction refund status and restores inventory.
  /// Returns updated transaction.
  static Future<IsarTransaction> processRefund({
    required String transactionNumber,
    required double refundAmount,
    required String userId,
    bool isPartial = false,
    String reason = 'Customer request',
  }) async {
    // Get transaction - find by transactionNumber field
    final allTransactions = await IsarDatabaseService.getAllTransactions();
    IsarTransaction? transaction;
    
    for (final tx in allTransactions) {
      if (tx.transactionNumber == transactionNumber) {
        transaction = tx;
        break;
      }
    }
    
    if (transaction == null) {
      throw Exception('Transaction not found: $transactionNumber');
    }
    
    if (transaction.refundStatus == 'full') {
      throw Exception('Transaction already fully refunded');
    }
    
    // Update refund info
    transaction.refundAmount = transaction.refundAmount + refundAmount;
    transaction.refundStatus = isPartial ? 'partial' : 'full';
    transaction.isSynced = false;
    transaction.updatedAt = DateTime.now().millisecondsSinceEpoch;
    
    // Save updated transaction
    await IsarDatabaseService.saveTransaction(transaction);
    
    // Restore inventory if full refund
    if (!isPartial) {
      final items = jsonDecode(transaction.itemsJson) as List<dynamic>;
      
      for (final item in items) {
        final productId = item['productId'] as String?;
        final quantity = item['quantity'] as num?;
        
        if (productId == null || quantity == null) continue;
        
        final inventory = await IsarDatabaseService.getInventoryByProductId(productId);
        if (inventory == null) continue;
        
        // Add refund movement
        inventory.addMovement(
          type: 'refund',
          quantity: quantity.toDouble(),
          reason: 'Refund: $transactionNumber - $reason',
          userId: userId,
        );
        
        // Restore quantity
        inventory.currentQuantity += quantity.toDouble();
        inventory.isSynced = false;
        inventory.updatedAt = DateTime.now().millisecondsSinceEpoch;
        
        await IsarDatabaseService.saveInventory(inventory);
      }
    }
    
    return transaction;
  }
  
  /// Get daily sales summary.
  /// 
  /// Returns aggregated sales data for a specific date.
  static Future<DailySalesSummary> getDailySalesSummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final transactions = await IsarDatabaseService.getTransactionsByDateRange(
      startOfDay,
      endOfDay,
    );
    
    double grossSales = 0.0;
    double netSales = 0.0;
    double taxCollected = 0.0;
    double serviceChargeCollected = 0.0;
    double discounts = 0.0;
    double refunds = 0.0;
    int transactionCount = 0;
    int itemsSold = 0;
    
    final paymentMethodBreakdown = <String, double>{};
    
    for (final tx in transactions) {
      grossSales += tx.totalAmount;
      netSales += tx.subtotal;
      taxCollected += tx.taxAmount;
      serviceChargeCollected += tx.serviceChargeAmount;
      discounts += tx.discountAmount;
      refunds += tx.refundAmount;
      transactionCount++;
      
      // Count items
      final items = jsonDecode(tx.itemsJson) as List<dynamic>;
      itemsSold += items.fold<int>(0, (sum, item) => sum + (item['quantity'] as num).toInt());
      
      // Payment method breakdown
      paymentMethodBreakdown[tx.paymentMethod] =
          (paymentMethodBreakdown[tx.paymentMethod] ?? 0.0) + tx.totalAmount;
    }
    
    final averageTicket = transactionCount > 0 ? grossSales / transactionCount : 0.0;
    
    return DailySalesSummary(
      date: date,
      grossSales: grossSales,
      netSales: netSales,
      taxCollected: taxCollected,
      serviceChargeCollected: serviceChargeCollected,
      discounts: discounts,
      refunds: refunds,
      transactionCount: transactionCount,
      itemsSold: itemsSold,
      averageTicket: averageTicket,
      paymentMethodBreakdown: paymentMethodBreakdown,
    );
  }
  
  /// Get total revenue for a date range.
  static Future<double> getTotalRevenue(DateTime start, DateTime end) async {
    final transactions = await IsarDatabaseService.getTransactionsByDateRange(start, end);
    return transactions.fold<double>(0.0, (sum, tx) => sum + tx.totalAmount);
  }
  
  /// Get top selling products for a date range.
  static Future<List<ProductSalesData>> getTopSellingProducts({
    required DateTime start,
    required DateTime end,
    int limit = 10,
  }) async {
    final transactions = await IsarDatabaseService.getTransactionsByDateRange(start, end);
    
    final productSales = <String, ProductSalesData>{};
    
    for (final tx in transactions) {
      final items = jsonDecode(tx.itemsJson) as List<dynamic>;
      
      for (final item in items) {
        final productId = item['productId'] as String?;
        final productName = item['productName'] as String? ?? 'Unknown';
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        final revenue = (item['lineTotal'] as num?)?.toDouble() ?? 0.0;
        
        if (productId == null) continue;
        
        if (productSales.containsKey(productId)) {
          productSales[productId]!.unitsSold += quantity;
          productSales[productId]!.revenue += revenue;
        } else {
          productSales[productId] = ProductSalesData(
            productId: productId,
            productName: productName,
            unitsSold: quantity,
            revenue: revenue,
          );
        }
      }
    }
    
    final sortedProducts = productSales.values.toList()
      ..sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
    
    return sortedProducts.take(limit).toList();
  }
}

/// Daily sales summary data.
class DailySalesSummary {
  final DateTime date;
  final double grossSales;
  final double netSales;
  final double taxCollected;
  final double serviceChargeCollected;
  final double discounts;
  final double refunds;
  final int transactionCount;
  final int itemsSold;
  final double averageTicket;
  final Map<String, double> paymentMethodBreakdown;
  
  DailySalesSummary({
    required this.date,
    required this.grossSales,
    required this.netSales,
    required this.taxCollected,
    required this.serviceChargeCollected,
    required this.discounts,
    required this.refunds,
    required this.transactionCount,
    required this.itemsSold,
    required this.averageTicket,
    required this.paymentMethodBreakdown,
  });
  
  @override
  String toString() {
    return '''
DailySalesSummary(
  Date: $date,
  Gross Sales: $grossSales,
  Net Sales: $netSales,
  Transactions: $transactionCount,
  Items Sold: $itemsSold,
  Average Ticket: $averageTicket
)''';
  }
}

/// Product sales data for reporting.
class ProductSalesData {
  final String productId;
  final String productName;
  int unitsSold;
  double revenue;
  
  ProductSalesData({
    required this.productId,
    required this.productName,
    required this.unitsSold,
    required this.revenue,
  });
  
  @override
  String toString() {
    return 'ProductSalesData($productName: $unitsSold units, RM $revenue)';
  }
}
