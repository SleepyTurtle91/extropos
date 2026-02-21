# FlutterPOS AI Instructions



## Quick Start


- **Version**: 1.0.27+ (January 2026)

- **Architecture**: Multi-flavor Flutter app (POS/KDS/Backend/KeyGen)

- **Data**: SQLite (current), Isar (planned migration)

- **Build**: `./build_flavors.ps1 [flavor] [debug|release]` (Windows) or `./build_flavors.sh` (Linux)

- **Test**: `flutter test` (100+ unit/integration tests)

- **Platform**: Windows desktop primary, Android tablets secondary


## Critical Architecture Patterns



### 1. Unified POS Screen Architecture (v1.0.25+)


**IMPORTANT**: As of v1.0.25, the application uses `UnifiedPOSScreen` as the main POS entry point, NOT `ModeSelectionScreen`.

**Navigation Flow**:


```
main.dart → LockScreen → UnifiedPOSScreen
                            ├→ RetailPOSScreenModern (if retail mode)
                            ├→ CafePOSScreen (if cafe mode)
                            └→ TableSelectionScreen (if restaurant mode)

```


**Key Details**:

- `UnifiedPOSScreen` (`lib/screens/unified_pos_screen.dart`) routes to mode-specific screens based on `BusinessInfo.instance.selectedBusinessMode`

- Provides unified AppBar with menu for Settings, Reports, User Sign-in, Shift Management, Business Session

- Enforces Business Session checking - blocks POS access if business is closed

- Training Mode overlay displayed at top when `TrainingModeService.instance.isTrainingMode` is true

- Mode switching happens in Settings → Business Mode, not at home screen level


**Three-Layer Access Control**:
 Management (v1.0.25+)
**Three-Layer Access Control**:
1. **Business Session** (`BusinessSessionService`): Open/Close business day (required for all POS operations)

2. **User Session** (`UserSessionService`): Cashier sign-in/sign-out (tracks who is using the POS)

3. **Shift Management** (`ShiftService`): Per-user shift tracking (opening/closing cash, shift reports)

**Enforcement Pattern**:

```dart
// Check business session first
if (!BusinessSessionService().isBusinessOpen) {
  return _showBusinessClosedScreen();
}

// Check shift in initState of POS screens
if (!ShiftService().hasActiveShift) {
  await showDialog(context: context, builder: (_) => StartShiftDialog(...));
}


```

**Critical Services**:

- `BusinessSessionService()`: Singleton, ChangeNotifier for reactive UI

- `ShiftService.instance`: Per-user shift management with database persistence

- `UserSessionService()`: Tracks current cashier, links to shift operations



### 3. BusinessInfo Singleton Pattern

**CRITICAL**: `BusinessInfo.instance` is the global configuration for ALL calculations.


**Access Pattern**:

```dart
// Always read from instance
final info = BusinessInfo.instance;
final taxAmount = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;

// Update pattern (after modifications)
BusinessInfo.updateInstance(modifiedInfo);


```

**Key Properties**:

- `selectedBusinessMode`: Determines which POS screen to show (retail/cafe/restaurant)

- `isTaxEnabled`, `taxRate` (stored as decimal: 0.10 = 10%)

- `isServiceChargeEnabled`, `serviceChargeRate`

- `currencySymbol` (default: "RM")

- Business details: name, address, tax number, phone


### 4. Responsive Design Standard

**REQUIRED**: All grids MUST use `LayoutBuilder` with adaptive columns.

**Pattern**:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    int columns = 4;
    if (constraints.maxWidth < 600) columns = 1;
    else if (constraints.maxWidth < 900) columns = 2;
    else if (constraints.maxWidth < 1200) columns = 3;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
      ),
      // ...
    );
  },
)

```

**Breakpoints**: <600px (mobile), 600-900px (tablet), 900-1200px (desktop), >1200px (large)


### 5. State Management Principle

**NO external state management libraries**. Use local `setState()` only.

**Cart State Example**:

```dart
List<CartItem> cartItems = [];

void addToCart(Product product) {
  setState(() {
    final existing = cartItems.firstWhereOrNull((item) => item.product.id == product.id);
    if (existing != null) {
      existing.quantity++;
    } else {
      cartItems.add(CartItem(product: product, quantity: 1));
    }
  });
}

```


## Critical Workflows



### Build & Release (Windows)

```powershell

# Build single flavor

.\build_flavors.ps1 pos release


# Build all flavors

.\build_flavors.ps1 all release


# Release workflow (MANDATORY)

flutter build apk --release
Copy-Item build/app/outputs/flutter-apk/app-release.apk ~\Desktop\FlutterPOS-v1.0.27-$(Get-Date -Format yyyyMMdd).apk
git tag -a v1.0.27-$(Get-Date -Format yyyyMMdd) -m "Release v1.0.27"
git push origin v1.0.27-$(Get-Date -Format yyyyMMdd)

