# FlutterPOS - Complete Documentation

## 📋 Project Overview

**FlutterPOS** is a comprehensive Point of Sale (POS) system built with Flutter,

designed specifically for Windows desktop environments. The application supports
three distinct business modes: Retail, Cafe, and Restaurant, each with tailored
workflows while sharing common core functionality.

### 🎯 Key Characteristics

- **Platform**: Windows desktop application (primary), Android tablets (secondary)

- **Architecture**: Multi-flavor architecture with shared codebase

- **State Management**: Local `setState()` pattern (no external libraries)

- **Data Persistence**: SQLite database with local backups

- **Activation Modes**: Offline (license key) or Tenant (Appwrite-connected)

- **Responsive Design**: Adaptive layouts for various screen sizes

- **Business Modes**: Retail, Cafe, Restaurant with shared models

- **Backend**: Appwrite for cloud sync, local SQLite for data storage

### 📊 Current Version & Status

**Version**: 1.0.14 (Build 14) - December 11, 2025
**Database**: SQLite with full schema (20+ tables)
**Backend**: Appwrite integration for multi-tenant cloud sync
**License System**: HMAC-SHA256 validation, offline operation
**Reports**: Employee performance analytics fully implemented
**Cloud Services**: RabbitMQ and Nextcloud removed - Appwrite only

---

## 🏗️ Architecture Overview

### Application Flow

```text
main.dart → ModeSelectionScreen (Home)
├── Retail Mode → RetailPOSScreen
│   └── Direct checkout workflow
├── Cafe Mode → CafePOSScreen
│   └── Order-by-number system
└── Restaurant Mode → TableSelectionScreen → POSOrderScreen
    └── Table-based order management

```

### Core Models & Relationships

#### 1. BusinessInfo (Global Singleton)

**Location**: [`lib/models/business_info_model.dart`](lib/models/business_info_model.dart )

- **Purpose**: Centralized configuration for tax, service charges, currency, and business details

- **Access Pattern**: Always use `BusinessInfo.instance`

- **Update Pattern**: `BusinessInfo.updateInstance(newInfo)` after modifications

- **Key Properties**:

  - `isTaxEnabled`, `taxRate` (decimal, e.g., 0.10 for 10%)

  - `isServiceChargeEnabled`, `serviceChargeRate`

  - `currencySymbol` (default: "RM")

  - Business details: name, address, tax number, phone

#### 2. Product → CartItem → RestaurantTable Flow

- **Product** ([`lib/models/product.dart`](lib/models/product.dart )): Immutable catalog items (name, price, category, icon)

- **CartItem** ([`lib/models/cart_item.dart`](lib/models/cart_item.dart )): Product + mutable quantity wrapper

- **RestaurantTable** ([`lib/models/table_model.dart`](lib/models/table_model.dart )): Stateful table with orders list (restaurant mode only)

### Business Mode Logic

**Location**: [`lib/models/business_mode.dart`](lib/models/business_mode.dart )

```dart
enum BusinessMode { retail, cafe, restaurant }

```

- **Retail**: Direct sales, no order tracking

- **Cafe**: Order-by-number system

- **Restaurant**: Full table management workflow

---

## 🎯 Feature Breakdown by Business Mode

### Retail Mode ([`lib/screens/retail_pos_screen.dart`](lib/screens/retail_pos_screen.dart ))

**Layout**: Products grid (70%) | Cart sidebar (30%)
**Workflow**:

1. Browse products → Add to cart
2. Modify quantities in cart
3. Checkout → Print receipt → Clear cart
**State**: Local `List<CartItem> cartItems` (cleared after checkout)
**Features**:

- ✅ Product catalog display

- ✅ Cart management with quantity controls

- ✅ Tax/service charge calculations

- ✅ Receipt generation

- ✅ Responsive grid layout

### Cafe Mode ([`lib/screens/cafe_pos_screen.dart`](lib/screens/cafe_pos_screen.dart ))

**Layout**: Products grid (70%) | Cart + Order number (70%)
**Workflow**:

1. Browse products → Add to cart
2. Checkout → Generate order number
3. Start new order
4. Track active orders in modal
**State**:

- Local `List<CartItem> cartItems` (per order)

- `List<CafeOrder> activeOrders` with auto-incrementing numbers
**Features**:

