---
name: pos-business-logic-calculations
description: Build accurate POS business logic for cart operations, tax/discount calculations, payment processing, and financial workflows. Implement cart management, pricing calculations with tax/service charge, discount logic, and payment validation.
license: Proprietary
compatibility: Flutter 3.0+, Dart 3.0+. Designed for POS systems with tax, service charge, and multi-payment support.
metadata:
  author: FlutterPOS
  version: "1.0"
  domain: flutter-dart
  focus: business-logic
---

# POS Business Logic & Calculations

**When to use this skill**: Implementing cart operations, tax/service charge calculations, discounts, payment processing, receipt generation, validating financial logic.

## Core POS Business Services

### 1. Cart Management (Layer A)

Keep cart state simple and testable:

```dart
class CartManagementService {
  final List<CartItem> _items = [];
  
  void addItem(CartItem item) {
    final existing = _items.firstWhereOrNull((i) => i.product.id == item.product.id);
    if (existing != null) {
      existing.quantity++;
    } else {
      _items.add(item);
    }
  }
  
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
  }
  
  void updateQuantity(String productId, int newQty) {
    if (newQty <= 0) {
      removeItem(productId);
      return;
    }
    final item = _items.firstWhereOrNull((i) => i.product.id == productId);
    if (item != null) item.quantity = newQty;
  }
  
  List<CartItem> get items => List.unmodifiable(_items);
  void clearCart() => _items.clear();
}
```

### 2. Price Calculations (Critical)

**ALWAYS use `BusinessInfo.instance` for tax/service rates**:

```dart
class CartCalculationService {
  static double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }
  
  static double calculateTax(double subtotal, BusinessInfo info) {
    return info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
  }
  
  static double calculateServiceCharge(double subtotal, BusinessInfo info) {
    return info.isServiceChargeEnabled ? subtotal * info.serviceChargeRate : 0.0;
  }
  
  static double calculateTotal(List<CartItem> items, BusinessInfo info) {
    final subtotal = calculateSubtotal(items);
    final tax = calculateTax(subtotal, info);
    final serviceCharge = calculateServiceCharge(subtotal, info);
    return subtotal + tax + serviceCharge;
  }
}
```

**Key Rules**:
- ✅ Tax/service rates stored as decimals (0.10 = 10%)
- ✅ Always get rates from `BusinessInfo.instance`
- ✅ Recalculate after ANY cart modification
- ❌ Never hardcode tax rates
- ❌ Never do calculations in widget build()

### 3. Discount Logic

Apply discounts BEFORE calculating tax:

```dart
class DiscountService {
  static double calculateTotal(
    List<CartItem> items,
    double discountAmount,
    BusinessInfo info,
  ) {
    final subtotalAfterDiscount = calculateSubtotal(items) - discountAmount;
    if (subtotalAfterDiscount < 0) throw ValidationException('Invalid discount');
    
    final tax = calculateTax(subtotalAfterDiscount, info);
    final serviceCharge = calculateServiceCharge(subtotalAfterDiscount, info);
    
    return subtotalAfterDiscount + tax + serviceCharge;
  }
}
```

### 4. Payment Processing

```dart
class PaymentProcessingService {
  static PaymentResult processPayment({
    required double amount,
    required double tendered,
    required PaymentMethod method,
  }) {
    if (amount <= 0) throw PaymentException('Invalid amount');
    if (tendered < amount) throw PaymentException('Insufficient payment');
    
    return PaymentResult(
      amount: amount,
      tendered: tendered,
      change: tendered - amount,
      method: method,
      timestamp: DateTime.now(),
      success: true,
    );
  }
}
```

## Unit Testing Business Logic

**All Layer A code must have unit tests**:

```dart
test('calculates tax correctly', () {
  final info = BusinessInfo()..isTaxEnabled = true..taxRate = 0.06;
  final tax = CartCalculationService.calculateTax(100.0, info);
  expect(tax, equals(6.0));
});

test('discounts do not exceed subtotal', () {
  expect(
    () => DiscountService.applyDiscount(150.0, 200.0),
    throwsA(isA<ValidationException>()),
  );
});
```

## Common Calculation Pitfalls

❌ **Wrong**: `total = subtotal + 0.06` (hardcoded tax)
✅ **Correct**: `total = subtotal + calculateTax(subtotal, info)`

❌ **Wrong**: Calculate tax on original subtotal after discount
✅ **Correct**: Tax = (subtotal - discount) × rate

❌ **Wrong**: Service charge on total including tax
✅ **Correct**: Service charge on subtotal only

❌ **Wrong**: Negative totals after discount
✅ **Correct**: Validate discount ≤ subtotal before applying

## Integration with Your Project

**Existing Services**:
- `lib/services/cart_service.dart` - Cart management
- `lib/services/payment_service.dart` - Payment processing
- `BusinessInfo.instance` - Global tax/service configuration

**Currency**: All amounts in RM with 0.05 rounding standard

**Testing**: 40+ unit tests for all calculations

---

See [references/CALCULATIONS_DETAILED.md](references/CALCULATIONS_DETAILED.md) for complete examples.