```


### Database Operations

**Current**: SQLite via `DatabaseHelper.instance` (singleton)
**Planned**: Isar migration (models exist in `lib/models/isar/` but not integrated)

**Pattern**:

```dart
final db = await DatabaseHelper.instance.database;
final products = await db.query('products', where: 'is_active = ?', whereArgs: [1]);

```


### Backend Sync (Appwrite)

**Endpoint**: `https://appwrite.extropos.org/v1`
**Project**: `6940a64500383754a37f`
**Database**: `pos_db` (14 collections, 4 storage buckets)

**Service**: `AppwriteSyncService` (`lib/services/appwrite_sync_service.dart`)

- Methods: `initialize()`, `fullSync()`, `syncProducts()`, `createProduct()`

- Real-time subscriptions via Appwrite Realtime API

- Used in Backend flavor only for remote management


## Common Pitfalls & Solutions



### ❌ Wrong: Fixed crossAxisCount

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4), // Breaks on resize!
)

```


### ✅ Correct: Adaptive columns

```dart
LayoutBuilder(builder: (context, constraints) {
  final columns = constraints.maxWidth < 600 ? 1 : 4;
  return GridView.builder(/* ... */);

})

```


### ❌ Wrong: Hardcoded tax calculation

```dart
double total = subtotal + (subtotal * 0.10); // Ignores BusinessInfo settings!

```


### ✅ Correct: Use BusinessInfo

```dart
double getTaxAmount() {
  final info = BusinessInfo.instance;
  return info.isTaxEnabled ? getSubtotal() * info.taxRate : 0.0;

}

```


### ❌ Wrong: Direct POS access without session check

```dart
// Navigating directly to RetailPOSScreenModern
Navigator.push(context, MaterialPageRoute(builder: (_) => RetailPOSScreenModern()));

```


### ✅ Correct: Use UnifiedPOSScreen (handles session checks)

```dart
// Navigate to UnifiedPOSScreen - it will route to correct mode

Navigator.pushNamed(context, '/pos');

