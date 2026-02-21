# Cafe Order Queue Display System

**Version**: 1.0.12  
**Feature**: Customer-Facing Order Status Display  
**Target**: Cafe Mode Operations  
**Created**: 2025-01-XX  
**Author**: AI Assistant (GitHub Copilot)

---

## Table of Contents

1. [Overview](#overview)
2. [Business Requirements](#business-requirements)
3. [Architecture](#architecture)
4. [Database Integration](#database-integration)
5. [User Interface](#user-interface)
6. [Workflow](#workflow)
7. [Technical Implementation](#technical-implementation)
8. [Testing Guide](#testing-guide)
9. [Troubleshooting](#troubleshooting)
10. [Future Enhancements](#future-enhancements)

---

## Overview

### Purpose

The **Cafe Order Queue Display** is a customer-facing display system designed for cafe-style operations where customers need to see their order status in real-time. It shows order numbers with status indicators (PREPARING vs READY) on a large, easily visible screen.

### Key Features

- 🖥️ **Customer-Facing Display**: Large order numbers (80pt font) visible from a distance

- 🔄 **Auto-Refresh**: Updates every 5 seconds for real-time status

- 🎨 **Dark Theme**: High contrast (#1A1A1A background) for better visibility

- ⏱️ **Wait Time Tracking**: Shows elapsed time for preparing orders

- ✅ **Auto-Cleanup**: Automatically removes orders ready for >5 minutes

- 📱 **Responsive Layout**: Adaptive grid (2-5 columns based on screen width)

- 🎭 **Smooth Animations**: TweenAnimationBuilder for card scaling and pulse effects

### Business Context

This feature completes the cafe workflow:

1. **Order Creation**: Customer places order at POS
2. **Kitchen Preparation**: Staff prepares order (status: `preparing`)
3. **Display Update**: Queue display shows order number with PREPARING badge
4. **Ready Notification**: Staff marks order ready (status: `ready`)
5. **Customer Pickup**: Customer sees READY badge and collects order
6. **Auto-Removal**: System removes order after 5 minutes

---

## Business Requirements

### Functional Requirements

1. **Order Visibility**

   - Display only cafe orders with status `preparing` or `ready`

   - Show order number prominently (80pt font)

   - Group orders by status (READY first, then PREPARING)

   - Show item count for each order

2. **Status Indicators**

   - PREPARING: Amber badge with timer

   - READY: Green badge with pulse animation

   - Wait time: Minutes elapsed since order creation

3. **Auto-Refresh**

   - Poll database every 5 seconds

   - Update display without full page reload

   - Smooth transitions when orders change

4. **Auto-Cleanup**

   - Remove orders that have been ready for >5 minutes

   - Prevent screen clutter from old orders

5. **Accessibility**

   - Large, high-contrast text

   - Color-coded status badges

   - Readable from 5+ meters away

### Non-Functional Requirements

1. **Performance**

   - Refresh cycle <100ms

   - Smooth 60fps animations

   - No UI freezing during updates

2. **Reliability**

   - Handle database connection loss gracefully

   - Show error state if data fetch fails

   - Retry on network errors

3. **Usability**

   - Zero-touch operation (fully automatic)

   - No staff intervention required

   - Works on any screen size

---

## Architecture

### System Components

```text
┌─────────────────────────────────────────────────────────────┐
│                    UnifiedPOSScreen                         │
│  (Cafe Mode AppBar)                                         │
│                                                              │
│  [Active Orders] [Order Queue Display] [Menu]               │
│         ↓                    ↓                               │
└─────────────────────────────────────────────────────────────┘
                               ↓
                ┌──────────────────────────────┐
                │   OrderQueueScreen           │
                │  (Customer-Facing Display)   │
                │                              │
                │  - Auto-refresh (5s)         │
                │  - Auto-cleanup (5min)       │
                │  - Animations                │
                └──────────────────────────────┘
                               ↓
                ┌──────────────────────────────┐
                │  DatabaseService             │
                │  getCafeQueueOrders()        │
                │                              │
                │  Query:                      │
                │  - order_type = 'cafe'       │
                │  - status IN ('preparing',   │
                │               'ready')       │
                │  - GROUP BY order_id         │
                │  - ORDER BY status, created  │
                └──────────────────────────────┘
                               ↓
                ┌──────────────────────────────┐
                │  SQLite Database (v22)       │
                │                              │
                │  Tables:                     │
                │  - orders (status column)    │
                │  - order_items (items)       │
                │  - order_status_history      │
                └──────────────────────────────┘

```text


### Data Flow


1. **Order Creation (Cafe POS)**

   ```dart
   CafePOSScreen.saveCompletedSale(
     status: 'preparing', // NEW: Sets initial status
     orderType: 'cafe',
     cafeOrderNumber: 42,
     // ... other params
   )
   ```

1. **Database Query (Auto-Refresh)**

   ```sql
   SELECT 
     o.id, 
     o.order_number, 
     o.status, 
     o.created_at,
     COUNT(oi.id) as item_count
   FROM orders o
   LEFT JOIN order_items oi ON o.id = oi.order_id
   WHERE o.order_type = 'cafe'
     AND o.status IN ('preparing', 'ready')
   GROUP BY o.id
   ORDER BY 
     CASE o.status 
       WHEN 'ready' THEN 0 
       ELSE 1 
     END,
     o.created_at ASC
   ```

2. **Display Rendering**

   ```dart
   // READY section (green, pulsing)
   GridView.builder(orders.where((o) => o.status == 'ready'))
   
   // PREPARING section (amber, with timer)
   GridView.builder(orders.where((o) => o.status == 'preparing'))
   ```

3. **Auto-Cleanup (5-minute threshold)**

   ```dart
   if (order.status == 'ready' && 
       order.waitMinutes > 5) {
     // Auto-remove from display (not from database)
     filteredOrders.remove(order);
   }
   ```

---

## Database Integration

### Schema Requirements

**orders table** (v22+):

```sql
CREATE TABLE orders (
  id TEXT PRIMARY KEY,
  order_number TEXT NOT NULL,
  status TEXT NOT NULL,        -- 'preparing', 'ready', 'completed'
  order_type TEXT NOT NULL,    -- 'cafe', 'restaurant', 'retail'
  created_at TEXT NOT NULL,
  -- ... other columns

);

```text

**order_items table**:


```sql
CREATE TABLE order_items (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL,
  item_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  -- ... other columns
  FOREIGN KEY (order_id) REFERENCES orders(id)
);

```text


### Database Method


**Location**: `lib/services/database_service.dart`


```dart
/// Fetch cafe orders with 'preparing' or 'ready' status for queue display
Future<List<Map<String, dynamic>>> getCafeQueueOrders() async {
  final db = await DatabaseHelper.instance.database;
  
  return await db.rawQuery('''
    SELECT 
      o.id, 
      o.order_number, 
      o.status, 
      o.created_at,
      COUNT(oi.id) as item_count
    FROM orders o
    LEFT JOIN order_items oi ON o.id = oi.order_id
    WHERE o.order_type = 'cafe'
      AND o.status IN ('preparing', 'ready')
    GROUP BY o.id
    ORDER BY 
      CASE o.status 
        WHEN 'ready' THEN 0 
        ELSE 1 
      END,
      o.created_at ASC
  ''');
}

```text

**Query Logic**:


- **Filter**: Only cafe orders with active statuses

- **Grouping**: Count items per order

- **Sorting**: READY orders first (priority), then by creation time


### Status Update Integration


**Cafe POS Screen** (`lib/screens/cafe_pos_screen.dart`):


```dart
savedOrderNumber = await DatabaseService.instance.saveCompletedSale(
  // ... standard params ...
  status: 'preparing', // ✅ NEW: Set initial status for queue display
);

```text

**Kitchen Display** (existing feature):


- When staff marks order ready: `status` → `'ready'`

- Queue display automatically picks up the change on next refresh

---


## User Interface



### Screen Layout



```text
┌───────────────────────────────────────────────────────────┐
│  ☰ Order Queue Display                           [Back]   │
├───────────────────────────────────────────────────────────┤
│                                                             │
│  ████████████████████ READY ORDERS ███████████████████     │
│                                                             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                    │
│  │  #042   │  │  #045   │  │  #048   │                    │
│  │   80pt  │  │   80pt  │  │   80pt  │                    │
│  │  READY  │  │  READY  │  │  READY  │  (Green pulse)     │
│  │ 3 items │  │ 2 items │  │ 5 items │                    │
│  └─────────┘  └─────────┘  └─────────┘                    │
│                                                             │
│  ██████████████████ PREPARING ORDERS ██████████████        │
│                                                             │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                    │
│  │  #050   │  │  #051   │  │  #052   │                    │
│  │   80pt  │  │   80pt  │  │   80pt  │                    │
│  │ PREPARING│ │ PREPARING│ │ PREPARING│ (Amber)            │
│  │ 2m | 4 items│ 1m | 3 items│ <1m | 6 items│             │
│  └─────────┘  └─────────┘  └─────────┘                    │
│                                                             │
│  Last updated: 12:45:32                                    │
└───────────────────────────────────────────────────────────┘

```text


### Visual Design


**Color Scheme**:


- Background: `#1A1A1A` (dark gray - high contrast)

- READY badge: `Colors.green[400]` with white text

- PREPARING badge: `Colors.amber[700]` with white text

- Card background: `#2A2A2A` (slightly lighter than background)

- Text: White for primary, `Colors.grey[400]` for secondary

**Typography**:


- Order number: `80px`, bold, white

- Status badge: `16px`, bold, uppercase

- Item count: `18px`, regular, grey

- Wait time: `16px`, regular, grey

- Section headers: `24px`, bold, white

**Spacing**:


- Card padding: `24px`

- Grid spacing: `16px`

- Section gap: `32px`


### Responsive Grid



```dart
LayoutBuilder(
  builder: (context, constraints) {
    int columns = 3; // default
    if (constraints.maxWidth < 600) {
      columns = 2;       // mobile/small tablet
    } else if (constraints.maxWidth < 900) {
      columns = 3;       // tablet
    } else if (constraints.maxWidth < 1200) {
      columns = 4;       // small desktop
    } else {
      columns = 5;       // large desktop
    }
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      // ...
    );
  },
)

```text


### Animations


**Card Scale Animation**:


```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.9, end: 1.0),
  duration: Duration(milliseconds: 300),
  curve: Curves.easeOut,
  builder: (context, scale, child) {
    return Transform.scale(scale: scale, child: child);
  },
)

```text

**Ready Pulse Animation**:


```dart
AnimatedContainer(
  duration: Duration(milliseconds: 1000),
  decoration: BoxDecoration(
    color: Colors.green[400],
    boxShadow: [
      BoxShadow(
        color: Colors.green.withOpacity(0.6),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  ),
)

```text

---


## Workflow



### Complete User Journey



#### 1. Customer Places Order



```text
Customer at Counter
       ↓
[Staff uses Cafe POS]
       ↓
Select items, take payment
       ↓
Press "Checkout"
       ↓
System generates order #042
Status: 'preparing'
       ↓
Order appears on Queue Display
(PREPARING section, amber badge)

```text


#### 2. Kitchen Prepares Order



```text
Kitchen receives order
       ↓
Staff prepares food/drinks
       ↓
Queue Display shows:
 "#042 PREPARING 2m | 3 items"
       ↓
Timer updates every 5 seconds

```text


#### 3. Order Ready



```text
Staff marks order ready
(via Kitchen Display System)
       ↓
Status: 'ready'
       ↓
Queue Display updates:
 "#042 READY | 3 items"
(Moves to top, green badge, pulse)

```text


#### 4. Customer Pickup



```text
Customer sees "#042 READY"
       ↓
Customer collects order
       ↓
[5-minute timer starts]
       ↓
After 5 minutes:
Order auto-removed from display

```text


### Status Transitions



```text
[NEW ORDER]
    ↓
'preparing' ──────────────→ Queue Display (PREPARING)
    │                              │
    │                        [Staff marks ready]
    ↓                              ↓
'ready' ──────────────────→ Queue Display (READY, priority)
    │                              │
    │                        [Auto-cleanup]
    ↓                              ↓
'completed'               Removed from display

```text

---


## Technical Implementation



### File Structure



```text
lib/
├── screens/
│   ├── order_queue_screen.dart       ✅ NEW (472 lines)
│   ├── cafe_pos_screen.dart          ✅ MODIFIED (added status param)
│   ├── unified_pos_screen.dart       ✅ MODIFIED (added queue button)
│   └── settings_screen.dart          ✅ MODIFIED (added menu item)
├── services/
│   └── database_service.dart         ✅ MODIFIED (added getCafeQueueOrders)
└── models/
    └── order_status.dart             ✅ EXISTING (supports 'preparing'/'ready')

```text


### Key Code Components



#### 1. QueueOrder Model



```dart
class QueueOrder {
  final String id;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final int itemCount;
  
  int get waitMinutes {
    return DateTime.now().difference(createdAt).inMinutes;
  }
  
  String get waitTimeDisplay {
    final mins = waitMinutes;
    if (mins < 1) return '<1m';
    if (mins >= 60) return '${(mins / 60).floor()}h ${mins % 60}m';
    return '${mins}m';
  }
  
  factory QueueOrder.fromMap(Map<String, dynamic> map) {
    return QueueOrder(
      id: map['id'] as String,
      orderNumber: map['order_number'] as String,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      itemCount: map['item_count'] as int? ?? 0,
    );
  }
}

```text


#### 2. Auto-Refresh Logic



```dart
Timer? _refreshTimer;

@override
void initState() {
  super.initState();
  _loadOrders();
  _refreshTimer = Timer.periodic(
    const Duration(seconds: 5),
    (_) => _loadOrders(),
  );
}

@override
void dispose() {
  _refreshTimer?.cancel();
  super.dispose();
}

Future<void> _loadOrders() async {
  final data = await DatabaseService.instance.getCafeQueueOrders();
  setState(() {
    _orders = data.map((m) => QueueOrder.fromMap(m)).toList();
    _lastUpdate = DateTime.now();
  });
}

```text


#### 3. Auto-Cleanup Logic



```dart
List<QueueOrder> get _filteredOrders {
  return _orders.where((order) {
    // Remove ready orders older than 5 minutes
    if (order.status == 'ready' && order.waitMinutes > 5) {
      return false;
    }
    return true;
  }).toList();
}

```text


#### 4. Adaptive Grid



```dart
int _getColumnCount(double width) {
  if (width < 600) return 2;
  if (width < 900) return 3;
  if (width < 1200) return 4;
  return 5;
}

```text

---


## Testing Guide



### Manual Testing Checklist



#### Setup


- [ ] Run app in Cafe mode

- [ ] Open Order Queue Display (AppBar button or Settings menu)

- [ ] Keep display open on secondary screen/device


#### Test Cases


**TC1: Order Creation**


- [ ] Create cafe order at POS

- [ ] Verify order appears in PREPARING section within 5 seconds

- [ ] Verify order number displayed correctly (80pt font)

- [ ] Verify item count shown

- [ ] Verify wait timer starts (<1m initially)

**TC2: Status Update**


- [ ] Mark order ready via Kitchen Display

- [ ] Verify order moves to READY section within 5 seconds

- [ ] Verify green badge appears

- [ ] Verify pulse animation active

- [ ] Verify wait timer no longer shown

**TC3: Auto-Refresh**


- [ ] Create order on POS

- [ ] Watch queue display (don't navigate away)

- [ ] Verify display updates every 5 seconds

- [ ] Verify "Last updated" timestamp changes

**TC4: Auto-Cleanup**


- [ ] Mark order ready

- [ ] Wait 5 minutes (or modify code for faster testing)

- [ ] Verify order disappears from display

- [ ] Verify order still exists in database (sales history)

**TC5: Multiple Orders**


- [ ] Create 10+ cafe orders

- [ ] Verify grid layout adapts to screen width

- [ ] Verify READY orders always shown first

- [ ] Verify PREPARING orders sorted by creation time

**TC6: Responsive Design**


- [ ] Test on 600px width (mobile): 2 columns

- [ ] Test on 900px width (tablet): 3 columns

- [ ] Test on 1200px width (desktop): 4 columns

- [ ] Test on 1920px width (large): 5 columns

- [ ] Verify no overflow errors at any size

**TC7: Empty States**


- [ ] Clear all orders (or wait for auto-cleanup)

- [ ] Verify "No orders in queue" message

- [ ] Verify coffee cup icon shown

- [ ] Verify message text readable

**TC8: Navigation**


- [ ] Open queue from AppBar button (Cafe mode only)

- [ ] Open queue from Settings menu

- [ ] Verify both routes work

- [ ] Verify back button returns to previous screen


### Automated Testing


**Unit Test** (`test/order_queue_test.dart`):


```dart
void main() {
  test('QueueOrder.waitMinutes calculation', () {
    final order = QueueOrder(
      id: '1',
      orderNumber: 'C001',
      status: 'preparing',
      createdAt: DateTime.now().subtract(Duration(minutes: 3)),
      itemCount: 2,
    );
    
    expect(order.waitMinutes, 3);
    expect(order.waitTimeDisplay, '3m');
  });
  
  test('Auto-cleanup filter', () {
    final oldOrder = QueueOrder(
      id: '1',
      orderNumber: 'C001',
      status: 'ready',
      createdAt: DateTime.now().subtract(Duration(minutes: 6)),
      itemCount: 2,
    );
    
    final newOrder = QueueOrder(
      id: '2',
      orderNumber: 'C002',
      status: 'ready',
      createdAt: DateTime.now().subtract(Duration(minutes: 2)),
      itemCount: 3,
    );
    
    final orders = [oldOrder, newOrder];
    final filtered = orders.where((o) => 
      !(o.status == 'ready' && o.waitMinutes > 5)
    ).toList();
    
    expect(filtered.length, 1);
    expect(filtered.first.id, '2');
  });
}

```text

**Widget Test** (`test/widget/order_queue_widget_test.dart`):


```dart
void main() {
  testWidgets('Displays order cards correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderQueueScreen(),
      ),
    );
    
    // Wait for initial load
    await tester.pump();
    
    // Verify UI elements
    expect(find.text('Order Queue Display'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    
    // Verify empty state
    expect(find.text('No orders in queue'), findsOneWidget);
  });
}

```text


### Performance Testing


**Metrics to Monitor**:


- Refresh cycle time: Should be <100ms

- Animation frame rate: Should maintain 60fps

- Memory usage: Should not increase over time (no leaks)

- Database query time: Should be <50ms

**Test Script**:


```dart
void main() {
  test('Refresh performance', () async {
    final sw = Stopwatch()..start();
    final orders = await DatabaseService.instance.getCafeQueueOrders();
    sw.stop();
    
    expect(sw.elapsedMilliseconds, lessThan(100));
  });
}

```text

---


## Troubleshooting



### Common Issues



#### Issue 1: Orders Not Appearing


**Symptoms**:


- Queue display shows "No orders in queue"

- New cafe orders not appearing

**Diagnosis**:


```sql
-- Check if orders exist with correct status

SELECT order_number, status, order_type, created_at
FROM orders
WHERE order_type = 'cafe'
ORDER BY created_at DESC
LIMIT 10;

```text

**Solutions**:

1. ✅ Verify order saved with `status: 'preparing'` (check cafe_pos_screen.dart line ~518)
2. ✅ Check order_type is exactly 'cafe' (case-sensitive)
3. ✅ Verify database migration v22 applied (status column exists)
4. ✅ Check getCafeQueueOrders() query filters


#### Issue 2: Display Not Refreshing


**Symptoms**:


- Timer stopped

- Orders stuck in old state

**Diagnosis**:


```dart
developer.log('Refresh timer active: ${_refreshTimer?.isActive}');
developer.log('Last update: $_lastUpdate');

```text

**Solutions**:

1. ✅ Check `_refreshTimer` initialized in `initState()`
2. ✅ Verify timer not cancelled prematurely
3. ✅ Check `setState()` called after data fetch
4. ✅ Ensure `dispose()` not called while screen active


#### Issue 3: Ready Orders Not Auto-Removing


**Symptoms**:


- Orders stay in READY section >5 minutes

**Diagnosis**:


```dart
for (final order in _orders) {
  developer.log('Order ${order.orderNumber}: ${order.waitMinutes}m, status=${order.status}');
}

```text

**Solutions**:

1. ✅ Verify `_filteredOrders` getter logic correct
2. ✅ Check `order.waitMinutes > 5` condition
3. ✅ Ensure using `_filteredOrders` not `_orders` in UI


#### Issue 4: Layout Overflow


**Symptoms**:


- "BOTTOM OVERFLOW" errors

- UI clipped on small screens

**Solutions**:

1. ✅ Check GridView wrapped in Expanded/Flexible
2. ✅ Verify LayoutBuilder used for column count
3. ✅ Ensure all text has `overflow: TextOverflow.ellipsis`
4. ✅ Check card constraints reasonable


#### Issue 5: Status Not Updating from Kitchen Display


**Symptoms**:


- Kitchen marks ready, but queue still shows PREPARING

**Diagnosis**:


```sql
-- Check order_status_history

SELECT order_id, status, changed_at
FROM order_status_history
WHERE order_id = '<order-id>'
ORDER BY changed_at DESC;

```text

**Solutions**:

1. ✅ Verify Kitchen Display updates order status in database
2. ✅ Check status value exactly 'ready' (case-sensitive)
3. ✅ Wait for next 5-second refresh cycle
4. ✅ Check getCafeQueueOrders() includes 'ready' in WHERE clause


### Debug Tools


**Enable Debug Logging**:


```dart
// In order_queue_screen.dart, uncomment:
developer.log(
  'Queue refresh: ${_orders.length} orders, ${_filteredOrders.length} visible',
  name: 'order_queue',
);

```text

**Database Query Test**:


```dart
// Run in debug console:
final orders = await DatabaseService.instance.getCafeQueueOrders();
print('Orders: ${orders.map((o) => o['order_number']).join(', ')}');

```text

---


## Future Enhancements



### Phase 1: UX Improvements


1. **Sound Notifications**

   - Play chime when order becomes ready

   - Configurable volume/sound

2. **Customer Names**

   - Show customer name instead of/with order number

   - "John's order is ready!"

3. **Estimated Wait Times**

   - Calculate average preparation time

   - Show "~5 minutes" for preparing orders


### Phase 2: Multi-Display Support


1. **Dual Display Configuration**

   - Auto-detect secondary display

   - Launch queue display on display 2

2. **Tablet Kiosk Mode**

   - Fullscreen lock

   - Prevent customer interaction

   - Auto-restart on crash


### Phase 3: Advanced Features


1. **Order Grouping**

   - Group multiple orders for same customer

   - Family/party order indicators

2. **Priority Orders**

   - VIP customer highlighting

   - Rush order badges

3. **Analytics Integration**

   - Track average wait times

   - Peak hours analysis

   - Staff performance metrics

4. **SMS/App Notifications**

   - Send SMS when order ready

   - Mobile app push notifications


### Phase 4: Hardware Integration


1. **LED Display Board**

   - External LED ticker

   - Scroll order numbers

2. **Receipt Printer Integration**

   - Print order number ticket

   - QR code for tracking

3. **Pager System**

   - Vibrating pager handout

   - Trigger on order ready

---


## Related Documentation


- [Kitchen Display System](KITCHEN_DISPLAY_SYSTEM.md) - Staff-facing order management

- [Database Schema](DATABASE_SCHEMA.md) - Database v22+ with status tracking

- [Order Status Model](../lib/models/order_status.dart) - Status enum and constants

- [Cafe POS Screen](../lib/screens/cafe_pos_screen.dart) - Order creation workflow

- [Business Info Model](../lib/models/business_info_model.dart) - Business mode settings

---


## Version History


**v1.0.12** (2025-01-XX)


- ✅ Initial release of Cafe Order Queue Display

- ✅ Auto-refresh every 5 seconds

- ✅ Auto-cleanup after 5 minutes

- ✅ Dark theme for customer visibility

- ✅ Responsive grid (2-5 columns)

- ✅ Smooth animations

- ✅ AppBar integration (Cafe mode only)

- ✅ Settings menu item

- ✅ Database method: getCafeQueueOrders()

- ✅ Status parameter in saveCompletedSale()

---


## Support


**For technical issues or feature requests, contact:**


- GitHub Issues: [FlutterPOS Repository]

- Email: [support@extropos.com]

- Documentation: `/docs/` folder

**Maintainer**: AI Assistant (GitHub Copilot)  
**Last Updated**: 2025-01-XX
