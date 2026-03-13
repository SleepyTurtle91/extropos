import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/services/utils/rounding_service.dart';

/// Pure business logic for cart calculations.
/// No Flutter imports — 100% unit testable.
///
/// Malaysian POS calculation order (matches BNM / LHDN requirements):
///   1. Subtotal  = sum(item.quantity × item.finalPrice)
///   2. Discount  = flat + (subtotal × discountPercent / 100)
///   3. Taxable   = subtotal − discount  (clamped ≥ 0)
///   4. Service   = taxable × serviceChargeRate  (if enabled)
///   5. Tax base  = taxable + service             (SST applies on service too)
///   6. Tax       = taxBase × taxRate             (if enabled)
///   7. Pre-round = taxable + service + tax
///   8. Total     = RoundingService.roundCash(preRound)  [cash only]
class CartCalculationService {
  /// Calculate subtotal from cart items.
  static double calculateSubtotal(List<CartItem> items) {
    return items.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.finalPrice),
    );
  }

  /// Calculate service charge on [taxableAmount].
  /// Applied BEFORE tax so that SST can include the service charge in its base.
  static double calculateServiceCharge(double taxableAmount, BusinessInfo info) {
    if (!info.isServiceChargeEnabled) return 0.0;
    return taxableAmount * info.serviceChargeRate;
  }

  /// Calculate tax on [taxBase] = (taxableAmount + serviceCharge).
  /// Malaysian SST is charged on goods + service charge.
  static double calculateTax(double taxBase, BusinessInfo info) {
    if (!info.isTaxEnabled) return 0.0;
    return taxBase * info.taxRate;
  }

  /// Calculate discount amount (flat + percentage of subtotal).
  static double calculateDiscount(
    double subtotal,
    double discountAmount,
    double discountPercent,
  ) {
    final percentDiscount = subtotal * (discountPercent / 100);
    return discountAmount + percentDiscount;
  }

  /// Full breakdown of a cart's financials.
  ///
  /// Returns a named record so callers can display each component clearly.
  static ({
    double subtotal,
    double discount,
    double taxableAmount,
    double serviceCharge,
    double taxBase,
    double tax,
    double preRoundTotal,
    double total,
    double roundingAdjustment,
  }) calculateBreakdown(
    List<CartItem> items,
    BusinessInfo info, {
    double discountAmount = 0.0,
    double discountPercent = 0.0,
    bool cashPayment = true,
  }) {
    final subtotal = calculateSubtotal(items);
    final discount = calculateDiscount(subtotal, discountAmount, discountPercent);
    final taxableAmount = (subtotal - discount).clamp(0.0, double.infinity);
    final serviceCharge = calculateServiceCharge(taxableAmount, info);
    final taxBase = taxableAmount + serviceCharge;
    final tax = calculateTax(taxBase, info);
    final preRoundTotal = taxBase + tax;
    final total = cashPayment
        ? RoundingService.roundCash(preRoundTotal)
        : (preRoundTotal * 100).round() / 100.0;
    final roundingAdjustment = total - preRoundTotal;

    return (
      subtotal: subtotal,
      discount: discount,
      taxableAmount: taxableAmount,
      serviceCharge: serviceCharge,
      taxBase: taxBase,
      tax: tax,
      preRoundTotal: preRoundTotal,
      total: total,
      roundingAdjustment: roundingAdjustment,
    );
  }

  /// Convenience: total for a cash transaction (with BNM rounding).
  static double calculateTotal(
    List<CartItem> items,
    BusinessInfo info, {
    bool cashPayment = true,
  }) {
    final b = calculateBreakdown(items, info, cashPayment: cashPayment);
    return b.total;
  }

  /// Convenience: total with discount applied.
  static double calculateTotalWithDiscount(
    List<CartItem> items,
    BusinessInfo info,
    double discountAmount,
    double discountPercent, {
    bool cashPayment = true,
  }) {
    final b = calculateBreakdown(
      items,
      info,
      discountAmount: discountAmount,
      discountPercent: discountPercent,
      cashPayment: cashPayment,
    );
    return b.total;
  }
}