# Phase 2 Day 1: Retail Mode Verification
## Complete Testing Checklist for Retail POS

**Date**: February 19, 2026  
**Target**: Verify retail mode works perfectly  
**Time Allocation**: 4-5 hours  
**Status**: Starting now

---

## Pre-Testing Checklist

### Environment Setup
- [x] Code changes committed
- [x] No compile errors in POS flavor
- [x] DatabaseService error handling added
- [x] POS screens null-safe
- [ ] Run `flutter pub get` 
- [ ] Run `flutter analyze` to verify no errors

### Test Data Verification
- [ ] SQLite database initialized with sample products
- [ ] 4 categories available: All, Apparel, Footwear, Accessories
- [ ] At least 10 sample products in database
- [ ] Business info configured for Retail mode

---

## Activity: Product Loading Test

### Setup: Launch Retail Mode
```
1. Run: flutter run --flavor pos
2. Wait for app to load
3. Verify: App shows UnifiedPOSScreen
4. Verify: Title shows "ExtroPOS — Retail Mode"
```

### Test Sequence: Product Grid Display

**Test 1.1: Initial Load**
- [ ] App loads within 3 seconds
- [ ] "All" category selected by default
- [ ] Product grid displays with items
- [ ] Grid is responsive (changes columns on resize)
- [ ] No console errors (check DevTools)

**Verification Steps**:
1. Launch app
2. Check console: `dart:developer` logs should show:
   ```
   DB: getCategories() returning X categories
   DB: getItems() returning Y items
   ```
3. If see errors like "Failed to load", that's OK - fallback sample data will load
4. Products should display in 2-3 seconds

**Expected Result**: ✅ Products visible in grid format

---

**Test 1.2: Category Filtering**
- [ ] "All" shows all products
- [ ] "Apparel" shows only apparel items
- [ ] "Footwear" shows only footwear items
- [ ] "Accessories" shows only accessories
- [ ] Switching categories updates grid instantly
- [ ] Selected category highlighted

**Verification Steps**:
1. Click on "Apparel" tab
2. Observe: Grid refreshes with only apparel items
3. Click on "Accessories"
4. Observe: Grid refreshes with accessories only
5. Click "All" again
6. Observe: All products return

**Expected Result**: ✅ Category filtering works smoothly

---

**Test 1.3: Responsive Layout**
- [ ] On desktop (>1200px): 4 columns
- [ ] On tablet (900-1200px): 3 columns
- [ ] On mobile (600-900px): 2 columns
- [ ] On phone (<600px): 1 column
- [ ] Grid automatically reflows on window resize

**Verification Steps**:
1. Open DevTools (F12)
2. Resize browser to 1400px wide
3. Verify: 4 columns of products
4. Resize to 1000px
5. Verify: 3 columns
6. Resize to 700px
7. Verify: 2 columns

**Expected Result**: ✅ Layout responsive without manual refresh

---

**Test 1.4: Product Display Details**
Each product card should show:
- [ ] Product image (or placeholder if missing)
- [ ] Product name
- [ ] Price in RM (Malaysian Ringgit)
- [ ] Category indicator (badge or text)
- [ ] Click-able (no errors on tap)

**Verification Steps**:
1. Inspect product card: "T-Shirt"
2. Verify all 4 details visible and correct
3. Check image: Should be placeholder if no real image
4. Check price format: RM 25.00 or similar

**Expected Result**: ✅ Product card complete and clickable

---

## Activity: Cart Operations Test

### Test 2.1: Add Single Item
- [ ] Click product: "T-Shirt"
- [ ] Item appears in cart panel
- [ ] Quantity shows: 1
- [ ] Price shows: RM 25.00
- [ ] No console errors

**Expected Result**: ✅ Item in cart with correct price

---

### Test 2.2: Add Same Item Again
- [ ] Click "T-Shirt" again
- [ ] Quantity updates to 2 (NOT 2 separate items)
- [ ] Subtotal updates to RM 50.00
- [ ] Cart shows: 2x T-Shirt @ RM 50.00

**Expected Result**: ✅ Quantity increases, not duplicated

---

### Test 2.3: Add Different Item
- [ ] Click "Jeans"
- [ ] Cart now shows 2 items:
  - 2x T-Shirt - RM 50.00
  - 1x Jeans - RM 60.00
- [ ] Subtotal: RM 110.00
- [ ] No quantity consolidation (separate line items)

