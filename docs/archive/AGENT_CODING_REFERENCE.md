# FlutterPOS - Agent's Coding Reference Guide

**Last Updated**: January 22, 2026  
**Version**: 1.0  
**Purpose**: Quick reference for agents implementing features in FlutterPOS

---

## 🎯 Quick Navigation

- [Architecture Principles](#architecture-principles)

- [Feature Implementation Patterns](#feature-implementation-patterns)

- [Malaysian Business Requirements](#malaysian-business-requirements)

- [Code Examples](#code-examples)

- [Common Implementation Checklist](#common-implementation-checklist)

- [Testing Strategy](#testing-strategy)

---

## Architecture Principles

### State Management

- **NO external state management libraries** (Provider, Riverpod, BLoC)

- **Use local `setState()` only**

- **Singletons for global state** (BusinessInfo, DatabaseHelper, etc.)

```dart
// ✅ CORRECT: Local state with setState
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  List<CartItem> cartItems = [];
  
  void addToCart(Product product) {
    setState(() {
      cartItems.add(CartItem(product: product, quantity: 1));
    });
  }
}

// ✅ CORRECT: Global state via singleton
final info = BusinessInfo.instance;
double taxAmount = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;

```

### Database Pattern

**Current**: SQLite via `DatabaseHelper.instance`  
**Future**: Isar migration (models in `lib/models/isar/`)

```dart
// SQLite query pattern
final db = await DatabaseHelper.instance.database;
final products = await db.query('products', where: 'is_active = ?', whereArgs: [1]);

// Isar pattern (when integrated)
final products = await IsarDatabaseService.getAllProducts();

```

### Navigation Pattern

```dart
// Push new screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TargetScreen()),
);

// Named route
Navigator.pushNamed(context, '/pos');

// Pop with data
Navigator.pop(context, result);

```

### Business Info Access Pattern

```dart
// ALWAYS use instance for consistent global config
final info = BusinessInfo.instance;

// Tax calculation
double getTaxAmount(double subtotal) {
  if (!info.isTaxEnabled) return 0.0;
  return subtotal * info.taxRate;  // Stored as decimal (0.10 = 10%)

}

// Update after modification
BusinessInfo.updateInstance(modifiedInfo);

```

---

## Feature Implementation Patterns

### 1. New POS Screen Implementation

**Steps**:

1. Create screen file in `lib/screens/`
2. Extend `StatefulWidget` or `StatelessWidget`
3. Implement responsive layout using `LayoutBuilder`
4. Use local `setState()` for state management
5. Handle business session checking
6. Add to navigation route

**Template**:

```dart
import 'package:flutter/material.dart';
import 'package:extropos/models/business_info_model.dart';

class NewPOSScreen extends StatefulWidget {
  const NewPOSScreen({super.key});

  @override
  State<NewPOSScreen> createState() => _NewPOSScreenState();
}

class _NewPOSScreenState extends State<NewPOSScreen> {
  List<CartItem> cartItems = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    // Load products, categories, etc.
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Screen'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Adaptive layout based on screen size
          return _buildLayout(constraints);
        },
      ),
    );
  }
  
  Widget _buildLayout(BoxConstraints constraints) {
    // Implementation here
    return Container();
  }
}

```

### 2. Responsive Grid Implementation

**CRITICAL**: Always use `LayoutBuilder` with adaptive columns

```dart
LayoutBuilder(
  builder: (context, constraints) {
    int columns = 4;  // default
    if (constraints.maxWidth < 600) columns = 1;
    else if (constraints.maxWidth < 900) columns = 2;
    else if (constraints.maxWidth < 1200) columns = 3;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1.0,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (context, index) => ProductCard(
        product: products[index],
        onTap: () => addToCart(products[index]),
      ),
    );
  },
)

```

### 3. Calculation Methods Pattern

**Always calculate in model/helper, use BusinessInfo for tax**

```dart
// Place in screen class or dedicated helper
double getSubtotal() {
  return cartItems.fold(0.0, 
    (sum, item) => sum + (item.product.price * item.quantity)
  );
}

double getTaxAmount() {
  final info = BusinessInfo.instance;
  if (!info.isTaxEnabled) return 0.0;
  return getSubtotal() * info.taxRate;

}

double getServiceChargeAmount() {
  final info = BusinessInfo.instance;
  if (!info.isServiceChargeEnabled) return 0.0;
  return getSubtotal() * info.serviceChargeRate;

}

double getTotal() {
  return getSubtotal() + getTaxAmount() + getServiceChargeAmount();

}

```

### 4. Dialog/Alert Pattern

**Always make scrollable for responsive design**

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Dialog Title'),
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 400,
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Form fields or content here
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ElevatedButton(onPressed: _onConfirm, child: const Text('Confirm')),
    ],
  ),
);

```

### 5. Error Handling Pattern

```dart
try {
  final result = await someAsyncOperation();
  if (!mounted) return;
  
  setState(() {
    // Update UI
  });
  
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Success!')),
  );
} catch (e) {
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
  print('🔥 Error in operation: $e');
}

```

### 6. User Feedback Pattern

**Use modern Material 3 API**

```dart
// ✅ CORRECT: ScaffoldMessenger
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Item added to cart'),
    duration: const Duration(seconds: 2),
    action: SnackBarAction(label: 'Undo', onPressed: () {}),
  ),
);

