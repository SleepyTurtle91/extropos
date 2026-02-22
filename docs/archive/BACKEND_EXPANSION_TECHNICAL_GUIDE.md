# Backend Flavor - Technical Expansion Planning

**Document Type**: Architecture & Technical Planning  
**Date**: January 31, 2026  
**Audience**: Development Team, Technical Leads

---

## Overview

This document provides technical guidance for implementing the Backend Flavor expansion features. It covers architecture decisions, database design, API design, and implementation patterns.

---

## Architecture Foundation

### Current Tech Stack

```yaml
Frontend:
  Framework: Flutter Web (Dart)
  Responsive: LayoutBuilder, MediaQuery
  State: Local setState() (no external providers)
  UI Kit: Material 3

Backend:
  Platform: Appwrite
  Collections: 14 collections
  Database: Appwrite Database
  Storage: Appwrite Storage
  Auth: Appwrite Auth
  API: REST

Sync:
  Pattern: Pull-based (manual "Sync Now" button)
  Conflict: Last-write-wins
  Offline: Queued operations (future)

Local:
  SQLite: Fallback storage
  Cache: None (future: Redis)
```

### Proposed Tech Stack Additions

```yaml
# For Multi-Tenant
Database:
  - Appwrite Collections: location, location_products, location_users
  - Query Optimization: Composite indexes

# For Analytics
Aggregation:
  - Appwrite Aggregation functions
  - Denormalized collections: daily_sales, product_metrics
  - Caching: Redis for frequently accessed KPIs
  - Charts: fl_chart or charts_flutter

# For Real-Time
WebSocket:
  - Appwrite Realtime API (already supported)
  - Server-Sent Events (alternative)
  - Firebase Realtime (if budget allows)

# For Email/Notifications
Services:
  - SendGrid (Email)
  - Twilio (SMS)
  - Firebase Cloud Messaging (Push)
  - Appwrite Cloud Functions (Scheduling)

# For Files/Reports
Reporting:
  - pdf: ^3.10.0 (PDF generation)
  - excel: ^2.1.0 (Excel export)
  - csv: ^5.0.0 (CSV export)
```

---

## Feature Implementation Guides

### 1. Multi-Tenant Management System

#### Database Schema Design

```dart
// New collections needed:

1. locations (extends business info)
   - id: String (primary, document ID)
   - owner_id: String (foreign key)
   - name: String
   - address: String
   - phone: String
   - timezone: String
   - currency: String
   - is_active: bool
   - parent_location_id: String? (for sub-locations)
   - settings: Map (JSON: tax_rate, service_charge, etc.)
   - created_at: DateTime
   - updated_at: DateTime

2. location_products (link products to locations)
   - id: String
   - location_id: String (foreign key)
   - product_id: String (foreign key)
   - local_price: double (location-specific override)
   - local_cost: double (location-specific override)
   - local_quantity: double (inventory per location)
   - is_active: bool (can disable product in specific location)

3. location_users (link users to locations)
   - id: String
   - location_id: String (foreign key)
   - user_id: String (foreign key)
   - role: String (admin, manager, supervisor)
   - can_modify_products: bool
   - can_view_reports: bool
   - created_at: DateTime

4. location_inventory (per-location stock)
   - id: String
   - location_id: String
   - product_id: String
   - quantity: double
   - reorder_point: double
   - min_stock: double
   - max_stock: double
   - movements: JsonArray (stock in/out history)
   - cost_per_unit: double
   - last_counted_at: DateTime
```

#### Query Patterns