- ✅ Order number generation

- ✅ Active orders tracking

- ✅ Modal order management

- ✅ Order completion workflow

### Restaurant Mode

#### Table Selection ([`lib/screens/table_selection_screen.dart`](lib/screens/table_selection_screen.dart ))

- Grid display of restaurant tables

- Shows table status (available/occupied)

- Table capacity display

- Navigation to per-table order screen

#### POS Order Screen ([`lib/screens/pos_order_screen.dart`](lib/screens/pos_order_screen.dart ))

**Workflow**:

1. Select table → Navigate to order screen
2. Add items to table's order
3. Save & return OR Checkout
**State**: Orders stored IN `RestaurantTable.orders` (persistent across navigation)
**Features**:

- ✅ Table status management

- ✅ Per-table order persistence

- ✅ Table capacity tracking

---

## 🔑 Activation System

FlutterPOS supports two activation modes:

### 1. Offline Activation (Standalone)

- **Use Case**: Single POS device, no cloud connectivity

- **Method**: License key validation using HMAC-SHA256

- **Features**: Full functionality, local data storage

- **Process**: Enter license key → Validate → Unlock features

### 2. Tenant Activation (Cloud-Connected)

- **Use Case**: Multi-POS setup with centralized backend

- **Method**: Connect to Appwrite tenant database

- **Features**: Cloud sync, multi-counter management, centralized data

- **Process**: Enter tenant credentials → Connect to backend → Assign counter

### Activation Flow

```text
App Start → Check License
    ├── Trial Active → Continue
    ├── License Valid → Continue  
    └── Expired/Invalid → Show Activation Screen
        ├── Select Mode (Offline/Tenant)
        ├── Offline: Enter license key
        └── Tenant: Enter tenant ID, endpoint, API key, counter ID

```

---

## 🌐 Web Backend Management Interface

### Web Backend Overview

FlutterPOS includes a standalone web-based management interface (`web-backend/`) for managing Appwrite data without building the Flutter app.

**Location**: `web-backend/`
**Tech Stack**: Pure HTML/CSS/JavaScript, Appwrite SDK
**Purpose**: Tenant provisioning, data management, multi-tenancy setup

### Features

- **Tenant Provisioning**: Create isolated databases with collections and API keys

- **Credential Vault**: Secure storage of tenant credentials in admin database

- **Proxy Bypass**: Python proxy to handle CORS/domain validation issues

- **Responsive UI**: Works on desktop/mobile browsers

### Setup

```bash

# 1. Serve static files

cd web-backend
python3 -m http.server 8000


# 2. Start proxy (in another terminal)

python3 proxy.py --port 9000 --target http://localhost:8080


# 3. Open http://localhost:8000

```

### Architecture

- **Static UI**: HTML/JS served on port 8000

- **Proxy**: Python server on port 9000 forwards requests to Appwrite

- **Vault**: Admin database stores tenant credentials for retrieval

---

## 🗄️ Appwrite Self-Hosted Backend

### Appwrite Backend Overview

FlutterPOS uses Appwrite as its primary backend for data storage and sync.

**Docker Setup**: `docker/appwrite-compose.yml`
**Data Location**: `/mnt/storage/appwrite/` (second storage drive)
**Features**: Multi-tenancy, collections, API keys, file storage

### Multi-Tenancy Implementation

- **Tenant Databases**: Each customer gets `tenant_[timestamp]` database

- **Collections**: Auto-provisioned (categories, products, modifiers, orders, users)

- **API Keys**: Scoped keys generated per tenant for POS client access

- **Vault**: Admin database (`admin.tenants_vault`) stores credentials

### Docker Configuration

```yaml

# Key settings in appwrite-compose.yml

_APP_DOMAIN: localhost
_APP_CONSOLE_WHITELIST_ORIGINS: "*"
_APP_OPTIONS_ABUSE: disabled
_APP_OPTIONS_FORCE_HTTPS: disabled


# Volumes on second storage

volumes:

  - /mnt/storage/appwrite/mysql:/var/lib/mysql

  - /mnt/storage/appwrite/redis:/data

  - /mnt/storage/appwrite/config:/etc/appwrite

  - /mnt/storage/appwrite/storage:/storage

```

