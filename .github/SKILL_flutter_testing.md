# Flutter Testing & Quality Assurance Expertise

**Skill Domain**: Build comprehensive test suites for Flutter apps with focus on unit, widget, and integration testing for POS systems

**When to Invoke**: Writing tests, improving test coverage, fixing failing tests, test architecture, quality validation

---

## Core Testing Areas

### 1. Unit Testing (Layer A Services)

**Purpose**: Test pure business logic in isolation
**Target**: Business logic layer (services, helpers, models)
**Coverage Goal**: 100% for all Layer A code

**Setup**:
```dart
// test/services/cart_calculation_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:extropos/services/cart_calculation_service.dart';
import 'package:extropos/models/cart_item.dart';

void main() {
  group('CartCalculationService', () {
    // Test methods here
  });
}
```

**Test Structure**:
```dart
void main() {
  group('CartCalculationService', () {
    late CartCalculationService service;
    
    setUp(() {
      // Initialize service and dependencies
      service = CartCalculationService();
    });
    
    tearDown(() {
      // Clean up resources
      service.dispose();
    });
    
    test('calculateSubtotal returns sum of item totals', () {
      // Arrange
      final items = [
        CartItem(product: Product(price: 50), quantity: 2),
        CartItem(product: Product(price: 30), quantity: 1),
      ];
      
      // Act
      final result = service.calculateSubtotal(items);
      
      // Assert
      expect(result, equals(130.0));
    });
  });
}
```

**Unit Test Patterns**:

```dart
// Test normal flow
test('adds two numbers correctly', () {
  expect(2 + 2, equals(4));
});

// Test edge cases
test('handles zero values', () {
  expect(calculateTotal([]), equals(0.0));
});

// Test error conditions
test('throws exception for negative quantity', () {
  expect(
    () => validateQuantity(-5),
    throwsA(isA<ValidationException>()),
  );
});

// Test state changes
test('service state updates correctly', () {
  service.addItem(item1);
  expect(service.itemCount, equals(1));
  
  service.addItem(item2);
  expect(service.itemCount, equals(2));
});

// Test with mock dependencies
test('calls database helper for product details', () {
  final mockDb = MockDatabaseHelper();
  final service = ProductService(mockDb);
  
  service.getProduct('123');
  
  verify(mockDb.query('products', '123')).called(1);
});
```

**Unit Test Checklist**:
- [ ] Test normal/happy path
- [ ] Test edge cases (0, negative, max values)
- [ ] Test error conditions (exceptions, validation)
- [ ] Test with different input combinations
- [ ] Mock external dependencies
- [ ] Verify method calls on mocks
- [ ] Test state transitions
- [ ] Benchmark performance-critical methods

**Example: Complete Unit Test Suite**:

```dart
void main() {
  group('PaymentProcessingService', () {
    late PaymentProcessingService service;
    
    setUp(() {
      service = PaymentProcessingService();
    });
    
    /// Positive cases
    test('processes valid payment successfully', () {
      final result = service.processPayment(
        amount: 100.0,
        tendered: 100.0,
        method: PaymentMethod.cash,
      );
      
      expect(result.success, isTrue);
      expect(result.change, equals(0.0));
    });
    
    test('calculates change correctly', () {
      final result = service.processPayment(
        amount: 100.0,
        tendered: 150.0,
        method: PaymentMethod.cash,
      );
      
      expect(result.change, equals(50.0));
    });
    
    /// Edge cases
    test('handles exact payment (no change)', () {
      final result = service.processPayment(
        amount: 99.99,
        tendered: 99.99,
        method: PaymentMethod.card,
      );
      
      expect(result.change, equals(0.0));
    });
    
    test('handles rounding in change calculation', () {
      final result = service.processPayment(
        amount: 100.05,
        tendered: 150.75,
        method: PaymentMethod.cash,
      );
      
      expect(result.change, equals(50.70));
    });
    
    /// Error cases
    test('throws exception for insufficient payment', () {
      expect(
        () => service.processPayment(
          amount: 100.0,
          tendered: 50.0,
          method: PaymentMethod.cash,
        ),
        throwsA(isA<PaymentException>()),
      );
    });
    
    test('throws exception for negative amount', () {
      expect(
        () => service.processPayment(
          amount: -10.0,
          tendered: 100.0,
          method: PaymentMethod.cash,
        ),
        throwsA(isA<PaymentException>()),
      );
    });
    
    test('throws exception for zero amount', () {
      expect(
        () => service.processPayment(
          amount: 0.0,
          tendered: 100.0,
          method: PaymentMethod.cash,
        ),
        throwsA(isA<PaymentException>()),
      );
    });
  });
}
```

