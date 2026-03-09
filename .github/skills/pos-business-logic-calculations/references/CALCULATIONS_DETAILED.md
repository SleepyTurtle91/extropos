# POS Business Logic - Detailed Reference

Complete guide to implementing accurate POS business logic for FlutterPOS.

## Cart Operations Deep Dive

### Adding Items to Cart

```dart
class CartManagementService {
  final List<CartItem> _items = [];
  
  void addItem(Product product, {int quantity = 1}) {
    // Validation
    if (product.id.isEmpty) throw ValidationException('Invalid product ID');
    if (quantity < 1) throw ValidationException('Quantity must be >= 1');
    if (quantity > 9999) throw ValidationException('Quantity too large');
    
    // Check if already in cart
    final existing = _items.firstWhereOrNull(
      (item) => item.product.id == product.id,
    );
    
    if (existing != null) {
      // Update quantity
      existing.quantity += quantity;
      if (existing.quantity > 9999) existing.quantity = 9999;
    } else {
      // Add new item
      _items.add(CartItem(
        product: product,
        quantity: quantity,
      ));
    }
  }
  
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
}
```

### Removing & Updating

```dart
void removeItem(String productId) {
  if (productId.isEmpty) throw ValidationException('Invalid product ID');
  
  _items.removeWhere((item) => item.product.id == productId);
}

void updateQuantity(String productId, int newQuantity) {
  if (productId.isEmpty) throw ValidationException('Invalid product ID');
  if (newQuantity < 0) throw ValidationException('Quantity cannot be negative');
  
  final item = _items.firstWhereOrNull((i) => i.product.id == productId);
  if (item == null) throw ValidationException('Item not in cart');
  
  if (newQuantity == 0) {
    removeItem(productId);
  } else {
    item.quantity = newQuantity;
    if (item.quantity > 9999) item.quantity = 9999;
  }
}

void clearCart() {
  _items.clear();
}
```

## Advanced Calculation Scenarios

### Scenario 1: Tax Before or After Discount?

In Malaysia (RM currency):
- Most POS systems: Apply discount to subtotal, THEN calculate tax on discounted amount
- Some systems: Calculate tax on original subtotal, apply discount to total

**Standard (Recommended)**:
```dart
Subtotal: RM 100.00
Discount: RM 10.00 (10%)
Subtotal after discount: RM 90.00
Tax: RM 90.00 × 6% = RM 5.40
Total: RM 90.00 + RM 5.40 = RM 95.40

// Code
double subtotal = calculateSubtotal(items); // 100.00
double discountAmount = subtotal * 0.10;   // 10.00
double subtotalAfterDiscount = subtotal - discountAmount; // 90.00
double tax = subtotalAfterDiscount * taxRate; // 5.40
double total = subtotalAfterDiscount + tax; // 95.40
```

**Alternative (Less common)**:
```dart
Subtotal: RM 100.00
Tax: RM 100.00 × 6% = RM 6.00
Subtotal + Tax: RM 106.00
Discount: RM 10.00 (percentage applied to original)
Total: RM 106.00 - RM 10.00 = RM 96.00
```

**Which to use**: Check your BusinessInfo configuration or business requirements.

### Scenario 2: Service Charge on What?

Options:
1. **On subtotal only**: RM 100 → Service: RM 100 × 10% = RM 10
2. **On subtotal + tax**: RM 100 + RM 6 = RM 106 → Service: RM 106 × 10% = RM 10.60
3. **On discounted amount**: RM 90 (after discount) → Service: RM 90 × 10% = RM 9.00

**Standard (Most common)**:
```dart
class CartCalculationService {
  static double calculateServiceCharge(double subtotal, BusinessInfo info) {
    // Service charge on subtotal ONLY, not including tax
    if (!info.isServiceChargeEnabled) return 0.0;
    return subtotal * info.serviceChargeRate;
  }
  
  // Order matters!
  static double calculateTotal(List<CartItem> items, BusinessInfo info) {
    final subtotal = calculateSubtotal(items);
    final tax = calculateTax(subtotal, info);
    final serviceCharge = calculateServiceCharge(subtotal, info);
    return subtotal + tax + serviceCharge;
  }
}
```

### Scenario 3: Rounding Malaysian RM

Malaysian Ringgit uses 5-sen rounding (0.05):
```dart
// Examples
100.01 → 100.00 (down)
100.02 → 100.00 (down)
100.03 → 100.05 (up)
100.04 → 100.05 (up)
100.06 → 100.10 (up)

class RoundingService {
  static double roundToNearestUnit(double amount, {double unit = 0.05}) {
    final rounded = (amount / unit).round() * unit;
    return double.parse(rounded.toStringAsFixed(2));
  }
}

// Usage
final total = 150.73;
final rounded = RoundingService.roundToNearestUnit(total);
// Result: 150.75
```

## Payment Validation Examples

### Sufficient Funds Check

