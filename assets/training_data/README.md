# Training Database Documentation

## Overview

The FlutterPOS training mode uses JSON-based mock databases to provide realistic
demo data for testing and training purposes. This replaces the old Dart-based
mock data generator with a more maintainable JSON format.

## Database Files

### Location

- **Retail Mode**: `assets/training_data/retail_training_database.json`
- **Restaurant Mode**: `assets/training_data/restaurant_training_database.json`

### Format

Each JSON file follows the current database schema (v35, FlutterPOS v1.1.8+) and includes:

- Business Information
- Categories
- Items (Products)
- Users
- Tables (Restaurant mode only)
- Payment Methods
- Printers
- Customers
- Modifier Groups
- Modifier Items
- Receipt Settings
- Discounts
- Offline Sync Queue (sync_queue)
- Offline Sync Statistics (sync_stats)

## Usage

### Loading Training Data

```dart
import 'package:extropos/services/mock_database_service.dart';

// For Retail Mode
await MockDatabaseService.instance.restoreRetailMockData();

// For Restaurant Mode
await MockDatabaseService.instance.restoreRestaurantMockData();
```

### Integration with Training Mode

The training mode service automatically loads the appropriate mock database
when training mode is enabled:

```dart
import 'package:extropos/services/training_mode_service.dart';

// Enable training mode
await TrainingModeService.instance.toggleTrainingMode(true);
```

## Database Schema

### Required Fields

All tables must include these timestamp fields:

- `created_at`: ISO 8601 timestamp
- `updated_at`: ISO 8601 timestamp

### Example Item Structure

```json
{
  "id": "item_1",
  "name": "Chicken Burger",
  "description": "Grilled chicken burger with lettuce and tomato",
  "price": 12.99,
  "category_id": "cat_1",
  "sku": "FOOD-001",
  "barcode": "1234567890001",
  "icon_code_point": 58271,
  "icon_font_family": "MaterialIcons",
  "color_value": 4294951477,
  "is_available": 1,
  "is_featured": 1,
  "stock": 50,
  "track_stock": 1,
  "low_stock_threshold": 10,
  "cost": 7.50,
  "image_url": "",
  "tags": "burger,chicken,lunch",
  "merchant_prices": "{}",
  "sort_order": 1,
  "printer_override": null,
  "created_at": "2026-01-01T00:00:00Z",
  "updated_at": "2026-01-01T00:00:00Z"
}
```

## Updating Training Data

### Step 1: Edit JSON File

1. Open `assets/training_data/retail_training_database.json` or
   `restaurant_training_database.json`
2. Make your changes following the schema structure
3. Ensure all required fields are present
4. Validate JSON syntax (use JSON validator)

### Step 2: Update Version

Update the `version` field in the JSON to match current app version:

```json
{
  "version": "1.1.6",
  "mode": "retail",
  "timestamp": "2026-03-02T00:00:00Z",
  ...
}
```

### Step 3: Test Loading

Run the app and enable training mode to verify the data loads correctly.

## Data Restoration Process

The `MockDatabaseService` performs the following steps:

1. **Clear Existing Data**: Removes all current database records
2. **Load JSON**: Reads and parses the JSON file from assets
3. **Insert in Order**: Inserts data respecting foreign key constraints:
   - Business Info
   - Categories
   - Items
   - Users
   - Tables (Restaurant)
   - Payment Methods
   - Printers
   - Customers
   - Modifier Groups
   - Modifier Items
   - Receipt Settings
   - Discounts

## Icon Code Points

Flutter Material Icons can be referenced by their code point:

```dart
Icons.restaurant.codePoint    // 58732
Icons.local_cafe.codePoint    // 58156
Icons.cake.codePoint         // 57669
```

Use these code points in the JSON `icon_code_point` field.

## Color Values

Colors are stored as integer values derived from Flutter Color objects:

```dart
Color(0xFFFF6B35).value    // 4294951477
Color(0xFF8B4513).value    // 4287137555
```

## Best Practices

### 1. Realistic Data

- Use realistic product names and prices
- Include variety in categories and items
- Set appropriate stock levels
- Include both active and featured items

### 2. Comprehensive Coverage

- Include all table types for testing
- Add multiple users with different roles
- Configure various payment methods
- Set up realistic modifier groups

### 3. Foreign Key Integrity

- Ensure all `category_id` references exist in categories
- Verify `modifier_group_id` matches defined groups
- Validate all user and table references

### 4. Testing Scenarios

Include data that supports testing:

- Low stock items (alerts)
- Out of stock items (availability)
- Featured vs non-featured items
- Items with and without tracking
- Various modifier combinations

## Troubleshooting

### JSON Syntax Errors

Use an online JSON validator (jsonlint.com) to check syntax before loading.

### Foreign Key Violations

Ensure referenced IDs exist in parent tables:

- Items reference valid category_id
- Modifier items reference valid modifier_group_id

### Loading Failures

Check console output for specific error messages:

```
✅ Inserted 12 rows into items
❌ Error loading mock database: Foreign key constraint failed
```

## Migration from Old System

The old Dart-based mock data system (`retail_mock_data.dart`,
`restaurant_mock_data.dart`) has been replaced. Benefits of JSON approach:

1. **Easier to Edit**: No Dart knowledge required
2. **Version Control**: Clear diffs in git
3. **Portable**: Can be edited in any text editor
4. **Maintainable**: Non-developers can update training data
5. **Testable**: Easy to create multiple test scenarios

## Future Enhancements

Planned improvements:

- [ ] SQLite database file export for faster loading
- [ ] Multiple training scenarios (beginner, advanced, stress test)
- [ ] Online training data updates
- [ ] User-customizable training datasets
- [ ] Automated data generation tools

---

**Last Updated**: March 6, 2026 (v1.1.8 with Offline-First Support)
