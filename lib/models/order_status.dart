import 'package:flutter/material.dart';

enum OrderStatus {
  pending, // Order created, not yet sent to kitchen
  sentToKitchen, // Order sent to kitchen, waiting to be prepared
  preparing, // Kitchen is actively preparing the order
  ready, // Order is ready for pickup/serving
  served, // Order has been served to customer (restaurant mode)
  completed, // Order fully completed and paid
  cancelled, // Order was cancelled
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.sentToKitchen:
        return 'Sent to Kitchen';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.served:
        return 'Served';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.sentToKitchen:
        return 'sent_to_kitchen';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.served:
        return 'served';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFF9800); // Orange
      case OrderStatus.sentToKitchen:
        return const Color(0xFF2196F3); // Blue
      case OrderStatus.preparing:
        return const Color(0xFFFFC107); // Amber
      case OrderStatus.ready:
        return const Color(0xFF4CAF50); // Green
      case OrderStatus.served:
        return const Color(0xFF9C27B0); // Purple
      case OrderStatus.completed:
        return const Color(0xFF607D8B); // Blue Grey
      case OrderStatus.cancelled:
        return const Color(0xFFF44336); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.sentToKitchen:
        return Icons.send;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.served:
        return Icons.room_service;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Returns true if this status represents an active order (not completed/cancelled)
  bool get isActive {
    return this != OrderStatus.completed && this != OrderStatus.cancelled;
  }

  /// Returns true if the order can be sent to kitchen
  bool get canSendToKitchen {
    return this == OrderStatus.pending;
  }

  /// Returns true if the order can be marked as preparing
  bool get canMarkPreparing {
    return this == OrderStatus.sentToKitchen;
  }

  /// Returns true if the order can be marked as ready
  bool get canMarkReady {
    return this == OrderStatus.preparing;
  }

  /// Returns true if the order can be marked as served
  bool get canMarkServed {
    return this == OrderStatus.ready;
  }
}

/// Parse OrderStatus from database string value
OrderStatus parseOrderStatus(String value) {
  switch (value) {
    case 'pending':
      return OrderStatus.pending;
    case 'sent_to_kitchen':
      return OrderStatus.sentToKitchen;
    case 'preparing':
      return OrderStatus.preparing;
    case 'ready':
      return OrderStatus.ready;
    case 'served':
      return OrderStatus.served;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}