```dart
class PaymentValidationService {
  static bool hasSufficientFunds(double required, double tendered) {
    return tendered >= required;
  }
  
  static double calculateChange(double required, double tendered) {
    if (!hasSufficientFunds(required, tendered)) {
      throw PaymentException('Insufficient payment');
    }
    return tendered - required;
  }
  
  static bool isValidPaymentAmount(double amount) {
    return amount > 0 && amount <= 999999.99; // Max RM 999,999.99
  }
  
  static bool isValidTenderedAmount(double amount) {
    return amount >= 0 && amount <= 999999.99;
  }
}
```

### Split Payment Validation

```dart
class SplitPaymentService {
  static SplitPaymentResult processSplitPayment({
    required double totalAmount,
    required List<PaymentPart> payments,
  }) {
    // Sum all payment parts
    final totalPaid = payments.fold<double>(
      0.0,
      (sum, payment) => sum + payment.amount,
    );
    
    // Check if total matches (within 0.01 RM for rounding)
    if ((totalPaid - totalAmount).abs() > 0.01) {
      throw PaymentException(
        'Payment amounts do not match. '
        'Expected RM ${totalAmount.toStringAsFixed(2)}, '
        'got RM ${totalPaid.toStringAsFixed(2)}',
      );
    }
    
    // Validate each part
    for (final payment in payments) {
      if (payment.amount < 0) {
        throw PaymentException('Payment amount cannot be negative');
      }
      if (payment.amount > totalAmount) {
        throw PaymentException('Payment part exceeds total');
      }
    }
    
    return SplitPaymentResult(
      totalAmount: totalAmount,
      payments: payments,
      timestamp: DateTime.now(),
      success: true,
    );
  }
}

class PaymentPart {
  final PaymentMethod method;
  final double amount;
  final String? reference; // Card last 4, e-wallet ID, etc.
  
  PaymentPart({
    required this.method,
    required this.amount,
    this.reference,
  });
}
```

## Receipt Generation

### Complete Receipt with All Details

```dart
class ReceiptGenerationService {
  static Receipt generateReceipt({
    required List<CartItem> items,
    required PaymentResult payment,
    required BusinessInfo businessInfo,
    required String receiptNumber,
    double? discountApplied,
  }) {
    // Calculate totals
    final subtotal = CartCalculationService.calculateSubtotal(items);
    final calculatedDiscount = discountApplied ?? 0.0;
    final subtotalAfterDiscount = subtotal - calculatedDiscount;
    final tax = CartCalculationService.calculateTax(subtotalAfterDiscount, businessInfo);
    final serviceCharge = CartCalculationService.calculateServiceCharge(
      subtotalAfterDiscount,
      businessInfo,
    );
    final total = subtotalAfterDiscount + tax + serviceCharge;
    
    // Verify totals match payment
    if ((total - payment.amount).abs() > 0.01) {
      throw ReceiptException('Total mismatch: calculated RM ${total.toStringAsFixed(2)}, payment RM ${payment.amount.toStringAsFixed(2)}');
    }
    
    return Receipt(
      receiptNumber: receiptNumber,
      timestamp: DateTime.now(),
      items: items,
      subtotal: subtotal,
      discountAmount: calculatedDiscount,
      subtotalAfterDiscount: subtotalAfterDiscount,
      tax: tax,
      taxRate: businessInfo.isTaxEnabled ? businessInfo.taxRate : 0.0,
      serviceCharge: serviceCharge,
      serviceChargeRate: businessInfo.isServiceChargeEnabled 
        ? businessInfo.serviceChargeRate 
        : 0.0,
      total: total,
      payment: payment,
      change: payment.tendered - total,
      businessName: businessInfo.businessName,
      businessAddress: businessInfo.businessAddress,
      businessPhone: businessInfo.businessPhone,
      businessTaxNumber: businessInfo.businessTaxNumber,
      currencySymbol: businessInfo.currencySymbol,
    );
  }
}

class Receipt {
  final String receiptNumber;
  final DateTime timestamp;
  final List<CartItem> items;
  final double subtotal;
  final double discountAmount;
  final double subtotalAfterDiscount;
  final double tax;
  final double taxRate;
  final double serviceCharge;
  final double serviceChargeRate;
  final double total;
  final PaymentResult payment;
  final double change;
  final String businessName;
  final String businessAddress;
  final String? businessPhone;
  final String? businessTaxNumber;
  final String currencySymbol;
  
  Receipt({
    required this.receiptNumber,
    required this.timestamp,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.subtotalAfterDiscount,
    required this.tax,
    required this.taxRate,
    required this.serviceCharge,
    required this.serviceChargeRate,
    required this.total,
    required this.payment,
    required this.change,
    required this.businessName,
    required this.businessAddress,
    this.businessPhone,
    this.businessTaxNumber,
    required this.currencySymbol,
  });
}
```

## Testing Business Logic

### Comprehensive Test Suite