### Starting Appwrite

```bash
cd docker
docker-compose -f appwrite-compose.yml up -d

```

---

## 🔧 Shared Components & Widgets

### Core Reusable Widgets

### Calculation Patterns (Applied Across All Modes)

```dart
double getSubtotal() => cartItems.fold(0.0, (sum, item) => sum + item.product.price * item.quantity);

double getTaxAmount() => BusinessInfo.instance.isTaxEnabled ? getSubtotal() * BusinessInfo.instance.taxRate : 0.0;

double getServiceChargeAmount() => BusinessInfo.instance.isServiceChargeEnabled ? getSubtotal() * BusinessInfo.instance.serviceChargeRate : 0.0;

double getTotal() => getSubtotal() + getTaxAmount() + getServiceChargeAmount();

```

### Responsive Design Overview

**Critical**: All screens use `LayoutBuilder` for adaptive layouts

- **Breakpoints**: <600px (1 col), 600-900px (2 cols), 900-1200px (3 cols), ≥1200px (4+ cols)

- **Text Overflow**: `TextOverflow.ellipsis` in constrained spaces

- **Scrollable Dialogs**: `ConstrainedBox` + `SingleChildScrollView`

---

## ⚙️ Settings & Management Screens

### Settings Hub ([`lib/screens/settings_screen.dart`](lib/screens/settings_screen.dart ))

Central navigation to all management screens via FAB menu.

### Business Information ([`lib/screens/business_info_screen.dart`](lib/screens/business_info_screen.dart ))

- **Tax & Service Charge Configuration**:

  - Enable/disable toggles

  - Percentage rate inputs (whole numbers, stored as decimals)

  - Immediate effect on all POS calculations

- **Business Details**: Name, address, tax number, phone

- **Business Hours**: Separate screen with per-day time ranges

### Tables Management ([`lib/screens/tables_management_screen.dart`](lib/screens/tables_management_screen.dart ))

- CRUD operations for restaurant tables

- Stats cards: Total, available, occupied counts

- Responsive grid layout

- Add/edit dialogs with name and capacity inputs

### Users Management ([`lib/screens/users_management_screen.dart`](lib/screens/users_management_screen.dart ))

- Staff user account management

- Role-based permissions (future implementation)

### Printers Management ([`lib/screens/printers_management_screen.dart`](lib/screens/printers_management_screen.dart ))

- Printer configuration and testing

- USB, Bluetooth, Network printer support

- Paper size settings (58mm/80mm)

- **Current Status**: Detection partially functional, printing needs refinement

### Reports ([`lib/screens/reports_screen.dart`](lib/screens/reports_screen.dart ))

- Sales reports with filtering

- Mock data implementation

- Date range selection

- Export functionality (planned)

---

## 🔌 Technical Implementation Details

### Platform-Specific Code

- **Android Integration**: Kotlin plugins for printer hardware

- **Windows Support**: C++ plugins for Windows-specific features

- **Cross-Platform**: Flutter handles UI, platform channels for native features

### Printer Integration ([`lib/services`](lib/services ))

- **AndroidPrinterService**: USB/Bluetooth/Network discovery

- **WindowsPrinterService**: Windows spooler integration

- **Dual USB Mode**: Serial vs Native USB support

- **Paper Size**: 58mm (32-column) and 80mm (48-column) support

- **Current Issues**: Detection works, but status reporting needs improvement

### e-Invoice Integration (MyInvois - Malaysia) 🇲🇾

**Dual API Integration** - Full support for both MyInvois APIs:

#### e-Invoice API (Core Features)

- **Document Submission**: Submit invoices to LHDNM (Lembaga Hasil Dalam Negeri Malaysia)

- **OAuth 2.0 Authentication**: Secure token-based authentication

- **Document Management**: Retrieve, search, and cancel documents

- **TIN Validation**: Validate Tax Identification Numbers

- **Status Tracking**: Monitor submission and validation status

#### Platform API (Advanced Features)

- **Notifications**: System alerts and updates from MyInvois

- **Advanced Search**: Filter by amount, status, date range, customer/supplier

- **Document Types**: Reference data for all supported document types

- **Classification Codes**: Units, categories, countries, states, currencies

- **Extended TIN Validation**: With business address and registration details