### 2. Widget Testing (Layer B Components)

**Purpose**: Test UI components in isolation
**Target**: Custom widgets and components
**Coverage Goal**: 80%+ for critical widgets

**Test Pattern**:

```dart
// test/widgets/cart_item_card_test.dart
void main() {
  group('CartItemCard', () {
    testWidgets('displays product information correctly', 
        (WidgetTester tester) async {
      // Arrange
      final item = CartItem(
        product: Product(name: 'Coffee', price: 5.50),
        quantity: 2,
      );
      
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              item: item,
              onQuantityChanged: (_) {},
              onRemove: () {},
            ),
          ),
        ),
      );
      
      // Assert
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('RM 5.50'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
    
    testWidgets('calls onQuantityChanged when quantity button pressed', 
        (WidgetTester tester) async {
      int? newQuantity;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              item: CartItem(
                product: Product(name: 'Tea', price: 3.50),
                quantity: 1,
              ),
              onQuantityChanged: (qty) => newQuantity = qty,
              onRemove: () {},
            ),
          ),
        ),
      );
      
      // Find and tap the + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle(); // Wait for animations
      
      expect(newQuantity, equals(2));
    });
    
    testWidgets('calls onRemove when delete button pressed', 
        (WidgetTester tester) async {
      bool removed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(
              item: CartItem(...),
              onQuantityChanged: (_) {},
              onRemove: () => removed = true,
            ),
          ),
        ),
      );
      
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      
      expect(removed, isTrue);
    });
    
    testWidgets('displays responsive layout on small screen', 
        (WidgetTester tester) async {
      // Set small screen size
      tester.binding.window.physicalSizeTestValue = 
        Size(400, 800); // Mobile size
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CartItemCard(item: item, /* ... */),
          ),
        ),
      );
      
      // Verify layout adapts for small screen
      expect(find.text('Coffee'), findsOneWidget);
      // More specific checks...
    });
  });
}
```

**Widget Testing Techniques**:

```dart
// Finding widgets
find.byType(ElevatedButton) // Find by widget type
find.byIcon(Icons.add) // Find by icon
find.text('Click Me') // Find by text
find.byKey(Key('submitBtn')) // Find by key
find.bySemanticsLabel('Submit') // Find by semantic label

// Interactions
await tester.tap(finder) // Tap a widget
await tester.enterText(finder, 'text') // Type text
await tester.drag(finder, offset) // Drag gesture
await tester.fling(finder, velocity, duration) // Fling gesture

// Waiting
await tester.pumpWidget(widget) // Build widget once
await tester.pumpAndSettle() // Build until no more animations
await tester.pump(Duration(milliseconds: 100)) // Build after delay

// Assertions
expect(find.byType(Text), findsOneWidget)
expect(find.byText('Label'), findsNothing)
expect(find.byIcon(Icons.add), findsWidgets) // Multiple matches
```

**Widget Test Checklist**:
- [ ] Test widget builds without errors
- [ ] Test UI elements are displayed correctly
- [ ] Test user interactions (tap, input, drag)
- [ ] Test callbacks are called
- [ ] Test responsive behavior
- [ ] Test error/empty states
- [ ] Test with various input data
- [ ] Test accessibility/semantics

### 3. Integration Testing (Full Workflows)

**Purpose**: Test complete user workflows and screen interactions
**Target**: Complete features (cart → payment → receipt)
**Coverage Goal**: Critical user workflows

**Test Pattern**:

