# Reports & Analytics Quick Reference - Option C

**Version**: 1.0.0 | **Status**: ✅ Complete | **Lines of Code**: 1,655

---

## Quick Start

### Import Screens

```dart
import 'package:extropos/screens/sales_dashboard_screen.dart';
import 'package:extropos/screens/category_analysis_screen.dart';
import 'package:extropos/screens/payment_breakdown_screen.dart';
import 'package:extropos/screens/customer_analytics_screen.dart';

```

### Use ReportsService

```dart
final reportsService = ReportsService();

// Generate daily report
final today = await reportsService.generateDailyReport(DateTime.now());

// Generate weekly report
final week = await reportsService.generateWeeklyReport(DateTime.now());

// Generate monthly report
final month = await reportsService.generateMonthlyReport(DateTime.now());

// Get trend data
final trend = await reportsService.getDailySalesForDateRange(
  start: DateTime.now().subtract(Duration(days: 30)),
  end: DateTime.now(),
);

```

### Access Report Data

```dart
SalesReport report = ...;

print('Gross Sales: RM ${report.grossSales.toStringAsFixed(2)}');
print('Net Sales: RM ${report.netSales.toStringAsFixed(2)}');
print('Tax: RM ${report.taxAmount.toStringAsFixed(2)} (${report.taxPercentage.toStringAsFixed(1)}%)');
print('Service Charge: RM ${report.serviceChargeAmount.toStringAsFixed(2)} (${report.serviceChargePercentage.toStringAsFixed(1)}%)');
print('Total Deductions: RM ${report.totalDeductions.toStringAsFixed(2)}');
print('Transactions: ${report.transactionCount}');
print('Customers: ${report.uniqueCustomers}');
print('Avg Ticket: RM ${report.averageTicket.toStringAsFixed(2)}');
print('Top Category: ${report.topCategory} (${report.topCategories[report.topCategory] ?? 0})');
print('Top Payment: ${report.topPaymentMethod} (${report.paymentMethods[report.topPaymentMethod] ?? 0})');

```

---

## Component Reference

### SalesReport Model

**File**: `lib/models/sales_report.dart` (266 lines)

**Key Properties**:

```dart
final String id;
final DateTime startDate, endDate;
final String reportType;  // 'daily', 'weekly', 'monthly', 'custom'
final double grossSales, netSales, taxAmount, serviceChargeAmount;
final int transactionCount, uniqueCustomers;
final double averageTicket, averageTransactionTime;
final Map<String, double> topCategories, paymentMethods;
final DateTime generatedAt;

```

**Computed Properties**:

```dart
double get totalDeductions => taxAmount + serviceChargeAmount;

double get discountPercentage => ((grossSales - netSales) / grossSales * 100);

double get taxPercentage => ((taxAmount / grossSales) * 100);

double get serviceChargePercentage => ((serviceChargeAmount / grossSales) * 100);

double get totalRevenue => netSales;
String? get topPaymentMethod => paymentMethods.isEmpty ? null : 
  paymentMethods.entries.reduce((a, b) => a.value > b.value ? a : b).key;
String? get topCategory => topCategories.isEmpty ? null : 
  topCategories.entries.reduce((a, b) => a.value > b.value ? a : b).key;

```

**Methods**:

```dart
// Create modified copy
SalesReport copyWith({
  String? id,
  DateTime? startDate,
  // ... other fields
})

// Serialization
Map<String, dynamic> toMap()
SalesReport.fromMap(Map<String, dynamic> map)
String toJson() // returns JSON string
SalesReport.fromJson(dynamic json) // accepts Map or String

```

### ReportsService

**File**: `lib/services/reports_service.dart` (290 lines)

**Singleton Pattern**:

```dart
final service = ReportsService(); // Always returns same instance

```

**Core Methods**:

```dart
// Generate reports
Future<SalesReport> generateDailyReport(DateTime date)
Future<SalesReport> generateWeeklyReport(DateTime date)
Future<SalesReport> generateMonthlyReport(DateTime date)

// Get trend data
Future<List<SalesReport>> getDailySalesForDateRange(
  DateTime start,
  DateTime end,
)

// Get statistics
Map<String, dynamic> getReportStats(SalesReport report)

```

**Report Statistics Returned**:

- `totalRevenue`: Net sales

- `totalTransactions`: Transaction count

- `averageTicket`: Average transaction value

- `totalCustomers`: Unique customer count

- `topCategory`: Best-selling category

- `topPaymentMethod`: Most used payment method

- `totalTax`: Tax amount

- `totalServiceCharge`: Service charge amount

---

## Screen Reference

### Sales Dashboard Screen

**File**: `lib/screens/sales_dashboard_screen.dart` (347 lines)

**Features**:

- 6-period selector (Today, Yesterday, This Week, Last Week, This Month, Last Month)

- 4 KPI cards: Gross Sales, Net Sales, Transactions, Avg Ticket

- Charges & Deductions breakdown

- Payment Methods breakdown

- Top Categories breakdown

**Navigation**:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => SalesDashboardScreen()),
);

```

**Key Widgets**:

```dart
// Period selector
FilterChip(label: Text('Today'), onSelected: ...)