```dart
// Get products for a location
Future<List<Product>> getLocationProducts(String locationId) async {
  final result = await appwrite.database.listDocuments(
    databaseId: 'pos_db',
    collectionId: 'location_products',
    queries: [
      Query.equal('location_id', locationId),
      Query.equal('is_active', true),
    ],
  );
  
  // Fetch product details and apply location-specific overrides
  return result.documents.map((doc) {
    final product = Product.fromAppwrite(doc);
    product.price = doc.data['local_price'] ?? product.price;
    return product;
  }).toList();
}

// Get all locations for user (multi-select)
Future<List<Location>> getUserLocations(String userId) async {
  return await appwrite.database.listDocuments(
    databaseId: 'pos_db',
    collectionId: 'location_users',
    queries: [Query.equal('user_id', userId)],
  ).then((result) async {
    // Get location details for each location_id
    final locationIds = result.documents.map((d) => d.data['location_id']).toList();
    return fetchLocations(locationIds);
  });
}

// Aggregated query: Sales across all locations
Future<double> getTotalSalesAllLocations(DateTime startDate) async {
  return await appwrite.database.listDocuments(
    databaseId: 'pos_db',
    collectionId: 'transactions',
    queries: [
      Query.greaterThanOrEqual('transaction_date', startDate.millisecondsSinceEpoch),
      Query.equal('is_synced', true),
    ],
  ).then((result) {
    return result.documents.fold(0.0, (sum, doc) => sum + (doc.data['total_amount'] ?? 0));
  });
}
```

#### UI Implementation

```dart
// Location selector widget
class LocationSelector extends StatefulWidget {
  final String initialLocationId;
  final ValueChanged<String> onLocationChanged;

  const LocationSelector({
    required this.initialLocationId,
    required this.onLocationChanged,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late Future<List<Location>> locations;
  late String selectedLocationId;

  @override
  void initState() {
    super.initState();
    selectedLocationId = widget.initialLocationId;
    locations = _loadLocations();
  }

  Future<List<Location>> _loadLocations() async {
    final userId = await _getUserId();
    return _getUserLocations(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Location>>(
      future: locations,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final locationList = snapshot.data!;
        return DropdownButton<String>(
          value: selectedLocationId,
          items: locationList.map((location) {
            return DropdownMenuItem(
              value: location.id,
              child: Text(location.name),
            );
          }).toList(),
          onChanged: (newLocationId) {
            if (newLocationId != null) {
              setState(() => selectedLocationId = newLocationId);
              widget.onLocationChanged(newLocationId);
            }
          },
        );
      },
    );
  }
}

// Usage in home screen
LocationSelector(
  initialLocationId: _currentLocationId,
  onLocationChanged: (locationId) {
    setState(() {
      _currentLocationId = locationId;
      _loadLocationData(); // Reload products, inventory, reports
    });
  },
)
```

#### Testing Strategy

```dart
// Unit tests for multi-tenant queries
test('getLocationProducts returns only active products for location', () async {
  final products = await getLocationProducts('location_123');
  expect(products.every((p) => p.locationId == 'location_123'), true);
  expect(products.every((p) => p.isActive == true), true);
});

test('getLocationProducts applies location-specific pricing', () async {
  final products = await getLocationProducts('location_456');
  final product = products.first;
  expect(product.price, equals(15.99)); // Location override, not base price
});

// Integration tests for multi-location workflow
test('User can switch between locations and see different data', () async {
  final screen = MaterialApp(home: BackendHomeScreen());
  await tester.pumpWidget(screen);
  
  // Verify location selector exists
  expect(find.byType(LocationSelector), findsOneWidget);
  
  // Select location 1
  await tester.tap(find.byType(DropdownButton));
  await tester.pumpAndSettle();
  
  // Products should be for location 1
  expect(find.text('Location 1 Products'), findsWidgets);
  
  // Select location 2
  await tester.tap(find.byType(DropdownButton));
  await tester.pumpAndSettle();
  
  // Products should be for location 2
  expect(find.text('Location 2 Products'), findsWidgets);
});
```

---

### 2. Advanced Analytics & Reporting Dashboard

#### Data Model for Analytics

