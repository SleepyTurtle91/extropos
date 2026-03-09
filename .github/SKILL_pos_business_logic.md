# POS Business Logic & Calculations Expertise

**Skill Domain**: Build accurate, maintainable business logic for cart, payments, taxes, discounts, and financial calculations

**When to Invoke**: Implementing cart operations, payment processing, tax/service charge calculations, discount logic, financial reporting

---

## Core Business Logic Areas

### 1. Cart Management (Layer A Service)

**Service**: `lib/services/cart_management_service.dart` (or split services)

**Core Methods**:
```dart
class CartManagementService {
  // ALWAYS use with dependency injection or singleton
  
  void addItem(CartItem item) {
    // Check if item exists, increment quantity if yes
    // Otherwise add new item
  }
  
  void removeItem(String productId) {
    // Remove from cart entirely
  }
  
  void updateQuantity(String productId, int newQuantity) {
    // Validate quantity > 0
    // Update existing item or remove if quantity = 0
  }
  
  void clearCart() {
    // Empty cart after successful transaction
  }
  
  List<CartItem> getCurrentCart() {
    // Return current items for display
  }
  
  int getTotalItems() {
    // Sum of all quantities
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }
}
```

**Key Rules**:
- ✅ Pure logic, no UI side effects
- ✅ Validate all inputs (null checks, quantity bounds)
- ✅ Return immutable results where possible
- ✅ Use constants for limits (min: 0, max: 9999)
- ❌ Never modify UI directly
- ❌ Never perform I/O operations (database writes happen in screen)

### 2. Price Calculations (Layer A Service)

**Service**: `lib/services/cart_calculation_service.dart`

**Core Methods**:
```dart
class CartCalculationService {
  static double calculateSubtotal(List<CartItem> items) {
    // Sum of (quantity × price) for each item
    return items.fold(0.0, (sum, item) => 
      sum + (item.quantity * item.price));
  }
  
  static double calculateTax(double subtotal, BusinessInfo info) {
    if (!info.isTaxEnabled) return 0.0;
    return subtotal * info.taxRate; // taxRate stored as 0.10 = 10%
  }
  
  static double calculateServiceCharge(double subtotal, BusinessInfo info) {
    if (!info.isServiceChargeEnabled) return 0.0;
    return subtotal * info.serviceChargeRate;
  }
  
  static double calculateTotal(List<CartItem> items, BusinessInfo info) {
    final subtotal = calculateSubtotal(items);
    final tax = calculateTax(subtotal, info);
    final serviceCharge = calculateServiceCharge(subtotal, info);
    return subtotal + tax + serviceCharge;
  }
  
  static double roundToNearestUnit(double amount, {double unit = 0.05}) {
    // Malaysian standard: round to nearest 0.05 RM
    return (amount / unit).round() * unit;
  }
}
```

**Critical Rules**:
- ✅ Use `BusinessInfo.instance` for tax/service charge rates
- ✅ Store rates as decimals: 0.10 = 10%, not 10
- ✅ Round final totals to nearest 0.05 (Malaysian standard)
- ✅ Recalculate totals after ANY cart modification
- ✅ Document calculation order with comments
- ❌ Never hardcode tax/service charge values
- ❌ Never perform calculations in widget build()

**Example Calculation Flow**:
```
Items: [{qty: 2, price: 50}, {qty: 1, price: 30}]
  ↓
Subtotal = (2 × 50) + (1 × 30) = 130.00
  ↓
Tax = 130 × 0.06 = 7.80 (from BusinessInfo.taxRate)
  ↓
Service = 130 × 0.10 = 13.00 (from BusinessInfo.serviceChargeRate)
  ↓
Subtotal + Tax + Service = 130 + 7.80 + 13.00 = 150.80
  ↓
Round to 0.05 = 150.80 (already rounded)
  ↓
FINAL TOTAL = 150.80 RM
```

### 3. Discount Application (Layer A Service)

**Service**: `lib/services/discount_service.dart`

**Core Methods**:
```dart
class DiscountService {
  // Loyalty points redemption
  static double calculateLoyaltyDiscount(int points, double redemptionRate) {
    // redemptionRate typically 0.01 = 100 points = 1 RM
    return points * redemptionRate;
  }
  
  // Percentage discount (e.g., 10% off)
  static double calculatePercentageDiscount(double subtotal, double discountPercent) {
    return subtotal * discountPercent;
  }
  
  // Fixed amount discount (e.g., RM 5 off)
  static double applyFixedDiscount(double amount, double discountAmount) {
    return max(0, amount - discountAmount);
  }
  
  // Validate discount (can't exceed subtotal)
  static bool isValidDiscount(double subtotal, double discountAmount) {
    return discountAmount >= 0 && discountAmount <= subtotal;
  }
  
  static double calculateTotalWithDiscount(
    List<CartItem> items,
    double discountAmount,
    BusinessInfo info,
  ) {
    final subtotalAfterDiscount = 
      calculateSubtotal(items) - discountAmount;
    
    final tax = calculateTax(subtotalAfterDiscount, info);
    final serviceCharge = 
      calculateServiceCharge(subtotalAfterDiscount, info);
    
    return subtotalAfterDiscount + tax + serviceCharge;
  }
}
```

