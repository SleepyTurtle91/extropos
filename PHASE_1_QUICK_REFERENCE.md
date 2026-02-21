# Phase 1 Features - Quick Reference Guide

## 🚀 Quick Start

All Phase 1 services are implemented and ready for integration. This guide provides quick access to the most important methods and usage patterns.

---

## 1️⃣ MyInvois Service

**Import:**

```dart
import 'package:extropos/services/my_invois_service.dart';

```

**Common Operations:**

```dart
// Submit invoice after transaction
final invoiceNumber = await MyInvoiceService().submitInvoice({
  'transaction_id': 'TXN-20260123-001',
  'subtotal': 100.00,
  'tax': 6.00,
  'service_charge': 5.00,
  'total': 111.00,
  'items': [...],  // List of cart items
  'customer': {...},  // Optional customer details
});

// Check invoice status
final status = await MyInvoiceService().getInvoiceStatus('inv_uuid_123');

// Resubmit rejected invoice
await MyInvoiceService().resubmitRejectedInvoice('inv_uuid_123', correctedData);

```

**BusinessInfo Fields:**

```dart
BusinessInfo.instance.isMyInvoisEnabled
BusinessInfo.instance.sstRegistrationNumber
BusinessInfo.instance.businessRegistrationNumber
BusinessInfo.instance.businessEmail

```

---

## 2️⃣ E-Wallet Payment Gateways

**Import:**

```dart
import 'package:extropos/services/payment/touch_n_go_gateway.dart';
import 'package:extropos/services/payment/grab_pay_gateway.dart';
import 'package:extropos/services/payment/boost_gateway.dart';
import 'package:extropos/services/payment/payment_gateway.dart';

```

**Process Payment:**

```dart
// Touch 'n Go
final tngGateway = TouchNGoGateway();
final result = await tngGateway.processPayment(
  PaymentRequest(
    amount: 150.00,
    referenceId: 'TXN-20260123-001',
    description: 'Order payment',
  ),
);

if (result.status == PaymentStatus.success) {
  print('Payment successful: ${result.transactionId}');
}

// GrabPay (same pattern)
final grabGateway = GrabPayGateway();

// Boost (same pattern)
final boostGateway = BoostGateway();

```

**Process Refund:**

```dart
final refund = await tngGateway.processRefund(
  transactionId: 'TXN123',
  amount: 50.00,
  reason: 'Customer request',
);

if (refund.success) {
  print('Refunded: RM ${refund.amount}');
}

```

---

## 3️⃣ Loyalty Program

**Import:**

```dart
import 'package:extropos/services/loyalty_service.dart';
import 'package:extropos/models/loyalty_program.dart';

```

**Add Points After Sale:**

```dart
await LoyaltyService().addPointsForTransaction(
  'customer_123',
  150.00,  // Transaction amount
  transactionId: 'TXN-20260123-001',
);

// Customer earns points based on their tier:
// Bronze: 150 points (1x)
// Silver: 187.5 points (1.25x)
// Gold: 225 points (1.5x)
// Platinum: 300 points (2x)

```

**Redeem Points:**

```dart
final success = await LoyaltyService().redeemPointsForDiscount(
  'customer_123',
  500.0,  // Points to redeem
);

// 500 points = RM 50 discount (100 points = RM 10)

```

**Get Customer Summary:**

```dart
final summary = await LoyaltyService().getCustomerSummary('customer_123');

print('Points: ${summary.points}');
print('Tier: ${summary.tierName}');
print('Discount: ${summary.tierDiscountPercentage}%');
print('Next tier: ${summary.nextTierName}');
print('Spend needed: RM ${summary.spendToNextTier}');

```

**Discount Amount:**

```dart
final discount = await LoyaltyService().getDiscountAmount(
  'customer_123',
  100.00,  // Subtotal
);

// Returns tier-based discount amount

```

---

## 4️⃣ PDPA Compliance

**Import:**

```dart
import 'package:extropos/services/pdpa_compliance_service.dart';

```

**Encrypt Customer Data:**

```dart
final encrypted = await PDPAComplianceService().encryptCustomerData(
  'John Doe',  // Plaintext
);

// Decryption
final decrypted = await PDPAComplianceService().decryptCustomerData(encrypted);

```

