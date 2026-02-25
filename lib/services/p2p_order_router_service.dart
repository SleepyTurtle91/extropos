import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/order_status.dart';
import 'package:extropos/models/p2p_device_model.dart';
import 'package:extropos/models/p2p_message_model.dart';
import 'package:extropos/models/p2p_order_message_model.dart';
import 'package:extropos/services/local_network_p2p_service.dart';
import 'package:uuid/uuid.dart';

/// Typedef for order sent event
typedef OrderSentCallback = void Function(String orderId, String deviceId);

/// Service for routing orders to appropriate client POS devices
class P2POrderRouterService {
  static final P2POrderRouterService _instance = P2POrderRouterService._internal();

  factory P2POrderRouterService() {
    return _instance;
  }

  P2POrderRouterService._internal();

  final LocalNetworkP2PService _p2pService = LocalNetworkP2PService();

  // Order tracking
  final Map<String, P2POrderMessage> _sentOrders = {};
  final List<OrderSentCallback> _orderSentCallbacks = [];

  /// Initialize the order router
  Future<void> initialize() async {
    if (!_p2pService.isInitialized) {
      throw Exception('P2P Service must be initialized first');
    }

    // Listen for order status updates
    _p2pService.onMessage(P2PMessageType.orderStatus, (message) {
      _handleOrderStatusUpdate(message);
    });

    // Listen for order cancellation
    _p2pService.onMessage(P2PMessageType.orderCancel, (message) {
      _handleOrderCancellation(message);
    });

    print('[OrderRouter] Initialized');
  }

  /// Send order to specific device
  Future<bool> sendOrderToDevice(
    String orderId,
    String deviceId,
    List<CartItem> items, {
    double subtotal = 0.0,
    double? tax,
    double? serviceCharge,
    double? discount,
    double total = 0.0,
    int? tableNumber,
    String? customerName,
    String? specialInstructions,
  }) async {
    try {
      if (!_p2pService.isRunning) {
        throw Exception('P2P Service is not running');
      }

      final device = _p2pService.connectedDevices
          .firstWhere((d) => d.deviceId == deviceId, orElse: () => null as dynamic);

      final p2pItems = items.map((item) => P2POrderItem.fromCartItem(item)).toList();

      final orderMessage = P2POrderMessage(
        messageId: const Uuid().v4(),
        fromDeviceId: _p2pService.deviceId,
        orderId: orderId,
        items: p2pItems,
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        discount: discount,
        total: total,
        orderStatus: OrderStatus.pending,
        destination: OrderRoutingDestination.values.firstWhere(
          (d) => d == OrderRoutingDestination.secondaryPOS ||
              d == OrderRoutingDestination.orderingTablet,
          orElse: () => OrderRoutingDestination.allDevices,
        ),
        destinationDeviceId: deviceId,
        tableNumber: tableNumber,
        customerName: customerName,
        specialInstructions: specialInstructions,
      );

      await _p2pService.sendMessage(orderMessage);
      _sentOrders[orderId] = orderMessage;

      _notifyOrderSent(orderId, deviceId);
      print('[OrderRouter] Order $orderId sent to device $deviceId');
      return true;
    } catch (e) {
      print('[OrderRouter] Error sending order: $e');
      return false;
    }
  }

  /// Send order to all connected client devices
  Future<int> broadcastOrderToAllClients(
    String orderId,
    List<CartItem> items, {
    double subtotal = 0.0,
    double? tax,
    double? serviceCharge,
    double? discount,
    double total = 0.0,
    String? specialInstructions,
  }) async {
    try {
      if (!_p2pService.isRunning) {
        throw Exception('P2P Service is not running');
      }

      int sentCount = 0;
      final devices = _p2pService.connectedDevices
          .where((d) => d.connectionStatus == P2PConnectionStatus.connected)
          .toList();

      if (devices.isEmpty) {
        print('[OrderRouter] No connected devices for broadcast');
        return 0;
      }

      for (final device in devices) {
        try {
          final sent = await sendOrderToDevice(
            orderId,
            device.deviceId,
            items,
            subtotal: subtotal,
            tax: tax,
            serviceCharge: serviceCharge,
            discount: discount,
            total: total,
            specialInstructions: specialInstructions,
          );
          if (sent) sentCount++;
        } catch (e) {
          print('[OrderRouter] Failed to send to ${device.displayTitle}: $e');
        }
      }

      print('[OrderRouter] Broadcast order sent to $sentCount devices');
      return sentCount;
    } catch (e) {
      print('[OrderRouter] Error broadcasting order: $e');
      return 0;
    }
  }

