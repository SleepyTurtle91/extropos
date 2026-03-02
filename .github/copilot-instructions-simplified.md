# FlutterPOS AI Instructions (Simplified)

**Version**: 1.0.27+ | **Architecture**: Multi-flavor Flutter (POS/KDS/Backend/KeyGen) | **Platform**: Windows desktop, Android tablets

---

## 🚨 CRITICAL RULES

1. **500-Line Maximum**: All `.dart` files MUST be <500 lines. Split immediately if exceeded.
2. **Three-Layer Architecture**: ALWAYS split code into Layer A (Logic), Layer B (Widgets), Layer C (Screens)
3. **No UI in Logic**: Services have ZERO Flutter imports
4. **No Logic in Widgets**: Widgets accept data via parameters, actions via callbacks
5. **Monolithic Code**: When user submits >500 lines, refactor BEFORE implementation

---

## Three-Layer Architecture

### Layer A: The Logic (The "Brain")
- **Location**: `lib/services/`, `lib/helpers/`, `lib/models/`
- **Rules**: Pure Dart only (no Flutter imports), testable, single responsibility
- **Contains**: Calculations, validations, data operations
- **Testing**: 100% unit testable

### Layer B: The Specialized Widget (The "Components")
- **Location**: `lib/widgets/`, `lib/widgets/custom/`
- **Rules**: Accept all data via constructor params, all actions via callbacks
- **Contains**: Reusable UI components, no business logic
- **Testing**: Widget tests for rendering and interactions

### Layer C: The Screen (The "Assembler")
- **Location**: `lib/screens/`
- **Rules**: Imports Layer A services + Layer B widgets, orchestrates only
- **Contains**: State management, navigation, screen-level coordination
- **Testing**: Integration tests for user flows

---

## File Splitting Quick Reference

| Problem | Solution |
|---------|----------|
| Service >500 lines | Split by domain (cart_mgmt, cart_calc, cart_discount) |
| Widget >500 lines | Split by component (cart_item, payment_method, summary) |
| Screen >500 lines | Use mixins (logic, dialogs, handlers) in separate files |
| Deeply nested widgets | Extract to separate widget files |
| Calculations in build() | Move to Layer A service |
| Direct DB access in widget | Fetch in screen, pass values to widget |

---

## Unified POS Screen Architecture

- Entry point: `UnifiedPOSScreen` → routes to mode-specific screen based on `BusinessInfo.instance.selectedBusinessMode`
- Modes: retail, cafe, restaurant
- Session flow: Business Session (open/close) → User Session (cashier login) → Shift Management (per-user shifts)

---

## BusinessInfo Singleton

```dart
final info = BusinessInfo.instance;
final taxAmount = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
```

Key properties: `selectedBusinessMode`, `isTaxEnabled`, `taxRate`, `serviceChargeRate`, `currencySymbol`

---

## Responsive Design

Use `LayoutBuilder` for adaptive columns:
- <600px: 1 column
- 600-900px: 2 columns  
- 900-1200px: 3 columns
- >1200px: 4 columns

---

## Code Submission Checklist

When user submits code:
- [ ] Count lines - any file >500 lines?
- [ ] Contains business logic and UI mixed?
- [ ] Services importing Flutter?
- [ ] Widgets calling services directly?
- [ ] Nested widgets >5 levels deep?

If ANY yes → **Refactor immediately** before implementation

---

## Common Pitfalls

| ❌ WRONG | ✅ CORRECT |
|---------|----------|
| `GridView(crossAxisCount: 4)` | Use `LayoutBuilder` with dynamic count |
| `subtotal * 0.10` (hardcoded tax) | `BusinessInfo.instance.taxRate` |
| Service in widget constructor | Pass data/callbacks to widget, fetch in screen |
| `print()` for logging | Use structured logging |
| Calculations in `build()` | Move to Layer A service |
| Direct navigation to POS | Use `UnifiedPOSScreen` (checks sessions) |

---

## Database & Backend

- **Current**: SQLite via `DatabaseHelper.instance` (singleton)
- **Appwrite**: `https://appwrite.extropos.org/v1` | Project: `6940a64500383754a37f` | DB: `pos_db`
- **Service**: `AppwriteSyncService` for sync operations

---

## Build & Test

```bash
# Build single flavor
./build_flavors.ps1 pos release

# Build all flavors
./build_flavors.ps1 all release

# Run tests
flutter test
```

---

## Quick Implementation Workflow

1. **Step 1**: Create Layer A service (pure Dart with unit tests)
2. **Step 2**: Create Layer B widgets (reusable UI, no logic)
3. **Step 3**: Create Layer C screen (import both, orchestrate)
4. **Step 4**: Wire callbacks between C → B → A
5. **Step 5**: Test end-to-end

**Timeline**: Logic (30 min) → Widgets (20 min) → Screen (15 min) → E2E Test (15 min) = 80 min

---

## Refactoring Template (for monolithic code)

```
I notice this code is [X] lines. Per architecture rules, I'm splitting it:

**Layer A (Services)**: [list what was extracted]
**Layer B (Widgets)**: [list what was extracted]
**Layer C (Screen)**: Main orchestration

This follows the 500-line rule. Each layer has single responsibility.
```

---

## Quality Gate Checklist

✅ No file exceeds 500 lines
✅ Services have zero Flutter imports
✅ Widgets accept all data via parameters
✅ No business logic in widget build()
✅ Unit tests for all Layer A code
✅ Widget tests for Layer B components
✅ No direct service access from widgets
✅ File names snake_case, match primary class

---

## Key Files

- `lib/screens/unified_pos_screen.dart` - POS entry router
- `lib/models/business_info.dart` - Global configuration
- `lib/services/database_helper.dart` - SQLite singleton
- `lib/services/appwrite_sync_service.dart` - Backend sync

---

## Resources

- [Architecture Details](copilot-architecture.md)
- [Development Workflows](copilot-workflows.md)
- [Database Guide](copilot-database.md)

---

*Last updated: February 28, 2026 (v1.0.27) | Simplified for agent readability*
