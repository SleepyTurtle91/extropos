import 'dart:convert';

import 'package:extropos/models/parked_sale_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing parked/suspended sales
class ParkedSaleService {
  static const String _parkedSalesKey = 'parked_sales';
  static ParkedSaleService? _instance;

  ParkedSaleService._();

  static ParkedSaleService get instance {
    _instance ??= ParkedSaleService._();
    return _instance!;
  }

  /// Save a parked sale
  Future<void> saveParkedSale(ParkedSale sale) async {
    final prefs = await SharedPreferences.getInstance();
    final sales = await getParkedSales();

    // Remove existing sale with same ID if it exists
    sales.removeWhere((s) => s.id == sale.id);

    // Add new sale
    sales.add(sale);

    // Save to storage
    final salesJson = sales.map((s) => s.toJson()).toList();
    await prefs.setString(_parkedSalesKey, jsonEncode(salesJson));
  }

  /// Get all parked sales
  Future<List<ParkedSale>> getParkedSales() async {
    final prefs = await SharedPreferences.getInstance();
    final salesJson = prefs.getString(_parkedSalesKey);

    if (salesJson == null) return [];

    try {
      final salesList = jsonDecode(salesJson) as List;
      return salesList.map((json) => ParkedSale.fromJson(json)).toList();
    } catch (e) {
      // If parsing fails, return empty list
      return [];
    }
  }

  /// Delete a parked sale by ID
  Future<void> deleteParkedSale(String saleId) async {
    final prefs = await SharedPreferences.getInstance();
    final sales = await getParkedSales();

    sales.removeWhere((s) => s.id == saleId);

    final salesJson = sales.map((s) => s.toJson()).toList();
    await prefs.setString(_parkedSalesKey, jsonEncode(salesJson));
  }

  /// Get a parked sale by ID
  Future<ParkedSale?> getParkedSale(String saleId) async {
    final sales = await getParkedSales();
    return sales.where((s) => s.id == saleId).firstOrNull;
  }

  /// Clear all parked sales
  Future<void> clearAllParkedSales() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_parkedSalesKey);
  }

  /// Get count of parked sales
  Future<int> getParkedSalesCount() async {
    final sales = await getParkedSales();
    return sales.length;
  }
}