```


## POS App Perfection Strategies



### 1. Business Mode Implementation Strategy


**Objective**: Ensure seamless operation across Retail, Cafe, and Restaurant modes with distinct UX patterns.

**Key Details for Agentic**:


- **Mode Detection**: Always check `BusinessMode` enum values (retail, cafe, restaurant) to determine workflow

- **Conditional UI**: Use `if (businessMode == BusinessMode.retail)` blocks for mode-specific features

- **Data Persistence**: Restaurant mode requires table-based cart persistence; others use session-based carts

- **Navigation Flow**: Implement `UnifiedPOSScreen` as router with conditional rendering

- **Testing**: Create separate test scenarios for each mode's unique workflows

**Implementation Steps**:

1. Define mode-specific constants and helper methods
2. Implement conditional widget rendering in POS screens
3. Add mode-specific validation logic
4. Test mode switching and data isolation


### 2. Cart Management Strategy


**Objective**: Robust cart operations with quantity adjustments, item management, and real-time calculations.



- **State Management**: Use `List<CartItem>` with `setState()` for immediate UI updates

- **Quantity Controls**: Implement +/- buttons with validation (min 0, max reasonable limits)

- **Price Calculations**: Always recalculate totals after any cart modification

- **Item Persistence**: For restaurant mode, persist cart in `RestaurantTable.orders`

- **Undo/Redo**: Consider implementing cart state snapshots for recovery

**Implementation Steps**:

**Implementation Steps**:
1. Create `CartItem` model with immutable `Product` reference
2. Implement add/remove/update methods with validation
3. Add real-time subtotal/tax/total calculations
4. Handle cart clearing after successful transactions
5. Test edge cases (negative quantities, large orders)


### 3. Payment Processing Strategy


**Objective**: Secure, flexible payment handling with multiple methods and split payments.

**Key Details for Agentic**:


- **Payment Methods**: Support cash, card, e-wallet with extensible enum

- **Split Payments**: Allow multiple payment methods per transaction

- **Rounding Logic**: Implement Malaysian standard (round to nearest 0.05)

- **Receipt Generation**: Trigger receipt printing immediately after payment

- **Error Handling**: Graceful failure for payment device issues

**Implementation Steps**:

1. Define `PaymentMethod` enum with display names and icons
2. Implement payment split logic with amount allocation
3. Add rounding calculations in transaction processing
4. Integrate receipt printing service
5. Test payment flows and error scenarios


### 4. Receipt Printing Strategy


**Objective**: Professional thermal receipt generation with customizable templates.



- **Printer Integration**: Support 58mm and 80mm thermal printers

- **Template System**: Use configurable headers, footers, and business info

- **Dual Receipts**: Generate customer and merchant copies

- **Error Recovery**: Handle printer offline/disconnected states

- **Platform Specific**: Android native printing vs Windows spooler

**Implementation Steps**:

**Implementation Steps**:
1. Implement printer discovery and connection logic
2. Create receipt template builder with business info
3. Add print job queuing and status tracking
4. Handle paper size detection (58mm/80mm)
5. Test printing on target hardware



### 5. Table Management Strategy (Restaurant Mode)


- **Table States**: Available, occupied, reserved with color coding

- **Order Persistence**: Store orders directly in table objects

- **Merge/Split**: Support table merging for large groups

- **Real-time Updates**: Reflect table status changes immediately

- **Capacity Management**: Track table capacity and current occupancy

**Implementation Steps**:
Reflect table status changes immediately

- **Capacity Management**: Track table capacity and current occupancy

**Implementation Steps**:
1. Define `TableStatus` enum with visual indicators
2. Implement table selection grid with status display
3. Add order persistence in `RestaurantTable` model
4. Create table management CRUD operations

5. Test table lifecycle (available → occupied → cleared)


### 6. Responsive Design Strategy


- **Breakpoint System**: 1-4 columns based on screen width (<600:1, 600-900:2, 900-1200:3, >1200:4)

- **LayoutBuilder Usage**: Always wrap grids in `LayoutBuilder` for dynamic columns

- **Text Overflow**: Use `TextOverflow.ellipsis` for constrained text areas

- **Scrollable Dialogs**: Implement `ConstrainedBox` with `SingleChildScrollView` for forms

- **Platform Testing**: Verify on Android tablets and Windows desktops

**Implementation Steps**:
 Implement `ConstrainedBox` with `SingleChildScrollView` for forms

- **Platform Testing**: Verify on Android tablets and Windows desktops

**Implementation Steps**:
1. Implement adaptive column calculation functions
2. Wrap all grids with `LayoutBuilder`

3. Add overflow protection to text widgets
4. Test on various screen sizes and orientations
5. Validate touch targets for mobile/desktop



- **Global Configuration**: Use `BusinessInfo.instance` for tax/service charge settings

- **Real-time Updates**: Recalculate all prices when settings change

- **Display Logic**: Conditionally show tax/service rows based on enabled flags

- **Percentage Storage**: Store rates as decimals (e.g., 0.10 for 10%)

- **Audit Trail**: Log calculation details for transaction records

**Implementation Steps**:
itionally show tax/service rows based on enabled flags

- **Percentage Storage**: Store rates as decimals (e.g., 0.10 for 10%)

- **Audit Trail**: Log calculation details for transaction records

**Implementation Steps**:
1. Implement calculation methods in business logic layer
2. Add conditional UI rendering for tax displays

3. Create settings dialog for rate configuration
4. Test calculation accuracy with various scenarios


- **Try-Catch Blocks**: Wrap all async operations in error handling

- **User Feedback**: Show `SnackBar` or dialogs for errors

- **Recovery Options**: Provide retry mechanisms for failed operations

- **Logging**: Extensive print statements for debugging

- **Fallback Modes**: Continue operation with reduced functionality

**Implementation Steps**:
rap all async operations in error handling

- **User Feedback**: Show `SnackBar` or dialogs for errors

- **Recovery Options**: Provide retry mechanisms for failed operations

- **Logging**: Extensive print statements for debugging

- **Fallback Modes**: Continue operation with reduced functionality

**Implementation Steps**:
1. Add error handling to all service calls

2. Implement user notification system
3. Create retry logic for network/hardware operations


- **Lazy Loading**: Load products/categories on demand

- **Efficient Rendering**: Use `ListView.builder` for large lists

- **Image Optimization**: Cache and resize product images

- **Database Queries**: Optimize SQLite queries with proper indexing

- **Memory Management**: Dispose controllers and clear caches

**Implementation Steps**:
**:

- **Lazy Loading**: Load products/categories on demand

- **Efficient Rendering**: Use `ListView.builder` for large lists

- **Image Optimization**: Cache and resize product images

- **Database Queries**: Optimize SQLite queries with proper indexing

- **Memory Management**: Dispose controllers and clear caches


**Implementation Steps**:
1. Implement pagination for product loading
2. Use efficient list widgets with builders
3. Add image caching and compression


- **Unit Tests**: Test business logic and calculations

- **Integration Tests**: Test screen interactions and workflows

- **Platform Testing**: Verify on Android and Windows targets

- **Edge Case Coverage**: Test with empty carts, network failures, hardware issues

- **Regression Prevention**: Run full test suite before commits

**Implementation Steps**:
**:

- **Unit Tests**: Test business logic and calculations

- **Integration Tests**: Test screen interactions and workflows

- **Platform Testing**: Verify on Android and Windows targets

- **Edge Case Coverage**: Test with empty carts, network failures, hardware issues

- **Regression Prevention**: Run full test suite before commits

**Implementation Steps**:
1. Write unit tests for all calculation logic
2. Create integration tests for user workflows
3. Test on physical devices and emulators
4. Document and test edge cases
5. Automate testing in CI/CD pipeline


### 11. Markdown Linting & Quality Standards


**Objective**: Ensure all created *.md files follow markdown best practices and pass linting validation.

**Critical Linting Rules**:

- **MD003**: Heading style must be consistent (use # for all headings)

- **MD013**: Line length should not exceed 80 characters (configure as needed for code blocks)

- **MD022**: Headings must be surrounded by blank lines (one blank line before and after each heading)

- **MD030**: Spacing between list markers and content must be consistent

- **MD032**: Lists must be surrounded by blank lines (one blank line before and after each list block)

- **MD040**: Fenced code blocks must have a language specified (use ```bash, ```dart, ```yaml, ```text, etc.)

- **MD060**: Table column style must have proper spacing around pipes (use `| Header | Header |` not `|Header|Header|`)

**Validation Steps** (ALWAYS perform after creating *.md files):

1. After creating or modifying any *.md file, validate with markdownlint
2. Check specifically for MD022 (heading spacing) violations
3. Check specifically for MD032 (list spacing) violations
4. Ensure proper blank lines surround all headings and lists
5. For code blocks, verify formatting is correct
6. Use following command to validate:


```bash