**Log Data Access:**

```dart
await PDPAComplianceService().logActivity(
  'user_123',
  'VIEW_CUSTOMER_DETAILS',
  {'customer_id': 'cust_456', 'screen': 'customer_details'},
  customerId: 'cust_456',
  ipAddress: '192.168.1.100',
);

```

**Record Consent:**

```dart
await PDPAComplianceService().recordConsent(
  'cust_456',
  'marketing',  // Type: marketing, data_usage, analytics
  true,  // Granted
  ipAddress: '192.168.1.100',
);

```

**Delete Customer Data:**

```dart
await PDPAComplianceService().deleteCustomerData('cust_456');

```

**Generate Compliance Report:**

```dart
final report = await PDPAComplianceService().generateComplianceReport(
  DateTimeRange(
    start: DateTime.now().subtract(Duration(days: 30)),
    end: DateTime.now(),
  ),
);

print('Data access: ${report.totalDataAccess}');
print('Deletion requests: ${report.deletionRequests}');
print('Unauthorized access: ${report.unauthorizedAccessAttempts}');
print('Compliant: ${report.isCompliant}');

```

---

## 5️⃣ Offline Sync Service

**Import:**

```dart
import 'package:extropos/services/offline_sync_service.dart';

```

**Queue Items for Sync:**

```dart
// Transaction (high priority)
await OfflineSyncService().queueTransaction({
  'id': 'TXN-20260123-001',
  'amount': 150.00,
  'items': [...],
});

// Product (medium priority)
await OfflineSyncService().queueProduct({
  'id': 'prod_123',
  'name': 'Coffee',
  'price': 5.00,
});

// Inventory (high priority)
await OfflineSyncService().queueInventoryUpdate({
  'product_id': 'prod_123',
  'quantity': 50.0,
});

// Customer (medium priority)
await OfflineSyncService().queueCustomer({
  'id': 'cust_456',
  'name': 'John Doe',
});

// Settings (low priority)
await OfflineSyncService().queueSettings({
  'tax_rate': 0.06,
  'service_charge': 0.05,
});

```

**Smart Sync:**

```dart
final result = await OfflineSyncService().smartSync(
  syncImages: false,  // Bandwidth-aware
  maxRetries: 3,
);

print('Success rate: ${result.successRate}%');
print('Synced: ${result.syncedItems.length}');
print('Failed: ${result.failedItems.length}');

```

**Get Sync Statistics:**

```dart
final stats = await OfflineSyncService().getSyncStatistics();

print('Queued: ${stats['total_queued']}');
print('Synced: ${stats['total_synced']}');
print('Failed: ${stats['total_failed']}');
print('Success rate: ${stats['success_rate']}%');

```

**Clear Queue:**

```dart
await OfflineSyncService().clearQueue();

```

---

## 6️⃣ Inventory Service

**Import:**

```dart
import 'package:extropos/services/inventory_service.dart';
import 'package:extropos/models/inventory_models.dart';

```

**Update Stock After Sale:**

```dart
await InventoryService().updateStockAfterSale(
  'prod_123',  // Product ID
  2.0,  // Quantity sold
  transactionId: 'TXN-20260123-001',
  userId: 'user_001',
);

// Automatically reduces stock by 2

```

**Add Stock (Purchase):**

```dart
await InventoryService().addStock(
  'prod_123',
  50.0,  // Quantity added
  reason: 'Purchase from supplier',
  referenceId: 'PO-20260123-001',
  userId: 'user_001',
);

```

**Adjust Stock (Manual):**

```dart
await InventoryService().adjustStock(
  'prod_123',
  45.0,  // New quantity
  reason: 'Stock count correction',
  userId: 'user_001',
);

```

**Record Damage:**

```dart
await InventoryService().recordDamage(
  'prod_123',
  3.0,  // Quantity damaged
  reason: 'Broken during handling',
  userId: 'user_001',
);

```

**Create Purchase Order:**

```dart
final po = await InventoryService().createPurchaseOrder(
  supplierId: 'supplier_001',
  supplierName: 'ABC Suppliers',
  items: [
    PurchaseOrderItem(
      productId: 'prod_123',
      productName: 'Coffee Beans',
      quantity: 50.0,
      unitCost: 25.00,
      totalCost: 1250.00,
    ),
  ],
  expectedDeliveryDate: DateTime.now().add(Duration(days: 7)),
  notes: 'Regular monthly order',
);

print('PO Created: ${po.poNumber}');  // PO-20260123-001

```

