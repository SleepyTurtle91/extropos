import 'dart:developer' as developer;

import 'package:extropos/models/table_model.dart';
import 'package:extropos/services/database_helper.dart';
import 'package:flutter/foundation.dart';

/// Service for managing restaurant tables
/// Handles CRUD operations, status management, merging/splitting, and persistence
class TableManagementService extends ChangeNotifier {
  static final TableManagementService _instance = TableManagementService._();
  
  factory TableManagementService() => _instance;
  TableManagementService._();

  // In-memory cache of tables
  List<RestaurantTable> _tables = [];
  
  List<RestaurantTable> get tables => List.unmodifiable(_tables);
  
  /// Get table by ID
  RestaurantTable? getTableById(String id) {
    try {
      return _tables.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
  
  /// Get all available tables
  List<RestaurantTable> getAvailableTables() {
    return _tables.where((t) => t.isAvailable).toList();
  }
  
  /// Get all occupied tables
  List<RestaurantTable> getOccupiedTables() {
    return _tables.where((t) => t.isOccupied || t.isMerged).toList();
  }
  
  /// Get all reserved tables
  List<RestaurantTable> getReservedTables() {
    return _tables.where((t) => t.isReserved).toList();
  }
  
  /// Get all tables that need cleaning
  List<RestaurantTable> getTablesCleaning() {
    return _tables.where((t) => t.isCleaning).toList();
  }
  
  /// Load all tables from database
  Future<void> loadTablesFromDatabase() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('restaurant_tables', orderBy: 'name ASC');
      _tables = maps.map((map) => RestaurantTable.fromMap(map)).toList();
      developer.log('✅ Loaded ${_tables.length} tables from database');
      notifyListeners();
    } catch (e) {
      developer.log('❌ Failed to load tables: $e');
    }
  }
  