```dart
// Aggregation model
class SalesAnalytics {
  final double grossSales;
  final double netSales; // After discounts
  final double taxCollected;
  final int transactionCount;
  final double averageTicket;
  final Map<String, double> salesByCategory;
  final Map<String, int> salesByPaymentMethod;
  final List<HourlyTrend> hourlyTrends;
  final DateTime reportDate;

  SalesAnalytics({
    required this.grossSales,
    required this.netSales,
    required this.taxCollected,
    required this.transactionCount,
    required this.averageTicket,
    required this.salesByCategory,
    required this.salesByPaymentMethod,
    required this.hourlyTrends,
    required this.reportDate,
  });

  factory SalesAnalytics.fromAppwrite(List<DocumentModel> transactions) {
    // Aggregate transactions into analytics
    double totalGross = 0;
    double totalNet = 0;
    double totalTax = 0;
    int count = 0;
    Map<String, double> byCategory = {};
    Map<String, int> byPayment = {};
    
    for (var tx in transactions) {
      totalGross += tx.data['total_amount'] ?? 0;
      totalNet += (tx.data['total_amount'] ?? 0) - (tx.data['discount_amount'] ?? 0);
      totalTax += tx.data['tax_amount'] ?? 0;
      count++;
      
      // Category breakdown
      final items = jsonDecode(tx.data['items_json'] ?? '[]');
      for (var item in items) {
        final category = item['category'] ?? 'Other';
        byCategory[category] = (byCategory[category] ?? 0) + (item['line_total'] ?? 0);
      }
      
      // Payment breakdown
      final method = tx.data['payment_method'] ?? 'Unknown';
      byPayment[method] = (byPayment[method] ?? 0) + 1;
    }
    
    return SalesAnalytics(
      grossSales: totalGross,
      netSales: totalNet,
      taxCollected: totalTax,
      transactionCount: count,
      averageTicket: count > 0 ? totalNet / count : 0,
      salesByCategory: byCategory,
      salesByPaymentMethod: byPayment,
      hourlyTrends: _calculateHourlyTrends(transactions),
      reportDate: DateTime.now(),
    );
  }
}

// Denormalized collection for fast queries (updated daily)
// daily_sales:
//   - date: DateTime
//   - location_id: String
//   - gross_sales: double
//   - net_sales: double
//   - tax_collected: double
//   - transaction_count: int
//   - avg_ticket: double
//   - sales_by_category: Map<String, double>
//   - sales_by_payment: Map<String, int>
```

#### Analytics Query Service

```dart
class AnalyticsService {
  // Fetch analytics for date range (uses denormalized data if available)
  Future<SalesAnalytics> getAnalytics(
    DateTime startDate,
    DateTime endDate,
    String locationId,
  ) async {
    // Try to use denormalized daily_sales for speed
    final dailyRecords = await appwrite.database.listDocuments(
      databaseId: 'pos_db',
      collectionId: 'daily_sales',
      queries: [
        Query.equal('location_id', locationId),
        Query.greaterThanOrEqual('date', startDate.millisecondsSinceEpoch),
        Query.lessThanOrEqual('date', endDate.millisecondsSinceEpoch),
      ],
    );
    
    // Aggregate daily records
    double totalGross = 0;
    double totalNet = 0;
    int totalTransactions = 0;
    
    for (var record in dailyRecords.documents) {
      totalGross += record.data['gross_sales'] ?? 0;
      totalNet += record.data['net_sales'] ?? 0;
      totalTransactions += record.data['transaction_count'] ?? 0;
    }
    
    return SalesAnalytics(
      grossSales: totalGross,
      netSales: totalNet,
      // ... other fields
    );
  }
  
  // Top products (from product_metrics denormalized table)
  Future<List<ProductMetrics>> getTopProducts({
    required DateTime startDate,
    required DateTime endDate,
    required String locationId,
    int limit = 10,
  }) async {
    return await appwrite.database.listDocuments(
      databaseId: 'pos_db',
      collectionId: 'product_metrics',
      queries: [
        Query.equal('location_id', locationId),
        Query.greaterThanOrEqual('date', startDate.millisecondsSinceEpoch),
        Query.lessThanOrEqual('date', endDate.millisecondsSinceEpoch),
        Query.orderDesc('total_sold'),
        Query.limit(limit),
      ],
    ).then((result) => result.documents.map(ProductMetrics.fromAppwrite).toList());
  }
  
  // Comparison (week-over-week, month-over-month)
  Future<ComparisonMetrics> getComparison({
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
    required String locationId,
  }) async {
    final current = await getAnalytics(currentStart, currentEnd, locationId);
    final previous = await getAnalytics(previousStart, previousEnd, locationId);
    
    return ComparisonMetrics(
      currentGross: current.grossSales,
      previousGross: previous.grossSales,
      growthPercent: ((current.grossSales - previous.grossSales) / previous.grossSales) * 100,
      // ... other metrics
    );
  }
}
```