**Receive Purchase Order:**

```dart
await InventoryService().receivePurchaseOrder('po_id_123');

// Automatically adds stock quantities from all PO items

```

**Generate Inventory Report:**

```dart
final report = await InventoryService().generateInventoryReport();

print('Total products: ${report.totalProducts}');
print('Low stock: ${report.lowStockCount}');
print('Out of stock: ${report.outOfStockCount}');
print('Total value: RM ${report.totalValue}');

// Top value items
for (final item in report.topValueItems) {
  print('${item.productName}: RM ${item.value}');
}

```

**Set Stock Levels:**

```dart
await InventoryService().setStockLevels(
  productId: 'prod_123',
  minLevel: 10.0,
  maxLevel: 100.0,
  reorderQuantity: 50.0,
);

// Automatically triggers reorder alerts when below min

```

---

## 📊 Database Tables

### Query Examples

**MyInvois:**

```sql
SELECT * FROM invoices WHERE status = 'rejected';

SELECT * FROM invoice_sequences WHERE date = '20260123';

```

**E-Wallet:**

```sql
SELECT * FROM e_wallet_transactions WHERE status = 'success';

SELECT * FROM e_wallet_settings WHERE is_enabled = 1;

```

**Loyalty:**

```sql
SELECT * FROM customer_loyalty WHERE current_tier = 'platinum';

SELECT * FROM loyalty_transactions WHERE customer_id = 'cust_123';

```

**PDPA:**

```sql
SELECT * FROM audit_logs WHERE action = 'DELETE_CUSTOMER';

SELECT * FROM customer_consents WHERE granted = 1;

```

**Inventory:**

```sql
SELECT * FROM inventory WHERE current_quantity < min_stock_level;

SELECT * FROM purchase_orders WHERE status = 'draft';

```

**Sync:**

```sql
SELECT * FROM sync_queue WHERE priority = 3 ORDER BY created_at;

SELECT * FROM sync_stats WHERE id = 1;

```

---

## 🔧 Integration Points

### Checkout Flow Integration

```dart
// In retail_pos_screen_modern.dart:

Future<void> _completeCheckout() async {
  // 1. Save transaction to database
  final transactionId = await _saveTransaction();
  
  // 2. Submit MyInvois invoice
  if (BusinessInfo.instance.isMyInvoisEnabled) {
    await MyInvoiceService().submitInvoice(transactionData);
  }
  
  // 3. Process e-wallet payment if selected
  if (paymentMethod == PaymentMethod.touchNGo) {
    final result = await TouchNGoGateway().processPayment(request);
  }
  
  // 4. Add loyalty points
  if (customerId != null) {
    await LoyaltyService().addPointsForTransaction(customerId, total);
  }
  
  // 5. Update inventory
  for (final item in cartItems) {
    await InventoryService().updateStockAfterSale(
      item.product.id,
      item.quantity,
      transactionId: transactionId,
    );
  }
  
  // 6. Log PDPA activity
  await PDPAComplianceService().logActivity(
    userId,
    'COMPLETE_TRANSACTION',
    {'transaction_id': transactionId, 'amount': total},
  );
  
  // 7. Queue for offline sync
  await OfflineSyncService().queueTransaction(transactionData);
}

```

---

## ⚠️ Important Notes

1. **MyInvois**: Test with sandbox first, then switch to production
2. **E-Wallets**: Replace mock implementations with real API calls
3. **Loyalty**: Configure tiers in database before use
4. **PDPA**: Always log data access for compliance
5. **Sync**: Call `smartSync()` when network reconnects
6. **Inventory**: Set min/max levels for automatic alerts

---

## 📞 Support

- **Implementation Plan**: `/PHASE_1_IMPLEMENTATION_PLAN.md`

- **Completion Summary**: `/PHASE_1_MALAYSIAN_FEATURES_COMPLETE.md`

- **Database Migration**: `/database/migrations/phase_1_migration.sql`

---

**Version**: 1.0.27  
**Date**: January 23, 2026  
**Status**: Ready for Integration
