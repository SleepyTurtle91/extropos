# FlutterPOS AI Instructions



## Quick Start


- **Version**: 1.0.28+ (March 2026)

- **Architecture**: Multi-flavor Flutter app (POS/KDS/Backend/KeyGen)

- **Data**: SQLite (current), Isar (planned migration)

- **Build**: `./build_flavors.ps1 [flavor] [debug|release]` (Windows) or `./build_flavors.sh` (Linux)

- **Test**: `flutter test` (100+ unit/integration tests)

- **Platform**: Windows desktop primary, Android tablets secondary


## Code Submission & Refactoring Standards


**CRITICAL RULE**: When receiving long or monolithic code (>500 lines), ALWAYS automatically refactor it to follow the three-layer modular architecture BEFORE implementation.

### When to Refactor Submitted Code

**Refactor IMMEDIATELY if**:

- Code file exceeds 500 lines
- Code mixes business logic with UI rendering
- Code contains multiple unrelated concerns in one class
- Code has deeply nested widgets (5+ levels)
- Code directly accesses services/database in widgets
- Code performs calculations in widget build() methods

### Refactoring Process for Monolithic Code

**Step 1: Analyze the Code**

```dart
// ❌ WRONG: User submits 800-line monolithic screen
class ProductManagementScreen extends StatefulWidget { ... }
class _ProductManagementScreenState extends State<ProductManagementScreen> {
  // 800 lines mixing:
  // - Product fetching and database queries
  // - Complex calculations (pricing, tax, discounts)
  // - Entire UI tree (product list, filters, search, pagination)
  // - CSV export/import logic
  // - Receipt generation
}
```

**Step 2: Identify Layers**

- **Layer A (Logic)**: Product calculations, filtering, CSV handling, receipt generation
- **Layer B (Widgets)**: Product list card, search bar, filter selector, pagination controls
- **Layer C (Screen)**: Main orchestration and assembly

**Step 3: Extract and Split**

```
❌ BEFORE (1 file, 800 lines)
lib/screens/product_management_screen.dart

✅ AFTER (Split into 6 focused files)
lib/services/product_filter_service.dart (120 lines)
lib/services/product_calculation_service.dart (100 lines)
lib/services/csv_export_service.dart (90 lines)
lib/widgets/product_list_card.dart (85 lines)
lib/widgets/product_search_bar.dart (60 lines)
lib/widgets/product_filter_section.dart (75 lines)
lib/screens/product_management_screen.dart (200 lines)
```

**Step 4: Communicate the Refactoring**

When refactoring user-submitted code, clearly explain:

1. **What was split** - Show which parts became services, widgets, screens
2. **Why it was split** - Reference the 500-line rule and separation of concerns
3. **How to reassemble** - Show how the screen orchestrates all pieces
4. **Testing approach** - Explain unit tests for services, widget tests for components

### Template Response for Monolithic Code

```
I notice this code submission is [X lines]. According to our architecture rules, 
I'm refactoring it into the three-layer modular pattern:

**Layer A (Logic)**: I've extracted [list services]
- Create these files in lib/services/

**Layer B (Widgets)**: I've extracted [list widgets]
- Create these files in lib/widgets/

**Layer C (Screen)**: The main screen now orchestrates the above
- This file stays in lib/screens/

This follows our 500-line maximum rule and ensures each file has a single responsibility.

[Show file structure and provide code for each file]
```

### Common Refactoring Patterns for User Submissions

| ❌ **Submitted Code Has** | ✅ **Should Be Extracted To** |
| --- | --- |
| Database queries in initState() | Layer A service with dependency injection |
| Complex calculations in build() | Layer A static methods called from Layer C |
| Multiple related widgets in one file | Separate Layer B widget files |
| Event handlers mixed with UI | Layer C handler methods in a mixin |
| Helper methods beyond 500 lines | Separate service or mixin classes |
| Nested widget trees 6+ levels | Extract inner widgets to separate files |
| UI constants hardcoded throughout | Create separate constants file (lib/constants/) |
| Business logic in setState() | Move to Layer A services |
| Multiple screen concerns in one class | Split screen file into logical parts |
| Direct service access in widgets | Pass via constructor parameters only |

### File Size Enforcement for Submitted Code

**Before accepting any code submission**:

- [ ] Count lines in each file (use `wc -l` or editor line count)
- [ ] Any file >500 lines must be refactored
- [ ] Verify layer separation (services don't import Flutter)
- [ ] Verify widgets don't import services directly
- [ ] Confirm screens import both services and widgets

### Example: Refactoring a User-Submitted 650-Line Widget

**User Submits**:

```dart
// User's checkout_screen.dart (650 lines)
class CheckoutScreen extends StatefulWidget { ... }
class _CheckoutScreenState extends State<CheckoutScreen> {
  // 650 lines of:
  // - Tax/discount calculations
  // - Cart item display
  // - Payment UI
  // - Receipt generation
  // - Printer communication
}
```

**Agent Response - Refactored Into**:

```bash
lib/services/checkout_calculation_service.dart (120 lines)
  - calculateTax()
  - calculateDiscount()
  - calculateTotal()
  - validatePayment()

lib/services/receipt_generation_service.dart (100 lines)
  - generateReceipt()
  - formatReceiptData()
  - prepareForPrinting()

lib/widgets/cart_items_section.dart (80 lines)
  - CartItemsList widget
  - CartItemCard widget

lib/widgets/payment_section.dart (95 lines)
  - PaymentMethodSelector
  - PaymentAmountInput
  - ChangeDisplay

lib/widgets/receipt_preview.dart (75 lines)
  - ReceiptPreview widget

lib/screens/checkout_screen.dart (180 lines)
  - Main orchestration
  - State management
  - Navigation
  - Calls to services and widgets
```

### Quality Gates Before Submission

**All code submissions must pass**:

- ✅ No file exceeds 500 lines
- ✅ Layer A (services) have zero Flutter imports
- ✅ Layer B (widgets) accept all data via constructor parameters
- ✅ Layer C (screens) only orchestrate and assemble
- ✅ Unit tests exist for all Layer A code
- ✅ Widget tests exist for Layer B components
- ✅ No business logic in widget build() methods
- ✅ No direct service access from widgets (dependency injection only)
- ✅ Clear file naming (snake_case matching primary class)
- ✅ Documentation comments on public methods


## Critical Architecture Patterns



### 1. Unified POS Screen Architecture (v1.0.25+)


**IMPORTANT**: As of v1.0.25, the application uses `UnifiedPOSScreen` as the main POS entry point, NOT `ModeSelectionScreen`.

**Navigation Flow**:


```
main.dart → LockScreen → UnifiedPOSScreen
                            ├→ RetailPOSScreenModern (if retail mode)
                            ├→ CafePOSScreen (if cafe mode)
                            └→ TableSelectionScreen (if restaurant mode)

```


**Key Details**:

- `UnifiedPOSScreen` (`lib/screens/unified_pos_screen.dart`) routes to mode-specific screens based on `BusinessInfo.instance.selectedBusinessMode`

- Provides unified AppBar with menu for Settings, Reports, User Sign-in, Shift Management, Business Session

- Enforces Business Session checking - blocks POS access if business is closed

- Training Mode overlay displayed at top when `TrainingModeService.instance.isTrainingMode` is true

- Mode switching happens in Settings → Business Mode, not at home screen level


**Three-Layer Access Control**:
 Management (v1.0.25+)
**Three-Layer Access Control**:
1. **Business Session** (`BusinessSessionService`): Open/Close business day (required for all POS operations)

2. **User Session** (`UserSessionService`): Cashier sign-in/sign-out (tracks who is using the POS)

3. **Shift Management** (`ShiftService`): Per-user shift tracking (opening/closing cash, shift reports)

**Enforcement Pattern**:

```dart
// Check business session first
if (!BusinessSessionService().isBusinessOpen) {
  return _showBusinessClosedScreen();
}

// Check shift in initState of POS screens
if (!ShiftService().hasActiveShift) {
  await showDialog(context: context, builder: (_) => StartShiftDialog(...));
}


```

**Critical Services**:

- `BusinessSessionService()`: Singleton, ChangeNotifier for reactive UI

- `ShiftService.instance`: Per-user shift management with database persistence

- `UserSessionService()`: Tracks current cashier, links to shift operations



### 3. BusinessInfo Singleton Pattern

**CRITICAL**: `BusinessInfo.instance` is the global configuration for ALL calculations.


**Access Pattern**:

```dart
// Always read from instance
final info = BusinessInfo.instance;
final taxAmount = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;

// Update pattern (after modifications)
BusinessInfo.updateInstance(modifiedInfo);


```

**Key Properties**:

- `selectedBusinessMode`: Determines which POS screen to show (retail/cafe/restaurant)

- `isTaxEnabled`, `taxRate` (stored as decimal: 0.10 = 10%)

- `isServiceChargeEnabled`, `serviceChargeRate`

- `currencySymbol` (default: "RM")

- Business details: name, address, tax number, phone


### 4. Responsive Design Standard

**REQUIRED**: All grids MUST use `LayoutBuilder` with adaptive columns.

**Pattern**:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    int columns = 4;
    if (constraints.maxWidth < 600) columns = 1;
    else if (constraints.maxWidth < 900) columns = 2;
    else if (constraints.maxWidth < 1200) columns = 3;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
      ),
      // ...
    );
  },
)