**Expected Result**: ✅ Multiple items tracked correctly

---

### Test 2.4: Adjust Quantity
- [ ] On "T-Shirt" line: Click "+" button
- [ ] Quantity increases to 3
- [ ] Subtotal updates to RM 135.00
- [ ] Cart total updates immediately

**Expected Result**: ✅ Quantity adjustable in real-time

---

### Test 2.5: Remove Item
- [ ] Click trash/remove icon on "Jeans"
- [ ] Jeans removed from cart
- [ ] Only "T-Shirt" remains (qty 3)
- [ ] Subtotal: RM 75.00
- [ ] Cart count updates

**Expected Result**: ✅ Item removal works correctly

---

### Test 2.6: Clear Cart
- [ ] Click "Clear Cart" or "Reset" button (if exists)
- [ ] All items removed
- [ ] Cart shows empty state
- [ ] Subtotal: RM 0.00
- [ ] Able to add items again

**Expected Result**: ✅ Cart clears and resets

---

## Activity: Tax & Calculation Test

### Test 3.1: Subtotal Calculation
- [ ] Add: 1x Item ($30) + 1x Item ($20)
- [ ] Subtotal = $50 (Verify manually: 30 + 20 = 50)
- [ ] No errors in calculation

**Expected Result**: ✅ Subtotal correct

---

### Test 3.2: Tax Calculation (If Enabled)
Assuming Business Info has `isTaxEnabled = true` and `taxRate = 0.10` (10%)

- [ ] Subtotal: RM 100.00
- [ ] Tax (10%): RM 10.00
- [ ] Total: RM 110.00
- [ ] Tax line displays in cart summary
- [ ] Calculation: 100 × 0.10 = 10 ✓

**Expected Result**: ✅ Tax calculated correctly

---

### Test 3.3: Service Charge (If Enabled)
Assuming `isServiceChargeEnabled = true` and `serviceChargeRate = 0.06` (6%)

- [ ] Subtotal: RM 100.00
- [ ] Service Charge (6%): RM 6.00
- [ ] Tax (10%): RM 10.00
- [ ] Total: RM 116.00
- [ ] All three lines show in summary

**Expected Result**: ✅ Service charge applied correctly

---

### Test 3.4: Discount (If Supported)
- [ ] Enter discount: RM 5
- [ ] Subtotal becomes: RM 95
- [ ] Tax calculated on RM 95
- [ ] Service charge calculated on RM 95
- [ ] Final total reflects discount

**Expected Result**: ✅ Discount applied to all calculations

---

## Activity: Payment Processing Test

### Test 4.1: Cash Payment
**Scenario**: Subtotal RM 75 (with tax & service charge = RM 88)

- [ ] Click "Checkout" button
- [ ] Payment dialog opens
- [ ] Shows: 
  - Subtotal: RM 75
  - Tax: RM 7.50
  - Service Charge: RM 4.50
  - Total: RM 87.00
- [ ] Enter paid amount: RM 100
- [ ] System calculates: Change = RM 13
- [ ] Click "Complete Payment"
- [ ] Transaction succeeds

**Expected Result**: ✅ Cash payment with correct change calculation

---

### Test 4.2: Card Payment
- [ ] Click "Checkout"
- [ ] Payment dialog shows
- [ ] Select "Card" payment method
- [ ] Show card form or confirmation
- [ ] Click "Pay with Card"
- [ ] Payment processed (shows success message)
- [ ] Transaction saved

**Expected Result**: ✅ Card payment option available

---

### Test 4.3: E-Wallet Payment
- [ ] Click "Checkout"
- [ ] Select "E-Wallet" payment method
- [ ] Choose e-wallet type (if multiple)
- [ ] Process payment
- [ ] Confirmation shows

**Expected Result**: ✅ E-Wallet payment option available

---

## Activity: Receipt & Transaction Test

### Test 5.1: Receipt Generation
After successful payment:
- [ ] Receipt dialog appears
- [ ] Receipt shows:
  - Business name
  - Date & time
  - Order number
  - All items with prices
  - Subtotal, Tax, Service Charge, Total
  - Payment method
  - Change (if applicable)
- [ ] No layout issues or overflow
- [ ] Print button available (if printer connected)

**Expected Result**: ✅ Receipt complete and readable

---

