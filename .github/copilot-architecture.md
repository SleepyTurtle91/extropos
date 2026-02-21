# FlutterPOS Architecture Details

## Product Flavors Architecture

### Four-Flavor System

FlutterPOS consists of four distinct product flavors, each serving specific users:

#### 1. POS Flavor (Main App)

- **Entry Point**: `lib/main.dart`

- **Package**: `com.extrotarget.extropos.pos`

- **Home Screen**: `lib/screens/unified_pos_screen.dart` (UnifiedPOSScreen)

- **Users**: Cashiers, waitstaff, counter staff

- **Features**:

  - Order taking (Retail, Cafe, Restaurant modes)

  - Payment processing

  - Receipt printing

  - Customer display (dual display support)

  - Table management

  - Reports and analytics

  - Google Drive backup

#### 2. KDS Flavor (Kitchen Display)

- **Entry Point**: `lib/main_kds.dart`

- **Package**: `com.extrotarget.extropos.kds`

- **Users**: Kitchen staff, cooks

- **Features**:

  - Real-time order display

  - Order status management

  - Preparation timers

  - Kitchen-optimized UI

  - Large text for readability

#### 3. Backend Flavor (Management)

- **Entry Point**: `lib/main_backend.dart`

- **Package**: `com.extrotarget.extropos.backend`

- **Home Screen**: `lib/screens/backend_home_screen.dart`

- **Users**: Restaurant owners, managers

- **Features**:

  - Categories management (remote)

  - Products management (remote)

  - Modifiers management (remote)

  - Business information configuration

  - Advanced reports viewing

  - Google Drive sync

  - Desktop-friendly resizable window (1200x800)

  - No order taking or payment processing

#### 4. KeyGen Flavor (License Generator)

- **Entry Point**: `lib/main_keygen.dart`

- **Package**: `com.extrotarget.extropos.keygen`

- **Home Screen**: `lib/screens/keygen_home_screen.dart`

- **Users**: System administrators, sales team

- **Features**:

  - Generate 1-month trial keys (30 days)

  - Generate 3-month trial keys (90 days)

  - Generate lifetime license keys

  - Validate license keys

  - Batch generation (1-100 keys)

  - Offline operation (no internet required)

  - Desktop-friendly resizable window (900x700)

  - No activation required for generator itself

### Build Commands

```bash

# Build individual flavors

./build_flavors.sh pos release      # POS only

./build_flavors.sh kds release      # KDS only

./build_flavors.sh backend release  # Backend only

./build_flavors.sh keygen release   # Key Generator only



# Build all flavors at once

./build_flavors.sh all release


# Debug builds

./build_flavors.sh pos debug
./build_flavors.sh backend debug
./build_flavors.sh keygen debug

```

### APK Output Locations

```text
build/app/outputs/flutter-apk/
├── app-posapp-release.apk         # POS flavor (~85MB)
├── app-kdsapp-release.apk         # KDS flavor (~80MB)
├── app-backendapp-release.apk     # Backend flavor (~85MB)
└── app-keygenapp-release.apk      # KeyGen flavor (~85MB)
```

**Note**: All flavors can coexist on the same device.

---

## Business Mode Architecture (POS Flavor only)

```text
UnifiedPOSScreen (Root)
├── BusinessMode.retail → RetailPOSScreenModern
│   └── Direct checkout with cart
├── BusinessMode.cafe → CafePOSScreen
│   └── Order numbers + active orders modal

└── BusinessMode.restaurant → TableSelectionScreen
    └── POSOrderScreen (per-table)
```

### Business Mode Logic (`lib/models/business_mode.dart`)

```dart
enum BusinessMode { retail, cafe, restaurant }

// Mode determines:
// - hasTableManagement: restaurant only

// - useCallingNumbers: cafe only

// - workflow: direct sale vs order tracking

```

### Global Singleton Pattern - BusinessInfo

**CRITICAL**: `BusinessInfo.instance` is a global singleton used across all flavors for:

- Tax settings (`isTaxEnabled`, `taxRate`)

- Service charge settings (`isServiceChargeEnabled`, `serviceChargeRate`)

- Currency display (`currencySymbol`, default "RM")

- Business details (name, address, tax number, etc.)

