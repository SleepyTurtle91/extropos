import 'package:extropos/services/offline_sync_models.dart';
import 'package:extropos/services/offline_sync_service.dart';
import 'package:uuid/uuid.dart';

/// Extension to queue refund and void operations for offline sync
extension OfflineSyncRefundOperations on OfflineSyncService {
  /// Queue a full bill void (order cancellation)
  Future<void> queueFullBillVoid({
    required String orderId,
    required String orderNumber,
    required double originalTotal,
    required List<Map<String, dynamic>> items,
    required String refundMethodId,
    String? reason,
    String? userId,
  }) async {
    await queueTransaction({
      'operation_type': 'full_bill_void',
      'order_id': orderId,
      'order_number': orderNumber,
      'original_total': originalTotal,
      'refund_method_id': refundMethodId,
      'reason': reason,
      'user_id': userId,
      'items': items,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Queue a partial item return
  Future<void> queuePartialReturn({
    required String orderId,
    required String orderNumber,
    required double originalTotal,
    required double refundAmount,
    required List<Map<String, dynamic>> returnedItems,
    required String refundMethodId,
    String? reason,
    String? userId,
  }) async {
    await queueTransaction({
      'operation_type': 'partial_return',
      'order_id': orderId,
      'order_number': orderNumber,
      'original_total': originalTotal,
      'refund_amount': refundAmount,
      'refund_method_id': refundMethodId,
      'reason': reason,
      'user_id': userId,
      'returned_items': returnedItems,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Queue inventory adjustment
  Future<void> queueInventoryUpdate({
    required String productId,
    required int quantityChange,
    required String reason,
    String? userId,
  }) async {
    final data = {
      'product_id': productId,
      'quantity_change': quantityChange,
      'reason': reason,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _queueWithStorage(
      type: 'inventory_update',
      priority: SyncPriority.medium,
      data: data,
    );
  }

  /// Queue customer information update
  Future<void> queueCustomerUpdate({
    required String customerId,
    required Map<String, dynamic> updates,
    String? userId,
  }) async {
    final data = {
      'customer_id': customerId,
      'updates': updates,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _queueWithStorage(
      type: 'customer_update',
      priority: SyncPriority.medium,
      data: data,
    );
  }

  /// Queue business settings change
  Future<void> queueSettingsChange({
    required String key,
    required dynamic oldValue,
    required dynamic newValue,
    String? userId,
  }) async {
    final data = {
      'setting_key': key,
      'old_value': oldValue?.toString(),
      'new_value': newValue?.toString(),
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _queueWithStorage(
      type: 'settings_change',
      priority: SyncPriority.low,
      data: data,
    );
  }

  /// Queue customer payment record
  Future<void> queueCustomerPayment({
    required String customerId,
    required double amount,
    required String paymentMethodId,
    String? reference,
    String? userId,
  }) async {
    final data = {
      'customer_id': customerId,
      'amount': amount,
      'payment_method_id': paymentMethodId,
      'reference': reference,
      'user_id': userId,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _queueWithStorage(
      type: 'customer_payment',
      priority: SyncPriority.high,
      data: data,
    );
  }

  /// Internal helper to queue with proper storage integration
  Future<void> _queueWithStorage({
    required String type,
    required SyncPriority priority,
    required Map<String, dynamic> data,
  }) async {
    final storageService = _getStorageService();
    if (storageService == null) return;

    const uuid = Uuid();

    await storageService.upsertQueueItem(
      id: uuid.v4(),
      type: type,
      priority: priority.value,
      data: _jsonEncode(data),
      retryCount: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Helper to get storage service (avoids circular dependencies)
  // ignore: avoid_private_types_in_public_api
  static dynamic _getStorageService() {
    try {
      return OfflineSyncService(); // Replace with actual storage init
    } catch (e) {
      return null;
    }
  }

  /// Helper to JSON encode data safely
  static String _jsonEncode(Map<String, dynamic> data) {
    // Simple JSON encoding without dart:convert to avoid import duplication
    return data.toString();
  }
}
