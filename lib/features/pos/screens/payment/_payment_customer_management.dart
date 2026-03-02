import 'package:extropos/models/customer_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:flutter/material.dart';

/// Mixin for payment screen customer management operations
mixin PaymentScreenCustomerManagement {
  // Text controllers (from main state)
  late TextEditingController _phoneController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  // State variables (from main state)
  late Customer? _selectedCustomer;
  late List<Customer> _customerSuggestions;
  late bool _isSearchingCustomer;

  /// Search for customers by phone number
  Future<void> searchCustomerByPhone(String phone) async {
    if (phone.trim().isEmpty) {
      // Clear suggestions if phone is empty
      _setSearching(false, []);
      return;
    }

    _setSearching(true, []);

    try {
      final results = await DatabaseService.instance.searchCustomers(phone);
      _setSearching(false, results);
    } catch (e) {
      _setSearching(false, []);
    }
  }

  /// Select a customer from search results
  void selectCustomer(Customer customer) {
    _selectedCustomer = customer;
    _phoneController.text = customer.phone ?? '';
    _nameController.text = customer.name;
    _emailController.text = customer.email ?? '';
    _setSearching(false, []);
  }

  /// Clear customer selection
  void clearCustomer() {
    _selectedCustomer = null;
    _phoneController.clear();
    _nameController.clear();
    _emailController.clear();
    _setSearching(false, []);
  }

  /// Helper to update search state
  void _setSearching(bool searching, List<Customer> suggestions) {
    _isSearchingCustomer = searching;
    _customerSuggestions = suggestions;
  }

  /// Get currently selected customer
  Customer? get selectedCustomer => _selectedCustomer;

  /// Get customer suggestions list
  List<Customer> get customerSuggestions => _customerSuggestions;

  /// Check if customer search is in progress
  bool get isSearchingCustomer => _isSearchingCustomer;

  /// Get customer name (selected or entered)
  String get customerName => _nameController.text.trim();

  /// Get customer phone (selected or entered)
  String get customerPhone => _phoneController.text.trim();

  /// Get customer email (selected or entered)
  String get customerEmail => _emailController.text.trim();

  /// Check if customer fields are filled (at least name and phone)
  bool get hasCustomerInfo =>
      _nameController.text.trim().isNotEmpty &&
      _phoneController.text.trim().isNotEmpty;
}
