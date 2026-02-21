Milestone Schedule — 2-week Plan (Feb 20 → Mar 5, 2026)

Goal: Ship POS flavor redesign with YUMA-like UI and Offline-Only operation.

Owners: You (Product), Developer (Implementation). Adjust owners as needed.

Day 0 (Today — Feb 20)
- Kickoff: confirm scope, accept UI spec draft (this document).
- Mark `Design UI spec` as in-progress (done).

Sprint 1 — Design & Theme (Feb 21–22)
- Feb 21: Finalize colors, typography, tile density, and asset list.
- Feb 22: Produce final mockups/screens: Home, Product tile, Cart panel, Checkout modal.
Deliverables: `design/pos_yuma_ui_spec.md` (this), mockup PNGs.

Sprint 2 — Core UI Implementation (Feb 23–26)
- Feb 23: Scaffold POS screen widgets (`CategoryBar`, `ProductGrid`, `ProductTile`).
- Feb 24: Implement `CartPanel` with line items and totals.
- Feb 25: Connect UI to local data source (DB read of products/categories); implement add-to-cart flows.
- Feb 26: Polish interactions + animations, responsive tweaks.
Deliverables: Working UI branch `feature/pos-yuma-ui`.

Sprint 3 — Offline Persistence & DB (Feb 27–28)
- Feb 27: Define/verify local DB schema; create seed script to populate sample products.
- Feb 28: Ensure CRUD flows use `DatabaseHelper.instance` and handle migrations.
Deliverables: Migration + seed SQL, local DB file for QA.

Sprint 4 — Payment & Receipt (Mar 1–2)
- Mar 1: Implement cash payment flow, rounding rules, receipt generation.
- Mar 2: Add print stub and export receipt as PDF/printable HTML for Windows.
Deliverables: Payment flow and receipt testing.

Sprint 5 — QA & Tests (Mar 3–4)
- Mar 3: Unit tests for calculations (tax, service charge, rounding). Integration tests for core flows.
- Mar 4: Manual QA checklist run: empty cart, large orders, modifiers, offline app restart.
Deliverables: Test reports, resolved critical bugs.

Day 14 — Release Prep (Mar 5)
- Build release APK/installer for POS flavor.
- Create release notes and package assets; tag release in git.
- Publish to distribution channel.

Post-Release (first 48 hours)
- Monitor crash reports and user feedback.
- Prepare quick patch plan if major issues appear.

Contingency
- If any critical blocker appears: move Sprint 4 to Mar 3 and shift QA to Mar 4–5; keep release date but prepare hotfix branch.

Acceptance Criteria (must pass before publishing)
- Offline-only POS can open and perform full order → payment → receipt without network.
- UI implements YUMA-like product grid and cart layout, responsive across desktop/tablet.
- Local DB seeded with sample data, and migrations handled.
- Basic rounding/tax/service calculations are tested and correct.

Next steps (I'll take unless you change priorities)
- Create simple Flutter widget skeletons for `ProductGrid`, `ProductTile`, and `CartPanel` in `lib/screens/pos/`.
- Seed a small product dataset SQL or Dart fixture.

