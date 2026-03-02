# Training Database Quick Reference

## Quick Start

### Enable Training Mode

```dart
import 'package:extropos/services/training_mode_service.dart';

// Enable training mode - auto-loads database
await TrainingModeService.instance.toggleTrainingMode(true);

// Disable training mode
await TrainingModeService.instance.toggleTrainingMode(false);
```

### Manual Database Load

```dart
import 'package:extropos/services/mock_database_service.dart';

// Load retail training data
await MockDatabaseService.instance.restoreRetailMockData();

// Load restaurant training data
await MockDatabaseService.instance.restoreRestaurantMockData();
```

## File Locations

### JSON Database Files

- **Retail**: `assets/training_data/retail_training_database.json`
- **Restaurant**: `assets/training_data/restaurant_training_database.json`

### Service Files

- **Loader**: `lib/services/mock_database_service.dart`
- **Training Mode**: `lib/services/training_mode_service.dart`

### Documentation

- **Full Guide**: `assets/training_data/README.md`
- **Update Summary**: `TRAINING_DATABASE_UPDATE.md`

## Common Tasks

### Update Product Price

1. Open `assets/training_data/retail_training_database.json`
2. Find item in `"items"` array
3. Change `"price"` value
4. Save and restart app

### Add New Product

```json
{
  "id": "item_new",
  "name": "New Item",
  "description": "Description here",
  "price": 9.99,
  "category_id": "cat_1",
  "sku": "NEW-001",
  "barcode": "1234567890099",
  "icon_code_point": 58732,
  "icon_font_family": "MaterialIcons",
  "color_value": 4294951477,
  "is_available": 1,
  "is_featured": 0,
  "stock": 100,
  "track_stock": 1,
  "low_stock_threshold": 10,
  "cost": 5.50,
  "image_url": "",
  "tags": "tag1,tag2",
  "merchant_prices": "{}",
  "sort_order": 99,
  "printer_override": null,
  "created_at": "2026-03-02T00:00:00Z",
  "updated_at": "2026-03-02T00:00:00Z"
}
```

### Add New Category

```json
{
  "id": "cat_new",
  "name": "New Category",
  "description": "Category description",
  "icon_code_point": 58732,
  "icon_font_family": "MaterialIcons",
  "color_value": 4294951477,
  "sort_order": 99,
  "is_active": 1,
  "tax_rate": 0.10,
  "created_at": "2026-03-02T00:00:00Z",
  "updated_at": "2026-03-02T00:00:00Z"
}
```

### Change Business Info

Edit `"business_info"` section:

```json
{
  "id": "1",
  "name": "Your Business Name",
  "address": "Your Address",
  "phone": "+60123456789",
  "email": "email@example.com",
  "tax_number": "TAX-001",
  "tax_rate": 0.10,
  "currency": "RM",
  ...
}
```

## Icon Code Points

Get icon code points from Flutter:

```dart
print(Icons.restaurant.codePoint);  // 58732
print(Icons.local_cafe.codePoint);  // 58156
print(Icons.cake.codePoint);        // 57669
```

## Color Values

Get color values from Flutter:

```dart
print(Color(0xFFFF6B35).value);  // 4294951477
print(Color(0xFF8B4513).value);  // 4287137555
```

## Database Structure

```
business_info       → Business settings
categories          → Product categories
items               → Products/menu items
users               → System users
tables              → Restaurant tables (restaurant mode only)
payment_methods     → Payment options
printers            → Printer configuration
customers           → Customer database
modifier_groups     → Modifier group definitions
modifier_items      → Individual modifiers
receipt_settings    → Receipt configuration
discounts           → Discount definitions
```

## Testing

### Test Training Mode

1. Open app
2. Go to Settings → Training Mode
3. Toggle ON
4. Verify products load in POS
5. Complete a test transaction
6. Toggle OFF to clear data

### Verify JSON

Use online validator: [jsonlint.com](https://jsonlint.com)

## Troubleshooting

### JSON Parse Error

```
❌ Error loading mock database: FormatException
```

**Solution**: Validate JSON syntax with jsonlint.com

### Foreign Key Error

```
❌ Foreign key constraint failed
```

**Solution**: Ensure all `category_id`, `modifier_group_id`, etc. reference existing IDs

### Asset Not Found

```
❌ Unable to load asset: assets/training_data/...
```

**Solution**: Run `flutter pub get` to refresh assets

### Database Not Loading

**Check**:

1. JSON files exist in `assets/training_data/`
2. Files listed in `pubspec.yaml` under `assets:`
3. Run `flutter clean` and rebuild

## Best Practices

### 1. Always Validate JSON

Before committing, validate with:

- [jsonlint.com](https://jsonlint.com)
- VS Code JSON extension
- Command line: `python -m json.tool file.json`

### 2. Use Realistic Data

- Real product names and prices
- Appropriate stock levels
- Valid Malaysian ringgit (RM) pricing

### 3. Test After Changes

1. Load training mode
2. Add items to cart
3. Complete transaction
4. Verify all data appears correctly

### 4. Version Control

- Commit JSON changes with descriptive messages
- Review diffs before committing
- Keep backup of working version

## Quick Commands

### Validate JSON (Linux/Mac)

```bash
python -m json.tool assets/training_data/retail_training_database.json
```

### Validate JSON (Windows PowerShell)

```powershell
Get-Content assets\training_data\retail_training_database.json | ConvertFrom-Json
```

### Count Items

```bash
# Linux/Mac
cat assets/training_data/retail_training_database.json | jq '.items | length'

# Windows PowerShell
(Get-Content assets\training_data\retail_training_database.json | ConvertFrom-Json).items.Count
```

## Support

- **Documentation**: `assets/training_data/README.md`
- **Update Summary**: `TRAINING_DATABASE_UPDATE.md`
- **Database Schema**: `lib/services/database_helper_tables.dart`

---

**Version**: 1.1.6 | **Updated**: March 2, 2026