// ❌ WRONG: Old ToastHelper (deprecated)
// ToastHelper.showToast(context, 'message');

```

---

## Malaysian Business Requirements

### Tax Calculation

```dart
// GST/SST is configured in BusinessInfo
// Standard rates: 6% or 10%
// Some items may be tax-exempt

double calculatePrice(Product product, double quantity) {
  double subtotal = product.price * quantity;
  
  final info = BusinessInfo.instance;
  double tax = 0.0;
  
  if (info.isTaxEnabled && !product.isTaxExempt) {
    tax = subtotal * info.taxRate;
  }
  
  return subtotal + tax;

}

```

### Payment Methods (Malaysian)

```dart
enum PaymentMethod {
  cash,
  card,
  touchNGo,      // Most popular e-wallet
  grabPay,       // Second popular
  boost,         // Bank Malaysia initiative
  alipay,        // For Chinese tourists
  wechatPay,     // For Chinese tourists
  bankTransfer,  // B2B orders
}

// Split payment support
class SplitPayment {
  PaymentMethod method;
  double amount;
  String? referenceId;  // For e-wallets
}

```

### MyInvois Integration

```dart
// Government e-invoice requirement
// Invoice format: INV-YYYYMMDD-XXXX
// QR code generated for customer receipt
// Automatic submission to MyInvois API

class MyInvoiceService {
  Future<String> submitInvoice(Transaction transaction) async {
    // Generate invoice number
    // Submit to MyInvois
    // Get QR code
    // Return document UUID
  }
}

```

### Offline Support

```dart
// All POS operations must work offline
// Sync queued transactions when back online
// Conflict resolution: last-write-wins

if (isOnline) {
  await syncPendingTransactions();
} else {
  await queueTransaction(transaction);
  showSnackBar('Offline mode - will sync when online');

}

```

---

## Code Examples

### Example 1: Complete Cart Feature

```dart
class CartService {
  List<CartItem> items = [];
  
  void addItem(Product product, int quantity) {
    final existing = items.firstWhereOrNull(
      (item) => item.product.id == product.id
    );
    
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      items.add(CartItem(product: product, quantity: quantity));
    }
  }
  
  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(productId);
      return;
    }
    
    final item = items.firstWhereOrNull(
      (item) => item.product.id == productId
    );
    if (item != null) item.quantity = newQuantity;
  }
  
  void removeItem(String productId) {
    items.removeWhere((item) => item.product.id == productId);
  }
  
  double getSubtotal() {
    return items.fold(0.0, (sum, item) => 
      sum + (item.product.price * item.quantity)
    );
  }
  
  void clear() => items.clear();
}

```

### Example 2: Product Grid with Search

```dart
class ProductGridScreen extends StatefulWidget {
  @override
  State<ProductGridScreen> createState() => _ProductGridScreenState();
}