**Key Rules**:
- ✅ Always validate discount doesn't exceed subtotal
- ✅ Apply discount BEFORE calculating tax (in most POS systems)
- ✅ Recalculate tax/service after discount applied
- ✅ Support multiple discount types (loyalty, percentage, fixed)
- ✅ Log discount details for audit trail
- ❌ Never apply discount to tax/service charge
- ❌ Never allow negative totals after discount

### 4. Payment Processing (Layer A Service)

**Service**: `lib/services/payment_processing_service.dart`

**Core Methods**:
```dart
class PaymentProcessingService {
  static PaymentResult processPayment({
    required double amount,
    required double tendered,
    required PaymentMethod method,
    required DateTime timestamp,
  }) {
    // Validate payment amount
    if (amount <= 0) {
      throw PaymentException('Invalid amount');
    }
    
    if (tendered < amount) {
      throw PaymentException('Insufficient payment');
    }
    
    final change = tendered - amount;
    
    return PaymentResult(
      amount: amount,
      tendered: tendered,
      change: change,
      method: method,
      timestamp: timestamp,
      success: true,
    );
  }
  
  static SplitPaymentResult processSplitPayment({
    required double totalAmount,
    required List<PaymentPart> payments,
  }) {
    // Validate split payments sum to total
    final totalPaid = 
      payments.fold(0.0, (sum, p) => sum + p.amount);
    
    if ((totalPaid - totalAmount).abs() > 0.01) {
      throw PaymentException('Payment amounts do not match total');
    }
    
    return SplitPaymentResult(
      totalAmount: totalAmount,
      payments: payments,
      timestamp: DateTime.now(),
    );
  }
  
  static double calculateChange(double amount, double tendered) {
    return (tendered - amount).toStringAsFixed(2).parseDouble();
  }
}

class PaymentResult {
  final double amount;
  final double tendered;
  final double change;
  final PaymentMethod method;
  final DateTime timestamp;
  final bool success;
  
  PaymentResult({
    required this.amount,
    required this.tendered,
    required this.change,
    required this.method,
    required this.timestamp,
    required this.success,
  });
}

enum PaymentMethod {
  cash,
  card,
  eWallet,
  cheque,
  creditNote;
}
```

**Key Rules**:
- ✅ Validate sufficient payment before processing
- ✅ Calculate change accurately with rounding
- ✅ Support multiple payment methods
- ✅ Log all payment transactions
- ✅ Handle split payments (multiple methods in one transaction)
- ❌ Never accept payment less than amount due
- ❌ Never process payment without validation
- ❌ Never store sensitive payment card data locally

### 5. BusinessInfo Integration (Global Configuration)

**Critical**: Always use `BusinessInfo.instance` for calculations

```dart
class BusinessInfo {
  static final BusinessInfo instance = BusinessInfo._();
  
  // Tax configuration
  late bool isTaxEnabled;
  late double taxRate; // 0.06 = 6%
  
  // Service charge configuration
  late bool isServiceChargeEnabled;
  late double serviceChargeRate; // 0.10 = 10%
  
  // Display
  late String currencySymbol; // "RM"
  late String businessName;
  late String businessAddress;
  
  // Mode
  late BusinessMode selectedBusinessMode; // retail/cafe/restaurant
}

// CORRECT: Use BusinessInfo in calculations
double getTotalAmount() {
  final info = BusinessInfo.instance;
  const subtotal = 100.0;
  
  final tax = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
  final serviceCharge = info.isServiceChargeEnabled 
    ? subtotal * info.serviceChargeRate 
    : 0.0;
  
  return subtotal + tax + serviceCharge;
}

// WRONG: Hardcode tax/service rates
double getTotalAmount() {
  const subtotal = 100.0;
  const tax = subtotal * 0.06; // ❌ Hardcoded!
  return subtotal + tax;
}
```

### 6. Receipt Generation (Layer A)

**Service**: `lib/services/receipt_generation_service.dart`

