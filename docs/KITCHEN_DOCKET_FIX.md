# Kitchen Docket Template Fix

## Issue Report

**Problem**: Kitchen docket still using old template with big "STORE" header
and showing "RM0.00" pricing
**Root Cause**: Running outdated APK from before kitchen template refactor
**Fix**: Rebuild and reinstall APK with latest code

---

## Investigation Summary

### ✅ Current Code is Correct

The codebase does NOT contain any "STORE" header or pricing in kitchen templates:

1. **Receipt Generator** (`lib/services/receipt_generator.dart`):

   - `generateKitchenOrderText()` - Routes to compact or standard template

   - `_generateCompactKitchenOrderText()` - Table-number focused layout

   - `_generateStandardKitchenOrderText()` - Detailed KOT layout

   - **NO PRICING FIELDS** - Kitchen staff don't need to see prices

2. **Receipt Settings Model** (`lib/models/receipt_settings_model.dart`):

   - Default `kitchenHeaderText = 'Kitchen Order'` (line 46)

   - Customizable via database/settings screen

   - Two template styles: `compact` and `standard`

3. **Printer Service** (`lib/services/printer_service_clean.dart`):

   - `printKitchenOrder()` properly sets header (lines 604-607):

     ```dart
     if (printer.type == PrinterType.kitchen) {
       printerOrderData['order_header'] = 'Kitchen Order';
     }
     ```

### 📋 Kitchen Template Structure

#### Standard Template

```text
       KITCHEN ORDER         (centered, uppercase)

ORD-001            12/26/2024 3:45 PM
Customer : John Doe
Table No. : 5
--------------------------------
Sl.No Item Name              Qty.
--------------------------------
1     Nasi Goreng             2

         - Extra spicy

2     Teh Tarik               1
--------------------------------

Total Items :                  3

```text


#### Compact Template



```text
========================================
#5                        KITCHEN ORDER
========================================

ORDER: #ORD-001
TABLE: 5
TYPE: Dine In

Merchant: Your Restaurant
Address: 123 Main St

========================================

2x Nasi Goreng

   - Extra spicy

1x Teh Tarik

========================================
12/26/2024              3:45 PM
========================================

```text

---


## Key Features (Latest Version)


✅ **NO Pricing Display** - Kitchen staff only see item names and quantities

✅ **Customizable Header** - Default "Kitchen Order", can be changed in settings

✅ **Two Template Styles**:


- `compact`: Table-number focused, minimal info

- `standard`: Detailed KOT with order metadata

✅ **Modifiers Support** - Shows item customizations (extra spicy, no onions, etc.)

✅ **Category Filtering** - Printers only receive items from assigned categories

✅ **Separate Bar Orders** - Bar printers show "Bar Order" header

---


## Why Old Template is Showing



### Most Likely Causes


1. **Old APK installed** - Device running version before kitchen template refactor

   - Git commits: `3f91321`, `a4814e8` (kitchen docket updates)

   - Need to rebuild and reinstall

2. **Cached Database Settings** - Old ReceiptSettings stored in SQLite

   - Solution: Clear app data or reset receipt settings

3. **Wrong printer type** - Receipt printer being used instead of kitchen printer

   - Verify printer type in Printer Management

---


## How to Fix



### Step 1: Rebuild APK



```bash
cd /mnt/Storage/Projects/flutterpos
flutter clean
./build_flavors.sh pos release

```text


### Step 2: Install Fresh APK



```bash

# Copy to desktop

cp build/app/outputs/flutter-apk/app-posapp-release.apk ~/Desktop/FlutterPOS-v1.0.15-kitchen-fix.apk


# OR deploy directly to device

adb install -r build/app/outputs/flutter-apk/app-posapp-release.apk

```text


### Step 3: Clear App Data (if needed)



```text
Settings → Apps → FlutterPOS → Storage → Clear Data

```text

**⚠️ Warning**: Clearing app data will:


- Reset all receipt settings to defaults

- Remove license activation (need to reactivate)

- Keep database data (products, orders intact in SQLite)


### Step 4: Verify Kitchen Printer Setup


1. Open **Settings** → **Printers Management**

2. Check kitchen printer:

   - Type: **Kitchen** (not Receipt)

   - Categories assigned correctly

   - Test print to verify template

---


## Technical Details



### Template Selection Logic



```dart
// In generateKitchenOrderText (lib/services/receipt_generator.dart)
final templateStyle = (data['kitchen_template_style'] as String?) ?? 
                     settings.kitchenTemplateStyle.name;

if (templateStyle == 'compact') {
  return _generateCompactKitchenOrderText(...);
} else {
  return _generateStandardKitchenOrderText(...);
}

```text


### Header Override Priority


1. `data['order_header']` - Passed by printer service

2. `settings.kitchenHeaderText` - From database

3. Fallback: `'Kitchen Order'`


### Data Flow



```text
POS Screen (Restaurant/Cafe)
    ↓
printKitchenOrder(orderData)
    ↓
Filter items by printer categories
    ↓
Add 'order_header': 'Kitchen Order'
    ↓
AndroidPrinterService.printOrder()
    ↓
generateKitchenOrderText()
    ↓
Select template (compact/standard)
    ↓
Format text with NO PRICING
    ↓
Print to thermal printer

```text

---


## Verification Checklist


After installing the new APK:


- [ ] Kitchen docket shows "Kitchen Order" header (not "STORE")

- [ ] NO pricing displayed (no RM amounts)

- [ ] Items show name and quantity only

- [ ] Modifiers displayed if enabled

- [ ] Table number shown for restaurant mode

- [ ] Order number displayed

- [ ] Date/time shown at bottom

- [ ] Template uses proper formatting (columns, separators)

---


## Related Files


- `lib/services/receipt_generator.dart` - Kitchen template generation

- `lib/services/printer_service_clean.dart` - Kitchen order printing

- `lib/services/android_printer_service.dart` - Native print bridge

- `lib/models/receipt_settings_model.dart` - Kitchen settings

- `lib/screens/receipt_settings_screen.dart` - UI for settings

---


## Relevant Git Commits



```bash
3f91321 - Separate kitchen docket settings from receipt settings

a4814e8 - Add compact kitchen docket template option

3e93da3 - Fix kitchen printer double-cut issue

f522447 - Refactor printer service and database helper

```text

---


## Future Enhancements


- [ ] Add more template styles (minimal, detailed, etc.)

- [ ] Allow custom CSS-like formatting

- [ ] Support for kitchen display screens (KDS flavor)

- [ ] Real-time order status updates

- [ ] Multi-language headers

- [ ] Kitchen-specific instructions field

---

**Document Version**: 1.0.15
**Last Updated**: 2025-01-26
**Issue Status**: Fixed (pending APK deployment)