#### UI Implementation

```dart
class AnalyticsDashboard extends StatefulWidget {
  final String locationId;

  const AnalyticsDashboard({required this.locationId});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  late DateRange _selectedDateRange;
  late Future<SalesAnalytics> _analyticsData;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = DateRange(
      start: DateTime.now().subtract(Duration(days: 7)),
      end: DateTime.now(),
    );
    _loadAnalytics();
  }

  void _loadAnalytics() {
    _analyticsData = AnalyticsService().getAnalytics(
      _selectedDateRange.start,
      _selectedDateRange.end,
      widget.locationId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Date range selector
          DateRangeSelector(
            selectedRange: _selectedDateRange,
            onRangeChanged: (range) {
              setState(() {
                _selectedDateRange = range;
                _loadAnalytics();
              });
            },
          ),
          
          // KPI Cards
          FutureBuilder<SalesAnalytics>(
            future: _analyticsData,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return LoadingWidget();
              
              final analytics = snapshot.data!;
              
              return Column(
                children: [
                  // KPI Row
                  Row(
                    children: [
                      KPICard(
                        title: 'Gross Sales',
                        value: '${BusinessInfo.instance.currencySymbol} ${analytics.grossSales.toStringAsFixed(2)}',
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                      KPICard(
                        title: 'Transactions',
                        value: '${analytics.transactionCount}',
                        icon: Icons.shopping_cart,
                        color: Colors.blue,
                      ),
                      KPICard(
                        title: 'Average Ticket',
                        value: '${BusinessInfo.instance.currencySymbol} ${analytics.averageTicket.toStringAsFixed(2)}',
                        icon: Icons.receipt,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                  
                  // Charts
                  SalesChart(data: analytics.hourlyTrends),
                  CategoryBreakdownChart(data: analytics.salesByCategory),
                  PaymentMethodChart(data: analytics.salesByPaymentMethod),
                  
                  // Top Products
                  TopProductsList(locationId: widget.locationId),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
```

---

### 3. Real-Time Inventory System

#### Database Schema

```dart
class InventoryItem {
  final String id;
  final String locationId;
  final String productId;
  final double currentQuantity;
  final double minStockLevel;
  final double maxStockLevel;
  final double reorderQuantity;
  final double costPerUnit;
  final List<StockMovement> movements; // Last 30 days
  final DateTime lastCountedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  double get inventoryValue => currentQuantity * costPerUnit;
  bool get isLowStock => currentQuantity < minStockLevel;
  bool get needsReorder => currentQuantity <= reorderQuantity;
}

class StockMovement {
  final String id;
  final String type; // 'sale', 'purchase', 'adjustment', 'count'
  final double quantity;
  final String reason; // 'End of day count', 'Supplier delivery', etc.
  final String createdBy; // User ID
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // Reference to transaction/PO
}
```

#### Inventory Operations Service

