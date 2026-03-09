# Flutter Architecture - Detailed Reference

Complete guide to three-layer architecture refactoring for FlutterPOS.

## Understanding Three-Layer Architecture

### Layer A: Logic (The Brain)

**Characteristics**:
- Pure Dart functions and classes
- Zero Flutter imports (except tests)
- Single responsibility per class
- Static methods for utilities, instance methods for state
- 100% unit testable
- No side effects (no I/O, no UI)

**Location**: `lib/services/`, `lib/helpers/`, `lib/models/`

**Size**: Keep under 300 lines per file

**Examples**:
```dart
// ✅ CORRECT: Pure logic
class CartCalculationService {
  static double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }
}

// ❌ WRONG: Has Flutter import
import 'package:flutter/material.dart';
class CartService {
  void showSnackBar(String message) { /* ... */ }
}

// ❌ WRONG: Multiple concerns
class CartService {
  void addItem(CartItem item) { /* ... */ }
  void printReceipt() { /* ... */ }
  void updateUI() { /* ... */ }
}
```

### Layer B: Widgets (The Components)

**Characteristics**:
- Reusable, focused UI components
- Accept ALL data via constructor (no service access)
- Accept ALL actions via callbacks
- Stateless when possible, Stateful only when necessary
- No business logic in build()
- Keep build() methods short (< 50 lines)

**Location**: `lib/widgets/`, `lib/widgets/custom/`

**Size**: Keep under 200 lines per file

**Widget Testing**: Test rendering, user interactions, callbacks

**Examples**:
```dart
// ✅ CORRECT: Pure presentation
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final Function() onRemove;
  
  const CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          Text(item.product.name),
          IconButton(
            icon: Icon(Icons.remove),
            onPressed: () => onQuantityChanged(item.quantity - 1),
          ),
          Text('${item.quantity}'),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => onQuantityChanged(item.quantity + 1),
          ),
        ],
      ),
    );
  }
}

// ❌ WRONG: Business logic in widget
class CartItemCard extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final total = item.quantity * item.price; // Calculation in build!
    final taxAmount = total * 0.06; // More calculation!
    
    return Text('Total: RM ${total + taxAmount}');
  }
}

// ❌ WRONG: Service access in widget
class CartItemCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cartService = CartService(); // No!
    cartService.addItem(item);
    
    return Text('Added');
  }
}
```

### Layer C: Screens (The Assembler)

**Characteristics**:
- Orchestrates services (Layer A) and widgets (Layer B)
- Manages screen-level state (loading, navigation)
- Implements navigation logic
- Calls services for data
- Passes data and callbacks to widgets
- Manages StatefulWidget state if needed

**Location**: `lib/screens/`

**Size**: Keep under 300 lines per file (use mixins for additional logic)

**Integration Testing**: Test complete workflows and navigation

**Examples**:
```dart
// ✅ CORRECT: Orchestration
class CartScreen extends StatefulWidget {
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<CartItem> _cartItems = [];
  
  @override
  void initState() {
    super.initState();
    _loadCart();
  }
  
  void _loadCart() {
    // Call Layer A service
    _cartItems = CartService.instance.getItems();
    setState(() {});
  }
  
  void _handleQuantityChange(CartItem item, int newQty) {
    if (newQty <= 0) {
      _removeItem(item);
      return;
    }
    
    // Call service
    CartService.instance.updateQuantity(item.product.id, newQty);
    _loadCart();
  }
  
  void _removeItem(CartItem item) {
    CartService.instance.removeItem(item.product.id);
    _loadCart();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cart (${_cartItems.length})')),
      body: _cartItems.isEmpty
          ? Center(child: Text('Empty'))
          : ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                // Use Layer B widget
                return CartItemCard(
                  item: _cartItems[index],
                  onQuantityChanged: (qty) => 
                    _handleQuantityChange(_cartItems[index], qty),
                  onRemove: () => _removeItem(_cartItems[index]),
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Total: RM ${CartCalculationService.calculateTotal(_cartItems)}',
              ),
            ),
            ElevatedButton(
              onPressed: _cartItems.isEmpty ? null : _checkout,
              child: Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _checkout() {
    // Navigate to next screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(items: _cartItems)),
    );
  }
}

// ❌ WRONG: Mixing layers
class CartScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    // All in one place!
    return ListView.builder(
      itemBuilder: (context, index) => Card(
        child: Row(
          children: [
            Text(cartItems[index].product.name), // Layer B
            Text('${cartItems[index].quantity}'), // Layer B
            // Layer A calculation in widget build
            Text('RM ${(cartItems[index].quantity * cartItems[index].price).toStringAsFixed(2)}'),
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                // Service call in widget callback
                CartService.instance.removeItem(cartItems[index].product.id);
                setState(() {}); // State management scattered
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## Refactoring Large Files (800+ lines)

### Step 1: Analyze
Identify all concerns:
```
800-line CheckoutScreen
  ├─ Tax/discount calculations (100 lines) → Layer A Service
  ├─ Cart item display (150 lines) → Layer B Widget
  ├─ Payment selection UI (120 lines) → Layer B Widget  
  ├─ Receipt preview (100 lines) → Layer B Widget
  ├─ Checkout orchestration (330 lines) → Layer C Screen (refactored to 180 lines)
