# POS Modular Refactor Plan

## Scope

- All Dart code under lib/.
- Feature-first modular layout.
- Hard limit: 500 to 1000 lines per file.

## Goals

- Improve maintainability and navigation.
- Reduce monolithic files via structured splits.
- Keep POS flows stable during migration.

## Target Module Layout

```text
lib/
  core/
    routing/
    session/
    data/
    logging/
    constants/
    exceptions/
    theme/
  shared/
    widgets/
    utils/
    formatters/
    extensions/
  features/
    pos/
      screens/
      widgets/
      services/
      models/
      data/
      routes/
    kds/
    backend/
    auth/
    reports/
    settings/
```

## Milestones

### Milestone 0: Baseline + Guardrails

- Define module map and naming conventions.
- Add CI lint to enforce file line count.
- Capture POS smoke flows and run tests.

### Milestone 1: Module Skeleton

- Create features and core/shared folders.
- Add placeholder barrels and route files.
- Keep file sizes within 500 to 1000 lines.

### Milestone 2: Core Extraction

- Move shared services into core/.
- Consolidate shared widgets and utils.
- Replace imports with new paths.

### Milestone 3: POS Feature Split

- Split unified POS screen into shell + sections.
- Move payment, cart, receipt, and refund flows.
- Keep mode-specific screens in features/pos.

### Milestone 4: Data + Models

- Split large model files by domain.
- Move repositories into core/data and feature data.
- Keep domain logic close to its feature.

### Milestone 5: Routing Cleanup

- Centralize app routing in core/routing.
- Compose feature routes from each module.

### Milestone 6: Cleanup + Verify

- Remove dead code and legacy leftovers.
- Run tests and validate line count.
- Update docs and migration notes.

## POS Mapping (Current to Target)

### Entry and Modes

- lib/screens/unified_pos_screen.dart
  -> lib/features/pos/screens/unified_pos/unified_pos_screen.dart
- lib/screens/retail_pos_screen_modern.dart
  -> lib/features/pos/screens/retail/retail_pos_screen.dart
- lib/screens/cafe_pos_screen.dart
  -> lib/features/pos/screens/cafe/cafe_pos_screen.dart
- lib/screens/pos_order_screen_fixed.dart
  -> lib/features/pos/screens/restaurant/restaurant_pos_screen.dart

### Payments

- lib/screens/payment_screen.dart
  -> lib/features/pos/screens/payment/payment_screen.dart
- lib/screens/ewallet_payment_screen.dart
  -> lib/features/pos/screens/payment/ewallet_payment_screen.dart
- lib/screens/payment_methods_management_screen.dart
  -> lib/features/pos/screens/payment/payment_methods_management_screen.dart
- lib/services/payment_service.dart
  -> lib/features/pos/services/payment/payment_service.dart