```dart
class InventoryService {
  // Record stock adjustment
  Future<void> adjustStock({
    required String locationId,
    required String productId,
    required double quantity,
    required String reason,
    required String userId,
  }) async {
    // Record movement
    final movement = StockMovement(
      id: '', // Generated by Appwrite
      type: 'adjustment',
      quantity: quantity,
      reason: reason,
      createdBy: userId,
      createdAt: DateTime.now(),
    );
    
    // Update inventory
    final currentItem = await _getInventoryItem(locationId, productId);
    final newQuantity = currentItem.currentQuantity + quantity;
    
    await appwrite.database.updateDocument(
      databaseId: 'pos_db',
      collectionId: 'inventory',
      documentId: currentItem.id,
      data: {
        'current_quantity': newQuantity,
        'movements': [...currentItem.movements, movement.toMap()],
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
    );
    
    // Trigger low stock alert if needed
    if (newQuantity < currentItem.minStockLevel) {
      _notifyLowStock(locationId, productId, newQuantity);
    }
  }
  
  // Record sale (called from POS after transaction)
  Future<void> recordSale({
    required String locationId,
    required String productId,
    required double quantity,
    required String transactionId,
  }) async {
    await adjustStock(
      locationId: locationId,
      productId: productId,
      quantity: -quantity,
      reason: 'Sale',
      userId: 'pos_system',
    );
    
    // Update transaction reference in movement
  }
  
  // Get low stock items
  Future<List<InventoryItem>> getLowStockItems(String locationId) async {
    final items = await appwrite.database.listDocuments(
      databaseId: 'pos_db',
      collectionId: 'inventory',
      queries: [
        Query.equal('location_id', locationId),
        Query.lessThanOrEqual('current_quantity', Query.field('min_stock_level')),
      ],
    );
    
    return items.documents.map(InventoryItem.fromAppwrite).toList();
  }
  
  // Stock take (physical count)
  Future<void> performStockTake({
    required String locationId,
    required Map<String, double> countedQuantities, // productId -> quantity
    required String userId,
  }) async {
    for (final entry in countedQuantities.entries) {
      final productId = entry.key;
      final countedQty = entry.value;
      final currentItem = await _getInventoryItem(locationId, productId);
      final variance = countedQty - currentItem.currentQuantity;
      
      if (variance != 0) {
        await adjustStock(
          locationId: locationId,
          productId: productId,
          quantity: variance,
          reason: 'Physical stock count',
          userId: userId,
        );
      }
    }
  }
}
```

#### Inventory Dashboard UI

```dart
class InventoryDashboard extends StatefulWidget {
  final String locationId;

  const InventoryDashboard({required this.locationId});

  @override
  State<InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends State<InventoryDashboard> {
  late Future<List<InventoryItem>> lowStockItems;

  @override
  void initState() {
    super.initState();
    lowStockItems = InventoryService().getLowStockItems(widget.locationId);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Low Stock Alerts
        FutureBuilder<List<InventoryItem>>(
          future: lowStockItems,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox.shrink();
            
            final items = snapshot.data!;
            if (items.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Text('All items in stock'),
              );
            }
            
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return LowStockCard(
                  item: item,
                  onReorder: () => _showReorderDialog(item),
                  onAdjust: () => _showAdjustmentDialog(item),
                );
              },
            );
          },
        ),
        
        // Inventory Stats
        Row(
          children: [
            StatCard(
              title: 'Total Inventory Value',
              value: '${BusinessInfo.instance.currencySymbol} ${_getTotalInventoryValue()}',
            ),
            StatCard(
              title: 'Items Low on Stock',
              value: '${_getLowStockCount()}',
              color: Colors.red,
            ),
          ],
        ),
        
        // Stock Take Button
        ElevatedButton.icon(
          icon: Icon(Icons.assignment),
          label: Text('Perform Stock Take'),
          onPressed: () => _showStockTakeDialog(),
        ),
      ],
    );
  }
}
```