- **MSIC Validation**: Malaysian Standard Industrial Classification codes

- **Document Rejection**: Reject received invoices (for buyers)

- **ERP Integration**: Consolidated document format for system integration

- **System Health**: Real-time API status monitoring

#### Configuration

- **Location**: Settings → e-Invoice Configuration

- **Environments**: Sandbox (testing) and Production

- **Credentials**: Client ID/Secret from MyInvois Portal

- **Test Connection**: Built-in connection tester

- **System Diagnostics**: Comprehensive API health monitoring

#### Documentation

- **Integration Guide**: [`MYINVOIS_INTEGRATION_GUIDE.md`](MYINVOIS_INTEGRATION_GUIDE.md)

- **Quick Reference**: [`MYINVOIS_DUAL_API_REFERENCE.md`](MYINVOIS_DUAL_API_REFERENCE.md)

- **Summary**: [`MYINVOIS_DUAL_API_SUMMARY.md`](MYINVOIS_DUAL_API_SUMMARY.md)

- **Services**:

  - [`lib/services/myinvois_service.dart`](lib/services/myinvois_service.dart) - Unified facade

  - [`lib/services/einvoice_service.dart`](lib/services/einvoice_service.dart) - e-Invoice API

  - [`lib/services/myinvois_platform_service.dart`](lib/services/myinvois_platform_service.dart) - Platform API

#### URLs

- **Sandbox**: `https://preprod-api.myinvois.hasil.gov.my`

- **Production**: `https://api.myinvois.hasil.gov.my`

- **Portal**: <https://myinvois.hasil.gov.my>

- **e-Invoice API Docs**: <https://sdk.myinvois.hasil.gov.my/einvoicingapi/>

- **Platform API Docs**: <https://sdk.myinvois.hasil.gov.my/api/>

### Database Architecture (Implemented)

- **Current**: SQLite database with full schema and migrations

- **Tables**: 20+ tables including users, items, categories, orders, reports

- **Backup**: Local backup/restore functionality

- **Models**: All core models integrated with database persistence

### File Structure

```text
lib/
├── main.dart
├── models/                          # Data models

│   ├── business_info_model.dart    # Global config singleton

│   ├── business_mode.dart          # Mode enum

│   ├── cart_item.dart              # Product + quantity wrapper

│   ├── product.dart                # Catalog items

│   ├── table_model.dart            # Restaurant tables

│   ├── sales_report.dart           # Reporting structures

│   ├── user_model.dart             # Staff user accounts

│   └── printer_model.dart          # Printer configurations

├── screens/                         # Full-page screens

│   ├── mode_selection_screen.dart  # Root screen

│   ├── retail_pos_screen.dart      # Retail mode POS

│   ├── cafe_pos_screen.dart        # Cafe mode POS

│   ├── table_selection_screen.dart # Restaurant table grid

│   ├── pos_order_screen.dart       # Table orders

│   ├── settings_screen.dart        # Settings hub

│   ├── business_info_screen.dart   # Tax/business settings

│   ├── tables_management_screen.dart
│   ├── users_management_screen.dart
│   ├── printers_management_screen.dart
│   └── reports_screen.dart
├── services/                        # Business logic

│   ├── printer_service.dart         # Printer abstraction

│   ├── android_printer_service.dart # Android-specific

│   ├── windows_printer_service.dart # Windows-specific

│   ├── database_service.dart        # Data persistence (SQLite)

│   └── receipt_generator.dart       # Receipt formatting

└── widgets/                         # Reusable components

    ├── cart_item_widget.dart        # Cart items

    └── product_card.dart            # Product cards

```

---

## 🐛 Current Limitations & Known Issues

### Critical Issues

1. **Printer Status Reporting**: Printers show "offline" even when detected and functional
2. **Authentication System**: No user login/roles implementation
3. **Payment Integration**: No payment processing
4. **Reports**: Mix of real data and mock data (employee performance fully implemented)

### Minor Issues

1. **Printer Save Bug**: Connection details not properly mapped for some printer types
2. **USB Discovery Logging**: Excessive logging in debug mode
3. **Bluetooth Permissions**: Runtime permission requests on Android 12+
4. **Responsive Layout**: Some edge cases on very small screens

### Performance Considerations