```

**Breakpoints**: <600px (mobile), 600-900px (tablet), 900-1200px (desktop), >1200px (large)


### 5. State Management Principle

**NO external state management libraries**. Use local `setState()` only.

**Cart State Example**:

```dart
List<CartItem> cartItems = [];

void addToCart(Product product) {
  setState(() {
    final existing = cartItems.firstWhereOrNull((item) => item.product.id == product.id);
    if (existing != null) {
      existing.quantity++;
    } else {
      cartItems.add(CartItem(product: product, quantity: 1));
    }
  });
}

```


## Critical Workflows



### Build & Release (Windows)

```powershell

# Build single flavor

.\build_flavors.ps1 pos release


# Build all flavors

.\build_flavors.ps1 all release


# Release workflow (MANDATORY)

flutter build apk --release
Copy-Item build/app/outputs/flutter-apk/app-release.apk ~\Desktop\FlutterPOS-v1.0.27-$(Get-Date -Format yyyyMMdd).apk
git tag -a v1.0.27-$(Get-Date -Format yyyyMMdd) -m "Release v1.0.27"
git push origin v1.0.27-$(Get-Date -Format yyyyMMdd)

```


### Database Operations

**Current**: SQLite via `DatabaseHelper.instance` (singleton)
**Planned**: Isar migration (models exist in `lib/models/isar/` but not integrated)

**Pattern**:

```dart
final db = await DatabaseHelper.instance.database;
final products = await db.query('products', where: 'is_active = ?', whereArgs: [1]);

```


### Backend Sync (Appwrite)

**Endpoint**: `https://appwrite.extropos.org/v1`
**Project**: `6940a64500383754a37f`
**Database**: `pos_db` (14 collections, 4 storage buckets)

**Service**: `AppwriteSyncService` (`lib/services/appwrite_sync_service.dart`)

- Methods: `initialize()`, `fullSync()`, `syncProducts()`, `createProduct()`

- Real-time subscriptions via Appwrite Realtime API

- Used in Backend flavor only for remote management


## Common Pitfalls & Solutions



### ❌ Wrong: Fixed crossAxisCount

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4), // Breaks on resize!
)

```


### ✅ Correct: Adaptive columns

```dart
LayoutBuilder(builder: (context, constraints) {
  final columns = constraints.maxWidth < 600 ? 1 : 4;
  return GridView.builder(/* ... */);

})

```


### ❌ Wrong: Hardcoded tax calculation

```dart
double total = subtotal + (subtotal * 0.10); // Ignores BusinessInfo settings!

```


### ✅ Correct: Use BusinessInfo

```dart
double getTaxAmount() {
  final info = BusinessInfo.instance;
  return info.isTaxEnabled ? getSubtotal() * info.taxRate : 0.0;

}

```


### ❌ Wrong: Direct POS access without session check

```dart
// Navigating directly to RetailPOSScreenModern
Navigator.push(context, MaterialPageRoute(builder: (_) => RetailPOSScreenModern()));

```


### ✅ Correct: Use UnifiedPOSScreen (handles session checks)

```dart
// Navigate to UnifiedPOSScreen - it will route to correct mode

Navigator.pushNamed(context, '/pos');

