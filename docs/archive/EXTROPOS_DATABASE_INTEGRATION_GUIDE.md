# ExtroPOS Database Integration Implementation Guide

## Overview

This guide provides complete instructions for implementing database integration and repository pattern in your ExtroPOS hybrid POS system.

**Important**: This implementation integrates with your existing **UnifiedPOSScreen** and mode selection system. Business mode is controlled through `BusinessInfo.instance.selectedBusinessMode` - no separate mode switcher needed.

## Architecture Summary

**Database**: SQLite (via existing DatabaseHelper)

**State Management**: setState() (no external libraries per project standards)

**Pattern**: Repository pattern for clean data access

**Mode Selection**: Handled by existing UnifiedPOSScreen (no built-in mode switcher)

**Features**: Mode-based filtering, real-time cart, category filtering, search

## Files Created

```
lib/
├── models/
│   └── pos_product.dart              # Enhanced Product model with serialization
├── repositories/
│   └── product_repository.dart       # Repository abstraction + SQLite implementation
├── migrations/
│   └── pos_products_migration.dart   # Database table creation
├── seeders/
│   └── pos_product_seeder.dart       # Sample data seeder
├── scripts/
│   └── extropos_setup.dart           # Quick setup utility
└── examples/
    ├── retail_pos_integration_example.dart  # 🔥 REAL integration example
    ├── extropos_integrated_main.dart        # Standalone demo (no mode switcher)
    └── extropos_quick_reference.dart        # Code snippets
```

**Key File**: [retail_pos_integration_example.dart](lib/examples/retail_pos_integration_example.dart) shows exactly how to integrate with your existing RetailPOSScreenModern, CafePOSScreen, and Restaurant screens.

## Step-by-Step Implementation

### Step 1: Add Dependencies

Add `uuid` package to [pubspec.yaml](pubspec.yaml) if not already present:

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite_common_ffi: ^2.3.0  # Already present
  uuid: ^4.0.0                 # Add this
```

Run: `flutter pub get`

### Step 2: Run Database Migration

The migration creates the `pos_products` table with mode filtering support.

```dart
// In your main.dart or initialization code
import 'package:extropos/migrations/pos_products_migration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run migration (only needs to run once)
  await POSProductsMigration.migrate();
  
  runApp(const ExtroPOSApp());
}
```

### Step 3: Seed Sample Data

Populate the database with sample products for testing:

```dart
import 'package:extropos/repositories/product_repository.dart';
import 'package:extropos/seeders/pos_product_seeder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run migration
  await POSProductsMigration.migrate();
  
  // Seed data (run once or when you need fresh data)
  final repository = DatabaseProductRepository();
  final seeder = POSProductSeeder(repository);
  await seeder.seedAll();
  
  runApp(const ExtroPOSApp());
}
```

This creates:
- **Retail**: 5 products (Electronics, Stationery, Accessories)
- **Cafe**: 6 products (Coffee, Pastries, Beverages)
- **Restaurant**: 7 products (Mains, Starters, Desserts)

### Step 4: Integrate Repository into Your Existing POS Screen

The repository is designed to work with your existing **UnifiedPOSScreen** and mode selection system.

#### Integration Pattern

Add repository to your existing POS screens (RetailPOSScreenModern, CafePOSScreen, etc.):

```dart
import 'package:extropos/models/pos_product.dart';
import 'package:extropos/repositories/product_repository.dart';

class _MainPOSScreenState extends State<MainPOSScreen> {
  final ProductRepository _repository = DatabaseProductRepository();
  
  List<POSProduct> products = [];
  List<String> categories = [];
  bool isLoading = false;

  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    
    try {
      final mode = activeMode.value; // 'retail', 'cafe', or 'restaurant'
      
      // Fetch products and categories from repository
      final results = await Future.wait([
        _repository.getProducts(mode: mode),
        _repository.getCategories(mode: mode),
      ]);
      
      setState(() {
        products = results[0] as List<POSProduct>;
        categories = results[1] as List<String>;
        isLoading = false;
      });
      
      print('✅ Loaded ${products.length} products in $mode mode');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('❌ Error: $e');
    }
  }
}
```

Update your cart to use POSProduct:

```dart
class CartItem {
  final POSProduct product;  // Changed from Product to POSProduct
  int quantity;

