# Horizon Admin Phase 3 Quick Start Guide

## 🎯 What's Deployed

Phase 3 of the **Horizon Admin** design system is now **LIVE** at:

```
🌐 https://backend.extropos.org

```

### What You Get

**Enhanced Pulse Dashboard** with:

- 📊 4 metric cards with sparkline trends

- 📈 Hourly sales velocity bar chart

- 🏆 Top selling products widget

- 📉 Performance statistics

Plus these screens (accessible with routing):

- 📦 **Inventory Grid:** Products with search/filters/advanced table

- 📊 **Reports:** Sales analytics with date picker and comparisons

## 🚀 Quick Navigation

### Local Development (Port 3003)

```bash

# View dashboard locally

open http://localhost:3003

```

### Production (Cloudflare Tunnel)

```bash

# Live dashboard

open https://backend.extropos.org

```

## 🛠️ Development Commands

### View Latest Logs

```bash
docker logs backend-admin -f

```

### Rebuild After Code Changes

```bash
cd e:\flutterpos
flutter build web --release -t lib/main_backend_web.dart

```

### Redeploy Container

```bash
cd e:\flutterpos\docker
docker build -f backend-web.Dockerfile -t backend-admin-web:latest .
docker stop backend-admin && docker rm backend-admin
docker run -d --name backend-admin --restart unless-stopped --network appwrite \
  -p 3003:8080 backend-admin-web:latest

```

## 📁 Key Files

### Design System (Phase 1)

- `lib/design_system/horizon_colors.dart` - Color palette

- `lib/design_system/horizon_typography.dart` - Typography system

- `lib/design_system/horizon_theme.dart` - Material 3 theme

### Layout (Phase 2)

- `lib/widgets/horizon_sidebar.dart` - Dark sidebar navigation

- `lib/widgets/horizon_header.dart` - Global header

- `lib/widgets/horizon_layout.dart` - Main layout wrapper

### Charts & Tables (Phase 3)

- `lib/widgets/horizon_charts.dart` - Sparkline, Bar, Line charts

- `lib/widgets/horizon_data_table.dart` - Advanced data table

### Screens (Phase 3)

- `lib/screens/horizon_pulse_dashboard_screen.dart` - Main dashboard

- `lib/screens/horizon_inventory_grid_screen.dart` - Product management

- `lib/screens/horizon_reports_screen.dart` - Analytics & reporting

## 🎨 Design Elements

### Colors

```dart
HorizonColors.electricIndigo  // #4F46E5 - Primary

HorizonColors.emerald         // #10B981 - Success

HorizonColors.amber           // #F59E0B - Warning

HorizonColors.rose            // #F43F5E - Danger

HorizonColors.paleSlate       // #F1F5F9 - Light bg

HorizonColors.deepMidnight    // #0F172A - Dark bg

```

### Components

```dart
// Buttons
HorizonButton.primary(label: 'Action', onPressed: () {})
HorizonButton.secondary(label: 'Secondary', onPressed: () {})

// Metric card with sparkline
HorizonMetricCard(
  title: 'Total Sales',
  value: 'RM 12,450',
  sparkline: HorizonSparkline(values: [10, 45, 30, 70, 50, 95]),
)

// Charts
HorizonBarChart(title: 'Sales', barGroups: [...])
HorizonLineChart(title: 'Trend', currentData: [...])

// Table
HorizonDataTable(
  columns: ['SKU', 'Product', 'Price'],
  rows: [...],
)

```

## 📈 Responsive Breakpoints

```
Mobile    < 600px   → 1 column, hamburger menu
Tablet    600-1200px → 2-3 columns, collapsed sidebar
Desktop   > 1200px   → 4 columns, expanded sidebar

```

## 🔧 Next Steps (Optional)

### 1. Add Navigation to Inventory Screen

```dart
// In horizon_sidebar.dart, add menu item:
MenuItem(label: 'Inventory', icon: Icons.inventory, route: '/inventory'),

// In main_backend_web.dart, add route:
'/inventory': (_) => const HorizonInventoryGridScreen(),

```

### 2. Add Navigation to Reports Screen

```dart
// In horizon_sidebar.dart:
MenuItem(label: 'Reports', icon: Icons.analytics, route: '/reports'),

// In main_backend_web.dart:
'/reports': (_) => const HorizonReportsScreen(),

```

### 3. Connect to Real Data

Replace sample data in screens with Appwrite queries:

```dart
Future<void> _loadProducts() async {
  final products = await AppwriteSyncService().getProducts();
  setState(() {
    _products = products;
  });
}

```

## 📊 Demo Data Included

### Dashboard Metrics

- Total Sales: RM 12,450.00 (+12.5%)

- Orders: 342 (+8.2%)

- AOV: RM 36.40 (+5.1%)

- Alerts: 3 (-2.0%)

### Top Products

- Espresso: 145 units, RM 725.00

- Cappuccino: 128 units, RM 768.00

- Latte: 112 units, RM 672.00

- Americano: 98 units, RM 490.00

### Inventory Sample

- Coffee Beans (SKU: CB-001): RM 45.00 (In Stock)

- Cups 8oz (SKU: CUP-008): RM 0.50 (Low Stock)

- Napkins (SKU: NAP-001): RM 15.00 (Out of Stock)

## 🐛 Troubleshooting

### Dashboard not loading?

```bash

# Check container is running

docker ps | grep backend-admin


# View logs

docker logs backend-admin

```

### Charts not rendering?

- Make sure `fl_chart: ^1.1.1` is in `pubspec.yaml`

- Run `flutter pub get` to install dependencies

- Clear browser cache (Ctrl+Shift+Del)

### Changes not showing?

```bash

# Rebuild and redeploy

flutter build web --release -t lib/main_backend_web.dart
docker build -f backend-web.Dockerfile -t backend-admin-web:latest .
docker restart backend-admin

```

## 📚 Documentation

- [Phase 3 Deployment Details](PHASE3_DEPLOYMENT_COMPLETE.md)

- [Architecture Overview](.github/copilot-architecture.md)

- [Horizon Design System Specs](lib/design_system/)

## 🎉 Summary

✅ **Phase 1:** Design System (Colors, Typography, Components)  

✅ **Phase 2:** Layout Architecture (Sidebar, Header, Responsive Grid)  

✅ **Phase 3:** Key Screens (Dashboard, Inventory, Reports)  

All phases complete and deployed! 🚀

---

**Status:** LIVE ✅  
**URL:** <https://backend.extropos.org>  
**Last Updated:** January 29, 2026