**Always access via**: `BusinessInfo.instance`
**To update**: Call `BusinessInfo.updateInstance(newInfo)` after making changes

---

## Key Models & Their Relationships

### Product → CartItem → RestaurantTable Flow

1. **Product** (`lib/models/product.dart`): Immutable catalog items

   - Properties: `name`, `price`, `category`, `icon`

   - No quantity - just represents the product definition

2. **CartItem** (`lib/models/cart_item.dart`): Product + quantity wrapper

   - `final Product product`

   - `int quantity` (mutable)

   - Used in all cart/order contexts

3. **RestaurantTable** (`lib/models/table_model.dart`): Restaurant mode only

   - Manages: `List<CartItem> orders`, `TableStatus`, `capacity`

   - Stateful: `status` changes (available → occupied → available)

   - Methods: `addOrder()`, `clearOrders()`, `totalAmount`, `itemCount`

### Tax & Service Charge Calculation Pattern

**ALL POS screens must implement this pattern**:

```dart
double getSubtotal() {
  return cartItems.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

}

double getTaxAmount() {
  final info = BusinessInfo.instance;
  return info.isTaxEnabled ? getSubtotal() * info.taxRate : 0.0;

}

double getServiceChargeAmount() {
  final info = BusinessInfo.instance;
  return info.isServiceChargeEnabled ? getSubtotal() * info.serviceChargeRate : 0.0;

}

double getTotal() {
  return getSubtotal() + getTaxAmount() + getServiceChargeAmount();

}

```

**Display Pattern**:

```dart
// Conditionally show tax/service charge rows based on enabled flags
if (BusinessInfo.instance.isTaxEnabled) ...[
  Text('Tax (${BusinessInfo.instance.taxRatePercentage})'),
  Text('${BusinessInfo.instance.currencySymbol} ${getTaxAmount().toStringAsFixed(2)}'),
],

```

---

## Screen Responsibilities

### Mode Selection → Settings Hierarchy

```text
ModeSelectionScreen
└── Settings (FAB) → SettingsScreen
    ├── Printers Management
    ├── Users Management
    ├── Tables Management (restaurant setup)
    └── Business Information (tax/service charge toggles)
```

### POS Screen Patterns

#### Retail Mode (`retail_pos_screen_modern.dart`)

- **Layout**: Products grid (left 70%) | Cart sidebar (right 30%)

- **Cart State**: Local `List<CartItem> cartItems`

- **Workflow**: Add to cart → Checkout → Clear cart

- **No persistence**: Cart cleared after checkout

**Implementation Guide**:

1. **Product Grid**: Use `LayoutBuilder` for responsive columns (1-4 based on width)
2. **Cart Sidebar**: Fixed width with `Expanded` for main grid
3. **Add to Cart**: `onTap` handler updates `cartItems` and calls `setState()`
4. **Quantity Controls**: +/- buttons with validation (min 0, max 99)

5. **Checkout Flow**: Navigate to payment screen with cart data
6. **Clear Cart**: Reset `cartItems` after successful payment

#### Cafe Mode (`cafe_pos_screen.dart`)

- **Layout**: Products grid (left 70%) | Cart + Order number (right 30%)

- **Cart State**: Local `List<CartItem> cartItems`

- **Order Tracking**: `List<CafeOrder> activeOrders` with auto-incrementing `nextOrderNumber`

