import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';

/// Pure business logic for cart calculations
/// No Flutter imports, 100% unit testable
class CartCalculationService {
  /// Calculate subtotal from cart items
  static double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }

  /// Calculate tax amount
  static double calculateTax(double subtotal, BusinessInfo info) {
    if (!info.isTaxEnabled) return 0.0;
    return subtotal * info.taxRate;
  }

  /// Calculate service charge amount
  static double calculateServiceCharge(double subtotal, BusinessInfo info) {
    if (!info.isServiceChargeEnabled) return 0.0;
    return subtotal * info.serviceChargeRate;
  }

  /// Calculate total including all charges
  static double calculateTotal(List<CartItem> items, BusinessInfo info) {
    final subtotal = calculateSubtotal(items);
    final tax = calculateTax(subtotal, info);
    final serviceCharge = calculateServiceCharge(subtotal, info);
    return subtotal + tax + serviceCharge;
  }

  /// Calculate discount amount (applied to subtotal before tax/service)
  static double calculateDiscount(double subtotal, double discountAmount, double discountPercent) {
    final percentDiscount = subtotal * (discountPercent / 100);
    return discountAmount + percentDiscount;
  }

  /// Calculate total including discount
  static double calculateTotalWithDiscount(List<CartItem> items, BusinessInfo info, double discountAmount, double discountPercent) {
    final subtotal = calculateSubtotal(items);
    final discount = calculateDiscount(subtotal, discountAmount, discountPercent);
    final subtotalAfterDiscount = subtotal - discount;
    if (subtotalAfterDiscount < 0) return 0.0; // Prevent negative totals
    
    final tax = calculateTax(subtotalAfterDiscount, info);
    final serviceCharge = calculateServiceCharge(subtotalAfterDiscount, info);
    return subtotalAfterDiscount + tax + serviceCharge;
  }
}