# Backend Flavor - Quick Start Guide

## What is the Backend Flavor?

The Backend Flavor is a remote management app for FlutterPOS that lets you manage your product catalog from anywhere.

---

## Quick Build Commands

```bash

# Debug build (faster, for testing)

./build_flavors.sh backend debug


# Release build (optimized, for production)

./build_flavors.sh backend release


# Build all three flavors

./build_flavors.sh all release

```text

---


## Installation


1. Build the APK: `./build_flavors.sh backend release`
2. Find APK: `build/app/outputs/flutter-apk/app-backendApp-release.apk`
3. Transfer to Android device
4. Install (enable "Unknown Sources" if needed)

**Note**: Backend app can coexist with POS and KDS apps on same device.

---


## First-Time Setup


1. **Activation**: Enter license key (same as POS)
2. **Setup**: Configure business info
3. **PIN**: Create security PIN
4. **Google Account**: Connect for cloud sync

---


## Main Features



### Home Screen


- **Sync Status**: Shows Google Drive connection

- **Categories**: Manage product categories

- **Products**: Add/edit menu items

- **Modifiers**: Configure size, toppings, etc.

- **Reports**: View sales analytics

- **Settings**: Google account and sync


### Google Drive Sync


All changes sync automatically across devices:


```text
Backend App → Google Drive → POS Device

```text

**Manual Sync**: Tap "Sync with Google Drive" button on home screen

---


## Common Tasks



### Add a New Product


1. Tap "Products" on home screen
2. Tap "+" button
3. Fill in: Name, Price, Category
4. Choose icon
5. Save
6. Sync to cloud
7. Product appears on POS within sync interval


### Update Prices


1. Tap "Products"
2. Find product
3. Edit price
4. Save
5. Sync to cloud


### Add Category


1. Tap "Categories"
2. Tap "+"
3. Enter name and details
4. Save
5. Sync to cloud

---


## Sync Best Practices


- ✅ **Before major changes**: Tap sync button first

- ✅ **After changes**: Tap sync to push updates

- ✅ **Wi-Fi recommended**: For faster sync

- ✅ **Check sync status**: Green = connected, Red = disconnected

---


## Troubleshooting



### Sync Not Working?


1. Check internet connection
2. Verify Google account is connected (Settings → Google Account)
3. Try manual sync
4. Restart app


### Changes Not Appearing on POS?


1. Verify both devices use same Google account
2. Wait for sync interval (default: 30 minutes)
3. Manually sync on both devices
4. Check POS has internet connection


### Cannot Add Products?


1. Verify setup is complete
2. Check category exists
3. Restart app
4. Check error messages

---


## Technical Info


- **Package**: `com.extrotarget.extropos.backend`

- **Entry Point**: `lib/main_backend.dart`

- **Flavor**: `backendApp`

- **Build**: `flutter build apk --flavor backendApp`

---


## File Locations



```text
lib/
├── main_backend.dart              # Backend entry point

├── screens/
│   └── backend_home_screen.dart   # Main dashboard

└── services/
    └── google_services.dart       # Sync functionality

```text

---


## Build Script Options



```bash

# Single flavor

./build_flavors.sh pos release      # POS only

./build_flavors.sh kds release      # KDS only

./build_flavors.sh backend release  # Backend only



# Multiple flavors

./build_flavors.sh all release      # All three flavors



# Build types

./build_flavors.sh backend debug    # Debug (fast)

./build_flavors.sh backend release  # Release (optimized)

```text

---


## Related Documentation


- **Full Guide**: `docs/BACKEND_FLAVOR_GUIDE.md`

- **Google Services**: `docs/GOOGLE_SERVICES_INTEGRATION.md`

- **Product Flavors**: `docs/PRODUCT_FLAVORS_GUIDE.md`

- **Database Schema**: `docs/DATABASE_SCHEMA.md`

---

**Need Help?** See `docs/BACKEND_FLAVOR_GUIDE.md` for detailed instructions.