```

### Step 2: Extract Services (Layer A)

Create focused services:
```dart
// lib/services/checkout_calculation_service.dart
class CheckoutCalculationService {
  static double calculateTax(double subtotal, BusinessInfo info) { /* ... */ }
  static double calculateTotal(List<CartItem> items, BusinessInfo info) { /* ... */ }
  static bool validatePayment(double amount, double tendered) { /* ... */ }
}

// lib/services/receipt_generation_service.dart
class ReceiptGenerationService {
  static Receipt generateReceipt(
    List<CartItem> items,
    PaymentResult payment,
    BusinessInfo info,
  ) { /* ... */ }
}
```

**Test these immediately**:
```dart
void main() {
  group('CheckoutCalculationService', () {
    test('calculates tax correctly', () { /* ... */ });
    test('validates sufficient payment', () { /* ... */ });
  });
}
```

### Step 3: Extract Widgets (Layer B)

Create reusable components:
```dart
// lib/widgets/cart_summary_card.dart
class CartSummaryCard extends StatelessWidget {
  final List<CartItem> items;
  final BusinessInfo info;
  
  const CartSummaryCard({
    required this.items,
    required this.info,
  });
  
  @override
  Widget build(BuildContext context) {
    final subtotal = CartCalculationService.calculateSubtotal(items);
    final tax = CartCalculationService.calculateTax(subtotal, info);
    final total = subtotal + tax;
    
    return Card(
      child: Column(
        children: [
          Text('Subtotal: RM ${subtotal.toStringAsFixed(2)}'),
          Text('Tax: RM ${tax.toStringAsFixed(2)}'),
          Text('Total: RM ${total.toStringAsFixed(2)}'),
        ],
      ),
    );
  }
}

// lib/widgets/payment_method_selector.dart
class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final Function(PaymentMethod) onChanged;
  
  @override
  Widget build(BuildContext context) {
    // Payment method selection UI
  }
}

