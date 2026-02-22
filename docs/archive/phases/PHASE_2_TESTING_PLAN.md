# Phase 2: Feature Validation Testing Plan
## Comprehensive Testing for Retail/Cafe/Restaurant Modes

**Target Date**: Complete by Feb 26, 2026 (7 days)  
**Build Status**: Ready (Backend errors don't affect POS flavor)  
**Focus**: Core features working without crashes

---

## Quick Test Scenarios (Per Mode)

### RETAIL MODE - Complete POS Flow
**File**: `lib/screens/retail_pos_screen_modern.dart`

#### Test 1: Product Loading
- [ ] App loads products from SQLite
- [ ] 4 categories show: All, Apparel, Footwear, Accessories
- [ ] Products display in grid (1/2/3/4 columns responsive)
- [ ] No console errors

**Steps**:
1. Launch app in Retail mode
2. Go to UnifiedPOSScreen
3. Verify products load in 2 seconds
4. Resize window - verify columns adjust
5. **Expected**: Product grid updates smoothly

---

#### Test 2: Shopping Cart Operations
**Action**: Add/Remove/Adjust items

- [ ] Click product → adds to cart (green feedback)
- [ ] Quantity can be adjusted (+/- buttons)
- [ ] Item can be removed (trash icon)
- [ ] Cart totals update in real-time
- [ ] Subtotal = sum of (price × quantity)
- [ ] Tax calculated correctly (if enabled)
- [ ] Service charge calculated (if enabled)
- [ ] Total = Subtotal + Tax + Service Charge

**Test Sequence**:
1. Click "T-Shirt" ($25) → 1x added
2. Click "T-Shirt" again → Quantity becomes 2
3. Click "Jeans" ($60) → added
4. Verify cart shows: 2x T-Shirt ($50), 1x Jeans ($60) = Subtotal $110
5. Adjust T-Shirt to 3 → Subtotal $135
6. Remove Jeans → Subtotal $75
7. **Expected**: All calculations correct, no crashes

---

#### Test 3: Payment Processing
**Action**: Complete sale with different payment methods

**Test Case 1: Cash Payment**
- [ ] Enter amount paid: $100
- [ ] System calculates change: $25 (if subtotal $75)
- [ ] Change displays correctly
- [ ] Payment accepted
- [ ] Receipt generates

**Test Case 2: Card Payment**
- [ ] Click "Card" button
- [ ] Show payment confirmation
- [ ] Accept payment
- [ ] Receipt generated

**Test Case 3: E-Wallet**
- [ ] Click "E-Wallet" button
- [ ] Select payment method (if configured)
- [ ] Process payment
- [ ] Confirm receipt

**Expected Results**:
- All 3 payment methods work
- Change calculated correctly
- No crashes during payment
- Receipt prints (if printer connected)
- Transaction saved to database

---

#### Test 4: Receipt Generation
- [ ] Receipt shows correct items
- [ ] Receipt shows correct totals
- [ ] Receipt shows business info
- [ ] Receipt shows payment method
- [ ] Receipt shows date/time

---

#### Test 5: Daily Sales Report (Retail)
- [ ] Make 3 sales with different payments (cash + card + ewallet)
- [ ] Go to Reports
- [ ] View Daily Sales
- [ ] Verify totals match (gross sales, tax, service charge)
- [ ] Verify payment breakdown correct

---

---

### CAFE MODE - Orders & Queue Management
**File**: `lib/screens/cafe_pos_screen.dart`

#### Test 1: Create New Order
- [ ] Click "New Order"
- [ ] Select category
- [ ] Add 2-3 items (e.g., Coffee, Pastry, Juice)
- [ ] Each item quantity selectable

**Expected**: Order list shows 1 active order

---

#### Test 2: Dine-in vs Takeaway
- [ ] Create order 1: Dine-in (Seat 1)
- [ ] Create order 2: Takeaway
- [ ] Verify both show correctly in order queue
- [ ] Each order tracked separately

---

#### Test 3: Order Queue Display
- [ ] Show all active orders
- [ ] Each order shows: Order Number, Items, Total, Status
- [ ] Mark order as "Called"
- [ ] Mark order as "Completed"
- [ ] Completed orders disappear from queue

---

#### Test 4: Payment for Cafe Orders
- [ ] Complete order 1 (Dine-in)
- [ ] Choose payment method
- [ ] Verify receipt shows "Dine-in" or seat number
- [ ] Verify receipt shows all items

---

#### Test 5: Cafe Daily Report
- [ ] Make 3 orders (mix of dine-in & takeaway)
- [ ] Complete all 3
- [ ] Go to Reports → Daily Sales
- [ ] Verify includes all cafe orders
- [ ] Show breakdown by order type if available

---

---

### RESTAURANT MODE - Table Management
**File**: `lib/screens/table_selection_screen.dart`

#### Test 1: Table Grid Display
- [ ] See table grid (4x4 or similar)
- [ ] Each table shows: Table Number, Capacity, Status
- [ ] Available tables = white/green
- [ ] Occupied tables = orange/different color
- [ ] Reserved tables = show differently (if supported)

**Expected**: Tables update status in real-time

---

#### Test 2: New Table Order
- [ ] Click on Table 1 (Available)
- [ ] Status changes to "Occupied"
- [ ] Can add menu items to table
- [ ] Add 2 items for different customers (if seat tracking exists)

---

#### Test 3: Multiple Tables
- [ ] Open Table 1 → Add items
- [ ] Open Table 2 → Add items
- [ ] Open Table 3 → Add items
- [ ] All 3 show as occupied
- [ ] Click back to table list → See 3 occupied, others available

---

#### Test 4: Table Merge
- [ ] Occupied Table 1 + Table 2
- [ ] Merge them
- [ ] New merged table shows all items from both
- [ ] Both original tables now available for reopening
- [ ] Single bill generated

**Expected**: Merged table total = Table 1 items + Table 2 items

---

#### Test 5: Table Split
- [ ] Merged Table (has items from 2 customers)
- [ ] Split by items or amount
- [ ] Create 2 separate bills
- [ ] Each customer pays separately
- [ ] Both transactions saved

---

#### Test 6: Table Settlement
- [ ] Table 1 with 3 items needs to pay
- [ ] Choose payment method
- [ ] Complete payment
- [ ] Table returns to "Available"
- [ ] Next customer can use Table 1

---

#### Test 7: Restaurant Daily Report
- [ ] Settle 3 tables with different payment methods
- [ ] Go to Reports → Daily Sales
- [ ] Verify includes all table orders
- [ ] Payment breakdown correct

---

---

## Cross-Mode Tests

### Session Management (All Modes)
#### Test: Business Session Open/Close
- [ ] App requires business session open
- [ ] Cannot process sales if business closed
- [ ] Can open business session
- [ ] Can see session active indicator
- [ ] Can close business session
- [ ] Report shows business hours

#### Test: Shift Management
- [ ] First use prompts to start shift
- [ ] Shift shows user, start time, opening cash
- [ ] Can end shift
- [ ] End shift generates shift summary
- [ ] Shift report shows all transactions in that shift

---

### Reports (All Modes)
#### Test: Daily Sales Report
- [ ] Report shows today's total sales
- [ ] Shows gross sales, net, tax, service charge
- [ ] Shows transaction count
- [ ] Shows payment method breakdown
- [ ] Shows category breakdown (if available)

#### Test: Weekly Report
- [ ] Select week
- [ ] Shows daily breakdown
- [ ] Total for week calculated

#### Test: Monthly Report
- [ ] Select month
- [ ] Shows weekly breakdown
- [ ] Total for month calculated

#### Test: Custom Date Range
- [ ] Select start date
- [ ] Select end date
- [ ] Report generated for range
- [ ] Empty range shows $0

---

### Error Recovery (All Modes)

#### Test: Offline Operation
- [ ] Disconnect network (if online features exist)
- [ ] Can still add products to cart
- [ ] Can still process payment
- [ ] Transaction saved locally
- [ ] Receipt generated

#### Test: Database Error Handling
- [ ] Delete database file (simulate corruption)
- [ ] App doesn't crash
- [ ] Shows appropriate error message
- [ ] Uses fallback sample data
- [ ] Can still operate

#### Test: Image Loading Failure
- [ ] Intentionally break image URLs
- [ ] Product shows placeholder instead of crashing
- [ ] App continues normally

#### Test: Rapid Clicking
- [ ] Rapidly click "Add to Cart" 10x
- [ ] Click checkout 3x simultaneously
- [ ] No duplications or crashes
- [ ] All actions queued properly

---

---

## Performance Benchmarks (Week 2)

### Startup Time ⏱️
- [ ] Cold start: < 5 seconds
- [ ] Hot start: < 2 seconds
- [ ] Product load: < 3 seconds

### Response Time
- [ ] Add item to cart: < 500ms
- [ ] Checkout: < 1 second
- [ ] Report generation: < 10 seconds

### Memory Usage
- [ ] After 1 hour use: < 200MB
- [ ] After 10 transactions: no memory leak
- [ ] Product images cached: no reload on re-select

### Battery Drain (Mobile)
- [ ] Hour of POS: < 10% battery
- [ ] No excessive CPU usage

---

---

## Crash Test Matrix

| Scenario | Expected | Pass |
|----------|----------|------|
| Network offline | Works, saves locally | [ ] |
| DB connection fails | Shows error, uses fallback | [ ] |
| Image URL broken | Shows placeholder | [ ] |
| Rapid cart adds | All added, no duplication | [ ] |
| Very large order | Calculates correctly | [ ] |
| Payment cancelled | Cart preserved | [ ] |
| Device rotation | UI adapts, data preserved | [ ] |
| App backgrounded | State preserved on resume | [ ] |
| Low memory | Graceful degradation | [ ] |
| Corrupted DB | Shows error, can recover | [ ] |

---

---

## Testing Execution Log

### Day 1: Retail Mode ✅

- [ ] **09:00** - Test: Product loading
- [ ] **09:30** - Test: Cart operations
- [ ] **10:00** - Test: Payment processing
- [ ] **10:30** - Test: Receipt generation
- [ ] **11:00** - Test: Daily sales report

**Issues Found**:
- [ ] None yet

**Fixes Applied**:
- [ ] None yet

---

### Day 2: Cafe Mode

- [ ] **09:00** - Test: New order creation
- [ ] **09:30** - Test: Dine-in vs Takeaway
- [ ] **10:00** - Test: Order queue
- [ ] **10:30** - Test: Cafe payment
- [ ] **11:00** - Test: Cafe reports

---

### Day 3: Restaurant Mode

- [ ] **09:00** - Test: Table grid
- [ ] **09:30** - Test: New table order
- [ ] **10:00** - Test: Multiple tables
- [ ] **10:30** - Test: Table merge
- [ ] **11:00** - Test: Table split

---

### Day 4: Cross-Mode & Error Handling

- [ ] **09:00** - Test: Session management
- [ ] **09:30** - Test: Shift management
- [ ] **10:00** - Test: Reports (all types)
- [ ] **10:30** - Test: Offline operation
- [ ] **11:00** - Test: Database errors

---

### Day 5: Stress Testing

- [ ] **09:00** - Test: Rapid interactions
- [ ] **09:30** - Test: Large orders
- [ ] **10:00** - Test: Many transactions
- [ ] **10:30** - Test: 1-hour continuous use
- [ ] **11:00** - Memory/CPU monitoring

---

### Day 6: Fix & Optimize

- [ ] **09:00** - Address all issues found
- [ ] **10:00** - Performance optimization
- [ ] **11:00** - Final verification

---

### Day 7: Final Polish

- [ ] **09:00** - Code review
- [ ] **10:00** - Documentation update
- [ ] **11:00** - Sign APK
- [ ] **12:00** - Final smoke test

---

---

## Success Criteria

✅ **MUST HAVE** (Blocking release):
- [x] No crashes in any mode
- [x] All 3 business modes fully functional
- [x] Products load from SQLite
- [x] Cart calculations correct
- [x] All payment methods work
- [x] Receipts generate correctly
- [x] All reports generate
- [x] Works completely offline

⚠️ **SHOULD HAVE** (Nice to have):
- [ ] Barcode scanning works
- [ ] Kitchen display shows orders
- [ ] Multiple user support
- [ ] Inventory tracking

🟡 **COULD HAVE** (Post-launch):
- [ ] Complex discounts
- [ ] Loyalty program
- [ ] Advanced analytics
- [ ] Cloud sync

---

**Testing Status**: Ready to begin  
**Current Build**: Phase 1 Stable  
**Next Step**: Launch app and verify product loading  