- **Database Queries**: Need optimization for large datasets

- **No Caching**: Frequent recalculations of totals

- **Image Loading**: Product icons loaded synchronously

---

## 🚀 Future Implementation Roadmap

### Phase 1: Core Infrastructure (High Priority)

1. **Database Optimization** ✅ COMPLETED

   - SQLite with full schema migration system

   - Persistent storage for all models

   - Local backup/restore functionality

2. **Authentication System**

   - User login/logout

   - Role-based permissions (admin, staff, manager)

   - Session management

3. **Printer Integration Fixes**

   - Fix "offline" status reporting

   - Improve connection detail mapping

   - Add printer health monitoring

   - Receipt logo support

### Phase 2: Business Features (Medium Priority)

1. **Payment Processing**

   - Cash payment handling

   - Card payment integration

   - Payment method tracking

   - Change calculation

2. **Advanced Reporting**

   - Real sales data analysis

   - Date range filtering

   - Export to PDF/Excel

   - Profit/loss calculations

   - Inventory tracking

3. **Order Management Enhancements**

   - Order history and search

   - Order modification after creation

   - Customer information tracking

   - Order notes/comments

### Phase 3: Advanced Features (Low Priority)

1. **Multi-Language Support**

   - Localization for UI text

   - Currency formatting by locale

   - RTL language support

2. **Cloud Synchronization**

   - Multi-device data sync

   - Online backup

   - Remote management dashboard

3. **Hardware Integration**

   - Barcode scanner support

   - Cash drawer control

   - Customer display integration

   - Kitchen printer routing

4. **Advanced Analytics**

   - Sales trends and forecasting

   - Customer behavior analysis

   - Inventory optimization

   - Performance metrics dashboard

### Phase 4: Platform Expansion (Future)

1. **Mobile Support**

   - Android/iOS companion apps

   - Tablet-optimized layouts

   - Touch-optimized controls

2. **Web Dashboard**

   - Browser-based management interface

   - Real-time sales monitoring

   - Remote configuration

---

## 📝 Development Notes

### Code Style & Conventions

- **State Management**: Local `setState()` pattern only

- **Immutability**: Models final where possible, `copyWith()` for updates

- **Naming**: Screens end with `*Screen`, private widgets start with `_`

- **Imports**: Material first, then models, then widgets

- **Constants**: Color values as `const Color(0xFF...)` inline

### Testing & Quality Assurance

- **Analysis**: `flutter analyze` for code quality

- **Responsive Testing**: Test on various window sizes

- **Mode Testing**: Verify all three business modes work correctly

- **Calculation Testing**: Tax/service charge calculations across modes

### Build & Deployment

- **Platform**: Windows desktop primary target

- **Build Command**: `flutter build windows`

- **Distribution**: Single executable with embedded assets

### Common Pitfalls to Avoid

1. **Fixed Grid Columns**: Always use `LayoutBuilder` for responsive grids
2. **Hardcoded Tax Rates**: Always use `BusinessInfo.instance`
3. **Modifying Immutable Products**: Change quantity in `CartItem`, not `Product`
4. **Unconstrained Dialogs**: Use `ConstrainedBox` + `SingleChildScrollView`

---

## 🤖 AI Coding Agent Instructions

### Project Overview

**FlutterPOS** is a multi-mode Point of Sale (POS) system built with Flutter for desktop (Windows). It supports three distinct business modes:

- **Retail Mode**: Direct sales with immediate checkout

- **Cafe Mode**: Order-by-number system for takeaway/counter service

- **Restaurant Mode**: Full table management with table service workflow

**Platform**: Windows desktop application (Flutter Windows), Android tablets
**Architecture**: Multi-flavor architecture with shared codebase
**Data Persistence**: SQLite database with local backups and Appwrite cloud sync

### Architecture & Data Flow

#### Application Entry Point

- **main.dart** → **ModeSelectionScreen** (home screen)

- User selects business mode → Navigate to mode-specific POS screen

- All modes share common models but have different workflows

#### Three-Mode Architecture

```text
ModeSelectionScreen (Root)
├── Retail Mode → RetailPOSScreen
│   └── Direct checkout workflow
├── Cafe Mode → CafePOSScreen
│   └── Order numbers + active orders modal

└── Restaurant Mode → TableSelectionScreen
    └── POSOrderScreen (per-table)

```

