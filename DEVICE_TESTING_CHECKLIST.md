# Manual Device Testing Guide - All 3 Business Modes
## FlutterPOS v1.0.27 - Android Device Testing
**Date**: February 19, 2026  
**Device**: 24075RP89G (Android 15, API 35)  
**APK**: app-posapp-release.apk (93.7 MB)  
**Status**: Ready for Manual Testing

---

## 📱 Installation & Setup

### Step 1: Install APK on Device
```bash
flutter run -d 8bab44b57d88 --flavor posApp
# OR manually install if above fails:
# Copy APK to device and tap to install
```

### Step 2: Initial App Launch
- [ ] App icon appears on home screen
- [ ] App opens without crashes
- [ ] Lock screen displays (if enabled)
- [ ] No error dialogs appear

---

## 🧪 Test Checklist - RETAIL MODE

### Business Session & Authentication
- [ ] **Lock Screen**: Appears on app launch
- [ ] **Unlock**: Successfully dismisses lock screen
- [ ] **Business Session**: Check appears (if business not open)
- [ ] **Shift Start**: Prompt appears to start shift
  - [ ] Start Shift button works
  - [ ] Opening cash amount accepted
  - [ ] Shift active indicator shows

### Main POS Screen
- [ ] Retail mode is selected (verify in Settings)
- [ ] Products display in grid
- [ ] Images load (or show placeholder)
- [ ] Product categories visible
- [ ] Cart section shows at bottom

### Adding Items to Cart
- [ ] **Tap Product 1**: Adds to cart with qty=1 ✓
  - [ ] Product name displays in cart
  - [ ] Price shows correctly
  - [ ] Quantity shows as "1"
- [ ] **Tap Product 2**: Adds to cart separately
  - [ ] Two line items show (no combining)
  - [ ] Quantities independent
- [ ] **Tap Product 1 again**: Increments quantity to 2
  - [ ] Cart shows "2x Product1" (or qty=2)
  - [ ] Total updates correctly

### Cart Operations
- [ ] **Quantity Toggle**: + button increases qty
  - [ ] + on first item increases qty
  - [ ] - button decreases qty
  - [ ] Qty won't go below 1
- [ ] **Remove Item**: Delete button removes from cart
  - [ ] Item disappears
  - [ ] Total recalculates
- [ ] **Clear Cart**: Clear button empties all items
  - [ ] All items removed
  - [ ] Cart shows empty
  - [ ] Totals reset to 0

### Calculations & Totals
**Test Order**: 2x Item($10) + 1x Item($5)  
Expected: Subtotal=$25, Tax=$2.50 (if 10% enabled), Total=$27.50

- [ ] **Subtotal**: Calculates correctly ($25)
- [ ] **Tax**: Applied if enabled
  - [ ] Tax amount displays
  - [ ] Correct percentage (10%)
  - [ ] Can toggle tax on/off in Settings
- [ ] **Service Charge**: Applied if enabled
  - [ ] Service charge displays (6% if enabled)
  - [ ] Optional toggle works
- [ ] **Discounts**: Can apply discount
  - [ ] Discount input accepts percentage
  - [ ] Total reduces by correct amount
  - [ ] Never goes negative
- [ ] **Final Total**: Sum correct
  - [ ] Subtotal + Tax + Service - Discount = Total
  - [ ] Shows 2 decimal places

### Payment Processing
**Test with order total of $27.50 (or calculated amount)**

- [ ] **Cash Payment**:
  - [ ] Enter cash amount (e.g., $50)
  - [ ] Change calculates correctly ($22.50)
  - [ ] Change displays
  - [ ] Payment succeeds