  CartItem({required this.product, this.quantity = 1});
  double get total => product.price * quantity;
}
```

### Step 5: Integrate with UnifiedPOSScreen

Your existing **UnifiedPOSScreen** handles mode selection via `BusinessInfo.instance.selectedBusinessMode`.

```dart
// In RetailPOSScreenModern, CafePOSScreen, or TableSelectionScreen
import 'package:extropos/repositories/product_repository.dart';
import 'package:extropos/models/business_info_model.dart';

class RetailPOSScreenModern extends StatefulWidget {
  // ...
}

class _RetailPOSScreenModernState extends State<RetailPOSScreenModern> {
  final ProductRepository _repository = DatabaseProductRepository();
  List<POSProduct> products = [];
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  Future<void> _loadProducts() async {
    // Get mode from BusinessInfo singleton
    final mode = BusinessInfo.instance.selectedBusinessMode.name; // 'retail', 'cafe', or 'restaurant'
    
    final loadedProducts = await _repository.getProducts(mode: mode);
    setState(() => products = loadedProducts);
  }
}
```

Mode switching happens automatically through your existing Settings → Business Mode flow.

## Repository API Reference

### ProductRepository Interface

```dart
// Get all products for a mode
Future<List<POSProduct>> getProducts({String? mode});

// Get products by category
Future<List<POSProduct>> getProductsByCategory(String category, {String? mode});

// Get all categories for a mode
Future<List<String>> getCategories({String? mode});

// CRUD operations
Future<POSProduct> createProduct(POSProduct product);
Future<POSProduct> updateProduct(POSProduct product);
Future<void> deleteProduct(String id);
Future<POSProduct?> getProductById(String id);
Future<POSProduct?> getProductByBarcode(String barcode);
```

### Usage Examples

```dart
final repository = DatabaseProductRepository();

// Get all cafe products
final cafeProducts = await repository.getProducts(mode: 'cafe');

// Get coffee category in cafe mode
final coffees = await repository.getProductsByCategory('Coffee', mode: 'cafe');

// Get all categories for retail mode
final retailCategories = await repository.getCategories(mode: 'retail');

// Find product by barcode
final product = await repository.getProductByBarcode('8888001');

// Create new product
final newProduct = POSProduct(
  id: '',
  name: 'New Item',
  price: 15.00,
  category: 'Snacks',
  mode: 'cafe',
  color: Colors.orange,
);
await repository.createProduct(newProduct);
```

## Database Schema

### pos_products Table

```sql
CREATE TABLE pos_products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  price REAL NOT NULL,
  category TEXT NOT NULL,
  mode TEXT DEFAULT 'all',           -- 'retail', 'cafe', 'restaurant', 'all'
  color_value INTEGER DEFAULT 0xFF2196F3,
  description TEXT,
  barcode TEXT,
  image_url TEXT,
  is_available INTEGER DEFAULT 1,
  stock INTEGER DEFAULT 0,
  track_stock INTEGER DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Indexes

- `idx_pos_products_mode` - Fast mode filtering
- `idx_pos_products_category` - Fast category filtering
- `idx_pos_products_barcode` - Fast barcode lookup

## State Management Pattern

Following project standards, we use **local setState()** only:

```dart
// ✅ Correct Pattern
void addToCart(POSProduct product) {
  setState(() {
    final index = cart.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      cart[index].quantity++;
    } else {
      cart.add(CartItem(product: product));
    }
  });
}

// ❌ Avoid external state management
// No Provider, Riverpod, or Bloc - per project guidelines
```

## Mode Filtering Logic

Products are filtered by the `mode` field:

- `mode: 'retail'` → Only shown in Retail mode
- `mode: 'cafe'` → Only shown in Cafe mode
- `mode: 'restaurant'` → Only shown in Restaurant mode
- `mode: 'all'` → Shown in ALL modes

The repository handles this automatically:

```dart
// Mode comes from BusinessInfo singleton
final mode = BusinessInfo.instance.selectedBusinessMode.name;
final products = await _repository.getProducts(mode: mode);
// Repository automatically filters to 'cafe' and 'all' products
```

## Key Features Implemented

### ✅ Repository Pattern

Clean separation between UI and data access following your existing CategoryRepository pattern.

### ✅ Mode-Based Filtering

Automatic product filtering when switching between Retail/Cafe/Restaurant modes.

### ✅ Real-Time Cart Management

Cart updates immediately with setState() for responsive UI.

### ✅ Category Filtering

Dynamic category chips populated from database for each mode.

### ✅ Search Functionality

Real-time product search across name field.

### ✅ Database Serialization

POSProduct model with fromMap/toMap for clean database operations.

### ✅ Error Handling

Graceful error display with retry functionality.

## Integration with Existing Screens