#### Business Mode Logic ([`lib/models/business_mode.dart`](lib/models/business_mode.dart ))

```dart
enum BusinessMode { retail, cafe, restaurant }

// Mode determines:
// - hasTableManagement: restaurant only

- useCallingNumbers: cafe only

- workflow: direct sale vs order tracking

```

#### Global Singleton Pattern - BusinessInfo

**CRITICAL**: `BusinessInfo.instance` is a global singleton used across all screens for:

- Tax settings (`isTaxEnabled`, `taxRate`)

- Service charge settings (`isServiceChargeEnabled`, `serviceChargeRate`)

- Currency display (`currencySymbol`, default "RM")

- Business details (name, address, tax number, etc.)

**Always access via**: `BusinessInfo.instance`
**To update**: Call `BusinessInfo.updateInstance(newInfo)` after making changes

### Key Models & Their Relationships

#### Product → CartItem → RestaurantTable Flow

1. **Product** ([`lib/models/product.dart`](lib/models/product.dart )): Immutable catalog items

   - Properties: `name`, `price`, `category`, `icon`

   - No quantity - just represents the product definition

2. **CartItem** ([`lib/models/cart_item.dart`](lib/models/cart_item.dart )): Product + quantity wrapper

   - `final Product product`

   - `int quantity` (mutable)

   - Used in all cart/order contexts

3. **RestaurantTable** ([`lib/models/table_model.dart`](lib/models/table_model.dart )): Restaurant mode only

   - Manages: `List<CartItem> orders`, `TableStatus`, `capacity`

   - Stateful: `status` changes (available → occupied → available)

   - Methods: `addOrder()`, `clearOrders()`, `totalAmount`, `itemCount`

#### Tax & Service Charge Calculation Pattern

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

### Screen Responsibilities

#### Mode Selection → Settings Hierarchy

```text
ModeSelectionScreen
└── Settings (FAB) → SettingsScreen
    ├── Printers Management
    ├── Users Management
    ├── Tables Management (restaurant setup)
    └── Business Information (tax/service charge toggles)

```

#### POS Screen Patterns

##### Retail Mode (`retail_pos_screen.dart`)

- **Layout**: Products grid (left 70%) | Cart sidebar (right 30%)

- **Cart State**: Local `List<CartItem> cartItems`

- **Workflow**: Add to cart → Checkout → Clear cart

- **No persistence**: Cart cleared after checkout

##### Cafe Mode (`cafe_pos_screen.dart`)

- **Layout**: Products grid (left 70%) | Cart + Order number (right 30%)

- **Cart State**: Local `List<CartItem> cartItems`

- **Order Tracking**: `List<CafeOrder> activeOrders` with auto-incrementing `nextOrderNumber`