- [ ] **Card Payment**:
  - [ ] Card option selectable
  - [ ] Payment processes (doesn't need real card)
  - [ ] Success message shows
- [ ] **E-Wallet Payment**:
  - [ ] QR code generates
  - [ ] QR code displays on screen
  - [ ] Accept payment completes transaction

### Receipt Generation
- [ ] **Receipt displays** after payment
  - [ ] Business name shows
  - [ ] Items list with qty × price
  - [ ] Tax calculation shows
  - [ ] Service charge shows (if applied)
  - [ ] Total shows
  - [ ] Payment method shows
  - [ ] Change shows (if cash)
  - [ ] Date/time stamps
  - [ ] Receipt number
- [ ] **Print Button** (if printer connected)
  - [ ] Sends to printer
  - [ ] Receipt prints correctly

### Transaction Completion
- [ ] **Back to Cart**: Returns to empty POS screen
- [ ] **New Transaction**: Can immediately add new items
- [ ] **Transaction Saved**: (Verify in reports later)

---

## ☕ Test Checklist - CAFE MODE

### Mode Switch
- [ ] **Settings → Business Mode**: Switch to Cafe
  - [ ] Mode changes
  - [ ] App refreshes to Cafe view
  - [ ] Returns to Cafe POS screen

### Cafe-Specific UI
- [ ] **Order Queue**: Visible
- [ ] **Modifiers Panel**: Shows for items (if applicable)
- [ ] **Status Buttons**: "Calling Order" and "Ready" visible
- [ ] **Call/Ready Indicators**: Color-coded display

### Taking an Order
- [ ] **Add Item**: Select a product
- [ ] **Add Modifier**: 
  - [ ] Modifier options appear (if item has them)
  - [ ] Select modifier (e.g., hot/iced, extra shot)
  - [ ] Modifier reflects in order
- [ ] **Item with Modifier**: Shows in queue
  - [ ] Format: "Item - Modifier"
  - [ ] Quantity shows
  - [ ] Price includes modifier upcharge (if applicable)

### Queue Management
- [ ] **Call Order**: Click "Calling Order" button
  - [ ] Order marked as "Calling"
  - [ ] Visual indicator (color change/animation)
  - [ ] Kitchen/staff can see status
- [ ] **Ready**: Click "Ready" button  
  - [ ] Order marked as "Ready"
  - [ ] Status updates visually
  - [ ] Notification to customer (if integrated)
- [ ] **Completed**: Remove order from queue
  - [ ] Order disappears
  - [ ] Next order visible

### Calculations
- [ ] **Multiple Items**: Add 3 different items
  - [ ] Each shows in queue with qty
  - [ ] Subtotal aggregates correctly
  - [ ] Modifiers add to price
- [ ] **Tax/Service**: Applied to cafe order
  - [ ] Same calculation as retail
  - [ ] Displays correctly

### Checkout & Payment (Cafe)
- [ ] **Complete Order**: Move to checkout
- [ ] **Show Total**: All items + modifiers calculated
- [ ] **Payment Options**: Same as retail
  - [ ] Cash, Card, E-Wallet work
  - [ ] Change calculates for cash
- [ ] **Receipt**: Shows all mods in items
  - [ ] Format readable
  - [ ] Modifiers clearly listed

---

## 🍽️ Test Checklist - RESTAURANT MODE

### Mode Switch
- [ ] **Settings → Business Mode**: Switch to Restaurant
  - [ ] Mode changes successfully
  - [ ] App shows Table Grid view

### Table Grid Display
- [ ] **Table Grid**: Shows all tables
  - [ ] Tables arranged in grid (2-4 columns depending on screen)
  - [ ] Table numbers visible (1-20 or configured count)
  - [ ] **Table Status Colors**:
    - [ ] Green = Available (empty)
    - [ ] Red = Occupied
    - [ ] Yellow/Orange = Reserved
  - [ ] **Occupancy**: Shows number of customers at table

### Selecting & Ordering at Table
- [ ] **Tap Table 1**: Selects table
  - [ ] Selection visual (highlight or border)
  - [ ] Opens POS cart for that table
  - [ ] Table number displays in cart header
- [ ] **Add Item**: Select product
  - [ ] Item added to Table 1's cart
  - [ ] Quantity controlswork
  - [ ] Modifiers available (if applicable)
- [ ] **Place Order**: Order stays on table
  - [ ] Can continue adding to same table
  - [ ] Or complete and proceed to payment

### Multiple Tables
- [ ] **Switch to Table 2**: Select different table
  - [ ] Cart switches to Table 2
  - [ ] Table 1's items still saved
  - [ ] Table 1 shows as Occupied
- [ ] **Add to Table 2**: Different items
  - [ ] Separate from Table 1
  - [ ] Both orders tracked independently
- [ ] **Back to Table 1**: 
  - [ ] Previous items still there
  - [ ] No cross-contamination

### Table Operations

#### Merge Tables
- [ ] **Add items to Table 1**: 2 items, subtotal $20
- [ ] **Add items to Table 2**: 1 item, subtotal $10
- [ ] **Merge Tables Button**: (If available)
  - [ ] Combines orders
  - [ ] Subtotal = $30
  - [ ] Can then checkout together

#### Split Bill
- [ ] **Items in Table 1**: Add 3 items
  - [ ] Item A: $10
  - [ ] Item B: $8
  - [ ] Item C: $7
  - [ ] Total: $25
- [ ] **Split Option**: Select "Split Bill"
  - [ ] Choose split method:
    - [ ] By Item (each person pays for their items)
    - [ ] By Percentage (40/60 split)
    - [ ] By Amount (Person 1: $15, Person 2: $10)
  - [ ] Split calculated correctly
  - [ ] Each portion shows
- [ ] **Multiple Bills**: Complete
  - [ ] Bill 1 processes
  - [ ] Bill 2 processes
  - [ ] Table clears

#### Table Persistence
- [ ] **Disconnect/Reconnect**: (If testing quick logout)
  - [ ] Table data persists
  - [ ] Orders recovered
  - [ ] No loss of data

### Table Status Updates
- [ ] **Table 3 Status**: Add items, then incomplete
  - [ ] Shows as Occupied while orders pending
  - [ ] When cleared/checked out, returns to Available
  - [ ] Color changes appropriately

### Calculations (Restaurant)
- [ ] **Multiple Tables Ordered**: 
  - [ ] Each calculates independently
  - [ ] Tax applied per bill
  - [ ] Service charge applied per bill
- [ ] **Merged Order**: 
  - [ ] Combined subtotal correct
  - [ ] Tax on full amount
  - [ ] Service charge on full amount

### Checkout (Restaurant)
- [ ] **Single Bill**: 
  - [ ] Shows all items for table
  - [ ] Total correct
  - [ ] Payment processes
  - [ ] Receipt shows table number
- [ ] **Split Bills**:
  - [ ] Each bill shows portion
  - [ ] Each payment processes separately
  - [ ] Each receipt clear about split

---

## 🔧 Core Features (Test All Modes)

### Settings Menu
- [ ] **Access Settings**: Menu button → Settings
- [ ] **Business Mode**: Can switch between retail/cafe/restaurant
- [ ] **Tax Settings**: 
  - [ ] Enable/disable tax
  - [ ] Adjust tax percentage
- [ ] **Service Charge Settings**:
  - [ ] Enable/disable service charge
  - [ ] Adjust service charge percentage
- [ ] **Business Info**:
  - [ ] Business name displays on receipts
  - [ ] Address displays
  - [ ] Phone displays
- [ ] **Currency**: Shows correct symbol (RM)

### Reports (If Accessible)
- [ ] **Daily Sales**: Shows transactions from today
- [ ] **Transactions List**: Can view all completed sales
- [ ] **Revenue Totals**: Sums calculate correctly

### Shift Management
- [ ] **Start Shift**: Opening cash entry
- [ ] **End Shift**: Closing balance entry
- [ ] **Shift Totals**: Displays cash in/out

### User Session
- [ ] **Current Cashier**: Shows in header or menu
- [ ] **Sign Out**: Clears session
- [ ] **Sign In**: Requires credentials

---

## 🐛 Crash & Stability Tests

### No Crashes On:
- [ ] **Rapid Tapping**: Add/remove items quickly
- [ ] **Large Orders**: 20+ items
- [ ] **Quick Mode Switch**: Retail → Cafe → Restaurant → Retail
- [ ] **Lock/Unlock**: Screen turns off and back on
- [ ] **Background/Foreground**: Switch to another app and back
- [ ] **Long Session**: Leave app open for 5+ minutes with idle

### Performance Checks:
- [ ] **Loading**: Products load within 2 seconds
- [ ] **Calculations**: Totals update instantly
- [ ] **Transitions**: Screen changes smooth (no jank)
- [ ] **Memory**: App doesn't slow down

---

## 📋 Test Results

### Retail Mode Summary
- **Status**: [ ] PASS [ ] FAIL
- **Issues Found**: 
  ```
  (List any crashes, calc errors, UI issues)
  ```

### Cafe Mode Summary
- **Status**: [ ] PASS [ ] FAIL
- **Issues Found**:
  ```
  (List any issues)
  ```

### Restaurant Mode Summary
- **Status**: [ ] PASS [ ] FAIL
- **Issues Found**:
  ```
  (List any issues)
  ```

### Overall Device Test
- **Overall Status**: [ ] PASS [ ] FAIL
- **Confidence Level**: [ ] HIGH [ ] MEDIUM [ ] LOW
- **Ready for Release**: [ ] YES [ ] NO (pending fixes)

---

## 🎯 Success Criteria

### All Modes Must:
✅ Launch without crashes  
✅ Add/remove items  
✅ Calculate totals correctly (with tax/service)  
✅ Process payment  
✅ Generate receipt  
✅ Handle mode switching  
✅ Complete transactions  

### Cafe Must Also:
✅ Show order queue  
✅ Handle modifiers  
✅ Call/Ready status  

### Restaurant Must Also:
✅ Show table grid  
✅ Track multiple table orders  
✅ Merge/split orders  
✅ Manage table status  

---

## 📝 Notes

**Test Duration**: ~45 minutes for comprehensive coverage  
**Test Device**: 24075RP89G (Android 15)  
**APK Version**: 1.0.27  
**Tester**: [Your Name]  

If any issues found during testing, document them with:
- [ ] Description of issue
- [ ] Steps to reproduce
- [ ] Expected vs. actual behavior
- [ ] Device state (Retail/Cafe/Restaurant)
- [ ] Screenshot if possible

---

**Good luck with testing! 🚀**

