# FlutterPOS 2-Week Launch Plan
## Fully Offline POS App - Publication Ready

**Target**: Production release in 2 weeks  
**Focus**: Offline-first POS flavor (retail/cafe/restaurant modes)  
**Goal**: Crash-free, feature-complete, consumer-ready application

---

## Phase Overview

### Week 1: Core Stability & Unified Screen Refactor
- Days 1-2: Bug fixes & crash investigation
- Days 3-4: Unified POS Screen implementation
- Days 5-7: Feature validation for each business mode

### Week 2: Testing & Polish
- Days 8-10: Comprehensive testing (unit + integration + manual)
- Days 11-13: Bug fixes & crash resolution
- Days 14: Final build, signing, & deployment

---

## Task Breakdown

### Phase 1: Assessment & Crash Prevention (Days 1-2)

#### 1.1 Current State Analysis
- [ ] Identify all existing POS screen components
  - RetailPOSScreenModern
  - CafePOSScreen
  - TableSelectionScreen
  - RestaurantPOSScreen (if exists)
- [ ] Audit crash logs & error handling gaps
- [ ] Review database operations for offline reliability
- [ ] Check image loading & asset handling

#### 1.2 Critical Stability Fixes
- [ ] Add try-catch to all database queries
- [ ] Implement graceful degradation for missing images
- [ ] Add cache validation for products/categories
- [ ] Fix null safety issues
- [ ] Add recovery options for failed operations

---

### Phase 2: Unified POS Screen Architecture (Days 3-5)

#### 2.1 Create UnifiedPOSScreen Scaffold
**File**: `lib/screens/unified_pos_screen.dart`

```dart
UnifiedPOSScreen
├── AppBar (shared)
│   ├── Business Mode Indicator
│   ├── Business Session Status
│   ├── Current User & Shift
│   └── Menu (Settings, Reports, Sign Out)
│
├── Mode Router
│   ├── if (mode == retail) → RetailPOSScreenModern
│   ├── if (mode == cafe) → CafePOSScreen
│   └── if (mode == restaurant) → TableSelectionScreen
│
└── Training Mode Overlay (if enabled)
```

#### 2.2 Implement Mode-Specific Features

##### RETAIL MODE
- [ ] Product grid with search/filter
- [ ] Cart management (add/remove/adjust quantity)
- [ ] Single payment method support
- [ ] Receipt printing
- [ ] Daily sales report
- [ ] Inventory tracking

##### CAFE MODE
- [ ] Category-based product browsing
- [ ] Quick add to cart
- [ ] Multiple payment methods
- [ ] Takeaway/Dine-in selection
- [ ] Receipt generation
- [ ] Hourly sales report

##### RESTAURANT MODE
- [ ] Table selection grid
- [ ] Table-based order management
- [ ] Waiter/Section assignment
- [ ] Kitchen display (simple)
- [ ] Table merge/split operations
- [ ] Bills & settlement
- [ ] Restaurant-specific reports

#### 2.3 Shared Components
- [ ] Unified cart component
- [ ] Payment dialog (supports all modes)
- [ ] Receipt template engine
- [ ] Tax & service charge calculator
- [ ] Transaction history viewer

---

### Phase 3: Feature Validation (Days 5-7)

#### 3.1 Product Management
- [ ] Product loading from SQLite
- [ ] Category filtering
- [ ] Image caching & display
- [ ] Barcode scanning support
- [ ] Quantity limits validation

#### 3.2 Cart Operations
- [ ] Add item functionality
- [ ] Remove item functionality
- [ ] Adjust quantity (+ / -)
- [ ] Clear cart
- [ ] Cart persistence (restaurant mode)
- [ ] Cart calculations (subtotal, tax, service charge, total)

#### 3.3 Payment Processing
- [ ] Cash payment
- [ ] Card payment (placeholder)
- [ ] E-wallet payment (if configured)
- [ ] Split payment support
- [ ] Change calculation
- [ ] Payment validation

#### 3.4 Transaction Management
- [ ] Save transaction to database
- [ ] Generate receipt
- [ ] Print receipt (if printer connected)
- [ ] Handle offline receipt queue
- [ ] Transaction history viewing

#### 3.5 Reports (High Priority)
- [ ] Daily sales report
- [ ] Hourly breakdown
- [ ] Payment method breakdown
- [ ] Category-wise sales
- [ ] Top products
- [ ] Tax/service charge breakdown
- [ ] User/cashier performance (if multi-user)