---

### 4. User & Access Control Management

#### RBAC Data Model

```dart
class Role {
  final String id;
  final String name; // 'Admin', 'Manager', 'Supervisor', 'Viewer'
  final String description;
  final Map<String, bool> permissions; // Map of permission_key -> granted
  final DateTime createdAt;

  // Standard permissions
  static const Map<String, String> permissionMap = {
    'view_dashboard': 'View dashboard and KPIs',
    'manage_products': 'Create/edit/delete products',
    'manage_categories': 'Create/edit/delete categories',
    'manage_modifiers': 'Create/edit/delete modifiers',
    'manage_users': 'Create/edit/delete users',
    'manage_roles': 'Create/edit/delete roles',
    'view_reports': 'View sales reports',
    'export_data': 'Export data (CSV, PDF)',
    'manage_promotions': 'Create/edit promotions',
    'manage_inventory': 'Adjust stock levels',
    'view_financial': 'View costs, margins, financial data',
    'manage_settings': 'Change business settings',
    'view_audit_log': 'View activity logs',
  };

  // Predefined roles
  static final Role admin = Role(
    id: 'admin',
    name: 'Administrator',
    description: 'Full access to all features',
    permissions: {for (var key in permissionMap.keys) key: true},
    createdAt: DateTime.now(),
  );

  static final Role manager = Role(
    id: 'manager',
    name: 'Manager',
    description: 'Manage products and view reports',
    permissions: {
      'view_dashboard': true,
      'manage_products': true,
      'manage_categories': true,
      'manage_modifiers': true,
      'view_reports': true,
      'export_data': true,
      'manage_inventory': true,
      'view_financial': true,
      'view_audit_log': true,
      // false for: manage_users, manage_roles, manage_settings
    },
    createdAt: DateTime.now(),
  );

  static final Role viewer = Role(
    id: 'viewer',
    name: 'Viewer',
    description: 'Read-only access to reports',
    permissions: {
      'view_dashboard': true,
      'view_reports': true,
      'view_financial': false,
      // false for all modifications
    },
    createdAt: DateTime.now(),
  );
}

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final String roleId;
  final List<String> locationIds; // Which locations this user can access
  final bool isActive;
  final DateTime lastLoginAt;
  final DateTime createdAt;
}

class ActivityLog {
  final String id;
  final String userId;
  final String userName;
  final String action; // 'product_created', 'product_updated', 'inventory_adjusted'
  final String resourceType; // 'product', 'category', 'inventory'
  final String resourceId;
  final Map<String, dynamic> changes; // What changed
  final String? notes;
  final DateTime createdAt;
}
```

#### Access Control Service

```dart
class AccessControlService {
  // Check if user has permission
  Future<bool> hasPermission(String userId, String permissionKey) async {
    final user = await _getUser(userId);
    final role = await _getRole(user.roleId);
    return role.permissions[permissionKey] ?? false;
  }

  // Check if user can access location
  Future<bool> canAccessLocation(String userId, String locationId) async {
    final user = await _getUser(userId);
    return user.locationIds.contains(locationId);
  }

  // Log activity
  Future<void> logActivity({
    required String userId,
    required String action,
    required String resourceType,
    required String resourceId,
    Map<String, dynamic>? changes,
    String? notes,
  }) async {
    final user = await _getUser(userId);
    final log = ActivityLog(
      id: '', // Generated by Appwrite
      userId: userId,
      userName: user.name,
      action: action,
      resourceType: resourceType,
      resourceId: resourceId,
      changes: changes ?? {},
      notes: notes,
      createdAt: DateTime.now(),
    );

    await appwrite.database.createDocument(
      databaseId: 'pos_db',
      collectionId: 'activity_logs',
      documentId: 'unique()',
      data: log.toMap(),
    );
  }

  // Get activity log for audit trail
  Future<List<ActivityLog>> getActivityLog({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    String? resourceId,
  }) async {
    final queries = [
      Query.greaterThanOrEqual('created_at', startDate.millisecondsSinceEpoch),
      Query.lessThanOrEqual('created_at', endDate.millisecondsSinceEpoch),
      if (userId != null) Query.equal('user_id', userId),
      if (resourceId != null) Query.equal('resource_id', resourceId),
      Query.orderDesc('created_at'),
    ];

    final result = await appwrite.database.listDocuments(
      databaseId: 'pos_db',
      collectionId: 'activity_logs',
      queries: queries,
    );

    return result.documents.map(ActivityLog.fromAppwrite).toList();
  }
}
```