// KPI card
Card(
  child: Container(
    decoration: BoxDecoration(gradient: ...),
    child: Column(
      children: [Icon(...), Text(label), Text(value)],
    ),
  ),
)

// Breakdown section
_buildPaymentMethodRow(label, amount, total)
_buildCategoryRow(label, amount, total)
_buildChargeLine(label, amount, percentage)

```

---

### Category Analysis Screen

**File**: `lib/screens/category_analysis_screen.dart` (224 lines)

**Features**:

- Summary card (Total Revenue, Category Count, Transactions)

- Sort options: Revenue, Alphabetical

- Category cards with progress bars

- Color-coded categories (5 colors)

**Navigation**:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => CategoryAnalysisScreen()),
);

```

**Color Scheme**:

```dart
const colors = [
  Color(0xFF2563EB),  // Blue
  Color(0xFF16A34A),  // Green
  Color(0xFFF59E0B),  // Orange
  Color(0xFF7C3AED),  // Purple
  Color(0xFFDC2626),  // Red
];

```

---

### Payment Breakdown Screen

**File**: `lib/screens/payment_breakdown_screen.dart` (238 lines)

**Features**:

- Gradient header with total revenue

- Payment method cards

- Sorted by amount (highest first)

- Progress bars showing distribution

- Color-coded payment methods

**Navigation**:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => PaymentBreakdownScreen()),
);

```

**Responsive Layout**:

```dart
// 1 column on phones < 600px
// 2 columns on tablets >= 600px
// 3+ columns on desktops >= 1200px

```

---

### Customer Analytics Screen

**File**: `lib/screens/customer_analytics_screen.dart` (290 lines)

**Features**:

- Date range picker

- 4 KPI metrics (Total Customers, Avg Value, Repeat Rate, Retention)

- Customer segments (High Value, Regular, New)

- Spending distribution chart

- Color-coded visual indicators

**Navigation**:

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => CustomerAnalyticsScreen()),
);

```

**Key Metrics**:

```dart
// Total Customers
report.uniqueCustomers

// Avg Customer Value
report.netSales / report.uniqueCustomers

// Repeat Rate
report.transactionCount / report.uniqueCustomers

// Customer Retention
(report.uniqueCustomers / report.transactionCount) * 100

```

---

## Common Patterns

### Loading Data in Screen

```dart
late SalesReport? currentReport;
late bool isLoading = true;

@override
void initState() {
  super.initState();
  _loadReport();
}

Future<void> _loadReport() async {
  try {
    setState(() => isLoading = true);
    final report = await ReportsService().generateMonthlyReport(DateTime.now());
    setState(() {
      currentReport = report;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ Error: $e')),
    );
  }
}

```

### Building Responsive Grids

```dart
LayoutBuilder(
  builder: (context, constraints) {
    int columns = 4;
    if (constraints.maxWidth < 600) columns = 1;
    else if (constraints.maxWidth < 900) columns = 2;
    else if (constraints.maxWidth < 1200) columns = 3;
    
    return GridView.count(
      crossAxisCount: columns,
      children: items.map((item) => _buildCard(item)).toList(),
    );
  },
)

```

### Building Progress Bars

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(4),
  child: LinearProgressIndicator(
    value: percentage / 100,  // 0.0 to 1.0
    minHeight: 12,
    backgroundColor: Colors.grey[200],
    valueColor: AlwaysStoppedAnimation<Color>(color),
  ),
)

```

### Date Range Handling

```dart
final startMs = startDate.millisecondsSinceEpoch;
final endMs = endDate.millisecondsSinceEpoch;

final transactions = await db.query(
  'transactions',
  where: 'transaction_date BETWEEN ? AND ?',
  whereArgs: [startMs, endMs],
);

```

### Color-Coded Categories

```dart
const colors = [
  Color(0xFF2563EB),  // 0 - Blue
  Color(0xFF16A34A),  // 1 - Green
  Color(0xFFF59E0B),  // 2 - Orange
  Color(0xFF7C3AED),  // 3 - Purple
  Color(0xFFDC2626),  // 4 - Red

];

Color getColor(int index) => colors[index % colors.length];

```

---

## Testing

### Run SalesReport Tests

```bash

# All tests

flutter test test/models/sales_report_test.dart


# Specific test group

flutter test test/models/sales_report_test.dart --name "Initialization"


# Verbose output

flutter test test/models/sales_report_test.dart -v

```

### Test Coverage

**28 Tests Total**:

- 1 Initialization test

- 1 copyWith test

- 5 Computed property tests

- 2 Top value tests

- 2 Serialization tests

- 5 Edge case tests

- 3 Date handling tests

- 3 Calculation accuracy tests

- 2 Round-trip serialization tests

- 4 Report type validation tests

- 2 Distribution sorting tests

---

## Integration Points

### With Business Info

```dart
// Use for tax/service charge settings
final info = BusinessInfo.instance;
final taxRate = info.taxRate;
final serviceChargeRate = info.serviceChargeRate;

```

### With Shift Management (Option A)

```dart
// Generate shift-specific reports
final shiftId = currentShift.id;
// Filter transactions by shiftId