**Core Methods**:
```dart
class ReceiptGenerationService {
  static Receipt generateReceipt({
    required List<CartItem> items,
    required PaymentResult payment,
    required BusinessInfo businessInfo,
    required String receiptNumber,
  }) {
    final subtotal = CartCalculationService.calculateSubtotal(items);
    final tax = CartCalculationService.calculateTax(subtotal, businessInfo);
    final serviceCharge = 
      CartCalculationService.calculateServiceCharge(subtotal, businessInfo);
    final total = subtotal + tax + serviceCharge;
    
    return Receipt(
      receiptNumber: receiptNumber,
      timestamp: DateTime.now(),
      items: items,
      subtotal: subtotal,
      tax: tax,
      serviceCharge: serviceCharge,
      total: total,
      payment: payment,
      change: payment.change,
      businessName: businessInfo.businessName,
      businessAddress: businessInfo.businessAddress,
      currencySymbol: businessInfo.currencySymbol,
    );
  }
  
  static String formatReceipt(Receipt receipt) {
    final buffer = StringBuffer();
    
    buffer.writeln(receipt.businessName.padCenter(40));
    buffer.writeln(receipt.businessAddress.padCenter(40));
    buffer.writeln('-' * 40);
    
    for (final item in receipt.items) {
      buffer.writeln(
        '${item.product.name} x${item.quantity} '
        '${receipt.currencySymbol}${(item.quantity * item.price).toStringAsFixed(2)}'
      );
    }
    
    buffer.writeln('-' * 40);
    buffer.writeln('Subtotal: ${receipt.currencySymbol}${receipt.subtotal.toStringAsFixed(2)}');
    if (receipt.tax > 0) {
      buffer.writeln('Tax: ${receipt.currencySymbol}${receipt.tax.toStringAsFixed(2)}');
    }
    if (receipt.serviceCharge > 0) {
      buffer.writeln('Service: ${receipt.currencySymbol}${receipt.serviceCharge.toStringAsFixed(2)}');
    }
    buffer.writeln('-' * 40);
    buffer.writeln('TOTAL: ${receipt.currencySymbol}${receipt.total.toStringAsFixed(2)}');
    buffer.writeln('Payment: ${receipt.payment.method.toString()}');
    buffer.writeln('Change: ${receipt.currencySymbol}${receipt.change.toStringAsFixed(2)}');
    
    return buffer.toString();
  }
}
```

### 7. Validation & Error Handling

**Best Practices**:

```dart
// ✅ CORRECT: Validate before calculating
void applyDiscount(double discountAmount) {
  final subtotal = calculateSubtotal(cartItems);
  
  if (discountAmount < 0) {
    throw ValidationException('Discount cannot be negative');
  }
  
  if (discountAmount > subtotal) {
    throw ValidationException('Discount exceeds subtotal');
  }
  
  // Safe to apply now
  _applyDiscountInternal(discountAmount);
}

// ✅ CORRECT: Error handling in screen (Layer C)
void handleApplyDiscount(double amount) {
  try {
    DiscountService.applyDiscount(amount);
    setState(() { /* update state */ });
  } catch (e) {
    showSnackBar(context, 'Error: ${e.toString()}');
  }
}

// ❌ WRONG: No validation, silent failure
void applyDiscount(double amount) {
  final newTotal = subtotal - amount; // Could be negative!
  // No error handling, no feedback
}
```

### 8. Unit Test Patterns for Business Logic

```dart
// test/services/cart_calculation_service_test.dart

void main() {
  group('CartCalculationService', () {
    test('calculateSubtotal sums item totals', () {
      final items = [
        CartItem(product: Product(price: 50), quantity: 2),
        CartItem(product: Product(price: 30), quantity: 1),
      ];
      
      final result = CartCalculationService.calculateSubtotal(items);
      expect(result, equals(130.0));
    });
    
    test('calculateTax applies rate correctly', () {
      final info = BusinessInfo()
        ..isTaxEnabled = true
        ..taxRate = 0.06;
      
      final tax = CartCalculationService.calculateTax(100.0, info);
      expect(tax, equals(6.0));
    });
    
    test('calculateTax returns 0 when disabled', () {
      final info = BusinessInfo()..isTaxEnabled = false;
      
      final tax = CartCalculationService.calculateTax(100.0, info);
      expect(tax, equals(0.0));
    });
  });
}
```

### 9. Testing Rules for Business Logic

**MANDATORY**:
- ✅ Unit test every calculation method
- ✅ Test edge cases (zero items, negative values, maximum limits)
- ✅ Test with different tax/service rates
- ✅ Test rounding behavior
- ✅ Test validation and error conditions
- ✅ Run business logic tests before every build
- ❌ Never skip tests for "simple" calculations
- ❌ Never assume calculations are "obviously correct"

---

## Quick Reference: When This Skill Applies

✅ **Invoke This Skill For**:
- Implementing cart operations (add/remove/update)
- Tax and service charge calculations
- Discount logic and loyalty points
- Payment processing
- Receipt generation
- Business logic validation
- Calculation accuracy issues
- Building calculation services
- Unit testing business logic
- Rounding and decimal precision

❌ **Don't Use For**:
- UI widget design (use Flutter Architecture skill)
- Database operations (use Database skill)
- Printer integration (use POS Hardware skill)
- Receipt formatting/printing (use POS Hardware skill)

---

## Integration with Your Project

**Existing Services**: Your project already has:
- `lib/services/cart_service.dart` - Cart management
- `lib/services/payment_service.dart` - Payment processing  
- `lib/services/business_info.dart` - BusinessInfo singleton
- `lib/helpers/` - Calculation helpers

**Testing**: 40+ unit tests for all calculation services

**Currency**: All values in RM with 0.05 rounding standard

