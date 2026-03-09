import 'dart:developer' as developer;

import 'package:extropos/services/offline_sync_service.dart';

/// Helper class for queueing offline sync operations
/// Simplifies integration with OfflineSyncService across the app
class SyncQueueHelper {
  static final SyncQueueHelper _instance = SyncQueueHelper._internal();

  factory SyncQueueHelper() {
    return _instance;
  }

  SyncQueueHelper._internal();

  /// Initialize sync service (call from main.dart startup)
  Future<void> initialize() async {
    try {
      final syncService = OfflineSyncService();
      await syncService.initialize();
      developer.log('SyncQueueHelper initialized');
    } catch (e) {
      developer.log('Failed to initialize SyncQueueHelper: $e');
    }
  }

  /// Queue a refund or void operation
  Future<void> queueRefund({
    required String orderId,
    required String orderNumber,
    required double refundAmount,
    required String refundType, // 'full_void', 'partial_return'
    required String refundMethodId,
    List<Map<String, dynamic>>? affectedItems,
    String? reason,
    String? userId,
  }) async {
    try {
      await OfflineSyncService().queueTransaction({
        'operation_type': 'refund',
        'refund_type': refundType,
        'order_id': orderId,
        'order_number': orderNumber,
        'refund_amount': refundAmount,
        'refund_method_id': refundMethodId,
        'affected_items': affectedItems ?? [],
        'reason': reason,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      developer.log('Queued refund operation: $orderNumber ($refundType)');
    } catch (e) {
      developer.log('Failed to queue refund: $e');
      // Don't fail the refund operation if queue fails
    }
  }

  /// Queue an inventory adjustment
  Future<void> queueInventoryAdjustment({
    required String productId,
    required int quantityChange,
    required String reason,
    String? userId,
  }) async {
    try {
      final syncService = OfflineSyncService();
      // For inventory updates, create a simple product update queue item
      await syncService.queueTransaction({
        'operation_type': 'inventory_adjustment',
        'product_id': productId,
        'quantity_change': quantityChange,
        'reason': reason,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      developer.log(
        'Queued inventory adjustment: product=$productId, qty=$quantityChange',
      );
    } catch (e) {
      developer.log('Failed to queue inventory adjustment: $e');
    }
  }

  /// Queue a customer information update
  Future<void> queueCustomerUpdate({
    required String customerId,
    required Map<String, dynamic> updates,
    String? userId,
  }) async {
    try {
      final syncService = OfflineSyncService();
      await syncService.queueTransaction({
        'operation_type': 'customer_update',
        'customer_id': customerId,
        'updates': updates,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      developer.log('Queued customer update: customer=$customerId');
    } catch (e) {
      developer.log('Failed to queue customer update: $e');
    }
  }

  /// Queue a business settings change
  Future<void> queueSettingsChange({
    required String settingKey,
    dynamic oldValue,
    dynamic newValue,
    String? userId,
  }) async {
    try {
      final syncService = OfflineSyncService();
      await syncService.queueTransaction({
        'operation_type': 'settings_change',
        'setting_key': settingKey,
        'old_value': oldValue?.toString(),
        'new_value': newValue?.toString(),
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      developer.log('Queued settings change: $settingKey');
    } catch (e) {
      developer.log('Failed to queue settings change: $e');
    }
  }

  /// Queue a customer payment record
  Future<void> queueCustomerPayment({
    required String customerId,
    required double amount,
    required String paymentMethodId,
    String? reference,
    String? userId,
  }) async {
    try {
      final syncService = OfflineSyncService();
      await syncService.queueTransaction({
        'operation_type': 'customer_payment',
        'customer_id': customerId,
        'amount': amount,
        'payment_method_id': paymentMethodId,
        'reference': reference,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      developer.log('Queued customer payment: customer=$customerId, amount=$amount');
    } catch (e) {
      developer.log('Failed to queue customer payment: $e');
    }
  }

  /// Get queue status info
  Future<Map<String, dynamic>> getQueueStatus() async {
    try {
      final syncService = OfflineSyncService();
      final stats = syncService.stats;
      return {
        'pending_count': syncService.queueSize,
        'total_queued': stats.totalQueued,
        'total_synced': stats.totalSynced,
        'total_failed': stats.totalFailed,
        'last_sync': stats.lastSuccessfulSync,
      };
    } catch (e) {
      developer.log('Failed to get queue status: $e');
      return {'error': e.toString()};
    }
  }
}