### Test 5.2: Transaction Saved
After receipt:
- [ ] Cart clears automatically
- [ ] Ready for next customer
- [ ] Click "History" or "Recent Transactions"
- [ ] Transaction appears in list with:
  - Transaction number
  - Amount
  - Payment method
  - Date & time

**Expected Result**: ✅ Transaction persisted to database

---

## Activity: Reports Test

### Test 6.1: Daily Sales Report
- [ ] Go to Menu → Reports → Daily Sales
- [ ] Report shows today's data
- [ ] Displays:
  - Gross Sales: (should include today's transactions)
  - Net Sales: $X
  - Tax: $Y
  - Service Charge: $Z
  - Transaction count: 1+ (from our tests)
  - Average ticket: Total/Count

**Expected Result**: ✅ Report shows correct totals

---

### Test 6.2: Report Calculations Verification
If we made 2 transactions today:
- Transaction 1: RM 75 total
- Transaction 2: RM 120 total
- Expected Gross Total: RM 195

**Check**:
- [ ] Daily report shows RM 195
- [ ] Or shows both amounts in breakdown
- [ ] Payment method breakdown shows counts

**Expected Result**: ✅ Report calculations match transactions

---

## Error Handling Tests

### Test 7.1: Database Error Recovery
- [ ] Intentionally disconnect database (comment out _loadData)
- [ ] Should show fallback sample products
- [ ] App doesn't crash
- [ ] User can still add items and checkout

**Expected Result**: ✅ Graceful degradation

---

### Test 7.2: Image Loading Error
- [ ] Modify image URL to invalid URL
- [ ] Product still displays with placeholder image
- [ ] No broken image icons
- [ ] App continues normally

**Expected Result**: ✅ Placeholder used for missing images

---

### Test 7.3: Rapid Cart Operations
- [ ] Rapidly click same product 10x
- [ ] Quantity increases correctly to 10
- [ ] No duplication or crashes
- [ ] All clicks processed

**Expected Result**: ✅ Handles rapid input

---

## Performance Tests

### Test 8.1: Startup Time
- [ ] Cold start (first launch): < 5 seconds
- [ ] Hot start (resume): < 2 seconds
- [ ] Product load: < 3 seconds

**Measurement**:
1. Kill app completely
2. Start from scratch
3. Time from tap to products visible
4. Record time: _____ seconds

**Expected Result**: ✅ < 5 seconds cold start

---

### Test 8.2: Checkout Speed
- [ ] From "Checkout" click to payment dialog: < 1 second
- [ ] From payment completion to receipt: < 2 seconds
- [ ] No freezing or lag

**Expected Result**: ✅ Responsive checkout

---

## Test Summary Template

```
═══════════════════════════════════════════════════════════
RETAIL MODE - DAY 1 TEST RESULTS
═══════════════════════════════════════════════════════════

Date: Feb 19, 2026
Tester: [Your Name]
Build: POS Flavor (Offline)
Device: [Desktop/Mobile/Tablet]
Screen Size: [Resolution]

PRODUCT LOADING:
  ✅ Load time: ___ seconds
  ✅ Products: ___ items loaded
  ✅ Categories: Working
  ✅ Responsive: Yes/No

CART OPERATIONS:
  ✅ Add item: Working
  ✅ Adjust qty: Working  
  ✅ Remove item: Working
  ✅ Clear cart: Working
  ✅ Calculations: Correct/Incorrect

PAYMENTS:
  ✅ Cash: Working
  ✅ Card: Working
  ✅ E-wallet: Working
  ✅ Change calculated: Yes/No

RECEIPT:
  ✅ Generated: Yes/No
  ✅ Details complete: Yes/No
  ✅ Saved to DB: Yes/No

REPORTS:
  ✅ Daily report: Shows correct totals
  ✅ Math: Verified

ERRORS FOUND:
  - [Error 1]
  - [Error 2]

ISSUES TO FIX:
  - [Issue 1]
  - [Issue 2]

READY FOR CAFE MODE: Yes/No

═══════════════════════════════════════════════════════════
```

---

## Next Steps After This Test

✅ If ALL tests pass → Move to **Cafe Mode (Day 2)**  
⚠️ If issues found → Fix and re-test before moving on  
🔴 If crashes → Review Phase 1 error handling

---

**Status**: Ready to begin retail mode testing  
**Expected Duration**: 4-5 hours  
**Target Completion**: Today (Feb 19)