- **Workflow**: Add to cart → Checkout (generates order #) → New order

- **Modal**: Active orders shown in bottom sheet with GridView

**Implementation Guide**:

1. **Order Number Generation**: Auto-increment `nextOrderNumber` on checkout
2. **Active Orders Modal**: Bottom sheet with `GridView` showing order cards
3. **Order Status**: Track preparation status (pending, preparing, ready)
4. **Cart Persistence**: Clear cart after order creation, show order number
5. **Order History**: Maintain list of active orders for kitchen display
6. **Order Completion**: Remove from active orders when completed

#### Restaurant Mode (`table_selection_screen.dart` → `pos_order_screen.dart`)

- **Two-screen flow**:
  1. Table selection grid (shows table status)
  2. Per-table order screen (passed `RestaurantTable` instance)

- **Cart State**: Stored IN the `RestaurantTable.orders` (persistent across navigation)

- **Workflow**: Select table → Add items → Save & return OR Checkout

- **Table Status**: Auto-updates to `occupied` when items added

**Implementation Guide**:

1. **Table Selection Grid**: Color-coded status (available=green, occupied=red)
2. **Table Persistence**: Update `RestaurantTable.status` when orders added
3. **Order Screen**: Pass table instance, modify `table.orders` directly
4. **Save & Return**: Update table status, navigate back to selection
5. **Checkout Flow**: Process payment, clear table orders, reset status
6. **Table Merging**: Support combining multiple tables for large parties

### Settings Screens

#### Business Info Screen (`business_info_screen.dart`)

- **Tax & Service Charge Dialog**:

  - Enable/disable toggles

  - Percentage rate inputs (entered as whole numbers, stored as decimals)

  - Updates `BusinessInfo.instance` → affects ALL POS calculations immediately

- **Business Hours**: Separate screen with per-day time ranges

- **Important**: Uses `copyWith()` pattern for updates

#### Tables Management (`tables_management_screen.dart`)

- CRUD for `RestaurantTable` definitions

- **Stats cards**: Total tables, available, occupied counts

- **Grid layout**: Responsive columns (1-4 based on screen width)

- **Dialogs**: Add/edit table with name, capacity inputs

#### Modern Reports Dashboard (`modern_reports_dashboard.dart`)

- **Dashboard-First Approach**: Unified view matching popular POS systems (Square, Toast, Loyverse)

- **Quick Date Selection**: Horizontal chip selector (Today, Yesterday, Week, Month, Custom)

- **KPI Cards**: 4 visual metrics (Gross Sales, Net Sales, Transactions, Average Ticket)

- **Interactive Charts**:

  - Line chart for sales trends

  - Donut charts for category distribution and payment methods breakdown

- **Top Products List**: Best-selling items with units sold and revenue

- **Export Options**:

  - CSV Export (cross-platform file picker)

  - PDF Export (A4/Thermal) - Coming soon

  - Thermal Print (58mm/80mm) - Coming soon

- **Pull-to-Refresh**: Swipe down to reload data

---

## Responsive Design Standards

### CRITICAL: All screens MUST be overflow-safe

**Problem**: Flutter's default layouts cause "BOTTOM OVERFLOW" errors on small screens or when windows resize.

**Solution Pattern Applied**:

#### 1. GridView with Adaptive Columns

```dart
LayoutBuilder(
  builder: (context, constraints) {
    int crossAxisCount = 4; // default
    if (constraints.maxWidth < 600) crossAxisCount = 1;
    else if (constraints.maxWidth < 900) crossAxisCount = 2;
    else if (constraints.maxWidth < 1200) crossAxisCount = 3;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        // ... other properties
      ),
      // ...
    );
  },
)

```

#### 2. Text Overflow Protection

```dart
// Always wrap text in constrained spaces with:
Flexible(
  child: Text(
    'Long text that might overflow',
    overflow: TextOverflow.ellipsis,
  ),
)

```

#### 3. Scrollable Dialogs

```dart
// Replace fixed SizedBox with:
ConstrainedBox(
  constraints: BoxConstraints(
    maxWidth: 400,
    maxHeight: MediaQuery.of(context).size.height * 0.6,
  ),
  child: SingleChildScrollView(
    child: Column(/* form fields */),
  ),
)

```

#### 4. Responsive Card Layouts

```dart
// Use LayoutBuilder to switch between Row/Wrap:
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 800) {
      return Wrap(spacing: 16, children: cards);
    } else {
      return Row(children: cards.map((c) => Expanded(child: c)).toList());
    }
  },
)

```

**Breakpoints Used**:

- `< 600px`: Mobile (1 column)

- `600-900px`: Small tablet (2 columns)

- `900-1200px`: Tablet (3 columns)

- `≥ 1200px`: Desktop (4+ columns)

---

## Reusable Widgets

### CartItemWidget (`lib/widgets/cart_item_widget.dart`)

- Standard cart line item with +/- quantity buttons

- **Props**: `CartItem item`, `VoidCallback onRemove`, `VoidCallback onAdd`

- **Used in**: All three POS modes

- Displays: Product name, unit price, quantity controls, line total

### ProductCard (`lib/widgets/product_card.dart`)

- Grid item for product selection

- **Props**: `Product product`, `VoidCallback onTap`

- Shows: Product icon, name, price

- Tap → adds to cart (handled by parent)

---

## Common Patterns & Conventions

### Navigation Pattern

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TargetScreen()),
);

