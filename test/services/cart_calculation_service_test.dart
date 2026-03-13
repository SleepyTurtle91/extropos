/// Tests for CartCalculationService — validates the Malaysian POS
/// calculation order: Subtotal → Discount → Service Charge → Tax → Rounding.
///
/// BNM/LHDN order:
///   taxableAmount = subtotal − discount
///   serviceCharge = taxableAmount × serviceChargeRate
///   taxBase       = taxableAmount + serviceCharge
///   tax           = taxBase × taxRate         (SST applies on service too)
///   total         = roundCash(taxBase + tax)  [cash] | toFixed(2) [non-cash]
library;
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/cart_calculation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fixtures ─────────────────────────────────────────────────────────────────

BusinessInfo _info({
  double taxRate = 0.06,       // 6% SST
  bool isTaxEnabled = true,
  double serviceChargeRate = 0.10,  // 10% service charge
  bool isServiceChargeEnabled = true,
}) {
  return BusinessInfo(
    businessName: 'Test Cafe',
    ownerName: 'Tester',
    email: 'test@example.com',
    phone: '0112345678',
    address: 'Jalan Test',
    city: 'KL',
    state: 'WP KL',
    postcode: '50000',
    taxRate: taxRate,
    isTaxEnabled: isTaxEnabled,
    serviceChargeRate: serviceChargeRate,
    isServiceChargeEnabled: isServiceChargeEnabled,
  );
}

