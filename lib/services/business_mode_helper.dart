import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/business_mode.dart';
import 'package:flutter/material.dart';

/// Helper service for business mode operations and conditional logic
class BusinessModeHelper {
  /// Get current business mode from BusinessInfo
  static BusinessMode get currentMode => BusinessInfo.instance.selectedBusinessMode;

  /// Check if current mode is retail
  static bool get isRetail => currentMode == BusinessMode.retail;

  /// Check if current mode is cafe
  static bool get isCafe => currentMode == BusinessMode.cafe;

  /// Check if current mode is restaurant
  static bool get isRestaurant => currentMode == BusinessMode.restaurant;

  /// Check if current mode has table management
  static bool get hasTableManagement => currentMode.hasTableManagement;

  /// Check if current mode uses calling numbers
  static bool get useCallingNumbers => currentMode.useCallingNumbers;

  /// Get display name for current mode
  static String get currentModeDisplayName => currentMode.displayName;

  /// Get subtitle for current mode
  static String get currentModeSubtitle => currentMode.subtitle;

  /// Execute callback only if in retail mode
  static void ifRetail(VoidCallback callback) {
    if (isRetail) {
      callback();
    }
  }

  /// Execute callback only if in cafe mode
  static void ifCafe(VoidCallback callback) {
    if (isCafe) {
      callback();
    }
  }

  /// Execute callback only if in restaurant mode
  static void ifRestaurant(VoidCallback callback) {
    if (isRestaurant) {
      callback();
    }
  }

  /// Execute callback only if table management is enabled
  static void ifTableManagement(VoidCallback callback) {
    if (hasTableManagement) {
      callback();
    }
  }

  /// Execute callback only if calling numbers are used
  static void ifCallingNumbers(VoidCallback callback) {
    if (useCallingNumbers) {
      callback();
    }
  }

  /// Build widget conditionally based on business mode
  static Widget buildConditional({
    required Widget retail,
    required Widget cafe,
    required Widget restaurant,
  }) {
    switch (currentMode) {
      case BusinessMode.retail:
        return retail;
      case BusinessMode.cafe:
        return cafe;
      case BusinessMode.restaurant:
        return restaurant;
    }
  }

  /// Build widget conditionally with null fallback
  static Widget? buildConditionalOrNull({
    Widget? retail,
    Widget? cafe,
    Widget? restaurant,
  }) {
    switch (currentMode) {
      case BusinessMode.retail:
        return retail;
      case BusinessMode.cafe:
        return cafe;
      case BusinessMode.restaurant:
        return restaurant;
    }
  }

  /// Get mode-specific configuration
  static Map<String, dynamic> getModeConfig() {
    switch (currentMode) {
      case BusinessMode.retail:
        return {
          'hasOrderNumbers': false,
          'hasTableManagement': false,
          'workflow': 'direct_checkout',
          'cartPersistence': 'session',
          'primaryAction': 'checkout',
        };
      case BusinessMode.cafe:
        return {
          'hasOrderNumbers': true,
          'hasTableManagement': false,
          'workflow': 'order_number_tracking',
          'cartPersistence': 'session',
          'primaryAction': 'generate_order_number',
        };
      case BusinessMode.restaurant:
        return {
          'hasOrderNumbers': false,
          'hasTableManagement': true,
          'workflow': 'table_based_orders',
          'cartPersistence': 'table_based',
          'primaryAction': 'save_to_table',
        };
    }
  }

  /// Validate operation for current business mode
  static bool validateOperation(String operation, {Map<String, dynamic>? context}) {
    switch (currentMode) {
      case BusinessMode.retail:
        // Retail allows direct checkout operations
        return ['checkout', 'add_to_cart', 'remove_from_cart', 'apply_discount'].contains(operation);

      case BusinessMode.cafe:
        // Cafe allows order number operations
        return ['generate_order_number', 'add_to_cart', 'remove_from_cart', 'apply_discount', 'track_order'].contains(operation);

      case BusinessMode.restaurant:
        // Restaurant requires table context for most operations
        if (operation == 'checkout' || operation == 'save_to_table') {
          return context?['tableId'] != null;
        }
        return ['add_to_cart', 'remove_from_cart', 'apply_discount', 'assign_seat'].contains(operation);
    }
  }

  /// Log mode-specific operation
  static void logOperation(String operation, {Map<String, dynamic>? data}) {
    developer.log(
      'BusinessModeHelper: $operation in ${currentMode.displayName} mode',
      name: 'business_mode',
    );

    if (data != null && data.isNotEmpty) {
      developer.log('Operation data: $data', name: 'business_mode');
    }
  }

  /// Get mode-specific UI hints
  static List<String> getUIHints() {
    switch (currentMode) {
      case BusinessMode.retail:
        return [
          'Direct checkout after adding items',
          'No order tracking needed',
          'Session-based cart (cleared after payment)',
        ];
      case BusinessMode.cafe:
        return [
          'Generate order numbers for tracking',
          'Monitor active orders in bottom sheet',
          'Auto-incrementing order numbers',
        ];
      case BusinessMode.restaurant:
        return [
          'Select table before adding items',
          'Cart persists with table selection',
          'Save orders to table or checkout directly',
        ];
    }
  }

  /// Check if feature is available in current mode
  static bool isFeatureAvailable(String feature) {
    final config = getModeConfig();
    switch (feature) {
      case 'table_management':
        return config['hasTableManagement'] as bool;
      case 'order_numbers':
        return config['hasOrderNumbers'] as bool;
      case 'order_tracking':
        return config['workflow'] != 'direct_checkout';
      case 'cart_persistence':
        return config['cartPersistence'] == 'table_based';
      default:
        return false;
    }
  }

  /// Get mode-specific navigation flow
  static List<String> getNavigationFlow() {
    switch (currentMode) {
      case BusinessMode.retail:
        return ['ProductSelection', 'CartManagement', 'Payment', 'Receipt'];
      case BusinessMode.cafe:
        return ['ProductSelection', 'CartManagement', 'OrderNumberGeneration', 'ActiveOrders', 'Payment', 'Receipt'];
      case BusinessMode.restaurant:
        return ['TableSelection', 'ProductSelection', 'CartManagement', 'SaveToTable', 'Payment', 'Receipt'];
    }
  }
}