```dart
// test/integration/checkout_workflow_test.dart
void main() {
  group('Checkout Workflow', () {
    final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    
    testWidgets('complete checkout flow', (WidgetTester tester) async {
      // Arrange
      app.main(); // Launch app
      await tester.pumpAndSettle();
      
      // Act: Navigate to home
      expect(find.byType(HomePage), findsOneWidget);
      
      // Act: Tap on product
      await tester.tap(find.text('Coffee'));
      await tester.pumpAndSettle();
      
      // Assert: Product added to cart
      expect(find.text('Cart (1)'), findsOneWidget);
      
      // Act: Increase quantity
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // Assert: Quantity updated
      expect(find.text('Qty: 2'), findsOneWidget);
      
      // Act: Proceed to checkout
      await tester.tap(find.text('Checkout'));
      await tester.pumpAndSettle();
      
      // Assert: Checkout screen displayed
      expect(find.byType(CheckoutScreen), findsOneWidget);
      
      // Act: Select payment method
      await tester.tap(find.byIcon(Icons.credit_card));
      await tester.pumpAndSettle();
      
      // Act: Process payment
      await tester.tap(find.text('Pay Now'));
      await tester.pumpAndSettle();
      
      // Assert: Receipt displayed
      expect(find.byType(ReceiptScreen), findsOneWidget);
      expect(find.text('RM 11.00'), findsOneWidget); // Total
    });
  });
}
```

**Integration Test Checklist**:
- [ ] Test complete user journeys
- [ ] Test data flow through screens
- [ ] Test navigation and routing
- [ ] Test service integration
- [ ] Test error recovery
- [ ] Test with realistic data
- [ ] Test database operations
- [ ] Test API calls (with mocks)

### 4. Test Organization & Structure

**File Structure**:
```
test/
├── services/               # Unit tests for Layer A
│   ├── cart_calculation_service_test.dart
│   ├── payment_service_test.dart
│   └── discount_service_test.dart
├── widgets/                # Widget tests for Layer B
│   ├── cart_item_card_test.dart
│   ├── payment_dialog_test.dart
│   └── product_grid_test.dart
├── screens/                # Integration tests for screens
│   ├── retail_pos_screen_test.dart
│   ├── checkout_screen_test.dart
│   └── reports_screen_test.dart
├── integration/            # E2E workflow tests
│   ├── checkout_workflow_test.dart
│   ├── payment_workflow_test.dart
│   └── reports_workflow_test.dart
├── fixtures/               # Test data and mocks
│   ├── mock_products.dart
│   ├── mock_services.dart
│   └── mock_database.dart
└── helpers/                # Test utilities
    ├── pump_widget.dart
    ├── test_helpers.dart
    └── mocks.dart
```

### 5. Mocking & Test Doubles

**Pattern for Mocking Services**:

```dart
// test/fixtures/mock_services.dart
import 'package:mockito/mockito.dart';
import 'package:extropos/services/cart_service.dart';

class MockCartService extends Mock implements CartService {
  @override
  void addItem(CartItem item) {
    super.noSuchMethod(Invocation.method(#addItem, [item]));
  }
  
  @override
  List<CartItem> getCurrentCart() {
    return super.noSuchMethod(
      Invocation.method(#getCurrentCart, []),
      returnValue: [],
    );
  }
}

// Usage in tests
void main() {
  group('CartScreen', () {
    late MockCartService mockService;
    
    setUp(() {
      mockService = MockCartService();
      when(mockService.getCurrentCart()).thenReturn([
        CartItem(product: Product(name: 'Coffee'), quantity: 1),
      ]);
    });
    
    testWidgets('displays cart items from service', (tester) async {
      // Use mockService in widget...
    });
  });
}
```

**Using Mockito for Mocking**:

```yaml
# pubspec.yaml
dev_dependencies:
  mockito: ^5.3.0
  build_runner: ^2.3.0
```

```bash
# Generate mocks
dart run build_runner build
```

### 6. Running Tests

**Commands**:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/cart_calculation_service_test.dart

# Run tests with coverage
flutter test --coverage
lcov --list coverage/lcov.info

# Run tests with verbose output
flutter test -v

# Run tests matching pattern
flutter test --grep "cart"

# Run integration tests on device
flutter drive --target=test_driver/app.dart
```

**Setup in GitHub Actions**:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v1
        with:
          flutter-version: '3.10.0'
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```

