import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/order_status.dart';
import 'package:extropos/models/p2p_message_model.dart';

/// Enum for order routing destinations
enum OrderRoutingDestination {
  mainPOS, // Main terminal (current device)
  secondaryPOS, // Secondary terminal
  orderingTablet, // Mobile ordering tablet
  kitchenDisplay, // Kitchen display system
  allDevices, // Broadcast to all connected devices
}

extension OrderRoutingDestinationExtension on OrderRoutingDestination {
  String get displayName {
    switch (this) {
      case OrderRoutingDestination.mainPOS:
        return 'Main POS';
      case OrderRoutingDestination.secondaryPOS:
        return 'Secondary POS';
      case OrderRoutingDestination.orderingTablet:
        return 'Ordering Tablet';
      case OrderRoutingDestination.kitchenDisplay:
        return 'Kitchen Display';
      case OrderRoutingDestination.allDevices:
        return 'All Devices';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static OrderRoutingDestination fromValue(String value) {
    return OrderRoutingDestination.values
        .firstWhere((e) => e.value == value, orElse: () => OrderRoutingDestination.mainPOS);
  }
}

/// Model for order items in P2P messages
class P2POrderItem {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final List<String> modifiers; // Modifier names/descriptions
  final String? variant;
  final String? notes;
  final double? discountPerItem;

  P2POrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.modifiers = const [],
    this.variant,
    this.notes,
    this.discountPerItem,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'modifiers': modifiers,
      'variant': variant,
      'notes': notes,
      'discountPerItem': discountPerItem,
    };
  }

  factory P2POrderItem.fromJson(Map<String, dynamic> json) {
    return P2POrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      modifiers: List<String>.from(json['modifiers'] as List? ?? []),
      variant: json['variant'] as String?,
      notes: json['notes'] as String?,
      discountPerItem: json['discountPerItem'] as double?,
    );
  }

  /// Convert from CartItem (with product and variant data)
  factory P2POrderItem.fromCartItem(CartItem cartItem) {
    return P2POrderItem(
      productId: cartItem.product.id,
      productName: cartItem.product.name,
      price: cartItem.finalPrice,
      quantity: cartItem.quantity,
      modifiers: cartItem.modifiers.map((m) => m.name).toList(),
      variant: cartItem.selectedVariant?.name,
      notes: cartItem.notes,
      discountPerItem: cartItem.discountPerUnit > 0 ? cartItem.discountPerUnit : null,
    );
  }
}

/// Model for complete order to forward to client devices
class P2POrderMessage extends P2PMessage {
  final String orderId;
  final List<P2POrderItem> items;
  final double subtotal;
  final double? tax;
  final double? serviceCharge;
  final double? discount;
  final double total;
  final OrderStatus orderStatus;
  final OrderRoutingDestination destination;
  final String? destinationDeviceId; // Specific device if not broadcast
  final int? tableNumber; // For restaurant mode
  final String? customerName;
  final String? specialInstructions;
  final DateTime? targetDeliveryTime;

  P2POrderMessage({
    required String messageId,
    required String fromDeviceId,
    required this.orderId,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.orderStatus,
    required this.destination,
    this.destinationDeviceId,
    this.tax,
    this.serviceCharge,
    this.discount,
    this.tableNumber,
    this.customerName,
    this.specialInstructions,
    this.targetDeliveryTime,
  }) : super(
    messageId: messageId,
    messageType: P2PMessageType.orderForward,
    fromDeviceId: fromDeviceId,
    toDeviceId: destinationDeviceId,
    timestamp: DateTime.now(),
    payload: {
      'orderId': orderId,
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'serviceCharge': serviceCharge,
      'discount': discount,
      'total': total,
      'orderStatus': orderStatus.value,
      'destination': destination.value,
      'tableNumber': tableNumber,
      'customerName': customerName,
      'specialInstructions': specialInstructions,
      'targetDeliveryTime': targetDeliveryTime?.toIso8601String(),
    },
    priority: 9,
  );

