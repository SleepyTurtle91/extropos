# Offline POS Build & Release Guide

## Overview

The POS flavor has been configured for **offline-only operation** with a 2-week release target. This guide covers:
- How to build the offline POS APK
- Architecture details
- Testing & validation steps

---

## Architecture: Offline-First POS

### Key Components

| Component | Details |
|-----------|---------|
| **Appwrite** | Disabled globally (set via `POS_OFFLINE` Dart define). All network calls return local fallbacks. |
| **Local SQLite DB** | Primary data store. Products and categories automatically seeded on first run. |
| **ProductService** | Abstraction layer reading from local DB when Appwrite is disabled. |
| **AuditService** | Activity logs persist to local `user_activity_log` table when offline. |
| **PosSeedService** | Auto-seeds 5 sample products (coffee, drinks, food) into `items` & `categories` tables. |

### Data Flow (Offline)

```
POS Home (UI)
  ↓
ProductService.getProducts()
  ↓
(Appwrite disabled)
  ↓
Local DB Query (items + categories tables)
  ↓
Products displayed in ProductGrid
```

---

## Build Instructions

### Prerequisites

- Flutter SDK (channel stable, v3.24+)
- Android SDK (API level 31+)
- Java Development Kit (JDK 11+)
- Windows/Linux/macOS development environment

### Build Release APK

Run the build command with the `POS_OFFLINE` flag:

```bash
flutter build apk \
  --flavor posApp \
  --release \
  --dart-define=POS_OFFLINE=true \
  --target lib/main.dart
```

**Output location:** `build/app/outputs/flutter-apk/app-posApp-release.apk`

### Build Debug APK (Testing)

```bash
flutter build apk \
  --flavor posApp \
  --debug \
  --dart-define=POS_OFFLINE=true \
  --target lib/main.dart
```

### Install to Device/Emulator

```bash
adb install -r build/app/outputs/flutter-apk/app-posApp-release.apk
```

---

## Features & Capabilities (v1.0.27+)

### ✅ Implemented

- [x] Offline-only mode (no network calls)
- [x] Local product seeding (5 sample items: Espresso, Cappuccino, Muffin, Sandwich, Water)
- [x] ProductService abstraction (Appwrite-ready for future migration)
- [x] Activity logging to local SQLite
- [x] Responsive POS layout (YUMA-inspired UI)
- [x] Cart management (add, qty adjust, clear, checkout stub)
- [x] Business session checks
- [x] Shift management integration

### 🚧 In Development

- [ ] Cash payment flow (full integration)
- [ ] Receipt printing (thermal integration)
- [ ] Responsive grid polish (adaptive columns)
- [ ] QA automation & test suite

### 📋 Not Included (Phase 2)

- [ ] Appwrite sync (planned for Phase 2 when network enabled)
- [ ] E-Invoice (MyInvois)
- [ ] Advanced reporting
- [ ] Multi-location support

---

## Testing Checklist

Before release, verify:

### Functional

- [ ] App launches without network (WiFi off, Airplane mode)
- [ ] POS screen displays sample products
- [ ] Add items to cart
- [ ] Adjust quantities (+/- buttons)
- [ ] Clear cart
- [ ] Checkout dialog appears with subtotal
- [ ] Activity logs recorded in local DB
- [ ] Business session required before POS access
- [ ] Shift start dialog appears on first POS entry

### Performance

- [ ] Initial product load < 2 seconds
- [ ] Smooth scrolling on Android tablet (1280x800+)
- [ ] No ANR (Application Not Responding) errors
- [ ] Memory usage stable after 30 transactions

### Edge Cases

- [ ] Empty DB (seed runs on first launch)
- [ ] Large order (50+ items)
- [ ] Rapid cart updates (add/remove/qty)
- [ ] Screen rotation (responsive layout)
- [ ] Back button handling (confirm exit)

---

## Configuration Files

### Appwrite Disable Flag

Location: `lib/main.dart` (line ~67)

```dart
final posOffline = const bool.fromEnvironment('POS_OFFLINE', defaultValue: false);
if (posOffline) {
  AppwritePhase1Service.setEnabled(false);
  // Seed local products...
}
```

### Product Seed Data

Location: `lib/data/pos_seed.dart`

```dart
final List<Product> sampleProducts = [
  Product('Espresso', 4.00, 'Beverages', Icons.local_cafe, imagePath: null),
  Product('Cappuccino', 5.50, 'Beverages', Icons.local_cafe, imagePath: null),
  // ... more items
];
```

### Database Schema

Location: `lib/services/database_helper.dart`

**Tables used:**
- `categories` – Product categories (auto-seeded)
- `items` – Products (auto-seeded)
- `user_activity_log` – Activity audit trail (populated by AuditService)

---

## Troubleshooting

### "No products available" on launch

**Cause:** Seed failed (DB permissions or schema mismatch)

**Fix:**
1. Check database file permissions: `E:\data\local\tmp\extropos.db` (or device path)
2. Verify items table exists: `adb shell sqlite3 /data/data/com.extropos.posApp/databases/extropos.db ".tables"`
3. Run `PosSeedService.seedIfNeeded()` manually in debug mode
4. Clear app data and reinstall: `adb shell pm clear com.extropos.posApp`

### "Appwrite not initialized" errors in offline build

**Cause:** Build missing `POS_OFFLINE=true` flag

**Fix:**
```bash
flutter build apk \
  --flavor posApp \
  --release \
  --dart-define=POS_OFFLINE=true \
  --target lib/main.dart
```

### Slow product load

**Cause:** Large product list (>500 items)

**Fix:**
- Implement pagination in ProductService
- Use virtual scrolling in ProductGrid
- Increase `limit` parameter in `_productService.getProducts(limit: 500)`

---

## Future Enhancements (Phase 2)

### Appwrite Integration

When ready to enable network sync:

1. Set `POS_OFFLINE=false` (or build without the flag)
2. Call `AppwritePhase1Service.initialize()` in startup
3. Implement `ProductService._getProductsFromAppwrite()` methods
4. Add sync queue for offline transactions

### Local DB → Appwrite Sync

Queue and replay transactions when network available:

```dart
// Example (pseudo-code)
final pendingTxns = await db.query('pending_transactions');
for (final txn in pendingTxns) {
  await appwrite.createDocument(...);
  await db.delete('pending_transactions', where: 'id = ?', whereArgs: [txn['id']]);
}
```

### Multi-Flavor Support

- **posApp** – Consumer retail (no features, offline-first)
- **kdsApp** – Kitchen display (readonly, partial sync)
- **backendApp** – Full admin (network required)
- **keygenApp** – License generation (offline-only)

---

## Release Checklist

- [ ] All test cases pass
- [ ] No analyzer errors: `dart analyze lib/`
- [ ] APK size < 150 MB
- [ ] Version bumped: `pubspec.yaml` → 1.0.27
- [ ] Changelog updated: `CHANGELOG.md`
- [ ] Tag created: `git tag -a v1.0.27-consumer-2026`
- [ ] APK signed and uploaded to internal test track
- [ ] Team approval obtained
- [ ] Production release date locked

---

## Contact & Support

For issues or questions:
- Check logs: `adb logcat | grep flutter`
- Consult: `BACKEND_EXPANSION_TECHNICAL_GUIDE.md`
- Test in emulator: `flutter emulators launch Android`

---

**Last Updated:** February 21, 2026  
**Status:** Ready for Consumer Release (v1.0.27)