### 7. POS-Specific Test Scenarios

**Scenario 1: Add Items to Cart**
```dart
// 1. Tap product
// 2. Verify item in cart
// 3. Add multiple items
// 4. Verify cart count
// 5. Verify total updates
```

**Scenario 2: Apply Discount**
```dart
// 1. Create cart with items
// 2. Apply 10% discount
// 3. Verify discount amount calculated
// 4. Verify tax recalculated after discount
// 5. Verify total updated
```

**Scenario 3: Process Payment**
```dart
// 1. Complete cart
// 2. Enter payment method
// 3. If cash: enter tendered amount
// 4. Verify change calculation
// 5. Verify payment processed
// 6. Verify receipt generated
```

**Scenario 4: Switch Business Modes**
```dart
// 1. Start in retail mode
// 2. Navigate to settings
// 3. Change to cafe mode
// 4. Verify UI changed (modifiers appear)
// 5. Verify data isolated between modes
```

### 8. Test Coverage Goals

**Target Coverage**:
- **Layer A (Services)**: 100% - All business logic tested
- **Layer B (Widgets)**: 80%+ - All user interactions tested
- **Layer C (Screens)**: 60%+ - Critical workflows tested
- **Overall**: 75%+ for release builds

**Measuring Coverage**:

```bash
# Generate coverage report
flutter test --coverage

# View coverage
lcov --list coverage/lcov.info

# Generate HTML report (requires lcov installed)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 9. Test Quality Checklist

**For Every Test**:
- [ ] Test has descriptive name
- [ ] Test is focused on one behavior
- [ ] Test follows AAA pattern (Arrange, Act, Assert)
- [ ] Test has meaningful assertions
- [ ] Test doesn't depend on other tests
- [ ] Test can run in any order
- [ ] Test cleans up after itself (tearDown)
- [ ] Test uses appropriate test type (unit/widget/integration)
- [ ] Test runs in < 1 second (for unit tests)
- [ ] Test is independent of network/database

**WRONG**:
```dart
test('cart functionality is correct', () {
  // Bad: Tests multiple behaviors
  // Bad: Vague description
  service.addItem(item1);
  service.addItem(item2);
  service.removeItem(item1);
  expect(service.items.length, 1);
  // Multiple assertions without clarity
});
```

**CORRECT**:
```dart
test('removes exact item from cart', () {
  // Good: One focused behavior
  // Good: Descriptive name
  service.addItem(item1);
  service.addItem(item2);
  
  // Act
  service.removeItem(item1.id);
  
  // Assert
  expect(service.items.length, equals(1));
  expect(service.items.first, equals(item2));
});
```

### 10. Continuous Testing

**Before Commit**:
```bash
# Run all tests
flutter test

# Check coverage
flutter test --coverage

# Verify no broken builds
flutter build apk --release --flavor posApp
```

**Automated Testing (CI/CD)**:
- Run tests on every push
- Block merge if tests fail
- Generate coverage reports
- Archive test results

---

## Quick Reference: When This Skill Applies

✅ **Invoke This Skill For**:
- Writing unit tests for services
- Writing widget tests for components
- Writing integration tests for workflows
- Fixing failing tests
- Improving test coverage
- Setting up test infrastructure
- Mocking external dependencies
- Test data and fixtures
- Running and debugging tests
- CI/CD test automation
- POS-specific test scenarios

❌ **Don't Use For**:
- General Dart/Flutter questions
- Non-POS business logic
- Code that shouldn't be tested

---

## Integration with Your Project

**Existing Test Structure**:
- 100+ unit tests in `test/services/`
- 40+ widget tests in `test/widgets/`
- Integration tests in `test/integration/`

**Test Command**:
```bash
flutter test                          # Run all
flutter test --coverage               # With coverage
flutter test test/services/*          # Specific directory
```

**Coverage Targets**:
- Business logic: 100% (all calculations tested)
- UI components: 80%+ (critical paths tested)
- Screens: 60%+ (main workflows tested)
- Overall: 75%+ for releases

**Your Current Coverage**: Check with `dart run coverage:format_coverage --packages=.packages --report-on=lib --in=coverage --out=coverage/html`

