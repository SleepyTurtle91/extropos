# FlutterPOS v1.0.15 Release Notes

**Release Date**: December 12, 2025
**Build Number**: 15
**Feature**: Kitchen Docket System Fixes

---

## 🐛 What's Fixed

### Kitchen Docket System Overhaul

Comprehensive fixes for kitchen docket printing issues across all POS modes (Retail, Cafe, Restaurant).

**Fixed Issues**:

- ✅ **Cafe Mode Calling Numbers** - Kitchen dockets now prominently display "***CALLING*** ORDER #[number]" headers

- ✅ **Paper Cutting Prevention** - Kitchen/bar printers no longer cut empty paper after printing dockets

- ✅ **Restaurant Receipt Format** - Eliminated old "STORE" header with RM 0.00 pricing on receipts

- ✅ **Duplicate Kitchen Printing** - Removed duplicate kitchen docket printing during table checkout

- ✅ **Retail Mode Duplicate Receipts** - Fixed double receipt printing (old "STORE" format + correct format)

- ✅ **Missing Change Amounts** - Receipts now properly display change amounts across all business modes

---

## 🔧 Technical Improvements

### Kitchen Printing System

**Flutter Side Changes**:

- **`lib/services/receipt_generator.dart`**: Added cafe-specific calling number display logic with prominent "***CALLING***" headers

- **`lib/services/android_printer_service.dart`**: Added `noCut=true` flag and removed `items` array for kitchen orders

- **`lib/screens/pos_order_screen_fixed.dart`**: Modified restaurant checkout to exclude `items` array from kitchen order data

- **`lib/screens/retail_pos_screen.dart`**: Removed incorrect kitchen order printing and excluded `items` array from receipt data

- **`lib/screens/cafe_pos_screen.dart`**: Excluded `items` array from receipt data to prevent duplicate printing

- **`lib/screens/pos_order_screen_fixed.dart`**: Excluded `items` array from restaurant receipt data

**Android Native Changes**:

- **`android/app/src/main/kotlin/com/extrotarget/extropos/PrinterPlugin.kt`**: Updated all printer methods (network, USB, Bluetooth) to conditionally execute cut commands based on `noCut` flag

### Print Logic Improvements

**Before**: Android native code prioritized structured `items` array for receipts, causing pricing to appear on kitchen dockets
**After**: Kitchen orders now use formatted content templates without pricing data, ensuring clean kitchen-focused output

**Before**: All printers executed cut commands regardless of use case
**After**: Cut commands are conditional based on `noCut` flag, preventing unwanted paper waste

---

## 📋 Testing Checklist

### Retail Mode Testing

- [ ] Only one receipt prints (not two)

- [ ] Receipt shows correct business information (not "STORE" header)

- [ ] Change amounts display properly when applicable

- [ ] No kitchen order printing (retail mode doesn't need kitchen orders)

### Cafe Mode Testing

- [ ] Kitchen dockets show prominent "***CALLING*** ORDER #[number]" headers

- [ ] No pricing information displayed on kitchen dockets

- [ ] Calling numbers are clearly visible for kitchen staff

- [ ] Only one receipt prints with change amounts displayed

### Restaurant Mode Testing

- [ ] Kitchen dockets show table numbers without pricing

- [ ] No "STORE" header or RM 0.00 pricing on receipts

- [ ] No duplicate kitchen printing during checkout

- [ ] Receipt printing works normally with proper formatting and change amounts

### Kitchen Printing Testing

- [ ] No empty paper cutting after kitchen dockets

- [ ] All printer types (USB, Bluetooth, Network) respect noCut flag

- [ ] Kitchen dockets print cleanly without receipt formatting

---

## 📁 Files Modified

```text
lib/services/receipt_generator.dart
lib/services/android_printer_service.dart
lib/screens/pos_order_screen_fixed.dart
lib/screens/retail_pos_screen.dart
lib/screens/cafe_pos_screen.dart
android/app/src/main/kotlin/com/extrotarget/extropos/PrinterPlugin.kt
docs/RELEASE_NOTES_v1.0.15.md
```text

---


## 🔄 Migration Notes


**No Database Changes**: This release contains only printing logic fixes with no database schema changes.

**Backward Compatibility**: All changes are backward compatible with existing installations.

**Printer Compatibility**: Fixes apply to all supported printer types (USB, Bluetooth, Network) and paper sizes (80mm, 58mm).

---


## 🏷️ Version History


- **v1.0.14** (2025-11-26): Employee Performance Tracking System

- **v1.0.15** (2025-12-12): Kitchen Docket System Fixes

---


## 📞 Support


For issues or questions about this release, please check:

1. Retail mode prints only one receipt with correct formatting and change amounts
2. Kitchen docket prints correctly without pricing
3. No unwanted paper cutting
4. Cafe calling numbers display prominently
5. No duplicate printing during checkout

All receipt printing issues from previous versions have been resolved in this release.