- **Workflow**: Add to cart → Checkout (generates order #) → New order

- **Modal**: Active orders shown in bottom sheet with GridView

##### Restaurant Mode (`table_selection_screen.dart` → `pos_order_screen.dart`)

- **Two-screen flow**:
  1. Table selection grid (shows table status)
  2. Per-table order screen (passed `RestaurantTable` instance)

- **Cart State**: Stored IN the `RestaurantTable.orders` (persistent across navigation)

- **Workflow**: Select table → Add items → Save & return OR Checkout

- **Table Status**: Auto-updates to `occupied` when items added

#### Settings Screens

##### Business Info Screen (`business_info_screen.dart`)

- **Tax & Service Charge Dialog**:

  - Enable/disable toggles

  - Percentage rate inputs (entered as whole numbers, stored as decimals)

  - Updates `BusinessInfo.instance` → affects ALL POS calculations immediately

- **Business Hours**: Separate screen with per-day time ranges

- **Important**: Uses `copyWith()` pattern for updates

##### Tables Management (`tables_management_screen.dart`)

- CRUD for `RestaurantTable` definitions

- **Stats cards**: Total tables, available, occupied counts

- **Grid layout**: Responsive columns (1-4 based on screen width)

- **Dialogs**: Add/edit table with name, capacity inputs

### Responsive Design Standards

#### CRITICAL: All screens MUST be overflow-safe

**Problem**: Flutter's default layouts cause "BOTTOM OVERFLOW" errors on small screens or when windows resize.

**Solution Pattern Applied**:

##### 1. GridView with Adaptive Columns

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

##### 2. Text Overflow Protection

```dart
// Always wrap text in constrained spaces with:
Flexible(
  child: Text(
    'Long text that might overflow',
    overflow: TextOverflow.ellipsis,
  ),
)

```

##### 3. Scrollable Dialogs

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

##### 4. Responsive Card Layouts

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

### Reusable Widgets

#### CartItemWidget ([`lib/widgets/cart_item_widget.dart`](lib/widgets/cart_item_widget.dart ))

- Standard cart line item with +/- quantity buttons

- **Props**: `CartItem item`, `VoidCallback onRemove`, `VoidCallback onAdd`

- **Used in**: All three POS modes

- Displays: Product name, unit price, quantity controls, line total

#### ProductCard ([`lib/widgets/product_card.dart`](lib/widgets/product_card.dart ))

- Grid item for product selection

- **Props**: `Product product`, `VoidCallback onTap`

- Shows: Product icon, name, price

- Tap → adds to cart (handled by parent)

### Common Patterns & Conventions

#### Navigation Pattern

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

#### Color Scheme

- **Primary Blue**: `Color(0xFF2563EB)` (AppBar, buttons, accents)

- **Background**: `Colors.grey[100]` for main areas

- **Cards**: White with elevation

- **Text**: Black87 for primary, `Colors.grey[600]` for secondary

#### Currency Formatting

```dart
'${BusinessInfo.instance.currencySymbol} ${amount.toStringAsFixed(2)}'
// Example: "RM 12.50"

```

#### Data Sources

- Products: Stored in SQLite database (`items` table)

- Tables: Managed via `TablesManagementScreen` (SQLite `tables` table)

- Reports: Mix of real database data and calculated metrics

- Business Info: Persistent in SQLite (`business_info` table)

### Testing & Development

#### Run Commands

```bash
cd /mnt/Storage/Projects/flutterpos
flutter analyze  # Check for errors

flutter run -d windows  # Run on Windows

```

#### Current Limitations (Future Work)

- Authentication system not fully implemented

- Payment methods not implemented

- Printer integration not functional

- Reports: Mix of real data (employee performance) and mock data

### Common Pitfalls & Solutions

#### ❌ WRONG: Fixed crossAxisCount

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 4, // Will overflow on small screens!
  ),
)

```

#### ✅ CORRECT: Adaptive columns with LayoutBuilder

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final columns = constraints.maxWidth < 600 ? 1 :
                    constraints.maxWidth < 900 ? 2 : 4;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
      ),
    );
  },
)

```

#### ❌ WRONG: Forgetting to check BusinessInfo flags

```dart
double getTotal() {
  return subtotal + (subtotal * 0.10); // Hardcoded tax!

}

```

#### ✅ CORRECT: Always use BusinessInfo.instance

```dart
double getTaxAmount() {
  final info = BusinessInfo.instance;
  return info.isTaxEnabled ? getSubtotal() * info.taxRate : 0.0;

}

```

#### ❌ WRONG: Modifying CartItem.product

```dart
cartItem.product.price = 100; // Product is immutable!

```

#### ✅ CORRECT: Modify quantity, not quantity

```dart
cartItem.quantity += 1; // Quantity is mutable

```

### When Making Changes

#### Adding a New Feature Checklist

1. ✅ Does it need to work across all 3 modes? → Update all POS screens
2. ✅ Does it involve pricing? → Use BusinessInfo.instance for tax/service charge
3. ✅ Does it have a grid/list? → Use LayoutBuilder for responsive columns
4. ✅ Does it have dialogs? → Make them scrollable with ConstrainedBox
5. ✅ Does it use text in constrained space? → Add `overflow: TextOverflow.ellipsis`
6. ✅ Run `flutter analyze` before committing

#### Modifying BusinessInfo

1. Update `business_info_model.dart` fields
2. Update `copyWith()` method
3. Update dialog in `business_info_screen.dart`
4. Test all 3 POS modes to ensure calculations work

#### Adding a New Screen

1. Create in [`lib/screens`](lib/screens )
2. Add to Settings if it's a management screen
3. Ensure responsive layout from the start (use LayoutBuilder)
4. Follow existing navigation patterns