#### 3.6 Session Management
- [ ] Business session open/close
- [ ] Shift open/close
- [ ] User sign-in/sign-out
- [ ] Shift reports
- [ ] Cash reconciliation

---

### Phase 4: Comprehensive Testing (Days 8-10)

#### 4.1 Unit Testing
- [ ] Cart calculation logic
- [ ] Tax/service charge calculations
- [ ] Payment processing logic
- [ ] Report generation logic
- [ ] Database operations
- [ ] Session management logic

#### 4.2 Integration Testing
- [ ] Complete POS flow (add item → checkout → payment → receipt)
- [ ] Mode switching (retail ↔ cafe ↔ restaurant)
- [ ] Session lifecycle (open → transactions → close → report)
- [ ] Shift management (open shift → transactions → close shift)
- [ ] Offline operation (no network)
- [ ] Product sync (from backend when available)

#### 4.3 Manual Testing Scenarios

##### Retail Mode
Scenario 1: Single item purchase
- [ ] Add 1 item to cart
- [ ] Checkout
- [ ] Pay with cash
- [ ] Print receipt
- [ ] Verify transaction in history

Scenario 2: Multiple items with discount
- [ ] Add 5 different items
- [ ] Apply discount (if supported)
- [ ] Verify tax calculation
- [ ] Complete payment
- [ ] Check report

Scenario 3: Barcode scanning (if supported)
- [ ] Scan barcode
- [ ] Verify correct product added
- [ ] Complete transaction

##### Cafe Mode
Scenario 1: Takeaway order
- [ ] Add items for takeaway
- [ ] Select takeaway option
- [ ] Checkout
- [ ] Generate receipt

Scenario 2: Mixed order
- [ ] Add takeaway items + dine-in items
- [ ] Process separately
- [ ] Verify reports separate orders

##### Restaurant Mode
Scenario 1: Table service
- [ ] Select table
- [ ] Add items to table
- [ ] See items on other devices (kitchen display)
- [ ] Complete order
- [ ] Generate bill
- [ ] Settle payment

Scenario 2: Table merge
- [ ] Create orders on Table 1 & Table 2
- [ ] Merge tables
- [ ] Verify combined bill
- [ ] Split payment

Scenario 3: Takeaway from restaurant
- [ ] Create takeaway order
- [ ] Checkout
- [ ] Verify separate from table orders

#### 4.4 Performance Testing
- [ ] App startup time (<3 seconds)
- [ ] Cart operations responsiveness
- [ ] Report generation speed
- [ ] Memory usage monitoring
- [ ] Battery drain assessment

#### 4.5 Crash Testing
- [ ] Test network offline conditions
- [ ] Test with invalid/missing data
- [ ] Test rapid UI interactions
- [ ] Test memory limits
- [ ] Test storage full scenarios
- [ ] Test app lifecycle (pause/resume)

---

### Phase 5: Bug Fixes & Stabilization (Days 11-13)

#### 5.1 Crash Investigation Protocol
For any crash:
1. Reproduce consistently
2. Check logcat/console output
3. Add error handling if missing
4. Test fix thoroughly
5. Add unit test to prevent regression

#### 5.2 Common Crash Patterns to Check
- [ ] Null pointer exceptions (use null coalescing)
- [ ] Database locked errors (add retry logic)
- [ ] Image loading failures (use placeholder)
- [ ] Missing permissions (validate at startup)
- [ ] State during lifecycle transitions (use mounted checks)
- [ ] Division by zero (add validation)
- [ ] Layout overflow errors (use SingleChildScrollView)

#### 5.3 Performance Optimization
- [ ] Lazy load products/categories
- [ ] Implement pagination for reports
- [ ] Cache frequently accessed data
- [ ] Optimize database queries
- [ ] Clean up temporary files

---

### Phase 6: Final Polish & Release (Day 14)

#### 6.1 Pre-Release Checklist
- [ ] Code review for quality
- [ ] Documentation updated
- [ ] All tests passing
- [ ] No known crashes
- [ ] No console errors
- [ ] All features tested
- [ ] Reports validated
- [ ] UI responsive across screen sizes

#### 6.2 Build & Signing
- [ ] Generate signed APK
- [ ] Verify APK signature
- [ ] Test on real device
- [ ] Final smoke test

#### 6.3 Deployment
- [ ] Tag release version
- [ ] Create release notes
- [ ] Upload to distribution channel
- [ ] Verify installability
- [ ] Document post-launch support