#### Permission Guard Decorator

```dart
// Use this to protect screens/features
class PermissionGuard {
  static Widget withPermission({
    required String permissionKey,
    required Widget Function(BuildContext) builder,
    required BuildContext context,
  }) {
    return FutureBuilder<bool>(
      future: AccessControlService().hasPermission(_getUserId(), permissionKey),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        
        if (!snapshot.data!) {
          return Center(
            child: Text(
              'You do not have permission to access this feature',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        return builder(context);
      },
    );
  }
}

// Usage in screens
@override
Widget build(BuildContext context) {
  return PermissionGuard.withPermission(
    permissionKey: 'manage_products',
    context: context,
    builder: (context) => ItemsManagementScreen(),
  );
}
```

---

## Database Optimization Strategies

### 1. Indexing Strategy

```appwrite
// Create composite indexes for common queries

// Multi-tenant queries
location_id + is_active
location_id + created_at

// Analytics queries
location_id + transaction_date + is_synced
location_id + payment_method

// Inventory queries
location_id + current_quantity
location_id + is_low_stock

// Audit queries
user_id + created_at
resource_id + action
```

### 2. Denormalization for Performance

```
// Daily aggregation collection: daily_sales
Purpose: Avoid querying millions of transactions for analytics
Update: Nightly via Cloud Function
Fields: location, date, gross_sales, net_sales, count, metrics

// Product metrics collection: product_metrics
Purpose: Fast top products queries
Update: Daily aggregation
Fields: product_id, location, date, units_sold, revenue, profit

// Update Frequency: Daily at 2 AM (off-peak)
// Retention: 2 years of daily data
```

### 3. Query Optimization

```dart
// ❌ SLOW: Query all transactions and filter in code
final allTransactions = await db.listDocuments(
  databaseId: 'pos_db',
  collectionId: 'transactions',
);
final filtered = allTransactions.documents
    .where((t) => t.data['location_id'] == locationId)
    .where((t) => t.data['created_at'] > startDate)
    .toList();

// ✅ FAST: Let database filter
final filtered = await db.listDocuments(
  databaseId: 'pos_db',
  collectionId: 'transactions',
  queries: [
    Query.equal('location_id', locationId),
    Query.greaterThanOrEqual('created_at', startDate.millisecondsSinceEpoch),
  ],
);
```

---

## Caching Strategy

### Layer 1: In-Memory Cache (App Level)

```dart
class CacheService {
  static final CacheService _instance = CacheService._internal();
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final int _cacheExpiryMinutes = 5;

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  void set(String key, dynamic value) {
    _cache[key] = value;
    _timestamps[key] = DateTime.now();
  }

  dynamic get(String key) {
    if (!_cache.containsKey(key)) return null;
    
    final timestamp = _timestamps[key]!;
    if (DateTime.now().difference(timestamp).inMinutes > _cacheExpiryMinutes) {
      _cache.remove(key);
      return null;
    }
    
    return _cache[key];
  }

  void clear() {
    _cache.clear();
    _timestamps.clear();
  }
}

// Usage
CacheService().set('user_locations_$userId', locationList);
final cached = CacheService().get('user_locations_$userId');
```

### Layer 2: Database-Level Caching (Redis - Future)

