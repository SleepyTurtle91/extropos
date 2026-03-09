---
name: flutter-testing-quality
description: Write comprehensive tests for Flutter apps with unit tests for Layer A logic, widget tests for Layer B components, and integration tests for workflows. Achieve 100% coverage for business logic, 80% for UI, use mocking and test doubles.
license: Proprietary
compatibility: Flutter 3.0+, Dart 3.0+. Requires flutter_test, mockito for mocking.
metadata:
  author: FlutterPOS
  version: "1.0"
  domain: flutter-dart
  focus: testing
---

# Flutter Testing & Quality Assurance

**When to use this skill**: Writing tests, improving coverage, fixing test failures, testing architecture, mocking services, test organization.

## Testing Pyramid for POS Apps

**Layer A (Logic)**: 100% coverage
- All business logic, calculations, validations tested
- Pure unit tests, fast execution
- No UI dependencies

**Layer B (Widgets)**: 80%+ coverage
- Critical UI paths tested
- User interactions validated
- Widget tests with dependencies

**Layer C (Screens)**: 60%+ coverage  
- Main user workflows tested
- Integration between components
- Screen navigation flows

## Unit Testing Business Logic

Test structure (AAA pattern):

```dart
void main() {
  group('CartCalculationService', () {
    test('calculateSubtotal sums item totals', () {
      // Arrange
      final items = [
        CartItem(product: Product(price: 50), quantity: 2),
        CartItem(product: Product(price: 30), quantity: 1),
      ];
      
      // Act
      final result = CartCalculationService.calculateSubtotal(items);
      
      // Assert
      expect(result, equals(130.0));
    });
  });
}
```

**Test Coverage**:
- ✅ Normal/happy path
- ✅ Edge cases (zero, negative, max values)
- ✅ Error conditions (exceptions, validation)
- ✅ State transitions
- ✅ Different input combinations

## Widget Testing Components

Test UI interactions and rendering:

```dart
testWidgets('CartItemCard displays product info', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CartItemCard(
          item: CartItem(product: Product(name: 'Coffee'), quantity: 2),
          onQuantityChanged: (_) {},
          onRemove: () {},
        ),
      ),
    ),
  );
  
  expect(find.text('Coffee'), findsOneWidget);
  expect(find.text('2'), findsOneWidget);
});

testWidgets('calls callback when + button tapped', (tester) async {
  int? newQty;
  
  await tester.pumpWidget(/* ... */);
  await tester.tap(find.byIcon(Icons.add));
  
  expect(newQty, equals(3));
});
```

## Mocking Services

Mock external dependencies:

```dart
class MockCartService extends Mock implements CartService {}

void main() {
  late MockCartService mockService;
  
  setUp(() {
    mockService = MockCartService();
    when(mockService.getItems()).thenReturn([
      CartItem(product: Product(name: 'Coffee'), quantity: 1),
    ]);
  });
  
  testWidgets('displays items from service', (tester) async {
    // Use mockService in widget...
  });
}
```

## Integration Testing Workflows

Test complete user flows:

```dart
testWidgets('checkout workflow', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Add item
  await tester.tap(find.text('Coffee'));
  await tester.pumpAndSettle();
  
  // Proceed to checkout
  await tester.tap(find.text('Checkout'));
  await tester.pumpAndSettle();
  
  // Process payment
  await tester.tap(find.text('Pay Now'));
  await tester.pumpAndSettle();
  
  // Verify success
  expect(find.byType(ReceiptScreen), findsOneWidget);
});
```

## Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/services/cart_service_test.dart

# Run with coverage
flutter test --coverage

# Watch mode (rerun on changes)
flutter test --watch
```

## Test Organization

```
test/
├── services/              # Unit tests for Layer A
│   ├── cart_calculation_service_test.dart
│   └── payment_service_test.dart
├── widgets/               # Widget tests for Layer B
│   ├── cart_item_card_test.dart
│   └── payment_dialog_test.dart
├── screens/               # Integration tests
│   └── checkout_screen_test.dart
└── fixtures/              # Test data, mocks
    └── mock_services.dart
```

## Coverage Goals

| Layer | Target | Rationale |
|-------|--------|-----------|
| Layer A (services) | 100% | All logic must be tested |
| Layer B (widgets) | 80%+ | UI interactions critical |
| Layer C (screens) | 60%+ | Main workflows essential |
| **Overall** | **75%+** | Release quality standard |

## Test Quality Checklist

For every test:
- [ ] Descriptive test name
- [ ] Single focused behavior
- [ ] Follows AAA pattern (Arrange/Act/Assert)
- [ ] Meaningful assertions
- [ ] Independent (no test ordering)
- [ ] Cleans up in tearDown()
- [ ] Runs in < 1 second (unit tests)

## Common Testing Patterns

**Test edge cases**:
```dart
test('handles empty cart', () {
  expect(CartCalculationService.calculateSubtotal([]), equals(0.0));
});

test('rejects negative quantities', () {
  expect(
    () => validateQuantity(-5),
    throwsA(isA<ValidationException>()),
  );
});
```

**Test with different states**:
```dart
test('cart updates with each add', () {
  service.addItem(item1);
  expect(service.itemCount, equals(1));
  
  service.addItem(item2);
  expect(service.itemCount, equals(2));
});
```

---

See [references/TEST_PATTERNS.md](references/TEST_PATTERNS.md) for complete examples.

See [references/MOCKING_GUIDE.md](references/MOCKING_GUIDE.md) for mocking strategies.