# Install markdownlint (if not already installed)

npm install -g markdownlint-cli


# Validate single file

markdownlint path/to/file.md


# Validate all markdown files

markdownlint '**/*.md'


# Fix common issues automatically

markdownlint --fix '**/*.md'

```

**Implementation Standards**:

- Always add blank line before headings (except at start of document)

- Always add blank line after headings

- Always add blank line before lists

- Always add blank line after lists (before non-list content)

- Use consistent heading levels (don't skip from # to ###)

- Ensure code blocks use proper fence markers with language specification (```language)

- Ensure table separators have spaces around pipes (use `| --- | --- |` not `|---|---|`)

- Test all created *.md files before final output

**Common Violations to Avoid**:

- Heading directly after previous content without blank line

- List items without blank line before or after

- Mixed heading styles (some # and some ##)

- Inconsistent list markers (mixing -, *, +)

- Code blocks without proper language specification

- Table separators without spaces (e.g., `|---|---|` instead of `| --- | --- |`)

**Example - Correct Format**:


```markdown

# Main Heading


Introduction paragraph.


## Sub Heading


Content paragraph.


### List Example


- Item 1

- Item 2

- Item 3

Follow-up paragraph after list.

```


### 12. Appwrite Self-Hosted Cloud Plan


- Hosting: Windows Docker Desktop or Ubuntu 22.04 with Docker; static IP/DNS; open ports 80/443/8080/3000

- TLS & domains: Cloudflare proxy off during setup; Traefik/NGINX + Let's Encrypt; map api.yourdomain (API) and console.yourdomain (Console)

- Storage: Persist volumes on fast disk (E:\appwrite-cloud or /opt/appwrite); schedule DB/storage backups

- Stack: Appwrite API, Console, MariaDB, Redis, workers (db, audits, usage, webhooks); optional ingress proxy

- Config: .env for secrets (DB, Redis, JWT/API keys); set public https APPWRITE_ENDPOINT; enable rate/size limits; no default creds

- Database: Tune MariaDB (innodb buffer, connections); strong passwords; automated dumps/mariabackup

- Storage controls: Plan buckets, size limits; optional AV scanning; consider S3-compatible offload later

- Security: Firewall to 80/443 only; DB/Redis internal; HTTPS-only; rotate secrets; enable audit logging

- Observability: Centralize logs; health checks; alerts on restarts, CPU/RAM, disk >80%, DB connections, queue lag

- Scaling: Start single node; vertical first; for horizontal later, externalize DB/Redis and add replicas behind LB

- CI/CD: docker compose pull && docker compose up -d; keep compose + .env template in repo (IaC)

- Backups/DR: Daily DB dumps, storage snapshots; off-box retention; monthly restore drills with documented RPO/RTO

- Access: Least privilege; service accounts for automation; strong password policy; 2FA on console

- Pre-go-live tests: HTTPS reachability, collection CRUD, file upload/download, webhooks, auth flows, backup/restore drill


## Resources


- **[Architecture Details](copilot-architecture.md)**: Multi-flavor system, business modes, data flow

- **[Development Workflows](copilot-workflows.md)**: Build, test, debug, and deployment processes

- **[Database Guide](copilot-database.md)**: SQLite to Isar migration, sync patterns

---
*Last updated: January 22, 2026 (v1.0.27)*
