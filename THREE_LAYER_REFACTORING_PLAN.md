# Three-Layer Modular Architecture Refactoring Plan

## Overview
**Objective**: Refactor 113 files >500 lines into three-layer modular architecture  
**Target**: Maximum 500 lines per file  
**Focus**: Scalability, Readability, Collaboration

## Three-Layer Architecture Pattern

### Layer A: Logic (`*_logic.dart`)
**Purpose**: Business logic, data operations, state management  
**Contents**:
- State classes/controllers
- Business rules and calculations
- API calls and data fetching
- State management logic
- Event handlers
- Validation logic

**Example**: `retail_pos_logic.dart`
```dart
class RetailPOSLogic {
  // Cart management
  void addToCart(Product product) { }
  void removeFromCart(String productId) { }
  double calculateTotal() { }
  
  // Payment processing
  Future<void> processPayment(PaymentMethod method) async { }
  
  // Business rules
  bool canApplyDiscount(double amount) { }
}
```

### Layer B: Widget Components (`*_widgets.dart` or `widgets/*.dart`)
**Purpose**: Specialized, reusable UI components  
**Contents**:
- Stateless widgets for UI elements
- Reusable card components
- Input fields and forms
- List items and grid items
- Custom buttons and controls

**Example**: `retail_pos_widgets.dart` or `widgets/product_card.dart`
```dart
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  
  const ProductCard({required this.product, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    // UI only - no logic
  }
}
```

### Layer C: Screen Assembler (`*_screen.dart`)
**Purpose**: Orchestration and composition  
**Contents**:
- Screen scaffold
- Layout composition
- Widget assembly
- Minimal glue code
- Route configuration

**Example**: `retail_pos_screen.dart`
```dart
class RetailPOSScreen extends StatefulWidget {
  @override
  _RetailPOSScreenState createState() => _RetailPOSScreenState();
}

class _RetailPOSScreenState extends State<RetailPOSScreen> {
  late final RetailPOSLogic _logic;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Retail POS')),
      body: Row(
        children: [
          Expanded(child: ProductGrid(logic: _logic)),
          SizedBox(width: 300, child: CartPanel(logic: _logic)),
        ],
      ),
    );
  }
}
```

## Refactoring Scope

### Summary Statistics
- **Total files**: 113 files >500 lines
- **Total lines**: 80,424 lines to refactor
- **Target reduction**: ~50-70% per file

### Priority Tiers

#### Tier 1: Critical (5 files, >=1000 lines)
1. `screens/printers_management_screen_widgets.dart` - 1,286 lines
2. `services/database_helper_upgrade.dart` - 1,234 lines
3. `screens/advanced_reports_screen_large_widgets.dart` - 1,166 lines
4. `services/mock_database_service.dart` - 1,019 lines
5. `models/advanced_reports.dart` - 1,013 lines

#### Tier 2: High Priority (31 files, 800-999 lines)
Key files:
- `screens/modern_reports_dashboard.dart` - 996 lines
- `screens/advanced_reports_screen.dart` - 981 lines
- `screens/receipt_designer_screen.dart` - 960 lines
- `features/pos/screens/unified_pos/unified_pos_screen.dart` - 955 lines
- `services/database_service_parts/database_service_products.dart` - 949 lines
- `services/payment_service.dart` - 930 lines
- [26 more files...]

#### Tier 3: Medium Priority (77 files, 500-799 lines)
Will be addressed after Tiers 1 & 2

## Implementation Strategy

### Phase 1: Create Templates & Tools
1. ✅ Scan codebase (COMPLETE - 113 files identified)
2. 🔄 Create architecture templates
3. Create automated extraction scripts
4. Set up validation tools

### Phase 2: Refactor Critical Files (Tier 1)
**Priority Order**:
1. `services/database_helper_upgrade.dart` - Already part/part of, need logic extraction
2. `services/mock_database_service.dart` - Pure data insertion, easy extraction
3. `models/advanced_reports.dart` - Model + logic separation
4. `screens/printers_management_screen_widgets.dart` - Already extracted, further modularize
5. `screens/advanced_reports_screen_large_widgets.dart` - Already extracted, split into smaller components

### Phase 3: Refactor High Priority (Tier 2)
Focus on screens first, then services:
- Group by domain (POS, Reports, Settings, etc.)
- Apply three-layer pattern consistently
- Maintain zero compilation errors

### Phase 4: Refactor Medium Priority (Tier 3)
- Batch process by directory
- Apply learned patterns
- Final validation

## File Organization Structure

### Before (Current):
```
lib/
  screens/
    retail_pos_screen.dart (1500 lines)
  services/
    payment_service.dart (900 lines)
```

### After (Three-Layer):
```
lib/
  screens/
    retail_pos/
      retail_pos_screen.dart (300 lines) - Assembler
      retail_pos_logic.dart (400 lines) - Business logic
      widgets/
        product_card.dart (80 lines)
        cart_panel.dart (150 lines)
        payment_dialog.dart (200 lines)
  services/
    payment/
      payment_service.dart (200 lines) - Core service
      payment_logic.dart (350 lines) - Processing logic
      payment_models.dart (150 lines) - Data models
```

## Success Criteria

### Per-File Metrics
- ✅ Main screen file: ≤500 lines
- ✅ Logic file: ≤500 lines
- ✅ Individual widget files: ≤300 lines (ideally <200)
- ✅ Zero compilation errors
- ✅ All existing functionality preserved

### Code Quality
- ✅ Clear separation of concerns
- ✅ Reusable widget components
- ✅ Testable logic layer
- ✅ Easy to navigate and understand
- ✅ Supports team collaboration

## Rollout Plan

### Week 1: Foundation
- Days 1-2: Critical files (Tier 1) - 5 files
- Days 3-4: First 10 high-priority files
- Day 5: Testing and validation

### Week 2: High Priority
- Days 1-4: Remaining 21 high-priority files
- Day 5: Integration testing

### Week 3: Medium Priority
- Days 1-5: Process 77 medium files (15-16 per day)

### Week 4: Polish & Documentation
- Final validation
- Update documentation
- Team training on new architecture

## Next Immediate Actions
1. ✅ Complete scan (DONE)
2. 🔄 Create extraction script for three-layer pattern
3. ▶️ Start with `services/mock_database_service.dart` (simplest)
4. ▶️ Move to `services/database_helper_upgrade.dart`
5. ▶️ Process remaining Tier 1 files

---
**Status**: Phase 1 in progress  
**Last Updated**: February 27, 2026  
**Progress**: 1/113 files (0.9%)