```dart
void main() {
  group('CartCalculationService', () {
    setUp(() {
      // Common test data
    });
    
    test('calculateSubtotal with single item', () {
      final items = [CartItem(product: Product(price: 50), quantity: 2)];
      expect(CartCalculationService.calculateSubtotal(items), equals(100.0));
    });
    
    test('calculateSubtotal with multiple items', () {
      final items = [
        CartItem(product: Product(price: 50), quantity: 2),
        CartItem(product: Product(price: 30), quantity: 3),
      ];
      expect(CartCalculationService.calculateSubtotal(items), equals(190.0));
    });
    
    test('calculateSubtotal with empty cart', () {
      expect(CartCalculationService.calculateSubtotal([]), equals(0.0));
    });
    
    test('calculateTax when enabled', () {
      final info = BusinessInfo()..isTaxEnabled = true..taxRate = 0.06;
      expect(
        CartCalculationService.calculateTax(100.0, info),
        equals(6.0),
      );
    });
    
    test('calculateTax when disabled', () {
      final info = BusinessInfo()..isTaxEnabled = false;
      expect(
        CartCalculationService.calculateTax(100.0, info),
        equals(0.0),
      );
    });
    
    test('calculateServiceCharge when enabled', () {
      final info = BusinessInfo()
        ..isServiceChargeEnabled = true
        ..serviceChargeRate = 0.10;
      expect(
        CartCalculationService.calculateServiceCharge(100.0, info),
        equals(10.0),
      );
    });
    
    test('calculateTotal includes all components', () {
      final items = [CartItem(product: Product(price: 100), quantity: 1)];
      final info = BusinessInfo()
        ..isTaxEnabled = true
        ..taxRate = 0.06
        ..isServiceChargeEnabled = true
        ..serviceChargeRate = 0.10;
      
      final tax = 100.0 * 0.06; // 6.0
      final service = 100.0 * 0.10; // 10.0
      final expected = 100.0 + tax + service; // 116.0
      
      expect(
        CartCalculationService.calculateTotal(items, info),
        equals(expected),
      );
    });
  });
  
  group('PaymentValidationService', () {
    test('sufficient payment accepted', () {
      final result = PaymentValidationService.hasSufficientFunds(100.0, 150.0);
      expect(result, isTrue);
    });
    
    test('exact payment accepted', () {
      final result = PaymentValidationService.hasSufficientFunds(100.0, 100.0);
      expect(result, isTrue);
    });
    
    test('insufficient payment rejected', () {
      final result = PaymentValidationService.hasSufficientFunds(100.0, 50.0);
      expect(result, isFalse);
    });
    
    test('change calculated correctly', () {
      final change = PaymentValidationService.calculateChange(100.0, 150.0);
      expect(change, equals(50.0));
    });
    
    test('insufficient payment throws exception', () {
      expect(
        () => PaymentValidationService.calculateChange(100.0, 50.0),
        throwsA(isA<PaymentException>()),
      );
    });
  });
  
  group('RoundingService', () {
    test('rounds to nearest 0.05', () {
      expect(RoundingService.roundToNearestUnit(100.01), equals(100.00));
      expect(RoundingService.roundToNearestUnit(100.03), equals(100.05));
      expect(RoundingService.roundToNearestUnit(100.07), equals(100.10));
    });
    
    test('handles exact 0.05 multiples', () {
      expect(RoundingService.roundToNearestUnit(100.00), equals(100.00));
      expect(RoundingService.roundToNearestUnit(100.05), equals(100.05));
      expect(RoundingService.roundToNearestUnit(100.10), equals(100.10));
    });
  });
}
```

## Common Calculation Bugs

### Bug 1: Tax Applied Twice
```dart
// ❌ WRONG
final total = subtotal + (subtotal * taxRate) + (subtotal * serviceTax);
// Tax applied to subtotal AND service charge

// ✅ CORRECT
final subtotalAfterDiscount = subtotal - discount;
final tax = subtotalAfterDiscount * taxRate;
final serviceCharge = subtotalAfterDiscount * serviceChargeRate;
final total = subtotalAfterDiscount + tax + serviceCharge;
```

### Bug 2: Money Precision Loss
```dart
// ❌ WRONG
double total = 0.0;
for (final item in items) {
  total += item.quantity * item.price; // Floating point errors accumulate
}

// ✅ CORRECT
final total = items.fold<double>(
  0.0,
  (sum, item) => sum + (item.quantity * item.price),
);
final rounded = double.parse(total.toStringAsFixed(2)); // Force 2 decimals
```

### Bug 3: Negative Totals After Discount
```dart
// ❌ WRONG
final total = subtotal - discount; // Could be negative!

// ✅ CORRECT
if (discount > subtotal) {
  throw DiscountException('Discount exceeds subtotal');
}
final total = subtotal - discount;
```

---

*Use these patterns and examples as reference for your POS business logic implementation.*
