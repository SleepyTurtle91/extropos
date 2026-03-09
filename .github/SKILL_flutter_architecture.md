# Flutter POS Architecture & Refactoring Expertise

**Skill Domain**: Design, refactor, and optimize Flutter app architecture following the three-layer modular pattern

**When to Invoke**: Code refactoring needs, architecture decisions, file structure improvements, large monolithic code cleanup

---

## Core Expertise Areas

### 1. Three-Layer Architecture Mastery

**Layer A (Logic)**: Pure Dart business logic
- No Flutter imports (only `dart:*`, models, constants)
- Services, helpers, utilities, calculation methods
- 100% unit testable
- Location: `lib/services/`, `lib/helpers/`, `lib/models/`

**Layer B (Widgets)**: Reusable UI components
- Accept ALL data via constructor parameters
- Accept ALL actions via callbacks
- No service imports or business logic
- Self-contained presentation
- Location: `lib/widgets/`, `lib/widgets/custom/`

**Layer C (Screens)**: Screen orchestration
- Import both services (Layer A) and widgets (Layer B)
- Handle navigation, state composition, user flows
- Delegate calculations to services
- Assemble components from widgets
- Location: `lib/screens/`

### 2. The 500-Line Rule

**MANDATORY**: Every Dart file must stay under 500 lines

**Automatic Refactoring Triggers**:
- File exceeds 500 lines
- Multiple unrelated concerns in one class
- Business logic mixed with UI rendering
- Widget tree deeper than 5 levels
- Direct service access in widgets
- Calculations in widget build() methods

**Separation Strategy**:
```
Monolithic File (800 lines)
  ↓
Layer A Service (150 lines) → Calculations, validations
Layer B Widget 1 (120 lines) → UI Component 1
Layer B Widget 2 (100 lines) → UI Component 2
Layer C Screen (180 lines) → Orchestration
Layer B Widget 3 (75 lines) → UI Component 3
```

### 3. Refactoring Process

**Step 1: Analyze**
- Identify all concerns (business logic, calculations, UI)
- Count lines and nested levels
- Mark logical breaking points with comments

**Step 2: Extract Layer A (Logic)**
- Create service classes with pure Dart
- Use static methods for utilities
- Write unit tests for each method
- No side effects or I/O

**Step 3: Extract Layer B (Widgets)**
- Create reusable, single-responsibility widgets
- Accept data via constructor parameters only
- Use callbacks for user interactions
- Keep build() methods shallow (<50 lines)

**Step 4: Refactor Layer C (Screen)**
- Remove all business logic (move to Layer A)
- Remove custom UI (replace with Layer B widgets)
- Screen imports services and widgets
- Simple state management only

**Step 5: Wire & Test**
- Screen calls services for data
- Screen passes data to widgets
- Widgets call back to screen handlers
- Services tested with unit tests
- Screens tested with integration tests

### 4. File Size Enforcement

**Check before committing**:
- [ ] Count lines in each Dart file
- [ ] Any file >500 lines must be refactored
- [ ] Verify layer separation (services/widgets/screens)
- [ ] Ensure services have zero Flutter imports
- [ ] Confirm widgets accept data via parameters only

**Common Anti-Patterns & Fixes**:

| ❌ WRONG | ✅ CORRECT |
|---------|-----------|
| Calculations in widget build() | Move to Layer A service |
| Database queries in initState() | Create service with dependency injection |
| Multiple widgets in one 800-line file | Create separate widget files |
| Service imports in widgets | Pass data via constructor parameters |
| Hardcoded calculations | Use BusinessInfo or passed parameters |
| Nested widgets 8+ levels deep | Extract inner widgets to separate files |

### 5. New Feature Development Workflow

**Always follow this order**:

1. **Layer A First** (30% effort)
   - Create service with pure Dart
   - Write unit tests
   - Validate calculations

2. **Layer B Second** (40% effort)
   - Design reusable widgets
   - Accept all data via parameters
   - Write widget tests

3. **Layer C Last** (30% effort)
   - Assemble components
   - Wire services to widgets
   - Write integration tests

**Example: Adding Loyalty Points**