  /// Send order to specific device type (e.g., all tablets)
  Future<int> sendOrderToDeviceType(
    String orderId,
    List<CartItem> items,
    P2PDeviceType targetDeviceType, {
    double subtotal = 0.0,
    double? tax,
    double? serviceCharge,
    double? discount,
    double total = 0.0,
    String? specialInstructions,
  }) async {
    try {
      int sentCount = 0;
      final devices = _p2pService.connectedDevices
          .where((d) =>
              d.deviceType == targetDeviceType &&
              d.connectionStatus == P2PConnectionStatus.connected)
          .toList();

      for (final device in devices) {
        try {
          final sent = await sendOrderToDevice(
            orderId,
            device.deviceId,
            items,
            subtotal: subtotal,
            tax: tax,
            serviceCharge: serviceCharge,
            discount: discount,
            total: total,
            specialInstructions: specialInstructions,
          );
          if (sent) sentCount++;
        } catch (e) {
          print('[OrderRouter] Failed to send to ${device.displayTitle}: $e');
        }
      }

      print(
          '[OrderRouter] Order sent to $sentCount devices of type ${targetDeviceType.displayName}');
      return sentCount;
    } catch (e) {
      print('[OrderRouter] Error routing to device type: $e');
      return 0;
    }
  }

  /// Update order status on all relevant devices
  Future<void> broadcastOrderStatusUpdate(
    String orderId, {
    required OrderStatus newStatus,
    String? reason,
    int? estimatedTime,
  }) async {
    try {
      final statusMessage = P2POrderStatusMessage(
        messageId: const Uuid().v4(),
        fromDeviceId: _p2pService.deviceId,
        orderId: orderId,
        newStatus: newStatus,
        statusReason: reason,
        estimatedTime: estimatedTime,
      );

      await _p2pService.sendMessage(statusMessage);
      print('[OrderRouter] Order status updated: $orderId -> ${newStatus.displayName}');
    } catch (e) {
      print('[OrderRouter] Error updating order status: $e');
    }
  }

  /// Send order cancellation to device
  Future<void> cancelOrderOnDevice(
    String orderId,
    String deviceId, {
    required String reason,
    bool refund = false,
  }) async {
    try {
      final cancelMessage = P2POrderCancelMessage(
        messageId: const Uuid().v4(),
        fromDeviceId: _p2pService.deviceId,
        toDeviceId: deviceId,
        orderId: orderId,
        reason: reason,
        refund: refund,
      );

      await _p2pService.sendMessage(cancelMessage);
      _sentOrders.remove(orderId);
      print('[OrderRouter] Order cancelled on device: $orderId -> $deviceId');
    } catch (e) {
      print('[OrderRouter] Error cancelling order: $e');
    }
  }

  /// Get sent order
  P2POrderMessage? getSentOrder(String orderId) {
    return _sentOrders[orderId];
  }

  /// Get all sent orders
  List<P2POrderMessage> getAllSentOrders() {
    return _sentOrders.values.toList();
  }

  /// Clear order from tracking
  void clearOrder(String orderId) {
    _sentOrders.remove(orderId);
  }

  /// Register callback for when order is sent
  void onOrderSent(OrderSentCallback callback) {
    _orderSentCallbacks.add(callback);
  }

  /// Dispose service
  void dispose() {
    _sentOrders.clear();
    _orderSentCallbacks.clear();
  }

  // ===== PRIVATE METHODS =====

  /// Handle order status update from device
  void _handleOrderStatusUpdate(P2PMessage message) {
    try {
      final statusMessage = P2POrderStatusMessage.fromMessage(message);
      print(
          '[OrderRouter] Order status update received: ${statusMessage.orderId} -> ${statusMessage.newStatus.displayName}');
      // Can be extended to update local order state
    } catch (e) {
      print('[OrderRouter] Error handling status update: $e');
    }
  }

  /// Handle order cancellation from device
  void _handleOrderCancellation(P2PMessage message) {
    try {
      final cancelMessage = P2POrderCancelMessage.fromMessage(message);
      print(
          '[OrderRouter] Order cancellation received: ${cancelMessage.orderId} - ${cancelMessage.reason}');
      _sentOrders.remove(cancelMessage.orderId);
      // Can be extended to handle refunds
    } catch (e) {
      print('[OrderRouter] Error handling cancellation: $e');
    }
  }

  /// Notify subscribers that an order was sent
  void _notifyOrderSent(String orderId, String deviceId) {
    for (final callback in _orderSentCallbacks) {
      try {
        callback(orderId, deviceId);
      } catch (e) {
        print('[OrderRouter] Error in callback: $e');
      }
    }
  }
}


