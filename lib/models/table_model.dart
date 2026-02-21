import 'package:extropos/models/cart_item.dart';

enum TableStatus { available, occupied, reserved, merged, cleaning }

class RestaurantTable {
  final String id;
  final String name;
  final int capacity;
  TableStatus status;
  List<CartItem> orders;
  DateTime? occupiedSince;
  String? customerName;
  String? customerPhone;
  String? notes;
  List<String>? mergedTableIds; // IDs of tables merged into this one
  DateTime? createdAt;
  DateTime? updatedAt;

  // Capacity management properties
  int get currentOccupancy => orders.fold(0, (sum, item) => sum + item.quantity);
  bool get isAtCapacity => currentOccupancy == capacity;
  bool get isOverCapacity => currentOccupancy > capacity;
  double get occupancyPercentage => capacity > 0 ? (currentOccupancy / capacity) * 100 : 0.0;

  // Status helpers for capacity warnings
  bool get needsCapacityWarning => occupancyPercentage >= 80.0;
  bool get isCapacityCritical => occupancyPercentage >= 100.0;

  RestaurantTable({
    required this.id,
    required this.name,
    required this.capacity,
    this.status = TableStatus.available,
    List<CartItem>? orders,
    this.occupiedSince,
    this.customerName,
    this.customerPhone,
    this.notes,
    this.mergedTableIds,
    this.createdAt,
    this.updatedAt,
  }) : orders = orders ?? [];

  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;
  bool get isReserved => status == TableStatus.reserved;
  bool get isMerged => status == TableStatus.merged;
  bool get isCleaning => status == TableStatus.cleaning;
  
  /// Get duration table has been occupied (in minutes)
  int get occupiedDurationMinutes {
    if (occupiedSince == null) return 0;
    return DateTime.now().difference(occupiedSince!).inMinutes;
  }

  double get totalAmount {
    return orders.fold(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
  }

  int get itemCount {
    return orders.fold(0, (sum, item) => sum + item.quantity);
  }

  void addOrder(CartItem item) {
    final existingIndex = orders.indexWhere(
      (o) => o.hasSameConfigurationWithDiscount(item.product, item.modifiers, item.discountPerUnit, otherPriceAdjustment: item.priceAdjustment, otherSeatNumber: item.seatNumber),
    );
    if (existingIndex != -1) {
      orders[existingIndex].quantity += item.quantity;
    } else {
      orders.add(item);
    }
    if (status == TableStatus.available) {
      status = TableStatus.occupied;
      occupiedSince = DateTime.now();
    }
  }

  /// Add or merge order using full CartItem configuration comparison.
  void addOrMergeOrder(CartItem item) {
    final existingIndex = orders.indexWhere(
      (o) => o.hasSameConfigurationWithDiscount(item.product, item.modifiers, item.discountPerUnit, otherPriceAdjustment: item.priceAdjustment, otherSeatNumber: item.seatNumber),
    );
    if (existingIndex != -1) {
      orders[existingIndex].quantity += item.quantity;
    } else {
      orders.add(item);
    }
    if (status == TableStatus.available) {
      status = TableStatus.occupied;
      occupiedSince = DateTime.now();
    }
  }

  void clearOrders() {
    orders.clear();
    status = TableStatus.available;
    occupiedSince = null;
    customerName = null;
  }

  RestaurantTable copyWith({
    String? id,
    String? name,
    int? capacity,
    TableStatus? status,
    List<CartItem>? orders,
    DateTime? occupiedSince,
    bool clearOccupiedSince = false,
    String? customerName,
    String? customerPhone,
    String? notes,
    List<String>? mergedTableIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      name: name ?? this.name,
      capacity: capacity ?? this.capacity,
      status: status ?? this.status,
      orders: orders ?? List.from(this.orders),
      occupiedSince: clearOccupiedSince ? null : (occupiedSince ?? this.occupiedSince),
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      notes: notes ?? this.notes,
      mergedTableIds: mergedTableIds ?? this.mergedTableIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'status': status.toString().split('.').last,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'notes': notes,
      'merged_table_ids': mergedTableIds?.join(',') ?? '',
      'occupied_since': occupiedSince?.millisecondsSinceEpoch,
      'created_at': createdAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    };
  }
  
  /// Create from database map
  factory RestaurantTable.fromMap(Map<String, dynamic> map) {
    return RestaurantTable(
      id: map['id'] as String,
      name: map['name'] as String,
      capacity: map['capacity'] as int,
      status: _parseStatus(map['status'] as String?),
      customerName: map['customer_name'] as String?,
      customerPhone: map['customer_phone'] as String?,
      notes: map['notes'] as String?,
      mergedTableIds: (map['merged_table_ids'] as String?)?.split(',').where((s) => s.isNotEmpty).toList(),
      occupiedSince: map['occupied_since'] != null ? DateTime.fromMillisecondsSinceEpoch(map['occupied_since'] as int) : null,
      createdAt: map['created_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int) : null,
      updatedAt: map['updated_at'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int) : null,
    );
  }
  
  static TableStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      case 'merged':
        return TableStatus.merged;
      case 'cleaning':
        return TableStatus.cleaning;
      default:
        return TableStatus.available;
    }
  }
}
