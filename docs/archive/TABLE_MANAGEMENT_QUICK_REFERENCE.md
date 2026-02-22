# Table Management System - Quick Reference

## 🎯 At a Glance

**Status**: ✅ Complete & Production Ready  
**Tests**: 21/21 Passing  
**Code Quality**: No analyzer issues  
**Database Version**: v34  

---

## 📦 Key Components

### Models

- **RestaurantTable**: Full table data model with occupancy, customer, and merge tracking

### Services

- **TableManagementService**: Singleton ChangeNotifier handling all table operations

### Screens

- **TableManagementScreen**: CRUD interface for table administration

- **TableReportsScreen**: Analytics dashboard with occupancy & performance metrics

- **TableSelectionScreen**: Enhanced with merged/cleaning status support

### Database

- **restaurant_tables**: SQLite table with complete schema (v34)

---

## 🚀 Quick Start

### Initialize Service

```dart
final service = TableManagementService();
await service.loadTablesFromDatabase();
service.addListener(() => setState(() {}));

```

### Create Table

```dart
await service.createTable(
  id: 'T1',
  name: 'Table 1',
  capacity: 4,
);

```

### Occupy Table

```dart
await service.occupyTable(
  'T1',
  customerName: 'John Doe',
  customerPhone: '555-1234',
);

```

### Get Statistics

```dart
final stats = service.getTableStatistics();
// {total: 10, available: 3, occupied: 5, reserved: 1, cleaning: 1, merged: 0}

final avgDuration = service.getAverageTableDuration();
// 45.5 (minutes)

```

### Release Table

```dart
await service.releaseTable('T1');
await service.setTableCleaning('T1');

```

### Merge Tables

```dart
await service.mergeTables(
  tableIds: ['T1', 'T2', 'T3'],
  mergedName: 'Party of 3',
);

```

---

## 📊 Table Status Flow

```
Available → Occupied → Released → Cleaning → Available
         ↘    ↙
          Reserved
             ↓
          Available

Occupied + Occupied → Merged → Released → Available

```

---

## 🎨 Status Colors

| Status | Color | Icon | Use Case |
|--------|-------|------|----------|
| Available | 🟢 Green | check_circle | Ready for customers |
| Occupied | 🟠 Orange | restaurant_menu | Active order |
| Reserved | 🔵 Blue | event | Future reservation |
| Merged | 🟣 Purple | merge | Multi-table order |
| Cleaning | 🟤 Brown | cleaning_services | Being cleaned |

---

## 📱 Screen Features

### TableManagementScreen

- ✅ Add new tables

- ✅ Edit table info

- ✅ Delete tables

- ✅ View real-time statistics

- ✅ Responsive grid layout

### TableReportsScreen

- ✅ KPI dashboard

- ✅ Occupancy analysis

- ✅ Status breakdown

- ✅ Performance metrics

- ✅ Table details list

---

## 🧪 Testing

```bash

# Run all tests

flutter test test/table_management_service_test.dart


# Run specific test group

flutter test -n "Table Management Service - CRUD"


# Run with coverage

flutter test --coverage test/table_management_service_test.dart

```

**Test Coverage**:

- CRUD operations (5 tests)

- Status management (5 tests)

- Model operations (6 tests)

- Filtering (3 tests)

- Statistics (2 tests)

---

## 🔍 Common Patterns

### React to Table Changes

```dart
service.addListener(() {
  setState(() {}); // Rebuild UI
});

```

### Get All Tables by Status

```dart
final available = service.getAvailableTables();
final occupied = service.getOccupiedTables();
final reserved = service.getReservedTables();
final cleaning = service.getTablesCleaning();

```

### Add Order to Table

```dart
final table = service.getTableById('T1');
final updated = table!.copyWith(
  orders: [...table.orders, cartItem],
);
await service._saveTable(updated);

```

### Calculate Revenue per Table

```dart
final avgDuration = service.getAverageTableDuration();
final estimatedRevenue = (avgDuration / 60) * 50; // $50/hour

```

---

## ⚠️ Important Notes

1. **Singleton Pattern**: Only one instance of `TableManagementService` per app
2. **Async Operations**: All database operations are async - use `await`

3. **State Consistency**: Service maintains both memory cache and SQLite
4. **Occupancy Tracking**: `occupiedDurationMinutes` calculated from `occupiedSince`
5. **Merge Operations**: Consolidates orders from all merged tables
6. **Status Transitions**: Some transitions have validation (e.g., can't delete occupied table)

---

## 📚 Files

| File | Purpose | Lines |
|------|---------|-------|
| lib/models/table_model.dart | RestaurantTable model | 184 |
| lib/services/table_management_service.dart | TableManagementService | 418 |
| lib/screens/table_management_screen.dart | CRUD UI | 450 |
| lib/screens/table_reports_screen.dart | Analytics UI | 604 |
| test/table_management_service_test.dart | Unit tests | 390 |

---

## 🔗 Related Documentation

- [TABLE_MANAGEMENT_SYSTEM.md](TABLE_MANAGEMENT_SYSTEM.md) - Full documentation

- [PHASE_1_IMPLEMENTATION_COMPLETE.md](PHASE_1_IMPLEMENTATION_COMPLETE.md) - Phase 1 overview

- [copilot-instructions.md](.github/copilot-instructions.md) - Development guidelines

---

## 💡 Tips & Tricks

### Debug Table Status

```dart
void debugTable(String id) {
  final t = service.getTableById(id);
  print('${t?.name}: ${t?.status} (${t?.orders.length} items)');
}

```

### Batch Create Tables

```dart
Future<void> createTablesLayout() async {
  for (int i = 1; i <= 20; i++) {
    await service.createTable(
      id: 'T$i',
      name: 'Table $i',
      capacity: i <= 10 ? 2 : 4,
    );
  }
}

```

### Monitor Occupancy

```dart
Timer.periodic(Duration(seconds: 5), (_) {
  final stats = service.getTableStatistics();
  final occupied = (stats['occupied'] ?? 0) as int;
  final total = (stats['total'] ?? 0) as int;
  final rate = (occupied / total * 100).toStringAsFixed(1);
  print('Occupancy: $rate%');
});

```

---

**Last Updated**: January 23, 2026  
**Version**: 1.0.0
