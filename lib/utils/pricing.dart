import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';

/// Pricing helpers centralizing subtotal, tax and service charge calculations.
///
/// Screens should prefer calling these helpers to ensure consistent totals
/// across Retail, Cafe and Restaurant modes and to honor `BusinessInfo` flags.
class Pricing {
  /// Sum of line totals for all cart items.
  static double subtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Tax amount based on `BusinessInfo.instance` configuration.
  static double taxAmount(List<CartItem> items) {
    final info = BusinessInfo.instance;
    final sub = subtotal(items);
    return info.isTaxEnabled ? sub * info.taxRate : 0.0;
  }

  /// Service charge based on `BusinessInfo.instance` configuration.
  static double serviceChargeAmount(List<CartItem> items) {
    final info = BusinessInfo.instance;
    final sub = subtotal(items);
    return info.isServiceChargeEnabled ? sub * info.serviceChargeRate : 0.0;
  }

  /// Total payable amount = subtotal + tax + service charge.
  static double total(List<CartItem> items) {
    return subtotal(items) + taxAmount(items) + serviceChargeAmount(items);
  }

  /// Tax amount with a flat bill-level discount applied to subtotal.
  static double taxAmountWithDiscount(List<CartItem> items, double discount) {
    final info = BusinessInfo.instance;
    final sub = subtotal(items) - discount;
    final base = sub < 0 ? 0.0 : sub;
    return info.isTaxEnabled ? base * info.taxRate : 0.0;
  }

  /// Service charge amount with a flat bill-level discount applied to subtotal.
  static double serviceChargeAmountWithDiscount(
    List<CartItem> items,
    double discount,
  ) {
    final info = BusinessInfo.instance;
    final sub = subtotal(items) - discount;
    final base = sub < 0 ? 0.0 : sub;
    return info.isServiceChargeEnabled ? base * info.serviceChargeRate : 0.0;
  }

  /// Total with bill-level discount applied before tax/service charge.
  static double totalWithDiscount(List<CartItem> items, double discount) {
    final sub = subtotal(items) - discount;
    final base = sub < 0 ? 0.0 : sub;
    return base + taxAmountWithDiscount(items, discount) +
        serviceChargeAmountWithDiscount(items, discount);
  }
}