```


## Refactor Rules: Three-Layer Architecture


The FlutterPOS codebase follows a strict architectural pattern separating concerns into three distinct layers:


### Layer A: The Logic (The "Brain")


**Purpose**: Contains pure business logic, calculations, and state management without any UI dependencies.

**Characteristics**:

- Pure Dart classes and functions (no Flutter imports)
- No widget dependencies, no BuildContext
- Single responsibility: calculations, validations, transformations
- Reusable across all contexts (unit testable)
- Services, models, helpers, and utility functions

**Location**: `lib/services/`, `lib/models/`, `lib/helpers/`, `lib/utils/`

**Examples**:

- `CartCalculationService`: Computes subtotal, tax, service charge (never touches UI)
- `PaymentProcessingLogic`: Validates payment amounts, calculates change
- `BusinessInfo`: Singleton configuration store with calculation helpers
- `DatabaseHelper`: Direct database operations without UI concerns

**Implementation Pattern**:

```dart
// ✅ CORRECT: Pure logic with no UI dependencies
class CartCalculationService {
  static double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }
  
  static double calculateTax(double subtotal, bool taxEnabled, double taxRate) {
    return taxEnabled ? subtotal * taxRate : 0.0;
  }
  
  static double calculateTotal(List<CartItem> items, BusinessInfo info) {
    final subtotal = calculateSubtotal(items);
    final tax = calculateTax(subtotal, info.isTaxEnabled, info.taxRate);
    return subtotal + tax;
  }
}
```

**DO's**:

- ✅ Import only dart:* and model packages
- ✅ Use pure functions when possible
- ✅ Create testable, isolated methods
- ✅ Document calculation logic with comments
- ✅ Throw clear exceptions for validation errors

**DON'Ts**:

- ❌ Import Flutter packages (flutter/material.dart, flutter/widgets.dart)
- ❌ Accept BuildContext as parameters
- ❌ Use StatefulWidget or StatelessWidget
- ❌ Mix UI rendering with business logic
- ❌ Use print() for logging (use structured logging if needed)


### Layer B: The Specialized Widget (The "Components")


**Purpose**: Self-contained, reusable UI components that consume logic layer services and display data.

**Characteristics**:

- Stateless or stateful widgets focused on presentation
- Accept data and callbacks as constructor parameters
- No business logic inside widgets (delegate to Layer A)
- Testable through widget tests
- Highly reusable across screens
- Single widget responsibility

**Location**: `lib/widgets/`, `lib/widgets/custom/`

**Examples**:

- `PriceDisplayWidget`: Shows total with formatting, reads from passed values
- `CartItemCard`: Card widget for individual cart items with +/- buttons
- `PaymentMethodSelector`: Payment method selection with radio buttons
- `TableStatusIndicator`: Visual table status display (available/occupied/reserved)

**Implementation Pattern**:

```dart
// ✅ CORRECT: Specialized widget with no embedded business logic
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final Function() onRemove;
  final BusinessInfo businessInfo;
  
  const CartItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.businessInfo,
  });
  
  @override
  Widget build(BuildContext context) {
    // Display only, all logic passed in
    final itemTotal = item.quantity * item.price;
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Text(item.product.name),
            Row(
              children: [
                IconButton(icon: Icon(Icons.remove), onPressed: () => onQuantityChanged(item.quantity - 1)),
                Text('${item.quantity}'),
                IconButton(icon: Icon(Icons.add), onPressed: () => onQuantityChanged(item.quantity + 1)),
                Spacer(),
                Text('${businessInfo.currencySymbol}${itemTotal.toStringAsFixed(2)}'),
                IconButton(icon: Icon(Icons.delete), onPressed: onRemove),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

**DO's**:

- ✅ Accept all data via constructor parameters
- ✅ Use callbacks for user interactions
- ✅ Focus on rendering and presentation
- ✅ Keep widget trees shallow (<10 lines of build())
- ✅ Extract complex builds into smaller widgets
- ✅ Write widget tests for UI behavior

**DON'Ts**:

- ❌ Perform calculations inside build()
- ❌ Call services directly (should be passed in)
- ❌ Use StatefulWidget without good reason
- ❌ Put business logic in setState()
- ❌ Access BusinessInfo.instance directly (pass via constructor)
- ❌ Create side effects in build()


### Layer C: The Screen (The "Assembler")


**Purpose**: Orchestrates the application: imports services (Layer A), assembles widgets (Layer B), and manages user flows.

**Characteristics**:

- Controls state composition and data flow
- Imports both logic services and specialized widgets
- Routes user input to appropriate handlers
- Manages screen-level state (navigation, dialogs, loading)
- Single responsibility: coordination, not implementation

**Location**: `lib/screens/`

**Examples**:

- `RetailPOSScreenModern`: Assembles product grid, cart, payment flow
- `CafePOSScreen`: Orchestrates cafe-specific widgets
- `RestaurantTableScreen`: Manages table selection and order flow

**Implementation Pattern**:

```dart
// ✅ CORRECT: Screen orchestrates logic and components
class CartScreenModern extends StatefulWidget {
  const CartScreenModern({Key? key}) : super(key: key);

  @override
  State<CartScreenModern> createState() => _CartScreenModernState();
}

class _CartScreenModernState extends State<CartScreenModern> {
  late List<CartItem> cartItems = [];
  
  @override
  void initState() {
    super.initState();
    _loadCart();
  }
  
  void _loadCart() {
    // Call Layer A service
    cartItems = CartService.instance.getCurrentCart();
    setState(() {});
  }
  
  void _handleQuantityChange(CartItem item, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(item);
      return;
    }
    // Delegate to Layer A
    CartService.instance.updateQuantity(item.product.id, newQuantity);
    _loadCart();
  }
  
  void _removeItem(CartItem item) {
    CartService.instance.removeItem(item.product.id);
    _loadCart();
  }
  
  void _checkout() async {
    // Perform Layer A calculations
    final total = CartCalculationService.calculateTotal(
      cartItems,
      BusinessInfo.instance,
    );
    
    // Navigate to payment, passing only what's needed (Layer B)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          items: cartItems,
          total: total,
          onPaymentComplete: _handlePaymentComplete,
        ),
      ),
    );
  }
  
  void _handlePaymentComplete() {
    CartService.instance.clearCart();
    _loadCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction complete')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Layer C: Assemble Layer B components
    return Scaffold(
      appBar: AppBar(title: Text('Cart')),
      body: cartItems.isEmpty
          ? Center(child: Text('Cart is empty'))
          : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                // Pass to Layer B widget with callbacks to this Layer C
                return CartItemCard(
                  item: cartItems[index],
                  onQuantityChanged: (qty) => _handleQuantityChange(cartItems[index], qty),
                  onRemove: () => _removeItem(cartItems[index]),
                  businessInfo: BusinessInfo.instance,
                );
              },
            ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Layer B: Price display widget
              PriceDisplayWidget(
                items: cartItems,
                businessInfo: BusinessInfo.instance,
              ),
              ElevatedButton(
                onPressed: cartItems.isEmpty ? null : _checkout,
                child: Text('Proceed to Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**DO's**:

- ✅ Import services and depend on Layer A
- ✅ Import widgets and assemble them (Layer B)
- ✅ Handle navigation and routing
- ✅ Manage screen-level state (loading, errors)
- ✅ Pass data down to widgets via constructor parameters
- ✅ Respond to widget callbacks and update accordingly
- ✅ Test screen flows with integration tests

**DON'Ts**:

- ❌ Perform calculations directly (use Layer A)
- ❌ Create custom UI elements (use Layer B widgets)
- ❌ Mix business logic with orchestration
- ❌ Make calculations conditional in build()
- ❌ Bypass services and access databases directly
- ❌ Create unmaintainable nested widget trees


### Refactoring Checklist


When refactoring code to follow three-layer architecture:

**Layer A (Logic) Extraction**:

- [ ] Identify all calculations, validations, and transformations
- [ ] Extract into pure Dart classes/functions with no Flutter imports
- [ ] Write unit tests for all logic functions
- [ ] Create service singleton if manages stateful data
- [ ] Document calculation formulas and edge cases
- [ ] Ensure all BusinessInfo access is centralized

**Layer B (Widget) Extraction**:

- [ ] Identify reusable UI patterns
- [ ] Extract into self-contained, state-less-where-possible widgets
- [ ] All data must come via constructor parameters
- [ ] All actions must go via callbacks
- [ ] Write widget tests for rendering and interactions
- [ ] No StatefulWidget unless absolutely necessary
- [ ] No service injection or BuildContext dependency climbing

**Layer C (Screen) Refactoring**:

- [ ] Remove all business logic (move to Layer A)
- [ ] Remove custom UI elements (replace with Layer B widgets)
- [ ] Screen solely orchestrates: imports services, assembles widgets
- [ ] All data flows clearly: services → setState → widgets
- [ ] All callbacks clearly wired: widgets → handler methods → services
- [ ] Navigation centralized in screen
- [ ] State management simple (lists, bools, enums only)

**Benefits of Three-Layer Separation**:

- **Testability**: Layer A can be 100% unit tested
- **Reusability**: Layer B widgets work in any Layer C
- **Maintainability**: Changes in one layer don't cascade
- **Readability**: Clear responsibility and data flow
- **Scalability**: Easy to add new features without architecture decay


### Adding New Code: Three-Layer Pattern Guide


**When implementing any new feature, ALWAYS follow this workflow**:


#### Step 1: Identify What You're Building

Ask yourself:
- Is this a **calculation, validation, or data operation**? → Layer A (Logic)
- Is this a **reusable visual component**? → Layer B (Widget)
- Is this a **screen or orchestration**? → Layer C (Screen)

Most new features require **all three layers** working together.


#### Step 2: Start with Layer A (The Logic)

**ALWAYS implement business logic first**, before any UI.

**Process**:

1. Create a pure Dart service/helper in `lib/services/`, `lib/helpers/`, or `lib/models/`
2. Import ONLY `dart:*` packages and model files
3. NO Flutter imports
4. Write calculation/validation methods as static functions or service methods
5. Add comprehensive comments explaining formulas and edge cases
6. Write unit tests for every method in `test/`

**Example - New Feature: Loyalty Points Calculation**:

```dart
// lib/services/loyalty_points_service.dart
// ✅ CORRECT: Pure logic layer with no UI dependencies

class LoyaltyPointsService {
  /// Calculate points earned based on transaction amount
  /// Points rate: 1 point per RM spent
  static int calculatePointsEarned(double amount) {
    return (amount).toInt(); // 1 RM = 1 point
  }
  
  /// Calculate discount from redeeming points
  /// Redemption rate: 100 points = RM 1
  static double calculatePointsDiscount(int points) {
    return points / 100;
  }
  
  /// Validate if customer has enough points
  static bool hasEnoughPoints(int customerPoints, int requiredPoints) {
    return customerPoints >= requiredPoints;
  }
}
```

**Test file** (`test/services/loyalty_points_service_test.dart`):

```dart
void main() {
  group('LoyaltyPointsService', () {
    test('calculatePointsEarned should return 100 for RM 100', () {
      final points = LoyaltyPointsService.calculatePointsEarned(100.0);
      expect(points, equals(100));
    });
    
    test('calculatePointsDiscount should return RM 1 for 100 points', () {
      final discount = LoyaltyPointsService.calculatePointsDiscount(100);
      expect(discount, equals(1.0));
    });
  });
}
```

**Checklist for Layer A**:

- [ ] No Flutter imports
- [ ] All methods are testable (pure functions preferred)
- [ ] Clear method names and documentation
- [ ] Edge cases handled (null, empty, negative values)
- [ ] Unit tests written and passing
- [ ] Service registered as singleton if needed (use `late static final instance`)


#### Step 3: Build Layer B (The Widgets)

**After logic is complete**, create reusable UI components.

**Process**:

1. Create widget in `lib/widgets/` or `lib/widgets/custom/`
2. Accept ALL data via constructor parameters
3. Accept ALL actions via callbacks
4. Focus purely on rendering
5. No service imports (data comes via parameters)
6. Write widget tests

**Example - New Widget: Loyalty Points Display**:

```dart
// lib/widgets/loyalty_points_card.dart
// ✅ CORRECT: Pure presentation with no business logic

class LoyaltyPointsCard extends StatelessWidget {
  final int currentPoints;
  final int pointsEarned;
  final Function(int) onRedeemPressed;
  final bool canRedeem;
  
  const LoyaltyPointsCard({
    required this.currentPoints,
    required this.pointsEarned,
    required this.onRedeemPressed,
    required this.canRedeem,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Current Points: $currentPoints',
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(height: 8),
            Text('Earned this transaction: +$pointsEarned',
              style: TextStyle(color: Colors.green),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: canRedeem ? () => onRedeemPressed(currentPoints) : null,
              child: Text('Redeem Points'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Checklist for Layer B**:

- [ ] All data comes via constructor parameters
- [ ] All actions are callbacks (Function parameters)
- [ ] No service imports
- [ ] No calculations in build()
- [ ] Widget is reusable (not tied to one screen)
- [ ] Widget tests written
- [ ] Clear parameter names and documentation


#### Step 4: Assemble in Layer C (The Screen)

**Finally**, wire everything together in a screen.

**Process**:

1. Create/update screen in `lib/screens/`
2. Import Layer A services
3. Import Layer B widgets
4. Manage screen-level state (lists, loading flags)
5. Call services for data
6. Pass data and callbacks to widgets
7. Write integration tests

**Example - Integrating into Checkout Screen**:

```dart
// lib/screens/checkout_screen.dart
// ✅ CORRECT: Layer C orchestrates Layer A and Layer B

class CheckoutScreenModern extends StatefulWidget {
  const CheckoutScreenModern({Key? key}) : super(key: key);

  @override
  State<CheckoutScreenModern> createState() => _CheckoutScreenModernState();
}

class _CheckoutScreenModernState extends State<CheckoutScreenModern> {
  late int customerLoyaltyPoints = 0;
  late int pointsEarned = 0;
  bool isRedeeming = false;
  
  @override
  void initState() {
    super.initState();
    _loadLoyaltyData();
  }
  
  void _loadLoyaltyData() {
    // Load from database or service (Layer A)
    customerLoyaltyPoints = 500; // Example: fetch from DB
    
    // Calculate earned points using Layer A service
    final cartTotal = _getCartTotal(); // Get from cart
    pointsEarned = LoyaltyPointsService.calculatePointsEarned(cartTotal);
    
    setState(() {});
  }
  
  void _handleRedeemPoints(int points) {
    // Use Layer A for validation and calculation
    if (!LoyaltyPointsService.hasEnoughPoints(customerLoyaltyPoints, points)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Insufficient points')),
      );
      return;
    }
    
    final discount = LoyaltyPointsService.calculatePointsDiscount(points);
    
    // Apply discount to cart
    _applyLoyaltyDiscount(discount);
    
    setState(() { isRedeeming = true; });
  }
  
  void _applyLoyaltyDiscount(double discount) {
    // Layer A: Calculate new total
    final currentTotal = _getCartTotal();
    final newTotal = currentTotal - discount;
    
    // Update cart with discount
    _updateCartWithDiscount(discount);
  }
  
  double _getCartTotal() => 150.0; // Simplified
  
  void _updateCartWithDiscount(double discount) {
    // Update cart state
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: ListView(
        children: [
          // Layer B: Reusable loyalty points widget
          LoyaltyPointsCard(
            currentPoints: customerLoyaltyPoints,
            pointsEarned: pointsEarned,
            onRedeemPressed: _handleRedeemPoints,
            canRedeem: pointsEarned > 0,
          ),
          // ... other widgets
        ],
      ),
    );
  }
}
```

**Checklist for Layer C**:

- [ ] All business logic delegated to Layer A services
- [ ] All UI elements are Layer B widgets
- [ ] Screen imports services and widgets only
- [ ] State is simple (lists, flags, enums)
- [ ] Navigation and routing handled here
- [ ] Callbacks properly wire to handler methods
- [ ] Integration tests written


#### Complete Feature Development Workflow

Here's the order to follow when building ANY new feature:

1. **Define the feature**: What calculation/data operation is needed?
2. **Layer A - Logic**: Write pure Dart services with unit tests
3. **Layer B - Widgets**: Create reusable components with widget tests
4. **Layer C - Screens**: Wire components together with integration tests
5. **Integration**: Add to appropriate screens
6. **E2E Testing**: Test complete user flow

**Example Timeline for Loyalty Points Feature**:

- ✅ Create `LoyaltyPointsService` with unit tests (30 min)
- ✅ Create `LoyaltyPointsCard` widget with widget tests (20 min)
- ✅ Integrate into `CheckoutScreenModern` (15 min)
- ✅ Test loyalty flow end-to-end (15 min)

**Total: 80 minutes of focused, testable work**


#### Common Mistakes to Avoid When Adding New Code

| ❌ **WRONG** | ✅ **CORRECT** |
| --- | --- |
| Put calculation logic directly in widget build() | Create Layer A service, call from Layer C |
| Pass `DatabaseHelper` to widgets | Fetch data in screen, pass only values to widgets |
| Create `initState()` in widgets | Use callbacks and constructor parameters |
| Access `BusinessInfo.instance` in widgets | Pass via constructor parameter |
| Mix multiple features in one widget | Create single-responsibility widgets |
| Skip unit tests for Layer A | Write tests for ALL Layer A code first |
| Hardcode values in calculations | Use `BusinessInfo` or parameters |
| Create god objects in screens | Distribute responsibility across layers |


### Dart File Size Guidelines: The 500-Line Rule


**MANDATORY**: All Dart files (`.dart`) MUST NOT exceed **500 lines of code**. This is a hard requirement for code maintainability.

**Why 500 Lines?**

- Easier code reviews and understanding
- Reduced cognitive complexity
- Faster navigation and edits
- Better IDE performance
- Clear separation of concerns
- Simpler git diffs and conflict resolution

**When to Split a File**:

**IMMEDIATELY split when**:

- File exceeds 500 lines
- Widget tree becomes complex (nested beyond 5 levels)
- Multiple unrelated concerns exist in one file
- File has more than 3-5 public methods/classes
- Screen file handles both state management and complex UI rendering


#### File Separation Strategy


**For Layer A (Logic) - Services**:

```
❌ WRONG: Single massive service file
lib/services/cart_service.dart (800 lines)
  - Add to cart
  - Remove from cart
  - Calculate totals
  - Apply discounts
  - Process payments
  - Generate receipts
  - Handle refunds

✅ CORRECT: Separated by responsibility
lib/services/cart_management_service.dart (150 lines)
  - Add to cart
  - Remove from cart
  - Update quantities

lib/services/cart_calculation_service.dart (180 lines)
  - Calculate subtotal
  - Calculate tax
  - Calculate service charge
  - Calculate totals

lib/services/cart_discount_service.dart (120 lines)
  - Apply loyalty discount
  - Apply promotional discount
  - Calculate discount amount

lib/services/payment_processing_service.dart (200 lines)
  - Process payment
  - Handle refunds
  - Generate receipts
```

**For Layer B (Widgets) - Custom Components**:

```
❌ WRONG: Monolithic widget file
lib/widgets/checkout_widget.dart (750 lines)
  - Build entire checkout UI
  - Cart items display
  - Payment methods
  - Discount selection
  - Receipt preview
  - Receipt printing

✅ CORRECT: Separated by component
lib/widgets/cart_items_section.dart (120 lines)
  - Display cart items list

lib/widgets/cart_item_card.dart (95 lines)
  - Individual item with +/- buttons

lib/widgets/payment_methods_section.dart (110 lines)
  - Payment method selection

lib/widgets/discount_selector.dart (100 lines)
  - Apply discount selection

lib/widgets/order_summary_card.dart (85 lines)
  - Display totals, tax, service charge

lib/widgets/receipt_preview_section.dart (140 lines)
  - Show receipt preview
```

**For Layer C (Screens) - Screen Logic**:

```
❌ WRONG: All screen logic in one file
lib/screens/checkout_screen.dart (920 lines)
  - Build complete UI
  - Cart management
  - Payment processing
  - Receipt handling
  - Settings integration
  - Error handling

✅ CORRECT: Separated by responsibility
lib/screens/checkout_screen.dart (250 lines)
  - Main screen orchestration
  - State management
  - Widget assembly

lib/screens/checkout_screen_logic.dart (180 lines)
  - Business logic methods
  - Service calls
  - Complex calculations

lib/screens/checkout_dialogs.dart (150 lines)
  - Discount dialogs
  - Payment dialogs
  - Confirmation dialogs

lib/screens/checkout_handlers.dart (120 lines)
  - Event handlers
  - Navigation callbacks
  - State update methods
```


#### File Splitting Best Practices


**1. Screens - Split by Responsibility**:

```dart
// lib/screens/checkout_screen.dart (Main orchestration)
class CheckoutScreen extends StatefulWidget { ... }
class _CheckoutScreenState extends State<CheckoutScreen> {
  @override
  Widget build(BuildContext context) {
    // Assemble components
  }
}

// lib/screens/checkout_screen_logic.dart (Business logic)
mixin CheckoutScreenLogic {
  void _processPayment() { ... }
  void _applyDiscount() { ... }
}

// lib/screens/checkout_screens_dialogs.dart (Dialog widgets)
class PaymentMethodDialog extends StatelessWidget { ... }
class DiscountDialog extends StatelessWidget { ... }

// lib/screens/checkout_screen_handlers.dart (Event handlers)
mixin CheckoutScreenHandlers {
  void _handlePaymentComplete() { ... }
  void _handleCartUpdate() { ... }
}
```

**2. Services - Split by Feature**:

```dart
// lib/services/cart_management_service.dart
class CartManagementService {
  void addItem(Product product) { ... }
  void removeItem(String productId) { ... }
}

// lib/services/cart_calculation_service.dart
class CartCalculationService {
  static double calculateTotal(List<CartItem> items) { ... }
  static double calculateTax(double subtotal) { ... }
}

// lib/services/cart_discount_service.dart
class CartDiscountService {
  double applyDiscount(List<CartItem> items) { ... }
}
```

**3. Widgets - Split by Component**:

```dart
// lib/widgets/cart_item_card.dart
class CartItemCard extends StatelessWidget {
  // Single item display with controls
}

// lib/widgets/cart_total_section.dart
class CartTotalSection extends StatelessWidget {
  // Total price, tax, service charge
}

// lib/widgets/payment_method_selector.dart
class PaymentMethodSelector extends StatelessWidget {
  // Payment method selection UI
}
```


#### How to Refactor Large Files (500+ Lines)


**Step 1: Identify Breaking Points**

```dart
// Read your file and mark logical sections
class MyLargeScreen extends StatefulWidget { ... } // Lines 1-50

class _MyLargeScreenState extends State<MyLargeScreen> {
  // *** BREAK 1: State initialization ***
  @override
  void initState() { ... } // Lines 51-100
  
  // *** BREAK 2: Data loading ***
  void _loadData() { ... } // Lines 101-200
  
  // *** BREAK 3: State updates ***
  void _handleUserAction() { ... } // Lines 201-300
  
  // *** BREAK 4: Complex widget tree ***
  @override
  Widget build(BuildContext context) { ... } // Lines 301-500
  
  // *** BREAK 5: Helper widgets ***
  Widget _buildCartSection() { ... } // Lines 501-700
  
  Widget _buildPaymentSection() { ... } // Lines 701-900
}
```

**Step 2: Extract to Separate Files**

Create files for each logical section:

```dart
// lib/screens/my_screen.dart (Main screen - 150 lines)
class MyLargeScreen extends StatefulWidget { ... }

// lib/screens/my_screen_logic.dart (Business logic - 200 lines)
mixin MyScreenLogic {
  void _loadData() { ... }
  void _handleUserAction() { ... }
}

// lib/widgets/my_screen_cart_section.dart (Cart UI - 150 lines)
class MyScreenCartSection extends StatelessWidget { ... }

// lib/widgets/my_screen_payment_section.dart (Payment UI - 180 lines)
class MyScreenPaymentSection extends StatelessWidget { ... }
```

**Step 3: Wire Components Together**

```dart
// lib/screens/my_screen.dart
class _MyLargeScreenState extends State<MyLargeScreen> 
    with MyScreenLogic {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          MyScreenCartSection(
            items: cartItems,
            onUpdate: _handleCartUpdate,
          ),
          MyScreenPaymentSection(
            total: cartTotal,
            onPayment: _handlePayment,
          ),
        ],
      ),
    );
  }
}
```


#### File Organization Checklist


**Before Committing Any Dart File**:

- [ ] File is under 500 lines
- [ ] File has single primary responsibility
- [ ] Related code is grouped logically
- [ ] No duplicated code between files
- [ ] Public methods documented with comments
- [ ] Private methods have clear names (`_methodName`)
- [ ] Imports are organized (dart, package, relative)
- [ ] No unused imports
- [ ] File name matches primary class name (snake_case)

**When Creating New Features**:

- [ ] Plan file structure before coding
- [ ] Separate Layer A, B, C into different files
- [ ] Estimate line count for each component
- [ ] Create multiple small files rather than one large file
- [ ] Document file purposes in comments


#### Common File Size Anti-Patterns


| ❌ **ANTI-PATTERN** | ❌ **SYMPTOM** | ✅ **SOLUTION** |
| --- | --- | --- |
| **God File** | 1000+ lines, multiple classes | Split by layer (services, widgets, screens) |
| **Kitchen Sink Widget** | Widget handles UI + logic + database | Separate into Layer B widget + Layer A service |
| **Tangled Screen** | Screen with 10+ helper methods | Extract to mixins or separate logic files |
| **Monolithic Service** | Service does everything (cart, payment, tax) | Create separate services by domain |
| **Nested Widgets** | 8+ levels of nested widgets | Extract to separate widget files |
| **Mixed Concerns** | UI drawing + calculations in one method | Move logic to Layer A, keep widget pure |


## POS App Perfection Strategies



### 1. Business Mode Implementation Strategy


**Objective**: Ensure seamless operation across Retail, Cafe, and Restaurant modes with distinct UX patterns.

**Key Details for Agentic**:


- **Mode Detection**: Always check `BusinessMode` enum values (retail, cafe, restaurant) to determine workflow

- **Conditional UI**: Use `if (businessMode == BusinessMode.retail)` blocks for mode-specific features

- **Data Persistence**: Restaurant mode requires table-based cart persistence; others use session-based carts

- **Navigation Flow**: Implement `UnifiedPOSScreen` as router with conditional rendering

- **Testing**: Create separate test scenarios for each mode's unique workflows

**Implementation Steps**:

1. Define mode-specific constants and helper methods
2. Implement conditional widget rendering in POS screens
3. Add mode-specific validation logic
4. Test mode switching and data isolation


### 2. Cart Management Strategy


**Objective**: Robust cart operations with quantity adjustments, item management, and real-time calculations.



- **State Management**: Use `List<CartItem>` with `setState()` for immediate UI updates

- **Quantity Controls**: Implement +/- buttons with validation (min 0, max reasonable limits)

- **Price Calculations**: Always recalculate totals after any cart modification

- **Item Persistence**: For restaurant mode, persist cart in `RestaurantTable.orders`

- **Undo/Redo**: Consider implementing cart state snapshots for recovery

**Implementation Steps**:

**Implementation Steps**:
1. Create `CartItem` model with immutable `Product` reference
2. Implement add/remove/update methods with validation
3. Add real-time subtotal/tax/total calculations
4. Handle cart clearing after successful transactions
5. Test edge cases (negative quantities, large orders)


### 3. Payment Processing Strategy


**Objective**: Secure, flexible payment handling with multiple methods and split payments.

**Key Details for Agentic**:


- **Payment Methods**: Support cash, card, e-wallet with extensible enum

- **Split Payments**: Allow multiple payment methods per transaction

- **Rounding Logic**: Implement Malaysian standard (round to nearest 0.05)

- **Receipt Generation**: Trigger receipt printing immediately after payment

- **Error Handling**: Graceful failure for payment device issues

**Implementation Steps**:

1. Define `PaymentMethod` enum with display names and icons
2. Implement payment split logic with amount allocation
3. Add rounding calculations in transaction processing
4. Integrate receipt printing service
5. Test payment flows and error scenarios


### 4. Receipt Printing Strategy


**Objective**: Professional thermal receipt generation with customizable templates.



- **Printer Integration**: Support 58mm and 80mm thermal printers

- **Template System**: Use configurable headers, footers, and business info

- **Dual Receipts**: Generate customer and merchant copies

- **Error Recovery**: Handle printer offline/disconnected states

- **Platform Specific**: Android native printing vs Windows spooler

**Implementation Steps**:

**Implementation Steps**:
1. Implement printer discovery and connection logic
2. Create receipt template builder with business info
3. Add print job queuing and status tracking
4. Handle paper size detection (58mm/80mm)
5. Test printing on target hardware



### 5. Table Management Strategy (Restaurant Mode)


- **Table States**: Available, occupied, reserved with color coding

- **Order Persistence**: Store orders directly in table objects

- **Merge/Split**: Support table merging for large groups

- **Real-time Updates**: Reflect table status changes immediately

- **Capacity Management**: Track table capacity and current occupancy

**Implementation Steps**:
Reflect table status changes immediately

- **Capacity Management**: Track table capacity and current occupancy

**Implementation Steps**:
1. Define `TableStatus` enum with visual indicators
2. Implement table selection grid with status display
3. Add order persistence in `RestaurantTable` model
4. Create table management CRUD operations

5. Test table lifecycle (available → occupied → cleared)


### 6. Responsive Design Strategy


- **Breakpoint System**: 1-4 columns based on screen width (<600:1, 600-900:2, 900-1200:3, >1200:4)

- **LayoutBuilder Usage**: Always wrap grids in `LayoutBuilder` for dynamic columns

- **Text Overflow**: Use `TextOverflow.ellipsis` for constrained text areas

- **Scrollable Dialogs**: Implement `ConstrainedBox` with `SingleChildScrollView` for forms

- **Platform Testing**: Verify on Android tablets and Windows desktops

**Implementation Steps**:
 Implement `ConstrainedBox` with `SingleChildScrollView` for forms

- **Platform Testing**: Verify on Android tablets and Windows desktops

**Implementation Steps**:
1. Implement adaptive column calculation functions
2. Wrap all grids with `LayoutBuilder`

3. Add overflow protection to text widgets
4. Test on various screen sizes and orientations
5. Validate touch targets for mobile/desktop



- **Global Configuration**: Use `BusinessInfo.instance` for tax/service charge settings

- **Real-time Updates**: Recalculate all prices when settings change

- **Display Logic**: Conditionally show tax/service rows based on enabled flags

- **Percentage Storage**: Store rates as decimals (e.g., 0.10 for 10%)

- **Audit Trail**: Log calculation details for transaction records

**Implementation Steps**:
itionally show tax/service rows based on enabled flags

- **Percentage Storage**: Store rates as decimals (e.g., 0.10 for 10%)

- **Audit Trail**: Log calculation details for transaction records

**Implementation Steps**:
1. Implement calculation methods in business logic layer
2. Add conditional UI rendering for tax displays

3. Create settings dialog for rate configuration
4. Test calculation accuracy with various scenarios


- **Try-Catch Blocks**: Wrap all async operations in error handling

- **User Feedback**: Show `SnackBar` or dialogs for errors

- **Recovery Options**: Provide retry mechanisms for failed operations

- **Logging**: Extensive print statements for debugging

- **Fallback Modes**: Continue operation with reduced functionality

**Implementation Steps**:
rap all async operations in error handling

- **User Feedback**: Show `SnackBar` or dialogs for errors

- **Recovery Options**: Provide retry mechanisms for failed operations

- **Logging**: Extensive print statements for debugging

- **Fallback Modes**: Continue operation with reduced functionality

**Implementation Steps**:
1. Add error handling to all service calls

2. Implement user notification system
3. Create retry logic for network/hardware operations


- **Lazy Loading**: Load products/categories on demand

- **Efficient Rendering**: Use `ListView.builder` for large lists

- **Image Optimization**: Cache and resize product images

- **Database Queries**: Optimize SQLite queries with proper indexing

- **Memory Management**: Dispose controllers and clear caches

**Implementation Steps**:
**:

- **Lazy Loading**: Load products/categories on demand

- **Efficient Rendering**: Use `ListView.builder` for large lists

- **Image Optimization**: Cache and resize product images

- **Database Queries**: Optimize SQLite queries with proper indexing

- **Memory Management**: Dispose controllers and clear caches


**Implementation Steps**:
1. Implement pagination for product loading
2. Use efficient list widgets with builders
3. Add image caching and compression


- **Unit Tests**: Test business logic and calculations

- **Integration Tests**: Test screen interactions and workflows

- **Platform Testing**: Verify on Android and Windows targets

- **Edge Case Coverage**: Test with empty carts, network failures, hardware issues

- **Regression Prevention**: Run full test suite before commits

**Implementation Steps**:
**:

- **Unit Tests**: Test business logic and calculations

- **Integration Tests**: Test screen interactions and workflows

- **Platform Testing**: Verify on Android and Windows targets

- **Edge Case Coverage**: Test with empty carts, network failures, hardware issues

- **Regression Prevention**: Run full test suite before commits

**Implementation Steps**:
1. Write unit tests for all calculation logic
2. Create integration tests for user workflows
3. Test on physical devices and emulators
4. Document and test edge cases
5. Automate testing in CI/CD pipeline


### 11. Markdown Linting & Quality Standards


**Objective**: Ensure all created *.md files follow markdown best practices and pass linting validation.

**Critical Linting Rules**:

- **MD003**: Heading style must be consistent (use # for all headings)

- **MD013**: Line length should not exceed 80 characters (configure as needed for code blocks)

- **MD022**: Headings must be surrounded by blank lines (one blank line before and after each heading)

- **MD030**: Spacing between list markers and content must be consistent

- **MD032**: Lists must be surrounded by blank lines (one blank line before and after each list block)

- **MD040**: Fenced code blocks must have a language specified (use ```bash, ```dart, ```yaml, ```text, etc.)

- **MD060**: Table column style must have proper spacing around pipes (use `| Header | Header |` not `|Header|Header|`)

**Validation Steps** (ALWAYS perform after creating *.md files):

1. After creating or modifying any *.md file, validate with markdownlint
2. Check specifically for MD022 (heading spacing) violations
3. Check specifically for MD032 (list spacing) violations
4. Ensure proper blank lines surround all headings and lists
5. For code blocks, verify formatting is correct
6. Use following command to validate:


```bash

# Install markdownlint (if not already installed)

npm install -g markdownlint-cli


# Validate single file

markdownlint path/to/file.md


# Validate all markdown files

markdownlint '**/*.md'


# Fix common issues automatically

markdownlint --fix '**/*.md'

```

**Implementation Standards**:

- Always add blank line before headings (except at start of document)

- Always add blank line after headings

- Always add blank line before lists

- Always add blank line after lists (before non-list content)

- Use consistent heading levels (don't skip from # to ###)

- Ensure code blocks use proper fence markers with language specification (```language)

- Ensure table separators have spaces around pipes (use `| --- | --- |` not `|---|---|`)

- Test all created *.md files before final output

**Common Violations to Avoid**:

- Heading directly after previous content without blank line

- List items without blank line before or after

- Mixed heading styles (some # and some ##)

- Inconsistent list markers (mixing -, *, +)

- Code blocks without proper language specification

- Table separators without spaces (e.g., `|---|---|` instead of `| --- | --- |`)

**Example - Correct Format**:


```markdown

# Main Heading


Introduction paragraph.


## Sub Heading


Content paragraph.


### List Example


- Item 1

- Item 2

- Item 3

Follow-up paragraph after list.

```


### 12. Appwrite Self-Hosted Cloud Plan


- Hosting: Windows Docker Desktop or Ubuntu 22.04 with Docker; static IP/DNS; open ports 80/443/8080/3000

- TLS & domains: Cloudflare proxy off during setup; Traefik/NGINX + Let's Encrypt; map api.yourdomain (API) and console.yourdomain (Console)

- Storage: Persist volumes on fast disk (E:\appwrite-cloud or /opt/appwrite); schedule DB/storage backups

- Stack: Appwrite API, Console, MariaDB, Redis, workers (db, audits, usage, webhooks); optional ingress proxy

- Config: .env for secrets (DB, Redis, JWT/API keys); set public https APPWRITE_ENDPOINT; enable rate/size limits; no default creds

- Database: Tune MariaDB (innodb buffer, connections); strong passwords; automated dumps/mariabackup

- Storage controls: Plan buckets, size limits; optional AV scanning; consider S3-compatible offload later

- Security: Firewall to 80/443 only; DB/Redis internal; HTTPS-only; rotate secrets; enable audit logging

- Observability: Centralize logs; health checks; alerts on restarts, CPU/RAM, disk >80%, DB connections, queue lag

- Scaling: Start single node; vertical first; for horizontal later, externalize DB/Redis and add replicas behind LB

- CI/CD: docker compose pull && docker compose up -d; keep compose + .env template in repo (IaC)

- Backups/DR: Daily DB dumps, storage snapshots; off-box retention; monthly restore drills with documented RPO/RTO

- Access: Least privilege; service accounts for automation; strong password policy; 2FA on console

- Pre-go-live tests: HTTPS reachability, collection CRUD, file upload/download, webhooks, auth flows, backup/restore drill


## 13. Version Bumping & Changelog Management Workflow


**Objective**: Maintain consistent version numbers across the app and keep a comprehensive changelog documenting all changes for each release.

### Version Numbering Scheme

**Format**: `MAJOR.MINOR.PATCH` (e.g., 1.0.27, 1.1.0, 2.0.0)

- **MAJOR**: Breaking changes, major feature overhauls, or significant architecture changes
- **MINOR**: New features, non-breaking enhancements, new POS modes, new business logic
- **PATCH**: Bug fixes, performance improvements, UI refinements, security patches

**Examples**:

- v1.0.27 → v1.0.28: Bug fix or minor UI improvement
- v1.0.27 → v1.1.0: New feature (e.g., loyalty points system, table reservation)
- v1.0.27 → v2.0.0: Major refactor or breaking API change

### Changelog File Structure

**File**: `CHANGELOG.md` (root directory)

**Format**: Follow standard Changelog Markdown (https://keepachangelog.com/)

```markdown

# Changelog

All notable changes to FlutterPOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).


## [Unreleased]

(Features/fixes being worked on but not yet released)


## [1.0.28] - 2026-03-03

### Added

- New settlement report with detailed cash reconciliation
- Loyalty points redemption in checkout flow
- Export reports to CSV format

### Fixed

- Fixed cart total calculation for items with service charge
- Resolved printer connection timeout issues
- Fixed table status not updating in real-time

### Changed

- Improved receipt formatting for 58mm thermal printers
- Enhanced responsive grid layout for tablet view
- Optimized database query performance for large product catalogs

### Deprecated

- Old payment reconciliation screen (use new settlement report instead)


```

**Categories to Include** (in order):

1. **Added**: New features, new POS modes, new services, new settings
2. **Changed**: Changes to existing functionality, UI improvements, performance enhancements
3. **Deprecated**: Features that will be removed in future versions
4. **Removed**: Features removed in this release
5. **Fixed**: Bug fixes, corrected calculations, resolved issues
6. **Security**: Security patches, vulnerability fixes

### Step-by-Step Version Bump Workflow

**Step 1: Identify the Version Change Type**

Before making any changes, determine if this is a MAJOR, MINOR, or PATCH version bump based on the changes you've made.

**Step 2: Update pubspec.yaml**

```yaml
# pubspec.yaml
version: 1.0.28+28  # Format: semantic_version+build_number
# Increment build number with each release
```

**Pattern**:

- PATCH: Increment last number only (1.0.27+27 → 1.0.28+28)
- MINOR: Reset patch, increment minor (1.0.27+27 → 1.1.0+28)
- MAJOR: Reset minor and patch, increment major (1.0.27+27 → 2.0.0+28)

**Step 3: Update Version in Code Files**

If you have version constants in your code, update them:

```dart
// lib/constants/app_constants.dart
class AppConstants {
  static const String appVersion = '1.0.28';
  static const String appBuildNumber = '28';
  static const String releaseName = 'v1.0.28';
}
```

Also update in platform-specific files:

```gradle
// android/app/build.gradle
versionCode 28
versionName "1.0.28"
```

**Step 4: Update CHANGELOG.md**

1. Copy the "Unreleased" section and create a new versioned section
2. Format: `## [VERSION] - YYYY-MM-DD`
3. Document ALL changes in categories (Added, Changed, Fixed, etc.)
4. Keep entries user-facing and clear

**Example Entry**:

```markdown

## [1.0.28] - 2026-03-03

### Added

- New loyalty points system with points earning and redemption
- CSV export functionality for sales reports
- Table merge feature for restaurant mode

### Changed

- Improved cart item display with better spacing
- Enhanced error messages for network issues
- Optimized product search performance

### Fixed

- Fixed tax calculation not applying to discounted items
- Resolved printer offline detection delay
- Fixed crash when opening reports with no data

### Security

- Updated dependencies for security vulnerabilities
- Enhanced password validation for user accounts

```

**Step 5: Commit Changes**

```bash

# Stage version and changelog updates
git add pubspec.yaml CHANGELOG.md lib/constants/app_constants.dart android/app/build.gradle

# Commit with clear message
git commit -m "Bump version to 1.0.28 and update changelog"

```

**Step 6: Create Git Tag**

```bash

# Create annotated tag with release notes
git tag -a v1.0.28 -m "Release v1.0.28: Loyalty points system, CSV export, table merge feature"

# Push tag to remote
git push origin v1.0.28

# Or push all tags
git push origin --tags

```

**Step 7: Build Release APK**

```powershell

# Build POS flavor release APK
.\build_flavors.ps1 pos release

# Copy to desktop with version tag
$apkPath = "build/app/outputs/flutter-apk/app-release.apk"
$dateTag = (Get-Date -Format yyyyMMdd)
$destination = "$env:USERPROFILE\Desktop\FlutterPOS-v1.0.28-$dateTag.apk"
Copy-Item $apkPath $destination

# Verify build
Write-Host "APK built: $destination"

```

### Version Bump Checklist

**Before Releasing Any Version**:

- [ ] All features/fixes are completed and tested
- [ ] Increment version in `pubspec.yaml`
- [ ] Update version constants in code (if applicable)
- [ ] Update `CHANGELOG.md` with clear, user-facing descriptions
- [ ] Verify CHANGELOG.md format follows Keep a Changelog standard
- [ ] Add date in ISO format (YYYY-MM-DD) to CHANGELOG entry
- [ ] Commit: `git commit -m "Bump version to X.Y.Z and update changelog"`
- [ ] Tag: `git tag -a vX.Y.Z -m "Release vX.Y.Z: [brief description]"`
- [ ] Push: `git push origin main && git push origin --tags`
- [ ] Verify tag appears in GitHub releases
- [ ] Build APK/bundle: `.\build_flavors.ps1 pos release`
- [ ] Test APK on target devices
- [ ] Copy APK with version tag to desktop for distribution
- [ ] Update any deployment documentation with new version

### Generated Release Notes Example

When you create a GitHub release from a tag:

```
## FlutterPOS v1.0.28

Release Date: March 3, 2026

**Major Features**:
- Loyalty points system with flexible redemption rates
- CSV export for comprehensive sales reports
- Table merging for large group orders (restaurant mode)

**Improvements**:
- 40% faster product search with indexed queries
- Better visual feedback for printing operations
- Clearer error messages for network and hardware issues

**Fixes**:
- Tax calculation now correctly applies to split payments
- Printer connection timeout reduced from 30s to 5s
- Fixed crash when generating reports with empty data

**Security**:
- Updated flutter_secure_storage to latest version
- Improved API key rotation in Appwrite sync

**Build Info**:
- Build Number: 28
- Target: Android 12+, Windows 10+
- Size: ~45MB APK

[Download v1.0.28 APK]
[View Full Changelog](https://github.com/yourusername/FlutterPOS/blob/main/CHANGELOG.md)

```

### Automated Version Bump Script (PowerShell)

For efficiency, use this script to automate version bumping:

```powershell

# version_bump.ps1
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('major', 'minor', 'patch')]
    [string]$BumpType,
    
    [Parameter(Mandatory=$true)]
    [string]$Description
)

# Get current version from pubspec.yaml
$pubspecContent = Get-Content pubspec.yaml
$currentVersion = $pubspecContent | Select-String -Pattern 'version:\s+(.+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }

# Parse version
$versionParts = $currentVersion.Split('+')[0].Split('.')
[int]$major = $versionParts[0]
[int]$minor = $versionParts[1]
[int]$patch = $versionParts[2]
[int]$buildNum = [int]$currentVersion.Split('+')[1]

# Increment based on bump type
switch ($BumpType) {
    'major' { $major++; $minor = 0; $patch = 0 }
    'minor' { $minor++; $patch = 0 }
    'patch' { $patch++ }
}

$newVersion = "$major.$minor.$patch"
$newBuildNum = $buildNum + 1
$newVersionFull = "$newVersion+$newBuildNum"

Write-Host "Bumping version: $currentVersion → $newVersionFull"

# Update pubspec.yaml
(Get-Content pubspec.yaml) -replace "version:\s+.+", "version: $newVersionFull" | Set-Content pubspec.yaml

# Update CHANGELOG.md
$date = (Get-Date -Format 'yyyy-MM-dd')
$changelogEntry = @"
## [$newVersion] - $date

### Added

- (Add new features)

### Changed

- (Add improvements)

### Fixed

- (Add bug fixes)

`n
"@

$content = Get-Content CHANGELOG.md -Raw
$newContent = $content -replace '(## \[Unreleased\])', "## [Unreleased]`n`n[Changes for unreleased version]`n$changelogEntry"
Set-Content CHANGELOG.md $newContent

# Commit
git add pubspec.yaml CHANGELOG.md
git commit -m "Bump version to $newVersion and update changelog`n`n$Description"

# Tag
git tag -a "v$newVersion" -m "Release v$newVersion: $Description"

Write-Host "✅ Version bumped to $newVersion ($newVersionFull)"
Write-Host "📝 Updated CHANGELOG.md"
Write-Host "🏷️ Created git tag: v$newVersion"
Write-Host "`nNext steps:"
Write-Host "1. Review changes: git log -1"
Write-Host "2. Push commits: git push origin main"
Write-Host "3. Push tags: git push origin v$newVersion"
Write-Host "4. Build: .\build_flavors.ps1 pos release"

```

**Usage**:

```powershell

# Bump patch version
.\version_bump.ps1 -BumpType patch -Description "Fixed cart calculation bug"

# Bump minor version
.\version_bump.ps1 -BumpType minor -Description "Added loyalty points system"

# Bump major version
.\version_bump.ps1 -BumpType major -Description "Major architecture refactor with breaking changes"

```

### Version History Maintenance

**Keep CHANGELOG.md Organized**:

- Never edit released versions (v1.0.27 and below are final)
- Always add unreleased changes to "Unreleased" section
- When releasing, move "Unreleased" to new version with date
- Keep 5-10 most recent versions visible in CHANGELOG
- Archive older versions in separate file if document becomes too large

**Git Tag Conventions**:

- Always use: `v` prefix + semantic version (v1.0.28, NOT 1.0.28)
- Use annotated tags, not lightweight tags: `git tag -a` not `git tag`
- Include release description in tag message
- Never delete released tags (they're part of history)


## Resources


- **[Architecture Details](copilot-architecture.md)**: Multi-flavor system, business modes, data flow

- **[Development Workflows](copilot-workflows.md)**: Build, test, debug, and deployment processes

- **[Database Guide](copilot-database.md)**: SQLite to Isar migration, sync patterns

---
*Last updated: March 3, 2026 (v1.0.28)*
