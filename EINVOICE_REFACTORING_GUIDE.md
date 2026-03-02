# E-Invoice Refactoring Implementation Guide

## Project Structure Overview

### New Models (Layer A - Core Logic)
Located in `lib/models/einvoice/`:

- **`submission.dart`**: Represents a submission to LHDN MyInvois
  - Properties: id, date, buyer, total, uin, status
  - Methods: fromJson(), toJson()

- **`unconsolidated_receipt.dart`**: Represents retail receipts awaiting consolidation
  - Properties: id, date, total, itemsCount
  - Methods: fromJson(), toJson()

- **`lhdn_config.dart`**: Stores LHDN/MyInvois API credentials
  - Properties: businessName, tin, regNo, clientId, clientSecret
  - Utility: isComplete getter for validation

### New Screens (Layer B - Presentation Components)
Located in `lib/screens/`:

1. **`submissions_screen.dart`**
   - Displays history of submitted invoices
   - Includes search, filter, and submission controls
   - Shows status badges (Validated/Rejected/Pending)
   - Fully stateless component (parameters-driven)

2. **`consolidate_screen.dart`**
   - Batch consolidation of receipts into single e-invoice
   - Left panel: List of unconsolidated receipts
   - Right panel: Summary with totals and tax calculation
   - LHDN compliance notice banner
   - Responsive two-column layout

3. **`lhdn_config_dialog.dart`**
   - Modal dialog for API configuration
   - Sections: Business Profile, MyInvois Credentials
   - Form validation and submission
   - Clean sectioned layout with dividers

### Service Layer (Layer A - Business Logic)
Located in `lib/services/`:

- **`einvoice_business_logic_service.dart`**
  - Pure Dart service with NO Flutter dependencies
  - Fully unit-testable business logic
  - Key methods:
    - `filterSubmissions()`: Search/filter logic
    - `calculateTotalAmount()`: Sum receipts
    - `calculateTaxAmount()`: 6% Malaysian tax
    - `isConfigValid()`: Validation logic
    - `getSubmissionsSummary()`: Statistics
    - `sortSubmissionsByDate()`: Sorting
    - `formatCurrency()`: Display formatting

### Integration Screen (Layer C - Orchestration)
Located in `lib/screens/`:

- **`einvoice_module_screen.dart`**
  - Main entry point combining all components
  - Two tabs: Submissions, Consolidate
  - State management and data loading
  - Routes user interactions to service calls
  - Delegates calculations to Layer A

## Architecture Pattern: Three-Layer Separation

```
┌─────────────────────────────────────────────────┐
│  Layer C: Screen (Orchestration)                │
│  einvoice_module_screen.dart                    │
│  - Imports services & widgets                   │
│  - Manages state & navigation                   │
│  - Delegates logic to Layer A                   │
└─────────────────────────────────────────────────┘
              ↓                      ↓
┌──────────────────────────┐  ┌──────────────────────────┐
│ Layer B: Widgets         │  │ Layer A: Services        │
│ - submissions_screen     │  │ - business_logic_svc     │
│ - consolidate_screen     │  │ - einvoice_service       │
│ - lhdn_config_dialog     │  │                          │
└──────────────────────────┘  └──────────────────────────┘
```

## File Sizes Compliance
All files follow the 500-line maximum rule:

- `submission.dart`: ~30 lines ✓
- `unconsolidated_receipt.dart`: ~35 lines ✓
- `lhdn_config.dart`: ~45 lines ✓
- `submissions_screen.dart`: ~180 lines ✓
- `consolidate_screen.dart`: ~250 lines ✓
- `lhdn_config_dialog.dart`: ~200 lines ✓
- `einvoice_business_logic_service.dart`: ~150 lines ✓
- `einvoice_module_screen.dart`: ~180 lines ✓

**Total**: 1,070 lines across 8 focused files

## Integration Steps

### 1. Update Route Navigation (main.dart)

Add route for the new e-invoice module:

```dart
'/einvoice': (_) => const EInvoiceModuleScreen(),
```

### 2. Update Existing Services

The `EInvoiceService` can now be extended to use the new models:

```dart
// In einvoice_service.dart
Future<LhdnConfig> loadConfig() async {
  // Load from database
  final configData = await databaseHelper.query('einvoice_config');
  return LhdnConfig.fromJson(configData);
}

Future<void> saveConfig(LhdnConfig config) async {
  // Save to database
  await databaseHelper.update('einvoice_config', config.toJson());
}
```

### 3. Database Tables (if needed)

Create tables for persistence:

