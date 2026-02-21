import 'dart:async';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter/foundation.dart';

/// Service for managing table operations with real-time updates
class TableService extends ChangeNotifier {
  static final TableService _instance = TableService._internal();
  factory TableService() => _instance;
  TableService._internal();

  List<RestaurantTable> _tables = [];
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  List<RestaurantTable> get tables => List.unmodifiable(_tables);
  bool get isRefreshing => _isRefreshing;

  // Getters for table statistics
  int get totalTables => _tables.length;
  int get availableTables => _tables.where((t) => t.isAvailable).length;
  int get occupiedTables => _tables.where((t) => t.isOccupied).length;
  int get reservedTables => _tables.where((t) => t.isReserved).length;
  int get totalCapacity => _tables.fold(0, (sum, t) => sum + t.capacity);
  int get currentOccupancy => _tables.fold(0, (sum, t) => sum + t.currentOccupancy);

  // Capacity management getters
  List<RestaurantTable> get tablesNeedingCapacityWarning =>
      _tables.where((t) => t.needsCapacityWarning).toList();

  List<RestaurantTable> get tablesAtCapacity =>
      _tables.where((t) => t.isAtCapacity).toList();

  List<RestaurantTable> get tablesOverCapacity =>
      _tables.where((t) => t.isOverCapacity).toList();

  /// Initialize the service and start real-time updates
  Future<void> initialize() async {
    await _loadTables();
    _startRealTimeUpdates();
  }

  /// Load tables from database
  Future<void> _loadTables() async {
    try {
      _tables = await DatabaseService.instance.getTables();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tables: $e');
    }
  }

  /// Start real-time updates every 30 seconds
  void _startRealTimeUpdates() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshTables();
    });
  }

  /// Manually refresh tables
  Future<void> refreshTables() async {
    await _refreshTables();
  }

  /// Internal refresh method
  Future<void> _refreshTables() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      final updatedTables = await DatabaseService.instance.getTables();
      _tables = updatedTables;
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing tables: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  /// Get table by ID
  RestaurantTable? getTableById(String id) {
    return _tables.cast<RestaurantTable?>().firstWhere(
      (table) => table?.id == id,
      orElse: () => null,
    );
  }

  /// Update table status and persist to database
  Future<void> updateTableStatus(String tableId, TableStatus newStatus) async {
    final table = getTableById(tableId);
    if (table == null) return;

    table.status = newStatus;
    if (newStatus == TableStatus.occupied && table.occupiedSince == null) {
      table.occupiedSince = DateTime.now();
    } else if (newStatus == TableStatus.available) {
      table.occupiedSince = null;
      table.customerName = null;
    }

    try {
      await DatabaseService.instance.updateTable(table);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating table status: $e');
    }
  }

  /// Add order to table
  Future<void> addOrderToTable(String tableId, CartItem item) async {
    final table = getTableById(tableId);
    if (table == null) return;

    table.addOrder(item);
    try {
      await DatabaseService.instance.updateTable(table);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding order to table: $e');
    }
  }

  /// Clear table orders
  Future<void> clearTableOrders(String tableId) async {
    final table = getTableById(tableId);
    if (table == null) return;

    table.clearOrders();
    try {
      await DatabaseService.instance.updateTable(table);
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing table orders: $e');
    }
  }

  /// Merge tables - combine orders from multiple tables into target
  Future<bool> mergeTables({
    required String targetTableId,
    required List<String> sourceTableIds,
  }) async {
    final targetTable = getTableById(targetTableId);
    if (targetTable == null) return false;

    final sourceTables = sourceTableIds
        .map((id) => getTableById(id))
        .where((table) => table != null)
        .cast<RestaurantTable>()
        .toList();

    if (sourceTables.isEmpty) return false;

    try {
      // Merge orders into target
      for (final sourceTable in sourceTables) {
        for (final order in sourceTable.orders) {
          targetTable.addOrMergeOrder(order);
        }
        sourceTable.clearOrders();
      }

      // Update all affected tables in database
      await DatabaseService.instance.updateTable(targetTable);
      for (final sourceTable in sourceTables) {
        await DatabaseService.instance.updateTable(sourceTable);
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error merging tables: $e');
      return false;
    }
  }

  /// Split table - move specific orders to another table
  Future<bool> splitTableOrders({
    required String sourceTableId,
    required String targetTableId,
    required List<CartItem> ordersToMove,
  }) async {
    final sourceTable = getTableById(sourceTableId);
    final targetTable = getTableById(targetTableId);

    if (sourceTable == null || targetTable == null) return false;

    try {
      // Move orders from source to target
      for (final order in ordersToMove) {
        targetTable.addOrMergeOrder(order);
        // Remove from source table
        sourceTable.orders.removeWhere((o) =>
          o.hasSameConfigurationWithDiscount(
            order.product,
            order.modifiers,
            order.discountPerUnit,
            otherPriceAdjustment: order.priceAdjustment,
            otherSeatNumber: order.seatNumber,
          ) && o.quantity >= order.quantity
        );
      }

      // Update table statuses
      if (sourceTable.orders.isEmpty) {
        sourceTable.status = TableStatus.available;
        sourceTable.occupiedSince = null;
      }
      if (targetTable.status == TableStatus.available && targetTable.orders.isNotEmpty) {
        targetTable.status = TableStatus.occupied;
        targetTable.occupiedSince = DateTime.now();
      }

      // Persist changes
      await DatabaseService.instance.updateTable(sourceTable);
      await DatabaseService.instance.updateTable(targetTable);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error splitting table orders: $e');
      return false;
    }
  }

  /// Create new table
  Future<bool> createTable(RestaurantTable table) async {
    try {
      await DatabaseService.instance.insertTable(table);
      await _loadTables(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('Error creating table: $e');
      return false;
    }
  }

  /// Update table information
  Future<bool> updateTable(RestaurantTable table) async {
    try {
      await DatabaseService.instance.updateTable(table);
      await _loadTables(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('Error updating table: $e');
      return false;
    }
  }

  /// Delete table
  Future<bool> deleteTable(String tableId) async {
    final table = getTableById(tableId);
    if (table == null || table.isOccupied) return false;

    try {
      await DatabaseService.instance.deleteTable(tableId);
      await _loadTables(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('Error deleting table: $e');
      return false;
    }
  }

  /// Get tables by status
  List<RestaurantTable> getTablesByStatus(TableStatus status) {
    return _tables.where((table) => table.status == status).toList();
  }

  /// Get tables with capacity warnings
  List<RestaurantTable> getCapacityWarningTables() {
    return _tables.where((table) => table.needsCapacityWarning).toList();
  }

  /// Get occupancy statistics
  Map<String, dynamic> getOccupancyStats() {
    final totalCapacity = _tables.fold(0, (sum, t) => sum + t.capacity);
    final currentOccupancy = _tables.fold(0, (sum, t) => sum + t.currentOccupancy);
    final occupancyRate = totalCapacity > 0 ? (currentOccupancy / totalCapacity) * 100 : 0.0;

    return {
      'totalCapacity': totalCapacity,
      'currentOccupancy': currentOccupancy,
      'occupancyRate': occupancyRate,
      'availableCapacity': totalCapacity - currentOccupancy,
      'tablesAtCapacity': tablesAtCapacity.length,
      'tablesOverCapacity': tablesOverCapacity.length,
    };
  }

  /// Dispose of resources
  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}