- lib/services/payment/*.dart
  -> lib/features/pos/services/payment/gateways/*.dart

### Cart and Products

- lib/services/cart_service.dart
  -> lib/features/pos/services/cart/cart_service.dart
- lib/models/cart_item.dart
  -> lib/features/pos/models/cart/cart_item.dart
- lib/widgets/cart_item_widget.dart
  -> lib/features/pos/widgets/cart/cart_item_widget.dart
- lib/widgets/quantity_control.dart
  -> lib/features/pos/widgets/cart/quantity_control.dart
- lib/widgets/product_card.dart
  -> lib/features/pos/widgets/products/product_card.dart

### Receipts

- lib/screens/receipt_settings_screen.dart
  -> lib/features/pos/screens/receipts/receipt_settings_screen.dart
- lib/screens/receipt_preview_screen.dart
  -> lib/features/pos/screens/receipts/receipt_preview_screen.dart
- lib/screens/receipt_designer_screen.dart
  -> lib/features/pos/screens/receipts/receipt_designer_screen.dart
- lib/services/receipt_generator.dart
  -> lib/features/pos/services/receipts/receipt_generator.dart
- lib/services/receipt_pdf_service.dart
  -> lib/features/pos/services/receipts/receipt_pdf_service.dart
- lib/services/thermal_receipt_generator.dart
  -> lib/features/pos/services/receipts/thermal_receipt_generator.dart

### Refunds and Parked Sales

- lib/screens/refund_screen.dart
  -> lib/features/pos/screens/refunds/refund_screen.dart
- lib/screens/refund_service_screen.dart
  -> lib/features/pos/screens/refunds/refund_service_screen.dart
- lib/services/refund_service.dart
  -> lib/features/pos/services/refunds/refund_service.dart
- lib/screens/parked_sales_screen.dart
  -> lib/features/pos/screens/parked_sales/parked_sales_screen.dart
- lib/services/parked_sale_service.dart
  -> lib/features/pos/services/parked_sales/parked_sale_service.dart
- lib/models/parked_sale_model.dart
  -> lib/features/pos/models/parked_sales/parked_sale_model.dart

## Detailed POS Split Plan

### Unified POS Entry

- lib/features/pos/screens/unified_pos/unified_pos_screen.dart
  - Shell widget and route entry point only.
- lib/features/pos/screens/unified_pos/unified_pos_session_gate.dart
  - Business session check and closed state.
- lib/features/pos/screens/unified_pos/unified_pos_mode_router.dart
  - Business mode to screen routing.
- lib/features/pos/screens/unified_pos/unified_pos_app_bar.dart
  - Unified app bar with actions and menus.
- lib/features/pos/screens/unified_pos/unified_pos_training_banner.dart
  - Training mode banner overlay.

### Retail POS Split

- lib/features/pos/screens/retail/retail_pos_screen.dart
  - Shell, layout, and state wiring only.
- lib/features/pos/widgets/retail/retail_product_grid.dart
  - Product grid and paging.
- lib/features/pos/widgets/retail/retail_cart_panel.dart
  - Cart list and quantity controls.
- lib/features/pos/widgets/retail/retail_totals_panel.dart
  - Subtotal, tax, and total summary.
- lib/features/pos/widgets/retail/retail_actions_panel.dart
  - Pay, park, refund, and clear actions.

### Cafe POS Split

- lib/features/pos/screens/cafe/cafe_pos_screen.dart
  - Cafe shell and layout.
- lib/features/pos/widgets/cafe/cafe_menu_grid.dart
  - Menu grid and category filters.
- lib/features/pos/widgets/cafe/cafe_cart_panel.dart
  - Cart list and modifiers.

### Restaurant POS Split

- lib/features/pos/screens/restaurant/restaurant_pos_screen.dart
  - Shell and table mode controls.
- lib/features/pos/widgets/restaurant/table_grid.dart
  - Table selection and status.
- lib/features/pos/widgets/restaurant/table_order_panel.dart
  - Table cart and order actions.

### Payment Flow Split

- lib/features/pos/screens/payment/payment_screen.dart
  - Payment flow shell and state wiring.
- lib/features/pos/widgets/payment/payment_summary.dart
  - Order summary and totals.
- lib/features/pos/widgets/payment/payment_method_list.dart
  - Method selection list.
- lib/features/pos/widgets/payment/payment_splits_panel.dart
  - Split payment inputs.
- lib/features/pos/widgets/payment/payment_actions.dart
  - Confirm, cancel, and print actions.

### Receipts Split

- lib/features/pos/screens/receipts/receipt_settings_screen.dart
  - Receipt configuration shell and sections.
- lib/features/pos/widgets/receipts/receipt_header_editor.dart
  - Header and branding configuration.
- lib/features/pos/widgets/receipts/receipt_footer_editor.dart
  - Footer and policy configuration.
- lib/features/pos/screens/receipts/receipt_preview_screen.dart
  - Live preview shell and selectors.
- lib/features/pos/widgets/receipts/receipt_preview_canvas.dart
  - Preview rendering and layout.
- lib/features/pos/screens/receipts/receipt_designer_screen.dart
  - Template designer shell.
- lib/features/pos/widgets/receipts/receipt_template_palette.dart
  - Template selection and presets.
- lib/features/pos/services/receipts/receipt_generator.dart
  - Core receipt composition logic.
- lib/features/pos/services/receipts/receipt_pdf_service.dart
  - PDF generation only.
- lib/features/pos/services/receipts/thermal_receipt_generator.dart
  - Thermal receipt generation only.

### Refunds Split

- lib/features/pos/screens/refunds/refund_screen.dart
  - Refund shell and search.
- lib/features/pos/widgets/refunds/refund_list.dart
  - Refundable items list.
- lib/features/pos/widgets/refunds/refund_reason_form.dart
  - Reason and notes entry.
- lib/features/pos/widgets/refunds/refund_totals.dart
  - Totals and validation.
- lib/features/pos/screens/refunds/refund_service_screen.dart
  - Service refund shell and filters.
- lib/features/pos/services/refunds/refund_service.dart
  - Refund orchestration and validation.

### Parked Sales Split

- lib/features/pos/screens/parked_sales/parked_sales_screen.dart
  - Parked sales shell and list.
- lib/features/pos/widgets/parked_sales/parked_sales_list.dart
  - List rendering and actions.
- lib/features/pos/widgets/parked_sales/parked_sale_details.dart
  - Details and restore actions.
- lib/features/pos/services/parked_sales/parked_sale_service.dart
  - Persistence and restore logic.
- lib/features/pos/models/parked_sales/parked_sale_model.dart
  - Parked sale model only.

## Core Session Dependencies

- lib/services/business_session_service.dart
  -> lib/features/auth/services/business_session_service.dart
- lib/models/business_session_model.dart
  -> lib/features/auth/models/business_session_model.dart
- lib/screens/business_sessions_screen.dart
  -> lib/features/auth/screens/business_sessions_screen.dart
- lib/widgets/business_session_dialogs.dart
  -> lib/features/auth/widgets/business_session_dialogs.dart
- lib/services/shift_service.dart
  -> lib/features/auth/services/shift_service.dart
- lib/models/shift_model.dart
  -> lib/features/auth/models/shift_model.dart
- lib/services/user_session_service.dart
  -> lib/features/auth/services/user_session_service.dart
- lib/screens/user/sign_in_dialog.dart
  -> lib/features/auth/screens/user/sign_in_dialog.dart
- lib/screens/user/sign_out_dialog_simple.dart
  -> lib/features/auth/screens/user/sign_out_dialog_simple.dart

## Legacy Cleanup Targets

- lib/screens/unified_pos_screen_fixed.dart
- lib/screens/unified_pos_screen_temp.dart
- lib/screens/pos/retail_pos_refactored.dart
- lib/screens/pos/pos_home.dart
- lib/screens/pos/cart_panel.dart
- lib/screens/pos/product_grid.dart
- lib/screens/retail_pos_screen_backup.dart
- lib/screens/retail_pos_screen_template.dart
- lib/examples/unified_pos_snippet.dart
- lib/examples/retail_pos_integration_example.dart
- lib/screens/pos/product_tile.dart

## Constraints

- Enforce 500 to 1000 lines per Dart file.
- No external state management libraries.
- Use BusinessInfo.instance for calculations.
- UnifiedPOSScreen remains the POS entry point.

## Line Count Enforcement

### Local Script

- Add a script that fails when any Dart file is outside 500 to 1000 lines.
- Count physical lines to keep the rule simple and consistent.
- Script: scripts/check_dart_line_counts.py
- Run: python3 scripts/check_dart_line_counts.py

### CI Check

- Run the same script in CI on every pull request.
- Fail fast before tests if line count breaks.

## Strict Line Rule Implications

### Generated Code

- Isolate large generated files into local packages if they exceed the 500-line limit.
- Update imports to use the package path and keep generated files out of `lib/`.

### Small File Consolidation

- Merge small models and helpers into domain pack files to reach 500 lines.
- Group by domain (payments, reports, sessions, inventory).
- Use one file per domain pack and keep types cohesive.