  /// Create a new table
  Future<bool> createTable({
    required String id,
    required String name,
    required int capacity,
  }) async {
    try {
      // Validate inputs
      if (id.isEmpty || name.isEmpty || capacity <= 0) {
        developer.log('❌ Invalid table data');
        return false;
      }
      
      // Check if table already exists
      if (_tables.any((t) => t.id == id)) {
        developer.log('❌ Table with ID $id already exists');
        return false;
      }
      
      final table = RestaurantTable(
        id: id,
        name: name,
        capacity: capacity,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save to database
      final db = await DatabaseHelper.instance.database;
      await db.insert('restaurant_tables', table.toMap());
      
      _tables.add(table);
      notifyListeners();
      developer.log('✅ Table created: $name');
      return true;
    } catch (e) {
      developer.log('❌ Failed to create table: $e');
      return false;
    }
  }
  
  /// Update table information
  Future<bool> updateTable({
    required String id,
    String? name,
    int? capacity,
    String? customerName,
    String? customerPhone,
    String? notes,
  }) async {
    try {
      final table = getTableById(id);
      if (table == null) {
        developer.log('❌ Table not found: $id');
        return false;
      }
      
      final updated = table.copyWith(
        name: name,
        capacity: capacity,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
        updatedAt: DateTime.now(),
      );
      
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'restaurant_tables',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      
      final idx = _tables.indexWhere((t) => t.id == id);
      if (idx != -1) {
        _tables[idx] = updated;
        notifyListeners();
      }
      
      developer.log('✅ Table updated: $id');
      return true;
    } catch (e) {
      developer.log('❌ Failed to update table: $e');
      return false;
    }
  }
  
  /// Delete table
  Future<bool> deleteTable(String id) async {
    try {
      final table = getTableById(id);
      if (table == null) {
        developer.log('❌ Table not found: $id');
        return false;
      }
      
      // Don't allow deleting occupied tables
      if (table.isOccupied || table.isMerged) {
        developer.log('❌ Cannot delete occupied table: $id');
        return false;
      }
      
      final db = await DatabaseHelper.instance.database;
      await db.delete(
        'restaurant_tables',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      _tables.removeWhere((t) => t.id == id);
      notifyListeners();
      developer.log('✅ Table deleted: $id');
      return true;
    } catch (e) {
      developer.log('❌ Failed to delete table: $e');
      return false;
    }
  }
  
  /// Set table as occupied
  Future<bool> occupyTable(String id, {String? customerName, String? customerPhone}) async {
    try {
      final table = getTableById(id);
      if (table == null) return false;
      
      final updated = table.copyWith(
        status: TableStatus.occupied,
        occupiedSince: DateTime.now(),
        customerName: customerName,
        customerPhone: customerPhone,
        updatedAt: DateTime.now(),
      );
      
      await _saveTable(updated);
      developer.log('✅ Table occupied: $id');
      return true;
    } catch (e) {
      developer.log('❌ Failed to occupy table: $e');
      return false;
    }
  }
  
  /// Set table as available (clear orders and reset)
  Future<bool> releaseTable(String id) async {
    try {
      final table = getTableById(id);
      if (table == null) return false;
      
      final updated = table.copyWith(
        status: TableStatus.available,
        orders: [],
        clearOccupiedSince: true,
        customerName: null,
        customerPhone: null,
        notes: null,
        mergedTableIds: null,
        updatedAt: DateTime.now(),
      );
      
      await _saveTable(updated);
      developer.log('✅ Table released: $id');
      return true;
    } catch (e) {
      developer.log('❌ Failed to release table: $e');
      return false;
    }
  }
  
  /// Set table for cleaning
  Future<bool> setTableCleaning(String id) async {
    try {
      final table = getTableById(id);
      if (table == null) return false;
      
      final updated = table.copyWith(
        status: TableStatus.cleaning,
        updatedAt: DateTime.now(),
      );
      
      await _saveTable(updated);
      developer.log('✅ Table marked for cleaning: $id');
      return true;
    } catch (e) {
      developer.log('❌ Failed to mark table for cleaning: $e');
      return false;
    }
  }
  
  /// Mark table as reserved
  Future<bool> reserveTable(
    String id, {
    required String customerName,
    required DateTime reservedUntil,
  }) async {
    try {
      final table = getTableById(id);
      if (table == null) return false;
      
      final updated = table.copyWith(
        status: TableStatus.reserved,
        customerName: customerName,
        updatedAt: DateTime.now(),
      );
      
      await _saveTable(updated);
      developer.log('✅ Table reserved: $id for $customerName');
      return true;
    } catch (e) {
      developer.log('❌ Failed to reserve table: $e');
      return false;
    }
  }
  
  /// Merge multiple tables into one
  Future<bool> mergeTables(List<String> tableIds, {String? mergedName}) async {
    try {
      if (tableIds.isEmpty || tableIds.length < 2) {
        developer.log('❌ Need at least 2 tables to merge');
        return false;
      }
      
      final mainTable = getTableById(tableIds.first);
      if (mainTable == null) return false;
      
      // Get all tables to merge
      final otherTableIds = tableIds.skip(1).toList();
      final otherTables = otherTableIds
          .map((id) => getTableById(id))
          .whereType<RestaurantTable>()
          .toList();
      
      if (otherTables.length != otherTableIds.length) {
        developer.log('❌ One or more tables not found');
        return false;
      }
      
      // Combine all orders and capacity
      final combinedOrders = [...mainTable.orders];
      int totalCapacity = mainTable.capacity;
      
      for (final table in otherTables) {
        combinedOrders.addAll(table.orders);
        totalCapacity += table.capacity;
      }
      
      // Create merged table entry
      final merged = mainTable.copyWith(
        name: mergedName ?? '${mainTable.name} + Others',
        capacity: totalCapacity,
        orders: combinedOrders,
        status: TableStatus.merged,
        mergedTableIds: tableIds,
        occupiedSince: mainTable.occupiedSince ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Save merged table and mark others as unavailable
      await _saveTable(merged);
      
      for (final otherId in otherTableIds) {
        final other = getTableById(otherId);
        if (other != null) {
          final updated = other.copyWith(
            status: TableStatus.merged,
            updatedAt: DateTime.now(),
          );
          await _saveTable(updated);
        }
      }
      
      developer.log('✅ Tables merged: ${tableIds.join(", ")}');
      return true;
    } catch (e) {
      developer.log('❌ Failed to merge tables: $e');
      return false;
    }
  }
  
  /// Split merged table back to individual tables
  Future<bool> splitTable(String mergedTableId) async {
    try {
      final table = getTableById(mergedTableId);
      if (table == null || !table.isMerged || table.mergedTableIds == null) {
        developer.log('❌ Not a merged table: $mergedTableId');
        return false;
      }
      
      // Reset all merged tables to available
      for (final id in table.mergedTableIds!) {
        final individual = getTableById(id);
        if (individual != null) {
          final updated = individual.copyWith(
            status: TableStatus.available,
            orders: [],
            occupiedSince: null,
            updatedAt: DateTime.now(),
          );
          await _saveTable(updated);
        }
      }
      
      developer.log('✅ Tables split: $mergedTableId');
      return true;
    } catch (e) {
      developer.log('❌ Failed to split table: $e');
      return false;
    }
  }
  
  /// Get table statistics
  Map<String, int> getTableStatistics() {
    return {
      'total': _tables.length,
      'available': getAvailableTables().length,
      'occupied': getOccupiedTables().length,
      'reserved': getReservedTables().length,
      'cleaning': getTablesCleaning().length,
    };
  }
  
  /// Get average table duration in minutes for occupied tables
  double getAverageTableDuration() {
    final occupied = getOccupiedTables();
    if (occupied.isEmpty) return 0.0;
    
    final totalMinutes = occupied.fold<int>(
      0,
      (sum, table) => sum + table.occupiedDurationMinutes,
    );
    return totalMinutes / occupied.length;
  }
  
  /// Internal method to save table to database and cache
  Future<void> _saveTable(RestaurantTable table) async {
    final db = await DatabaseHelper.instance.database;
    final idx = _tables.indexWhere((t) => t.id == table.id);
    
    if (idx != -1) {
      // Update existing
      await db.update(
        'restaurant_tables',
        table.toMap(),
        where: 'id = ?',
        whereArgs: [table.id],
      );
      _tables[idx] = table;
    } else {
      // Insert new
      await db.insert('restaurant_tables', table.toMap());
      _tables.add(table);
    }
    
    notifyListeners();
  }
}