```sql
CREATE TABLE einvoice_config (
  id TEXT PRIMARY KEY,
  businessName TEXT,
  tin TEXT,
  regNo TEXT,
  clientId TEXT,
  clientSecret TEXT,
  createdAt DATETIME,
  updatedAt DATETIME
);

CREATE TABLE submissions (
  id TEXT PRIMARY KEY,
  date TEXT,
  buyer TEXT,
  total REAL,
  uin TEXT,
  status TEXT,
  createdAt DATETIME
);

CREATE TABLE unconsolidated_receipts (
  id TEXT PRIMARY KEY,
  date TEXT,
  total REAL,
  itemsCount INTEGER,
  createdAt DATETIME
);
```

## Data Flow Example

### Submissions Screen Flow:
1. User navigates to `/einvoice`
2. `EInvoiceModuleScreen` loads submissions from `EInvoiceService`
3. Data converted from API responses to `Submission` objects
4. Sorted by date using `EInvoiceBusinessLogicService.sortSubmissionsByDate()`
5. Filtered by search query using `filterSubmissions()`
6. Passed to `SubmissionsScreen` as immutable data
7. User actions invoke callbacks in `EInvoiceModuleScreen`
8. Screen calls service methods or business logic

### Consolidate Screen Flow:
1. Show list of `UnconsolidatedReceipt` objects
2. Calculate total using `calculateTotalAmount()` (Layer A)
3. Calculate tax using `calculateTaxAmount()` (Layer A)
4. Display summary with formatted currency
5. On submit, call consolidation service
6. Update UI with success/error feedback

## Testing Strategy

### Layer A (Services) - Unit Tests
Test business logic in isolation:

```dart
test('filterSubmissions filters by UIN', () {
  final submissions = [
    Submission(id: '1', uin: 'TEST001', status: 'Validated', ...),
    Submission(id: '2', uin: 'LIVE001', status: 'Validated', ...),
  ];
  
  final filtered = EInvoiceBusinessLogicService.filterSubmissions(
    submissions, 
    'TEST'
  );
  
  expect(filtered.length, equals(1));
  expect(filtered.first.uin, equals('TEST001'));
});
```

### Layer B (Widgets) - Widget Tests
Test component rendering:

```dart
testWidgets('SubmissionItemRow displays status badge', (WidgetTester tester) async {
  final submission = Submission(
    id: 'INV-001',
    status: 'Validated',
    ...
  );
  
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SubmissionItemRow(submission: submission),
    ),
  ));
  
  expect(find.text('Validated'), findsOneWidget);
});
```

### Layer C (Screens) - Integration Tests
Test complete flows:

```dart
testWidgets('Submit to LHDN flow', (WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(
    home: EInvoiceModuleScreen(),
  ));
  
  // Verify initial state
  expect(find.text('E-Invoice Management'), findsOneWidget);
  
  // Interaction tests...
});
```

## Customization Points

### 1. Tax Calculation
Located in `einvoice_business_logic_service.dart`:

```dart
static double calculateTaxAmount(double totalAmount) {
  // Change tax rate here (currently 6% for Malaysia)
  return totalAmount * 0.06 / 1.06;
}
```

### 2. Currency Formatting
```dart
static String formatCurrency(double amount, {String currency = 'RM'}) {
  return '$currency ${amount.toStringAsFixed(2)}';
}
```

### 3. Status Mapping
Customize status display in `einvoice_module_screen.dart`:
```dart
String _mapDocumentStatus(String? status) {
  // Add custom status mappings here
}
```

## Migration from Old Implementation

### Old Files to Keep/Update:
- `einvoice_config.dart` - Keep but can deprecate
- `einvoice_document.dart` - Keep for UBL compliance
- `einvoice_service.dart` - Keep and extend with new methods
- `einvoice_config_screen.dart` - Can repurpose or keep as-is

### New Entry Point:
Replace direct navigation to old screens with:
```dart
Navigator.pushNamed(context, '/einvoice');
```

This will route to `EInvoiceModuleScreen` which orchestrates all features.

## Performance Considerations

1. **Lazy Loading**: Receipts/submissions loaded on demand
2. **Filtering**: Done in memory using Layer A services
3. **Search**: Real-time filtering, debounce if needed for large lists
4. **Sorting**: Single-pass sort by date, cached after load
5. **UI**: Responsive grid layout adapts to screen size

## Error Handling Pattern

All Layer A services throw clear exceptions:
```dart
if (!isConfigValid(config)) {
  throw Exception('Configuration incomplete: missing TIN');
}
```

Layer C catches and displays to user:
```dart
try {
  await _handleSubmit();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

## Next Steps

1. Add to `main.dart` routes
2. Implement database persistence in `DatabaseHelper`
3. Extend `EInvoiceService` with config CRUD methods
4. Add unit tests for `EInvoiceBusinessLogicService`
5. Add widget tests for UI components
6. Update backend sync if using Appwrite
7. Create admin panel for test submissions

---

**Architecture**: Three-layer modular pattern  
**Files**: 8 focused files, max 250 lines each  
**Models**: Type-safe with JSON serialization  
**Services**: Pure Dart, fully testable  
**UI**: Responsive, Material 3 compliant