  /// Create from P2PMessage
  factory P2POrderMessage.fromMessage(P2PMessage message) {
    final payload = message.payload;
    return P2POrderMessage(
      messageId: message.messageId,
      fromDeviceId: message.fromDeviceId,
      orderId: payload['orderId'] as String,
      items: (payload['items'] as List?)
              ?.map((i) => P2POrderItem.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      subtotal: (payload['subtotal'] as num).toDouble(),
      total: (payload['total'] as num).toDouble(),
      orderStatus: OrderStatus.values.firstWhere(
        (e) => e.value == payload['orderStatus'],
        orElse: () => OrderStatus.pending,
      ),
      destination: OrderRoutingDestinationExtension.fromValue(
          payload['destination'] as String? ?? 'mainPOS'),
      destinationDeviceId: message.toDeviceId,
      tax: payload['tax'] != null ? (payload['tax'] as num).toDouble() : null,
      serviceCharge: payload['serviceCharge'] != null
          ? (payload['serviceCharge'] as num).toDouble()
          : null,
      discount:
          payload['discount'] != null ? (payload['discount'] as num).toDouble() : null,
      tableNumber: payload['tableNumber'] as int?,
      customerName: payload['customerName'] as String?,
      specialInstructions: payload['specialInstructions'] as String?,
      targetDeliveryTime: payload['targetDeliveryTime'] != null
          ? DateTime.parse(payload['targetDeliveryTime'] as String)
          : null,
    );
  }

  /// Try to convert a generic P2PMessage to P2POrderMessage
  static P2POrderMessage? tryFromMessage(P2PMessage message) {
    if (message.messageType == P2PMessageType.orderForward) {
      try {
        return P2POrderMessage.fromMessage(message);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}

/// Model for order status updates
class P2POrderStatusMessage extends P2PMessage {
  final String orderId;
  final OrderStatus newStatus;
  final String? statusReason;
  final int? estimatedTime; // in seconds

  P2POrderStatusMessage({
    required String messageId,
    required String fromDeviceId,
    String? toDeviceId,
    required this.orderId,
    required this.newStatus,
    this.statusReason,
    this.estimatedTime,
  }) : super(
    messageId: messageId,
    messageType: P2PMessageType.orderStatus,
    fromDeviceId: fromDeviceId,
    toDeviceId: toDeviceId,
    timestamp: DateTime.now(),
    payload: {
      'orderId': orderId,
      'newStatus': newStatus.value,
      'statusReason': statusReason,
      'estimatedTime': estimatedTime,
    },
    priority: 8,
  );

  factory P2POrderStatusMessage.fromMessage(P2PMessage message) {
    final payload = message.payload;
    return P2POrderStatusMessage(
      messageId: message.messageId,
      fromDeviceId: message.fromDeviceId,
      toDeviceId: message.toDeviceId,
      orderId: payload['orderId'] as String,
      newStatus: OrderStatus.values.firstWhere(
        (e) => e.value == payload['newStatus'],
        orElse: () => OrderStatus.pending,
      ),
      statusReason: payload['statusReason'] as String?,
      estimatedTime: payload['estimatedTime'] as int?,
    );
  }
}

/// Model for order cancellation
class P2POrderCancelMessage extends P2PMessage {
  final String orderId;
  final String reason;
  final bool refund;

  P2POrderCancelMessage({
    required String messageId,
    required String fromDeviceId,
    String? toDeviceId,
    required this.orderId,
    required this.reason,
    this.refund = false,
  }) : super(
    messageId: messageId,
    messageType: P2PMessageType.orderCancel,
    fromDeviceId: fromDeviceId,
    toDeviceId: toDeviceId,
    timestamp: DateTime.now(),
    payload: {
      'orderId': orderId,
      'reason': reason,
      'refund': refund,
    },
    priority: 9,
  );

  factory P2POrderCancelMessage.fromMessage(P2PMessage message) {
    final payload = message.payload;
    return P2POrderCancelMessage(
      messageId: message.messageId,
      fromDeviceId: message.fromDeviceId,
      toDeviceId: message.toDeviceId,
      orderId: payload['orderId'] as String,
      reason: payload['reason'] as String? ?? 'Unknown reason',
      refund: payload['refund'] as bool? ?? false,
    );
  }
}