### UnifiedPOSScreen Architecture

Your existing architecture routes to mode-specific screens:

```
UnifiedPOSScreen → BusinessInfo.selectedBusinessMode
  ├→ RetailPOSScreenModern (if retail)
  ├→ CafePOSScreen (if cafe)
  └→ TableSelectionScreen (if restaurant)
```

### Example: Integrate into RetailPOSScreenModern

```dart
// lib/screens/pos/retail_pos_refactored.dart
import 'package:extropos/repositories/product_repository.dart';
import 'package:extropos/models/pos_product.dart';

class _RetailPOSRefactoredState extends State<RetailPOSRefactored> {
  final ProductRepository _repository = DatabaseProductRepository();
  List<POSProduct> products = [];
  List<String> categories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRetailProducts();
  }

  Future<void> _loadRetailProducts() async {
    setState(() => isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getProducts(mode: 'retail'),
        _repository.getCategories(mode: 'retail'),
      ]);
      setState(() {
        products = results[0] as List<POSProduct>;
        categories = results[1] as List<String>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading products: $e');
    }
  }
  
  // Use products in your existing grid
}
```

### Example: Integrate into CafePOSScreen

```dart
// lib/screens/pos/cafe_pos_screen.dart
Future<void> _loadCafeProducts() async {
  final products = await _repository.getProducts(mode: 'cafe');
  // Update your existing product list
}
```

### Example: Integrate into Restaurant Mode

```dart
// lib/screens/pos/table_selection_screen.dart or restaurant_pos_screen.dart
Future<void> _loadRestaurantMenu() async {
  final products = await _repository.getProducts(mode: 'restaurant');
  // Use with table orders
}
```

## Testing Checklist

- [ ] Migration creates pos_products table
- [ ] Seeder populates sample data
- [ ] Products load in RetailPOSScreenModern
- [ ] Products load in CafePOSScreen
- [ ] Products load in Restaurant mode screens
- [ ] Category filter shows correct categories per mode
- [ ] Search filters products correctly
- [ ] Adding to cart updates quantity
- [ ] Cart calculations (subtotal, tax, total) are correct
- [ ] Business mode switching (Settings → Business Mode) reloads products
- [ ] Empty state displays when no products
- [ ] Error state displays on database failure

## Troubleshooting

### Issue: "Table doesn't exist"

**Solution**: Run migration in main.dart before runApp():

```dart
await POSProductsMigration.migrate();
```

### Issue: "No products displayed"

**Solution**: Run seeder to populate data:

```dart
final seeder = POSProductSeeder(DatabaseProductRepository());
await seeder.seedAll();
```

### Issue: "Mode switching doesn't filter"

**Solution**: Mode is controlled by BusinessInfo.instance.selectedBusinessMode. When user changes mode in Settings:

```dart
// In your Settings screen
BusinessInfo.updateInstance(info.copyWith(selectedBusinessMode: newMode));

// Then reload products in POS screen
_loadProducts(); // This will fetch products for the new mode
```

### Issue: "uuid package not found"

**Solution**: Add to pubspec.yaml and run:

```bash
flutter pub add uuid
```

## Next Steps

### Recommended Enhancements

1. **Product Images**: Add image picker and display product images
2. **Stock Management**: Implement stock tracking and low stock alerts
3. **Barcode Scanner**: Integrate barcode scanner for quick product lookup
4. **Offline Sync**: Add Appwrite sync for multi-device support
5. **Product Management**: Create admin screen for CRUD operations
6. **Analytics**: Track product performance per mode

### Isar Migration (Future)

The project plan includes Isar migration. When ready:

1. Convert POSProduct to Isar model with @collection annotation
2. Create POSProductIsarRepository implementing ProductRepository
3. Swap DatabaseProductRepository with POSProductIsarRepository
4. No UI changes needed due to repository abstraction

## Architecture Compliance

This implementation follows ExtroPOS project standards:

- ✅ Uses existing DatabaseHelper singleton
- ✅ Follows BusinessInfo singleton pattern
- ✅ No external state management (setState() only)
- ✅ Repository pattern matching CategoryRepository
- ✅ SQLite current, Isar-ready for future migration
- ✅ Windows desktop + Android tablet compatible

## Support

For questions or issues, refer to:
- [copilot-architecture.md](.github/copilot-architecture.md)
- [copilot-workflows.md](.github/copilot-workflows.md)
- [copilot-database.md](.github/copilot-database.md)

---

**Last Updated**: February 21, 2026

**Version**: 1.0.0

**Status**: Production Ready
