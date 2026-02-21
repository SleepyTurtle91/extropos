# Unified POS Consumer Launch Plan (March 2026)

## Objective

Ship a frontend-only POS product with a single unified entry screen for all
business types:

- Retail POS
- Cafe POS
- Restaurant POS

All cashier access must go through `UnifiedPOSScreen`.

## Timeline

- Start date: 2026-02-16
- Target launch window: 2026-03-16 to 2026-03-22
- Delivery mode: weekly milestones with release gate checks

## Scope (In)

- Unified shell UX for POS with shared app bar and status controls
- Business mode routing inside `UnifiedPOSScreen`
- Session guard enforcement:
  - Business session
  - Cashier session
  - Shift session
- Consumer UX polish for tablet and desktop
- Frontend release packaging (APK)

## Scope (Out)

- Backend expansion work
- New non-POS modules unrelated to checkout flow
- Full architecture migration (for example SQLite to Isar)

## Milestones

### M1: Unified Shell Foundation (2026-02-16 to 2026-02-22)

- Refactor `UnifiedPOSScreen` for a cleaner, consumer-facing shell
- Keep one POS entry route (`/pos`)
- Preserve mode-specific behavior under a shared wrapper

Acceptance criteria:

- POS launch always opens unified shell
- Current mode is clearly visible in shell
- Status indicators are visible without app bar overflow

### M2: Shared Checkout Rules (2026-02-23 to 2026-03-01)

- Confirm all pricing uses `BusinessInfo.instance`
- Validate tax and service charge consistency by mode
- Standardize payment completion and receipt trigger points

Acceptance criteria:

- Same calculation rules across all modes
- No hardcoded tax/service rates in checkout path
- Payment success always reaches receipt flow

### M3: Consumer UX Revamp (2026-03-02 to 2026-03-08)

- Improve usability for first-time cashiers
- Ensure adaptive layouts across target breakpoints:
  - <600 (mobile)
  - 600-900 (tablet)
  - 900-1200 (desktop)
  - >1200 (large)
- Improve loading, empty, and error states

Acceptance criteria:

- Main POS actions reachable within 1-2 taps
- No clipped controls on tablet/desktop
- Consistent visual hierarchy across modes

### M4: Launch Hardening (2026-03-09 to 2026-03-15)

- Run full POS regression and mode-specific UAT
- Burn down P1/P2 defects
- Freeze release candidate and package APK

Acceptance criteria:

- UAT sign-off for Retail, Cafe, Restaurant
- Zero open P1 defects
- Release candidate tagged and reproducible build steps verified

## Go/No-Go Checklist

- [ ] Unified POS shell is default POS entry
- [ ] Business session guard blocks all POS actions when closed
- [ ] Cashier sign-in/sign-out works from unified shell
- [ ] Shift start/end works from unified shell
- [ ] Retail checkout happy path passes
- [ ] Cafe checkout happy path passes
- [ ] Restaurant table-to-payment happy path passes
- [ ] Receipt generation works for completed payment
- [ ] Crash-free smoke test on Windows and Android tablet
- [ ] Release APK generated and installed on test device

## Execution Board

### Active now

- Unified shell refactor in `lib/screens/unified_pos_screen.dart`
- Launch scope and release gates documented

### Next 3 actions

1. Complete mode-driven shell polish and analyzer validation
2. Run targeted regression on POS mode entry and checkout
3. Prepare UAT script for consumer pilot stores

## Risks and Mitigation

- SDK mismatch in local environment blocks analyzer/test execution
  - Mitigation: align local Dart/Flutter toolchain with `pubspec.yaml`
- Hidden direct navigation to legacy POS screens
  - Mitigation: grep-based audit and redirect all user-facing entries to `/pos`
- Visual regressions on small devices
  - Mitigation: enforce `LayoutBuilder` breakpoint behavior in touched screens