```

### With Loyalty Program (Option B)

```dart
// Calculate loyalty member metrics
final loyaltyTransactions = report.transactions
  .where((t) => t.customerId != null)
  .toList();

```

---

## Performance Tips

### Optimize Database Queries

```dart
// ✅ Good - Filtered query

final txs = await db.query(
  'transactions',
  where: 'transaction_date >= ? AND transaction_date <= ?',
  whereArgs: [startMs, endMs],
);

// ❌ Bad - Fetch all then filter

final txs = await db.query('transactions');
final filtered = txs.where((t) => ...).toList();

```

### Cache Report Results

```dart
// Store generated report to avoid regenerating
SalesReport? _cachedMonthlyReport;
DateTime? _cacheDate;

Future<SalesReport> getMonthlyReport(DateTime month) async {
  if (_cachedMonthlyReport != null && 
      _cacheDate?.month == month.month &&
      _cacheDate?.year == month.year) {
    return _cachedMonthlyReport!;
  }
  
  final report = await ReportsService().generateMonthlyReport(month);
  _cachedMonthlyReport = report;
  _cacheDate = month;
  return report;
}

```

### Use Lazy Loading

```dart
// ✅ Good - Build items as needed

GridView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => _buildCard(items[index]),
)

// ❌ Bad - Build all at once

GridView(
  children: items.map((item) => _buildCard(item)).toList(),
)

```

---

## Troubleshooting

### Report Returns No Data

**Check**:

1. Database has transactions in date range
2. Transaction dates are in milliseconds since epoch
3. No typos in query WHERE clause

**Fix**:

```dart
// Verify database contents
final allTxs = await db.query('transactions');
print('Total transactions: ${allTxs.length}');

// Check specific date range
final ms1 = DateTime(2024, 1, 1).millisecondsSinceEpoch;
final ms2 = DateTime(2024, 1, 31).millisecondsSinceEpoch;
final rangedTxs = await db.query(
  'transactions',
  where: 'transaction_date BETWEEN ? AND ?',
  whereArgs: [ms1, ms2],
);
print('Transactions in Jan 2024: ${rangedTxs.length}');

```

### Calculation Shows Wrong Results

**Check**:

1. BusinessInfo tax/service charge rates are correct
2. Gross sales > net sales (after discounts)
3. Payment methods sum equals total

**Fix**:

```dart
// Verify BusinessInfo settings
final info = BusinessInfo.instance;
print('Tax enabled: ${info.isTaxEnabled}');
print('Tax rate: ${info.taxRate}');
print('Service charge enabled: ${info.isServiceChargeEnabled}');
print('Service charge rate: ${info.serviceChargeRate}');

```

### Screen Not Displaying

**Check**:

1. ReportsService singleton properly initialized
2. Database accessible and populated
3. Try-catch block catching errors silently

**Fix**:

```dart
// Add debug logging
Future<void> _loadReport() async {
  try {
    print('📊 Loading report...');
    final report = await ReportsService().generateDailyReport(DateTime.now());
    print('✅ Report loaded: Gross=${report.grossSales}');
    setState(() => currentReport = report);
  } catch (e, st) {
    print('❌ Error: $e');
    print(st);
  }
}

```

---

## Code Examples

### Create Custom Report

```dart
final customReport = SalesReport(
  id: 'custom_1',
  startDate: DateTime(2024, 1, 1),
  endDate: DateTime(2024, 1, 31),
  reportType: 'custom',
  grossSales: 5000.0,
  netSales: 4500.0,
  taxAmount: 500.0,
  serviceChargeAmount: 250.0,
  transactionCount: 100,
  uniqueCustomers: 80,
  averageTicket: 50.0,
  averageTransactionTime: 2.5,
  topCategories: {
    'Food': 2500.0,
    'Beverages': 1500.0,
    'Desserts': 500.0,
  },
  paymentMethods: {
    'Cash': 3000.0,
    'Card': 1500.0,
  },
  generatedAt: DateTime.now(),
);

print('Custom report: ${customReport.grossSales}');

```

### Export Report to JSON

```dart
final report = await ReportsService().generateMonthlyReport(DateTime.now());
final json = jsonEncode(report.toJson());
print(json);
// Save to file or send to backend

```

### Compare Period Reports

```dart
final prevMonth = await ReportsService()
  .generateMonthlyReport(DateTime.now().subtract(Duration(days: 30)));
final thisMonth = await ReportsService()
  .generateMonthlyReport(DateTime.now());

final growth = ((thisMonth.grossSales - prevMonth.grossSales) / prevMonth.grossSales * 100);

print('Month-over-month growth: ${growth.toStringAsFixed(2)}%');

```

---

## Resources

- **Implementation Guide**: `docs/OPTION_C_IMPLEMENTATION_GUIDE.md`

- **Model Tests**: `test/models/sales_report_test.dart`

- **Related Options**:

  - Option A (Shift Management): `docs/OPTION_A_QUICK_REFERENCE.md`

  - Option B (Loyalty Program): `docs/OPTION_B_QUICK_REFERENCE.md`

---

*Last Updated: January 2026*