// For data return (e.g., table orders):
final result = await Navigator.push<List<CartItem>>(...);
if (result != null) {
  // Handle returned data
}

```

### Color Scheme

- **Primary Blue**: `Color(0xFF2563EB)` (AppBar, buttons, accents)

- **Background**: `Colors.grey[100]` for main areas

- **Cards**: White with elevation

- **Text**: Black87 for primary, `Colors.grey[600]` for secondary

### Currency Formatting

```dart
'${BusinessInfo.instance.currencySymbol} ${amount.toStringAsFixed(2)}'
// Example: "RM 12.50"

```

### Mock Data Location

- Products: Defined locally in each POS screen (not centralized)

- Tables: Defined in `TablesManagementScreen` and `TableSelectionScreen`

---

## When Making Changes

### Adding a New Feature Checklist

1. ✅ Which flavor(s) does it affect? → POS, KDS, Backend, or KeyGen
2. ✅ Does it need to work across all 3 POS modes? → Update retail, cafe, restaurant screens
3. ✅ Does it involve pricing? → Use BusinessInfo.instance for tax/service charge
4. ✅ Does it have a grid/list? → Use LayoutBuilder for responsive columns
5. ✅ Does it have dialogs? → Make them scrollable with ConstrainedBox
6. ✅ Does it use text in constrained space? → Add `overflow: TextOverflow.ellipsis`
7. ✅ Run `flutter analyze` before committing
8. ✅ Test on target flavor(s) with `./build_flavors.sh [flavor] debug`

### Implementing Cart Features

**For POS App Cart Enhancements**:

1. **State Management**: Always use `List<CartItem>` with `setState()` for immediate updates
2. **Quantity Validation**: Implement min/max checks (0-99) with user feedback
3. **Price Recalculation**: Trigger subtotal/tax/total updates on any cart change
4. **Persistence Logic**: Use table-based storage for restaurant mode, session for others
5. **UI Updates**: Ensure cart widget rebuilds show latest quantities and totals
6. **Edge Cases**: Handle empty cart, single item removal, bulk operations

### Adding Payment Methods

**For POS App Payment Integration**:

1. **Enum Extension**: Add new `PaymentMethod` values with display names and icons
2. **Split Logic**: Implement amount allocation across multiple methods
3. **Rounding**: Apply Malaysian 0.05 rounding standard to all calculations
4. **Receipt Trigger**: Automatically print receipts after successful payment
5. **Error Handling**: Graceful degradation for device failures (printers, card readers)
6. **Transaction Recording**: Store complete payment details in database

### Creating New POS Screens

**For POS App Screen Development**:

1. **Responsive Layout**: Start with `LayoutBuilder` for adaptive columns (1-4)
2. **Business Logic**: Integrate `BusinessInfo.instance` for tax/service calculations
3. **Navigation**: Use named routes with conditional logic for mode-specific flows
4. **State Management**: Local `setState()` only, no external providers
5. **Error Handling**: Wrap async operations in try-catch with user feedback
6. **Testing**: Verify on Android tablets and Windows desktops for responsiveness

### Modifying BusinessInfo

1. Update `business_info_model.dart` fields
2. Update `copyWith()` method
3. Update dialog in `business_info_screen.dart`
4. Test all 3 POS modes to ensure calculations work

### Adding a New Screen

1. Create in `lib/screens/`
2. Add to Settings if it's a management screen
3. Ensure responsive layout from the start (use LayoutBuilder)
4. Follow existing navigation patterns

---

## Code Style Preferences

- **State Management**: Local `setState()` only, no BLoC/Provider/Riverpod

- **Immutability**: Models are final where possible, use `copyWith()` for updates

- **Widget Extraction**: Use private `_WidgetName` classes in same file for complex components

- **Naming**:

  - Screens: `*Screen` suffix

  - Models: No suffix, descriptive nouns

  - Private widgets: `_WidgetName` prefix

- **Constants**: Color values as `const Color(0xFF...)` inline

- **Imports**: Material first, then models, then widgets