Layer A Service:
```dart
// lib/services/loyalty_points_service.dart
class LoyaltyPointsService {
  static int calculatePointsEarned(double amount) => amount.toInt();
  static double calculateDiscount(int points) => points / 100;
  static bool hasEnoughPoints(int current, int required) => current >= required;
}
```

Layer B Widgets:
```dart
// lib/widgets/loyalty_points_card.dart
class LoyaltyPointsCard extends StatelessWidget {
  final int currentPoints;
  final Function(int) onRedeem;
  // ... accepts all data via constructor
}
```

Layer C Screen:
```dart
// lib/screens/checkout_screen.dart
class _CheckoutScreenState extends State<CheckoutScreen> {
  void _handleRedeem() {
    final discount = LoyaltyPointsService.calculateDiscount(points);
    // ... call service, update cart
  }
  
  @override
  Widget build(BuildContext context) {
    return LoyaltyPointsCard(
      currentPoints: points,
      onRedeem: _handleRedeem,
    );
  }
}
```

### 6. Code Review Checklist

**For Every Submitted Code Piece**:

- [ ] File under 500 lines? (If no, refactor first)
- [ ] Clear layer separation? (Services, widgets, screens)
- [ ] Layer A has NO Flutter imports? (only `dart:*`, models)
- [ ] Layer B accepts data via constructor? (no service imports)
- [ ] Layer C orchestrates without business logic?
- [ ] SingleChildScrollView for scrollable content?
- [ ] Unit tests for all Layer A code?
- [ ] Widget tests for complex Layer B components?
- [ ] Integration tests for screen workflows?
- [ ] No hardcoded values (except constants)?
- [ ] Clear error handling with try-catch?
- [ ] Proper Immutability (final fields, const widgets)?

### 7. Common Refactoring Patterns

**Pattern: Extract Calculation Service**
```
From: Widget.build() doing math
To: CartCalculationService.calculateTotal()
Result: 30-line widget, 50-line service + unit tests
```

**Pattern: Extract Dialog Content**
```
From: 200-line screen with 10-line nested build
To: DiscountDialog widget, 80 lines
Result: Screen focus on orchestration, dialog handles UI
```

**Pattern: Extract Business Logic Mixin**
```
From: 600-line screen with 50 methods
To: Screen (150 lines) + ScreenLogic mixin (200 lines)
Result: Clearer separation, testable logic
```

**Pattern: Extract Widget List Items**
```
From: ListView.builder with 30-line item build
To: ListItemCard widget, 30 lines + Screen 20 lines
Result: Reusable item widget, clean screen
```

### 8. Performance & Scalability

**Optimization Rules**:
- Use `ListView.builder` for large lists (never fixed-count ListView)
- Cache calculations in Layer A services (not in widgets)
- Use `LayoutBuilder` for responsive grids
- Lazy-load data (don't fetch all products at once)
- Dispose stream controllers and animations

**Scalability Pattern**:
```
Single Service (200 lines) → Multiple Focused Services (100 lines each)
Monolithic Widget (400 lines) → Reusable Components (80 lines each)
God Screen (800 lines) → Orchestrator Screen (150 lines) + Mixins
```

---

## Quick Reference: When This Skill Applies

✅ **Invoke This Skill For**:
- Code exceeds 500 lines
- Need to refactor monolithic code
- Designing new features (architecture first)
- Improving layer separation
- Extracting widgets from screens
- Creating reusable services
- File structure planning
- Code review against three-layer pattern
- Performance optimization decisions

❌ **Don't Use For**:
- Simple bug fixes
- Single-file edits (<50 lines change)
- Framework-specific questions (use docs)
- General Dart syntax (use language docs)

---

## Integration with Project

**Existing Files**: Your project already follows this pattern!
- `lib/services/` - Layer A services
- `lib/widgets/` - Layer B components
- `lib/screens/` - Layer C orchestration

**Current Architecture**: POS, KDS, Backend, KeyGen flavors all follow three-layer pattern

**Database Access Pattern**: Services → DatabaseHelper.instance (never direct in widgets)

**State Management**: Local setState() only (no external packages)

**Testing**: 100+ unit/integration tests validating layer separation

