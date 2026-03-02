# Phase 3: POS Screen Decomposition — Status Update

**Objective**: Decompose monolithic POS screens into smaller, focused modules while maintaining 500–1000 line limit per file.

**Phase 3 Start Date**: February 26, 2026

---

## Completed in Phase 3 ✅

### Information Organization
- Created `lib/features/pos/screens/{retail_pos,payment}/` directory structure
- Created `lib/features/pos/screens/{retail_pos,payment}/{widgets,dialogs}/` subdirs for future components
- Created comprehensive phase3_pos_decomposition_strategy.rst with extraction patterns

### File Relocation
- ✅ Moved RetailPOSScreen: `lib/screens/retail_pos_screen.dart` → `lib/features/pos/screens/retail_pos/retail_pos_screen.dart` (1010 lines)
- ✅ Moved PaymentScreen: `lib/screens/payment_screen.dart` → `lib/features/pos/screens/payment/payment_screen.dart` (1012 lines)
- ✅ Updated 4 consumer file imports:
  - lib/screens/retail_pos_screen_modern.dart
  - lib/screens/retail_pos_screen_backup.dart
  - lib/screens/retail_pos_screen_template.dart
  - lib/features/pos/screens/unified_pos/unified_pos_screen.dart
- ✅ Deleted original lib/screens copies after migration

### Organizational Benefit
- Both 1000+ line screens now in feature-specific modules
- Reduced clutter in root lib/screens/ directory
- Clear folder structure ready for widget extraction

---

## Pending Work for Phase 3

### Option A: Widget Extraction (High Complexity, High Value)

**Targets**:
- PaymentScreen decomposition (1012 → multiple files):
  - `payment_method_selector.dart` (140 lines)
  - `amount_input_widget.dart` (130 lines)
  - `split_payment_dialog.dart` (200 lines)
  - `payment_summary_widget.dart` (120 lines)
  - Remaining orchestrator: `payment_screen.dart` (420 lines)

- RetailPOSScreen decomposition (1010 → multiple files):
  - `product_grid_widget.dart` (250 lines)
  - `cart_panel_widget.dart` (200 lines)
  -`pos_app_bar.dart` (100 lines)
  - Remaining orchestrator: `retail_pos_screen.dart` (460 lines)

**Effort**: High — Requires careful extraction with state management and callback passing
**Value**: Reduces 2 files from 2022 total lines → 6 files all <500 lines

### Option B: Model Consolidation (Low Complexity, Medium Value)

**Targets** (Small model files <100 lines each):
- Enum models: `activation_mode.dart` (4), `business_mode.dart` (35) → `enum_models.dart`
- Payment models: `payment_split_model.dart` (42), `payment_method_model.dart` (67) → `payment_models.dart`
- Infrastructure models: `merchant_model.dart` (21), `registered_frontend.dart` (69), `tenant_model.dart` (92) → `infrastructure_models.dart`
- Category models: `category_model.dart` (86), category_modifier_group_model.dart` (67) → `category_models.dart`

**Potential Impact**: Eliminate ~15-20 violations with grouped files

**Effort**: Low — Straightforward file concatenation and import updates
**Value**: Quick visible progress on violation count

### Option C: Hybrid Approach (Recommended)

1. **Quick Wins** (Option B): Consolidate 10-15 small model files → Reduce violations by 15-20
2. **Strategic Extraction** (Option A): Extract 1-2 major widget components → Reduce violations by 5
3. **Validate**: Run line-count script → Show combined impact (30+ violations reduced)

---

## Current Violation Status

**Before Phase 3**: ~289 violations
**After Relocation**: ~289 violations (files moved but still over 1000 lines)
**After Option B+A**: Projected ~250 violations (2 large screens → 6 smaller, 15 models → 4 grouped)

---

## Recommended Next Steps

**Immediate (Highest ROI)**:
1. Consolidate small models (Option B) — 30 mins, 15-20 violations reduced
2. Extract payment screen widgets (Option A) — 1-2 hours, 10+ violations reduced
3. Validate with line-count script
4. Document Phase 3 completion in progress.md

**Future Phases**:
- Phase 4: Database service split (5080 lines → multiple service files)
- Phase 5: Settings/Reports screen decomposition
- Phase 6: Final validation and cleanup

---

*Last updated: February 26, 2026*