class _ProductGridScreenState extends State<ProductGridScreen> {
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  String searchQuery = '';
  String selectedCategory = '';
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    // Load from database
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('products', where: 'is_active = ?', whereArgs: [1]);
    
    setState(() {
      allProducts = maps.map((map) => Product.fromMap(map)).toList();
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    filteredProducts = allProducts.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCategory = selectedCategory.isEmpty || product.categoryId == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              int columns = 4;
              if (constraints.maxWidth < 600) columns = 1;
              else if (constraints.maxWidth < 900) columns = 2;
              else if (constraints.maxWidth < 1200) columns = 3;
              
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  childAspectRatio: 0.75,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) => ProductCard(
                  product: filteredProducts[index],
                  onTap: () => _onProductSelected(filteredProducts[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            _applyFilters();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
  
  void _onProductSelected(Product product) {
    // Handle product selection (add to cart, etc.)
  }
}

```

---

## Common Implementation Checklist

### New Feature Implementation

- [ ] Create screen file in `lib/screens/`

- [ ] Add to `lib/main.dart` or appropriate main file

- [ ] Add route in `lib/routes/` if using named routing

- [ ] Implement responsive layout with `LayoutBuilder`

- [ ] Use local `setState()` for state management

- [ ] Handle errors with try-catch and user feedback

- [ ] Add null checks before context usage

- [ ] Test on multiple screen sizes

- [ ] Run `flutter analyze` and fix warnings

- [ ] Write unit tests if business logic involved

- [ ] Update documentation

### Business Logic Implementation

- [ ] Use `BusinessInfo.instance` for global settings

- [ ] Apply tax using `getTaxAmount()` pattern

- [ ] Support offline mode

- [ ] Queue for sync if offline

- [ ] Add activity logging

- [ ] Handle edge cases (empty lists, null values, etc.)

- [ ] Use proper error messages for users

- [ ] Log for debugging with print statements

### UI/UX Implementation

- [ ] Use Material 3 design system

- [ ] Primary color: `Color(0xFF2563EB)`

- [ ] Text overflow protection with `overflow: TextOverflow.ellipsis`

- [ ] Constrained dialogs with `ConstrainedBox` + `SingleChildScrollView`

- [ ] Adaptive layouts for all screen sizes

- [ ] Proper spacing with `SizedBox`

- [ ] Clear visual hierarchy

- [ ] Accessible tap targets (min 48x48dp)

### Database Implementation

- [ ] Use `DatabaseHelper.instance` for SQLite

- [ ] Prepare for Isar migration

- [ ] Add proper indexes for frequently queried fields

- [ ] Implement pagination for large datasets

- [ ] Cache frequently accessed data

- [ ] Clear caches on reset

---

## Testing Strategy

### Unit Tests

```dart
// Test calculations without UI
void main() {
  group('Tax Calculations', () {
    test('Tax calculation with enabled tax', () {
      final info = BusinessInfo(isTaxEnabled: true, taxRate: 0.10);
      final subtotal = 100.0;
      final tax = subtotal * info.taxRate;
      
      expect(tax, 10.0);
    });
    
    test('Tax calculation with disabled tax', () {
      final info = BusinessInfo(isTaxEnabled: false, taxRate: 0.10);
      final subtotal = 100.0;
      final tax = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
      
      expect(tax, 0.0);
    });
  });
}

```

### Integration Tests

```dart
// Test screen interactions
void main() {
  testWidgets('Add item to cart', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    
    // Tap product
    await tester.tap(find.text('Product Name'));
    await tester.pumpAndSettle();
    
    // Verify item added
    expect(find.text('1 item'), findsOneWidget);
  });
}

```

### Manual Testing Checklist

- [ ] Test on phone (Android)

- [ ] Test on tablet (landscape + portrait)

- [ ] Test on desktop (Windows)

- [ ] Test offline mode

- [ ] Test all business modes (Retail, Cafe, Restaurant)

- [ ] Test with and without tax enabled

- [ ] Test with various screen sizes

- [ ] Test keyboard navigation

- [ ] Test with empty data

- [ ] Test error scenarios

---

## Performance Guidelines

### Image Optimization

```dart
// Cache images properly
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  cacheWidth: 300,  // Cache at specific resolution
  cacheHeight: 300,
)

```

### List Optimization

```dart
// Use efficient builders
ListView.builder(  // Not ListView with fixed children
  itemCount: items.length,
  itemBuilder: (context, index) => ItemTile(items[index]),
)

```

### Database Queries

```dart
// Optimize queries
// ❌ WRONG: Load all data
final allProducts = await db.query('products');

// ✅ CORRECT: Filter at database level
final activeProducts = await db.query('products', where: 'is_active = ?', whereArgs: [1]);

```

---

## Debugging Tips

### Enable Debug Logging

```dart
// Use print with emoji prefixes for clarity
print('✅ Success: Item added');
print('⚠️ Warning: Low stock');
print('🔥 Error: Failed to load');
print('🔧 Debug: Variable = $variable');

```

### Use Flutter DevTools

```bash
flutter pub global run devtools

# Open browser to http://localhost:9100

```

### Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| "Bottom overflowed by X pixels" | Use `LayoutBuilder` + adaptive columns, or wrap in `SingleChildScrollView` |

| Null reference exception | Add null checks before accessing properties |
| State not updating | Call `setState()` inside method, not after callback |
| "mounted check failed" | Always check `if (!mounted) return;` in async callbacks |
| Slow grid rendering | Use `ListView.builder` or `GridView.builder`, not fixed children |

---

## File Structure Reference

```
lib/
├── main.dart                          # POS flavor entry point

├── main_kds.dart                      # Kitchen Display System

├── main_backend.dart                  # Backend Management

├── main_keygen.dart                   # License Key Generator

├── models/
│   ├── business_info_model.dart       # Global config singleton

│   ├── business_mode.dart             # Enum: retail/cafe/restaurant

│   ├── cart_item.dart                 # Product + quantity wrapper

│   ├── customer.dart
│   ├── product.dart
│   ├── transaction.dart
│   └── isar/                          # Future Isar models

├── screens/
│   ├── unified_pos_screen.dart        # Main POS router

│   ├── retail_pos_screen_modern.dart  # Retail mode

│   ├── cafe_pos_screen.dart           # Cafe mode

│   ├── table_selection_screen.dart    # Restaurant mode

│   ├── settings_screen.dart           # Settings hub

│   ├── business_info_screen.dart      # Tax/service charge config

│   └── ...                            # Other screens

├── services/
│   ├── database_helper.dart           # SQLite singleton

│   ├── appwrite_sync_service.dart     # Cloud sync

│   ├── business_session_service.dart  # Open/close business

│   ├── shift_service.dart             # Shift management

│   ├── training_mode_service.dart     # Training data

│   └── ...                            # Other services

├── widgets/
│   ├── cart_item_widget.dart          # Reusable cart item

│   ├── product_card.dart              # Reusable product grid card

│   └── ...
└── utils/
    ├── toast_helper.dart              # Notifications (deprecated)

    └── ...

```

---

## Quick Reference: Key Singletons

```dart
// Global configuration
BusinessInfo.instance               // Tax, service charge, mode, currency
BusinessInfo.updateInstance(info)   // Update after changes

// Database
DatabaseHelper.instance.database    // SQLite access

// Services
ShiftService.instance              // Shift management
UserSessionService()               // Current user
TrainingModeService.instance       // Training mode
ResetService.instance              // Reset broadcasting
LockManager.instance               // PIN lock

// Future: Isar
IsarDatabaseService.instance       // When Isar integrated

```

---

## When to Reference This Guide

✅ **Use this guide when**:

- Starting a new feature implementation

- Building responsive UI

- Implementing database queries

- Handling user authentication

- Processing payments

- Calculating taxes/discounts

- Creating dialogs/forms

- Debugging issues

✅ **Also reference**:

- `MALAYSIAN_POS_FEATURES_PLAN.md` - Feature specifications

- `copilot-instructions.md` - Architecture patterns

- `copilot-architecture.md` - Detailed architecture

- `copilot-database.md` - Database patterns

---

**Last Updated**: January 22, 2026  
**Maintained by**: AI Agent for FlutterPOS development
