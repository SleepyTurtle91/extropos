---
name: flutter-architecture-refactoring
description: Refactor Flutter code using three-layer modular architecture (Layer A/B/C). Enforce 500-line file limit. Split monolithic widgets into focused services, widgets, and screens. Design feature architecture before implementation.
license: Proprietary
compatibility: Flutter 3.0+, Dart 3.0+. Designed for FlutterPOS applications.
metadata:
  author: FlutterPOS
  version: "1.0"
  domain: flutter-dart
  focus: architecture-design
---

# Flutter Architecture & Refactoring

**When to use this skill**: Refactoring large files, planning new features, improving code organization, enforcing architecture standards, splitting widgets into components.

## Three-Layer Architecture

### Layer A: Logic (The "Brain")
- Pure Dart business logic, calculations, validations
- NO Flutter imports (only `dart:*`, models)
- Location: `lib/services/`, `lib/helpers/`, `lib/models/`
- 100% unit testable
- Single responsibility

**Example**:
```dart
class CartCalculationService {
  static double calculateSubtotal(List<CartItem> items) {
    return items.fold(0.0, (sum, item) => sum + (item.quantity * item.price));
  }
}
```

### Layer B: Widgets (The "Components")
- Reusable, self-contained UI components
- Accept ALL data via constructor parameters
- Accept ALL actions via callbacks
- NO business logic inside build()
- Location: `lib/widgets/`, `lib/widgets/custom/`

**Example**:
```dart
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  
  const CartItemCard({required this.item, required this.onQuantityChanged});
  
  @override
  Widget build(BuildContext context) {
    // Pure presentation, all data passed in
  }
}
```

### Layer C: Screens (The "Assembler")
- Orchestrates services (Layer A) and widgets (Layer B)
- Manages navigation and screen state
- Delegates calculations to Layer A
- Assembles components from Layer B
- Location: `lib/screens/`

**Example**:
```dart
class CartScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    final total = CartCalculationService.calculateTotal(cartItems);
    return CartPanel(
      items: cartItems,
      total: total,
      onQuantityChanged: _handleQuantityChange,
    );
  }
}
```

## The 500-Line Rule (MANDATORY)

Every Dart file must stay under 500 lines.

**Refactor immediately if**:
- File exceeds 500 lines
- Multiple unrelated concerns in one class
- Business logic mixed with UI rendering
- Widget tree deeper than 5 levels
- Direct service access in widgets
- Calculations in widget build() methods

**Refactoring Process**:
1. Identify all concerns (business logic, UI, calculations)
2. Extract Layer A services with unit tests
3. Extract Layer B widgets for reusable components
4. Keep Layer C screen focused on orchestration
5. Wire components together with callbacks

See [references/ARCHITECTURE_DETAILED.md](references/ARCHITECTURE_DETAILED.md) for complete patterns.

## Common Refactoring Patterns

| Code Has | Extract To |
|-----------|-----------|
| Calculations in build() | Layer A service method |
| Database queries in widgets | Layer A service + dependency injection |
| Multiple related widgets | Separate widget files in lib/widgets/ |
| 800+ line screen | Layer A/B/C split (see examples) |
| Helper methods > 100 lines | Separate service class |
| Nested widgets 6+ levels | Extract to separate widget files |

## Quick Refactoring Checklist

- [ ] File under 500 lines?
- [ ] Clear layer separation (services, widgets, screens)?
- [ ] Layer A has NO Flutter imports?
- [ ] Layer B accepts data via constructor?
- [ ] Layer C orchestrates without calculations?
- [ ] No hardcoded business values?
- [ ] Unit tests for all Layer A code?
- [ ] Widget tests for Layer B components?

## File Organization

```
lib/
├── services/              # Layer A - Pure logic
│   ├── cart_service.dart
│   └── payment_service.dart
├── widgets/               # Layer B - Reusable UI
│   ├── custom/
│   └── cart_item_card.dart
└── screens/               # Layer C - Screens
    └── cart_screen.dart
```

## Anti-Patterns to Avoid

❌ **Wrong**: Calculations in widget build()
✅ **Correct**: Move to Layer A service

❌ **Wrong**: Service imports in widgets
✅ **Correct**: Pass data via constructor parameters

❌ **Wrong**: Multiple concerns in one file
✅ **Correct**: Split by responsibility

❌ **Wrong**: Hardcoded values in logic
✅ **Correct**: Use passed parameters or config

## Integration with Your Project

Your FlutterPOS follows this architecture:
- `lib/services/` - 20+ Layer A services
- `lib/widgets/` - 50+ Layer B components
- `lib/screens/` - 10+ Layer C screens
- Multi-flavor support (POS/KDS/Backend/KeyGen)

All files must respect the 500-line maximum and three-layer separation.

---

**Need detailed guidance?** See [references/ARCHITECTURE_DETAILED.md](references/ARCHITECTURE_DETAILED.md)

**Example refactorings?** See [references/REFACTORING_EXAMPLES.md](references/REFACTORING_EXAMPLES.md)