---

## Key Technical Decisions

### Architecture
- **State Management**: Local `setState()` only (no external packages)
- **Database**: SQLite (offline-first, no cloud sync in v1)
- **Navigation**: Unified POS Screen as main router
- **Access Control**: Business Session → User Session → Shift

### Data Persistence
- **Products**: Loaded once at app startup, cached in memory
- **Transactions**: Saved to SQLite immediately
- **Cart State**: Lost on app close (except restaurant mode - saved to table)
- **Reports**: Queried from SQLite on demand

### Error Handling
- **Network**: Graceful degradation (app fully functional offline)
- **Database**: Retry logic with exponential backoff
- **UI**: Try-catch around all setState calls
- **Files**: Fallback to placeholder images
- **Permissions**: Request at startup with clear explanation

---

## Risk Mitigation

### High Risk Items
1. **Database corruption**
   - Mitigation: Regular validation checks, backup on app start
   - Test: Write 1000+ transactions and verify integrity

2. **Memory leaks on long sessions**
   - Mitigation: Dispose controllers properly, clear caches
   - Test: Keep app open for 4+ hours continuous use

3. **Report generation slowness**
   - Mitigation: Pagination, background loading
   - Test: Generate reports with 1000+ transactions

4. **Printer connection issues**
   - Mitigation: Queue receipts, retry logic
   - Test: Disconnect/reconnect printer mid-print

### Medium Risk Items
1. **Tax calculation precision**
   - Test: Various tax rates and amounts
2. **Barcode scanning reliability**
   - Test: Different barcode formats
3. **Large image handling**
   - Test: Products with HD images

### Low Risk Items
1. **UI responsiveness**
   - Already stable with Flutter
2. **Data validation**
   - Straightforward business logic

---

## Success Metrics

By launch day, verify:

✅ **Functionality**
- [x] All 3 business modes fully operational
- [x] All reports generate correctly
- [x] All transactions save properly
- [x] No crashes in 1-hour continuous use test

✅ **Performance**
- [x] App starts in <3 seconds
- [x] Cart operations are instant
- [x] Reports generate in <10 seconds
- [x] Memory stable after 1 hour use

✅ **Quality**
- [x] 90%+ unit test coverage
- [x] All integration test scenarios pass
- [x] Manual testing checklist complete
- [x] Code review approved

✅ **User Experience**
- [x] App works offline completely
- [x] Intuitive navigation for each mode
- [x] Clear error messages
- [x] No permission surprises

---

## Daily Standup Template

Record daily progress:

```
Date: [Date]
Completed:
- [ ] Task 1
- [ ] Task 2

In Progress:
- [ ] Task 3

Blocked By:
- [ ] Issue X

Risks Identified:
- [ ] Risk 1
```

---

## File Structure for Reference

```
lib/
├── screens/
│   ├── unified_pos_screen.dart ⭐ (NEW - Main router)
│   ├── pos/
│   │   ├── retail_pos_screen_modern.dart
│   │   ├── cafe_pos_screen.dart
│   │   ├── restaurant_pos_screen.dart
│   │   └── components/
│   │       ├── cart_panel.dart
│   │       ├── payment_dialog.dart
│   │       ├── receipt_generator.dart
│   │       └── product_grid.dart
│   ├── reports/
│   │   ├── daily_sales_report.dart
│   │   ├── shift_report.dart
│   │   └── category_report.dart
│   └── ...
├── services/
│   ├── business_session_service.dart
│   ├── shift_service.dart
│   ├── cart_service.dart (if extracted)
│   ├── receipt_service.dart
│   ├── report_service.dart
│   └── ...
├── models/
│   ├── transaction.dart
│   ├── cart_item.dart
│   ├── business_info.dart
│   └── ...
└── ...

assets/
├── locales/ (if multi-language)
└── default_images/
    └── product_placeholder.png
```

---

## Notes for Implementation

- **Avoid the cloud backend code** - disable AppwriteSyncService
- **Disable offline sync worker** - won't need it
- **Focus on DatabaseHelper** - all data is local
- **Test on real devices** - Android tablets for cafe/restaurant, phones for retail
- **Keep log statements** - helps with post-launch support
- **Document user flows** - needed for training/support

---

**Last Updated**: February 19, 2026  
**Status**: Ready for implementation  
**Version**: 1.0.27-offline
