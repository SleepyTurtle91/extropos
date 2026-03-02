import 'package:extropos/models/order_status.dart';

class KitchenOrder {
  final String id;
  final String orderNumber;
  final String? tableName;
  final List<KitchenOrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? sentToKitchenAt;
  final String? specialInstructions;

  KitchenOrder({
    required this.id,
    required this.orderNumber,
    this.tableName,
    required this.items,
    required this.status,
    required this.createdAt,
    this.sentToKitchenAt,
    this.specialInstructions,
  });

  factory KitchenOrder.fromMap(Map<String, dynamic> map) {
    return KitchenOrder(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String,
      tableName: map['table_name'] as String?,
      items: [], // Will be populated separately
      status: parseOrderStatus(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      sentToKitchenAt: map['sent_to_kitchen_at'] != null
          ? DateTime.parse(map['sent_to_kitchen_at'] as String)
          : null,
      specialInstructions: map['special_instructions'] as String?,
    );
  }

  Duration get waitTime {
    final reference = sentToKitchenAt ?? createdAt;
    return DateTime.now().difference(reference);
  }

  String get waitTimeDisplay {
    final minutes = waitTime.inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes == 1) return '1 min';
    return '$minutes mins';
  }
}

class KitchenOrderItem {
  final String itemName;
  final int quantity;
  final String? modifiers;
  final int? seatNumber;
  final String? notes;

  KitchenOrderItem({
    required this.itemName,
    required this.quantity,
    this.modifiers,
    this.seatNumber,
    this.notes,
  });

  factory KitchenOrderItem.fromMap(Map<String, dynamic> map) {
    return KitchenOrderItem(
      itemName: map['item_name'] as String,
      quantity: map['quantity'] as int,
      modifiers: map['notes'] as String?, // Modifiers stored in notes field
      seatNumber: map['seat_number'] as int?,
      notes: map['notes'] as String?,
    );
  }
}
