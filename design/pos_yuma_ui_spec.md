POS — YUMA-inspired UI Spec

Overview
- Purpose: Redesign POS flavor to visually and interaction-wise resemble YUMA POS (clean tile-based product grid, right-side cart, prominent quick actions), while keeping project conventions (BusinessInfo, UnifiedPOSScreen, local SQLite).
- Targets: Windows desktop primary, Android tablets secondary.

Visual Style
- Primary color: Deep Indigo / Navy (e.g., #0B3D91)
- Accent color: Warm Orange (e.g., #FF7A18)
- Surface: Light neutral (e.g., #F7F8FA)
- Text primary: #0F1724 (near-black)
- Card background: white with subtle elevation shadow
- Rounded corners: 8-12px on tiles and buttons
- Typography: Roboto/Inter family — weights: 400 (body), 600 (titles)

Layout & Key Regions
1. AppShell (UnifiedPOSScreen)
   - AppBar: left: hamburger/menu; center: business name + mode badge; right: user avatar, shift indicator, search.
   - Main area: two-column split (desktop) — left: product/category area (flexible grid); right: cart/details panel (fixed width ~420–480px on desktop, collapsible on small screens).

2. Category Bar
   - Horizontal scrollable chips across the top of the product area; selected chip highlighted with accent color.
   - Quick-access: Favorites and Recents chip.

3. Product Grid
   - Tile layout with adaptive columns (use `LayoutBuilder` breakpoints).
   - Tile contents: image (top), name (bold), price row (currency symbol left), modifier indicator (dot) if product has variants.
   - Tile actions: single tap = add to cart (quantity +1); long-press = quick modifiers/notes modal.

4. Cart Panel
   - Header: current table/session label, clear cart button.
   - Line items: compact rows with qty selector, item name, modifiers summary, total line price, and per-row contextual menu (edit/remove).
   - Totals area: subtotal, tax (conditional), service charge (conditional), rounding, total.
   - Payment CTA: large primary button `Take Payment` and a smaller `Quick Cash` preset buttons (e.g., Cash RM10/RM20/RM50).

5. Checkout Modal
   - Simple split showing cart summary and payment method selection (default cash). Option to print receipt and close session.

6. Notifications & Feedback
   - Use top snackbars for success/errors. Inline validation for quantity/stock.

Responsive Behavior
- Breakpoints (consistent with repo standards):
  - <600px: single column; cart collapses to bottom sheet
  - 600-900px: 2 columns
  - 900-1200px: 3 columns
  - >1200px: 4 columns
- Use `LayoutBuilder` for grid and `AnimatedContainer` for cart collapse/expand.

Interaction Details
- Add-to-cart animation: quick scale/fade micro-animation from tile to cart icon.
- Quantity change: inline +/- spinner; long press +/- to accelerate (hold to increment).
- Modifier flow: modal with checkboxes/radio for choices, price preview updated live.

Offline-Only Behavior
- Default flavor mode: Offline Only (no Appwrite initialization for POS flavor). Keep AppwriteSyncService calls behind a feature flag.
- Data storage: all products, categories, settings stored in local SQLite via `DatabaseHelper.instance`.
- Sync toggle: hidden in POS flavor UI (for now) — configuration stored but disabled.

Assets & Icons
- Replace remote-only assets with bundled assets under `assets/pos_yuma/`.
- Use Material icons + custom SVGs for POS actions; include high-DPI PNGs for printers.

Accessibility & Localization
- Ensure touch targets >= 48px.
- Support RTL later; use localized strings via existing i18n helper.

Developer Guidance
- Follow `UnifiedPOSScreen` routing; implement design in `lib/screens/pos/`.
- Keep state local with `setState()` where possible; persist cart in local DB for restaurant mode.
- Use modular widgets: `CategoryBar`, `ProductTile`, `CartPanel`, `CheckoutModal` for reuse and tests.

Notes / Non-goals for initial release
- No remote sync; no multi-device sharing; no payment terminals integration (cash + manual card only).

Example color tokens (suggested):
- `posPrimary`: #0B3D91
- `posAccent`: #FF7A18
- `posSurface`: #F7F8FA
- `posText`: #0F1724

End of spec