```
// For frequently accessed data:
- User permissions
- Location list
- Product catalog
- Daily KPIs

// Update strategy:
- Invalidate on write
- Refresh periodically
- TTL: 1 hour
```

---

## Testing Strategy

### Unit Tests

```dart
// Test individual services
test('AccessControlService: Admin has all permissions', () async {
  final service = AccessControlService();
  final hasPermission = await service.hasPermission('admin_user_id', 'manage_products');
  expect(hasPermission, isTrue);
});

test('InventoryService: Low stock alert triggered when below min', () async {
  final service = InventoryService();
  // ... setup
  await service.adjustStock(..., quantity: -50);
  expect(alertSent, isTrue);
});
```

### Integration Tests

```dart
// Test multi-feature workflows
test('Multi-tenant workflow: User switches locations and sees different data', () async {
  // 1. Login user
  // 2. Get user locations
  // 3. Switch to location 1 → verify data
  // 4. Switch to location 2 → verify data
  // 5. Verify location isolation
});

test('Inventory + Analytics: Sale recorded and reflected in analytics', () async {
  // 1. Create sale transaction
  // 2. Inventory decremented
  // 3. Daily sales updated
  // 4. Analytics reflects change
});
```

### Performance Tests

```dart
// Simulate large datasets
test('Analytics performance: Query 1M transactions in <500ms', () async {
  // Populate database with 1M transactions
  // Query date range
  // Assert response time < 500ms
});
```

---

## API Design (for Future Mobile Apps)

### REST Endpoints

```
# Products
GET    /api/v1/locations/{locationId}/products
POST   /api/v1/locations/{locationId}/products
PUT    /api/v1/locations/{locationId}/products/{productId}
DELETE /api/v1/locations/{locationId}/products/{productId}

# Inventory
GET    /api/v1/locations/{locationId}/inventory
POST   /api/v1/locations/{locationId}/inventory/{productId}/adjust
POST   /api/v1/locations/{locationId}/inventory/stock-take

# Analytics
GET    /api/v1/locations/{locationId}/analytics?start=...&end=...
GET    /api/v1/locations/{locationId}/top-products?limit=10
GET    /api/v1/locations/{locationId}/comparison?period=week

# Users
GET    /api/v1/users
POST   /api/v1/users
PUT    /api/v1/users/{userId}
DELETE /api/v1/users/{userId}

# Activity
GET    /api/v1/activity-logs?start=...&end=...&userId=...
```

### Response Format

```json
{
  "success": true,
  "data": { ... },
  "meta": {
    "timestamp": "2026-01-31T10:30:00Z",
    "requestId": "req_abc123"
  }
}
```

---

## Performance Benchmarks (Targets)

| Operation | Current | Target | Method |
|-----------|---------|--------|--------|
| Load products | ~500ms | <100ms | Indexing, caching |
| Analytics query | ~2000ms | <500ms | Denormalization |
| Stock adjustment | ~300ms | <100ms | Direct query |
| Permission check | ~200ms | <50ms | Cache |
| User location list | ~400ms | <100ms | Cache |

---

## Migration Path

### Phase 1: Build Modular Components
- Implement features independently
- Test thoroughly
- Deploy to staging

### Phase 2: Integration
- Connect components
- Test multi-feature workflows
- Performance testing

### Phase 3: Deployment
- Blue-green deployment
- Monitor for issues
- Gradual rollout

---

## Monitoring & Observability

### Key Metrics

```
- API response times (p50, p95, p99)
- Error rates by endpoint
- Database query times
- Cache hit rates
- Concurrent users
- Memory usage
```

### Logging Strategy

```dart
// Use consistent logging format
developer.log(
  'Event: User switched location',
  name: 'backend.analytics',
  error: null,
  stackTrace: null,
);
```

---

*Technical Planning Document*  
*For implementation, refer to individual feature guides*  
*Last Updated: January 31, 2026*