// lib/widgets/receipt_preview.dart
class ReceiptPreview extends StatelessWidget {
  final Receipt receipt;
  // Display receipt
}
```

### Step 4: Refactor Screen (Layer C)

```dart
// lib/screens/checkout_screen.dart (Now only 180 lines)
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  double _tendered = 0;
  Receipt? _receipt;
  
  @override
  Widget build(BuildContext context) {
    final info = BusinessInfo.instance;
    final total = CartCalculationService.calculateTotal(widget.items, info);
    
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Layer B widgets
            CartSummaryCard(items: widget.items, info: info),
            
            PaymentMethodSelector(
              selected: _selectedMethod,
              onChanged: (method) => setState(() => _selectedMethod = method),
            ),
            
            if (_selectedMethod == PaymentMethod.cash)
              TextField(
                decoration: InputDecoration(labelText: 'Amount Tendered'),
                onChanged: (value) => setState(() => _tendered = double.parse(value)),
              ),
            
            if (_receipt != null)
              ReceiptPreview(receipt: _receipt!),
            
            ElevatedButton(
              onPressed: _validateAndProcess,
              child: Text('Process Payment'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _validateAndProcess() {
    final info = BusinessInfo.instance;
    final total = CartCalculationService.calculateTotal(widget.items, info);
    
    try {
      // Validate using Layer A
      if (!CheckoutCalculationService.validatePayment(total, _tendered)) {
        throw ValidationException('Insufficient payment');
      }
      
      // Process using Layer A
      final paymentResult = PaymentProcessingService.processPayment(
        amount: total,
        tendered: _tendered,
        method: _selectedMethod,
      );
      
      // Generate receipt using Layer A
      final receipt = ReceiptGenerationService.generateReceipt(
        widget.items,
        paymentResult,
        info,
      );
      
      setState(() => _receipt = receipt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment successful')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
```

## Common Refactoring Mistakes

### Mistake 1: Incomplete Extraction
```dart
// ❌ WRONG: Service still has Flutter import
import 'package:flutter/material.dart';

class CartService {
  void addItem(CartItem item) {
    // OK: business logic
  }
  
  void showNotification() { // NO! This is UI
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}

// ✅ CORRECT: Move UI to screen
class CartService {
  void addItem(CartItem item) { /* ... */ }
}

class CartScreen {
  void _handleAddItem(CartItem item) {
    CartService.instance.addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}
```

### Mistake 2: Passing BuildContext to Services
```dart
// ❌ WRONG
class CartService {
  void processPayment(BuildContext context) { /* ... */ }
}

// ✅ CORRECT
class CartService {
  PaymentResult processPayment(double amount) { /* ... */ }
}

class PaymentScreen {
  void _handlePayment() {
    try {
      final result = CartService.instance.processPayment(amount);
      // Handle result in screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(...);
    }
  }
}
```

### Mistake 3: Service Knows About Widgets
```dart
// ❌ WRONG: Service depends on widget implementation
class CartService {
  CartItemCard buildCartItem(CartItem item) { /* ... */ }
}

// ✅ CORRECT: Service returns data, widget builds UI
class CartService {
  List<CartItem> getItems() { /* ... */ }
}

class CartScreen {
  List<CartItem> items = CartService.instance.getItems();
  
  // Screen builds CartItemCard with items
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) => CartItemCard(item: items[index]),
    );
  }
}
```

## Testing Layer Separation

```dart
// Unit test: Layer A logic isolated from UI
void main() {
  group('CartCalculationService', () {
    test('calculates subtotal correctly', () {
      final items = [
        CartItem(product: Product(price: 50), quantity: 2),
      ];
      expect(
        CartCalculationService.calculateSubtotal(items),
        equals(100.0),
      );
    });
  });
}

// Widget test: Layer B component with mocked data
void main() {
  group('CartItemCard', () {
    testWidgets('displays quantity and price', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              item: CartItem(product: Product(name: 'Coffee', price: 5.50), quantity: 2),
              onQuantityChanged: (_) {},
              onRemove: () {},
            ),
          ),
        ),
      );
      
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}

// Integration test: Layer C orchestration
void main() {
  group('CheckoutScreen', () {
    testWidgets('complete checkout flow', (tester) async {
      await tester.pumpWidget(const MyApp());
      
      // User adds item
      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();
      
      // User proceeds to checkout
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();
      
      // Verify totals calculated
      expect(find.text(RegExp(r'RM \d+\.\d{2}')), findsWidgets);
      
      // User processes payment
      await tester.tap(find.text('Pay'));
      await tester.pumpAndSettle();
      
      // Verify receipt shown
      expect(find.byType(ReceiptPreview), findsOneWidget);
    });
  });
}
```

## Enforcement Checklist

Before committing any Dart file:

- [ ] File is under 500 lines
- [ ] Clear single responsibility
- [ ] Layer A has zero Flutter imports
- [ ] Layer B accepts all data via constructor
- [ ] Layer C calls services and assembles widgets
- [ ] No business logic in widget build()
- [ ] No hardcoded values (except constants)
- [ ] Unit tests for all Layer A code
- [ ] Widget tests for Layer B components
- [ ] File name matches primary class (snake_case)
- [ ] Imports organized (dart, package, relative)

---

*This reference should help you refactor large files and understand the three-layer pattern deeply.*