CartItem _item(double price, {int qty = 1}) {
  return CartItem(
    Product('Test Item', price, 'Food', Icons.fastfood, id: 'test-item'),
    qty,
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('CartCalculationService.calculateSubtotal', () {
    test('single item x1', () {
      expect(
        CartCalculationService.calculateSubtotal([_item(10.0)]),
        closeTo(10.00, 0.001),
      );
    });

    test('single item x3', () {
      expect(
        CartCalculationService.calculateSubtotal([_item(5.0, qty: 3)]),
        closeTo(15.00, 0.001),
      );
    });

    test('multiple items', () {
      final items = [_item(10.0), _item(5.0, qty: 2), _item(3.50)];
      // 10 + 10 + 3.5 = 23.5
      expect(
        CartCalculationService.calculateSubtotal(items),
        closeTo(23.50, 0.001),
      );
    });

    test('empty cart returns 0', () {
      expect(CartCalculationService.calculateSubtotal([]), closeTo(0.0, 0.001));
    });
  });

  group('CartCalculationService.calculateBreakdown — tax-on-service order', () {
    test('no service charge, no tax → total equals subtotal (rounded)', () {
      final b = CartCalculationService.calculateBreakdown(
        [_item(10.00)],
        _info(isTaxEnabled: false, isServiceChargeEnabled: false),
      );
      expect(b.subtotal, closeTo(10.00, 0.001));
      expect(b.serviceCharge, closeTo(0.00, 0.001));
      expect(b.tax, closeTo(0.00, 0.001));
      expect(b.total, closeTo(10.00, 0.001));
    });

    test('service charge only (10%), NO tax', () {
      // subtotal=100, service=10, tax=0, total=110
      final b = CartCalculationService.calculateBreakdown(
        [_item(100.0)],
        _info(isTaxEnabled: false),
      );
      expect(b.serviceCharge, closeTo(10.00, 0.001));
      expect(b.tax, closeTo(0.00, 0.001));
      expect(b.total, closeTo(110.00, 0.001));
    });

    test('tax only (6%) on subtotal, NO service charge', () {
      // subtotal=100, service=0, taxBase=100, tax=6, total=106
      final b = CartCalculationService.calculateBreakdown(
        [_item(100.0)],
        _info(isServiceChargeEnabled: false),
      );
      expect(b.serviceCharge, closeTo(0.00, 0.001));
      expect(b.taxBase, closeTo(100.00, 0.001));
      expect(b.tax, closeTo(6.00, 0.001));
      expect(b.total, closeTo(106.00, 0.001));
    });

    test('service charge (10%) + tax (6%) — tax applies on service too', () {
      // subtotal=100
      // service = 100×0.10 = 10
      // taxBase = 100+10 = 110
      // tax     = 110×0.06 = 6.60
      // preRound= 110+6.60 = 116.60
      // total   = roundCash(116.60) → last digit 0 → 116.60
      final b = CartCalculationService.calculateBreakdown(
        [_item(100.0)],
        _info(),
      );
      expect(b.serviceCharge, closeTo(10.00, 0.001));
      expect(b.taxBase, closeTo(110.00, 0.001));
      expect(b.tax, closeTo(6.60, 0.001));
      expect(b.total, closeTo(116.60, 0.001));
    });

    test('SST tax applies on (subtotal + service charge)', () {
      // This is the KEY test proving the correct Malaysian calculation order.
      // If tax were applied only on subtotal (old wrong behaviour):
      //   tax = 100×0.06 = 6 → total = 116 (WRONG)
      // Correct: tax on (subtotal + service charge):
      //   tax = 110×0.06 = 6.60 → total = 116.60 (CORRECT)
      final b = CartCalculationService.calculateBreakdown(
        [_item(100.0)],
        _info(),
      );
      expect(b.tax, isNot(closeTo(6.00, 0.001)),
          reason: 'Tax must be on taxBase (subtotal+service), not just subtotal');
      expect(b.tax, closeTo(6.60, 0.001));
    });
  });

  group('CartCalculationService.calculateBreakdown — discount', () {
    test('flat discount applied before service+tax', () {
      // subtotal=100, discount=20 → taxable=80
      // service=80×0.10=8 → taxBase=88
      // tax=88×0.06=5.28 → total=93.28
      final b = CartCalculationService.calculateBreakdown(
        [_item(100.0)],
        _info(),
        discountAmount: 20.0,
      );
      expect(b.discount, closeTo(20.00, 0.001));
      expect(b.taxableAmount, closeTo(80.00, 0.001));
      expect(b.serviceCharge, closeTo(8.00, 0.001));
      expect(b.taxBase, closeTo(88.00, 0.001));
      expect(b.tax, closeTo(5.28, 0.001));
      // preRound=93.28 → ends in 8 → round up 2 → 93.30
      expect(b.total, closeTo(93.30, 0.001));
    });

    test('percentage discount', () {
      // subtotal=100, 10% discount=10 → taxable=90
      // service=90×0.10=9 → taxBase=99
      // tax=99×0.06=5.94 → total=104.94 → ends in 4 → round up → 104.95
      final b = CartCalculationService.calculateBreakdown(
        [_item(100.0)],
        _info(),
        discountPercent: 10.0,
      );
      expect(b.taxableAmount, closeTo(90.00, 0.001));
      expect(b.total, closeTo(104.95, 0.001));
    });

    test('discount exceeding subtotal clamps to zero', () {
      final b = CartCalculationService.calculateBreakdown(
        [_item(10.0)],
        _info(),
        discountAmount: 50.0,
      );
      expect(b.taxableAmount, closeTo(0.00, 0.001));
      expect(b.total, closeTo(0.00, 0.001));
    });
  });

  group('CartCalculationService — cash vs non-cash rounding', () {
    test('cash payment → BNM rounding applied', () {
      // Build a scenario where preRound doesn't end in 0 or 5 sen
      // subtotal=10.01, no service, no tax → preRound=10.01
      // cash → ends in 1 → round down → 10.00
      final b = CartCalculationService.calculateBreakdown(
        [_item(10.01)],
        _info(isTaxEnabled: false, isServiceChargeEnabled: false),
        cashPayment: true,
      );
      expect(b.total, closeTo(10.00, 0.001));
      expect(b.roundingAdjustment, closeTo(-0.01, 0.001));
    });

    test('non-cash payment → no BNM rounding', () {
      final b = CartCalculationService.calculateBreakdown(
        [_item(10.01)],
        _info(isTaxEnabled: false, isServiceChargeEnabled: false),
        cashPayment: false,
      );
      // Non-cash: just standard 2dp fix, no 5-sen rounding
      expect(b.total, closeTo(10.01, 0.001));
    });
  });

  group('CartCalculationService convenience methods', () {
    test('calculateTotal matches calculateBreakdown.total', () {
      final items = [_item(50.0), _item(25.0, qty: 2)];
      final info = _info();
      final breakdown = CartCalculationService.calculateBreakdown(items, info);
      final total = CartCalculationService.calculateTotal(items, info);
      expect(total, closeTo(breakdown.total, 0.001));
    });

    test('calculateTotalWithDiscount matches calculateBreakdown with discount', () {
      final items = [_item(100.0)];
      final info = _info();
      final breakdown = CartCalculationService.calculateBreakdown(
        items,
        info,
        discountAmount: 15.0,
      );
      final total = CartCalculationService.calculateTotalWithDiscount(
        items,
        info,
        15.0,
        0.0,
      );
      expect(total, closeTo(breakdown.total, 0.001));
    });
  });
}