### Code Style Preferences

- **State Management**: Local `setState()` only, no BLoC/Provider/Riverpod

- **Immutability**: Models are final where possible, use `copyWith()` for updates

- **Widget Extraction**: Use private `_WidgetName` classes in same file for complex components

- **Naming**:

  - Screens: `*Screen` suffix

  - Models: No suffix, descriptive nouns

  - Private widgets: `_WidgetName` prefix

- **Constants**: Color values as `const Color(0xFF...)` inline

- **Imports**: Material first, then models, then widgets

### Quick Reference: File Organization

```text
lib/
├── main.dart                        # App entry point

├── models/                          # Data models (immutable where possible)

│   ├── business_info_model.dart    # Global singleton for tax/currency/business data

│   ├── business_mode.dart          # Enum for retail/cafe/restaurant

│   ├── cart_item.dart              # Product + quantity wrapper

│   ├── product.dart                # Product catalog item

│   ├── table_model.dart            # Restaurant table with orders

│   ├── sales_report.dart           # Reporting data structures

│   ├── user_model.dart             # Staff user accounts

│   └── printer_model.dart          # Printer configurations

├── screens/                         # Full-page screens

│   ├── mode_selection_screen.dart  # Root/home screen

│   ├── retail_pos_screen.dart      # Retail mode POS

│   ├── cafe_pos_screen.dart        # Cafe mode POS with order numbers

│   ├── table_selection_screen.dart # Restaurant table grid

│   ├── pos_order_screen.dart       # Per-table order screen (restaurant)

│   ├── settings_screen.dart        # Settings hub

│   ├── business_info_screen.dart   # Tax/business settings

│   ├── tables_management_screen.dart
│   ├── users_management_screen.dart
│   ├── printers_management_screen.dart
│   └── reports_screen.dart
└── widgets/                         # Reusable widgets

    ├── cart_item_widget.dart        # Cart line item with +/- buttons

    └── product_card.dart            # Product grid item

```

### Summary: What Makes This Codebase Unique

1. **Four-flavor architecture**: Single codebase builds four distinct apps (POS, KDS, Backend, KeyGen)
2. **Three-mode POS workflow**: Retail/Cafe/Restaurant modes with different UX patterns
3. **Global singleton**: `BusinessInfo.instance` controls tax/currency across all flavors
4. **Stateful tables**: Restaurant mode persists cart data IN the table model
5. **Responsive-first**: All layouts must handle window resizing gracefully
6. **No external state management**: Pure Flutter setState() approach
7. **Desktop-focused**: Windows primary platform, not mobile-first
8. **Offline-first license system**: HMAC-SHA256 validation without internet
9. **Google Drive integration**: Cloud sync for Backend flavor
10. **Web backend management**: Standalone HTML/JS interface for Appwrite data management
11. **Multi-tenancy with Appwrite**: Isolated tenant databases with auto-provisioned collections and API keys
12. **Self-hosted backend**: Appwrite Docker stack with data on secondary storage

When in doubt:

- Determine which flavor(s) you're working on

- Check existing screens in that flavor for patterns

- Always use LayoutBuilder for grids

- Always check BusinessInfo.instance for tax/currency

---

## 📊 Project Status Summary

### ✅ Completed Features

- Three-mode POS architecture (Retail, Cafe, Restaurant)

- Responsive UI with adaptive layouts

- Tax and service charge calculations

- SQLite database with full schema and migrations

- Local backup/restore functionality

- License key system with HMAC-SHA256 validation

- Employee performance analytics and reporting

- Appwrite backend integration for multi-tenant sync

- Settings management system

- Cross-platform printer service architecture

### 🔄 In Progress

- Printer status reporting fixes

- Authentication system implementation

- Payment processing integration

### 📋 Planned Features

- Advanced user role management

- Payment gateway integration

- Enhanced reporting features

- Mobile app optimization

### 🎯 Project Strengths

- Clean, maintainable architecture

- Responsive design from the ground up

- Mode-based workflow flexibility

- Shared component reusability

- Platform-specific service abstraction

This documentation provides a comprehensive overview of FlutterPOS's current state and future direction. The application demonstrates solid architectural foundations with room for significant feature expansion.
