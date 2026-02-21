# FlutterPOS Backend Manager - Flavor Guide

## Overview

The **Backend Flavor** is a specialized version of FlutterPOS designed for remote management of your POS system. It allows restaurant/cafe owners and managers to manage their product catalog, categories, and modifiers from any Android device, with automatic synchronization through Google Drive.

**Version**: 1.0.14-backend  
**Package ID**: com.extrotarget.extropos.backend  
**App Name**: FlutterPOS Backend Manager

---

## Purpose

The Backend Manager flavor enables you to:

- **Remotely manage categories**: Add, edit, delete product categories

- **Remotely manage products**: Update menu items, prices, and details

- **Remotely manage modifiers**: Configure modifier groups (size, toppings, etc.)

- **View advanced reports**: Access sales analytics and performance metrics

- **Sync via Google Drive**: Automatic database synchronization across devices

- **Update business info**: Configure tax rates, service charges, business details

---

## Architecture

### Three-Flavor System

FlutterPOS now supports three distinct product flavors:

1. **POS Flavor** (`posApp`) - Point of Sale terminal for cashiers

2. **KDS Flavor** (`kdsApp`) - Kitchen Display System for kitchen staff

3. **Backend Flavor** (`backendApp`) - Management interface for owners/managers ✨ **NEW**

All three flavors share the same database schema and can sync data through Google Drive.

### Key Differences from POS Flavor

| Feature | POS Flavor | Backend Flavor |
|---------|-----------|----------------|
| Order taking | ✅ Yes | ❌ No |
| Payment processing | ✅ Yes | ❌ No |
| Product management | ✅ Yes | ✅ Yes |
| Reports viewing | ✅ Yes | ✅ Yes |
| Google Drive sync | ✅ Yes | ✅ Yes |
| Dual display support | ✅ Yes | ❌ No |
| Customer display | ✅ Yes | ❌ No |
| Window mode | ⬜ Fullscreen | ⬜ Resizable window |
| Default size | Full screen | 1200x800 |
| Printer integration | ✅ Full | ❌ No |

---

## Building the Backend Flavor

### Using the Build Script (Recommended)

```bash

# Build debug version

./build_flavors.sh backend debug


# Build release version

./build_flavors.sh backend release


# Build all flavors at once

./build_flavors.sh all release

```text


### Manual Build



```bash

# Debug build

flutter build apk --debug --flavor backendApp --dart-define=FLAVOR=backend


# Release build

flutter build apk --release --flavor backendApp --dart-define=FLAVOR=backend

```text


### Output Location


- **APK Path**: `build/app/outputs/flutter-apk/app-backendApp-release.apk`

- **Desktop Copy**: Automatically copied to `~/Desktop/FlutterPOS-v1.0.14-YYYYMMDD-backend.apk`

---


## Installation



### Prerequisites


- Android device (phone or tablet)

- Same device can run both POS and Backend apps simultaneously

- Recommended: Separate device for backend management


### Installation Steps


1. Build the backend APK using the build script
2. Transfer the APK to your Android device
3. Enable "Install from Unknown Sources" in device settings
4. Install the APK
5. Both POS and Backend apps can coexist on the same device


### Running Multiple Flavors


All three flavors (POS, KDS, Backend) can be installed on the same device:


- **POS**: `com.extrotarget.extropos.pos`

- **KDS**: `com.extrotarget.extropos.kds`

- **Backend**: `com.extrotarget.extropos.backend`

Each has its own app icon and data storage, but they can share databases via Google Drive sync.

---


## Initial Setup



### First Launch


1. **Activation Screen**: Enter your license key (same as POS app)
2. **Setup Screen**: Configure business information

   - Business name

   - Address

   - Tax settings

   - Service charge settings

3. **Lock Screen**: Create a PIN for security (shared with POS if using same device)


### Google Drive Setup


1. Open **Settings** → **Google Account**

2. Tap "Connect Google Account"
3. Sign in with your Google account
4. Grant permissions for Gmail and Drive access
5. Enable automatic sync

---


## Features



### Home Screen


The Backend Manager home screen provides:


#### Welcome Card


- Displays business name

- Quick access to business info


#### Sync Status


- Shows Google Drive connection status

- Displays last sync time

- Manual sync button


#### Management Section


**Categories Management**


- Add/edit/delete product categories

- Organize products by category

- Set category order and visibility

**Products Management**


- Add new products with:

  - Name, price, category

  - Product icon

  - Tax settings

  - Stock tracking (optional)

- Edit existing products

- Bulk operations

**Modifiers Management**


- Create modifier groups (size, toppings, add-ons)

- Set modifier prices

- Configure required/optional modifiers

- Assign modifiers to products

**Business Information**


- Update business details

- Configure tax rates

- Set service charge rates

- Manage business hours


#### Reports Section


**Advanced Reports**


- View sales analytics

- Export reports to CSV/PDF

- Email reports automatically

- Schedule recurring reports

---


## Google Drive Synchronization



### How It Works


1. **Database Backup**: Your SQLite database is automatically backed up to Google Drive
2. **Conflict Resolution**: Newest backup wins in case of conflicts
3. **Multi-Device**: Same database can be synced across multiple devices
4. **Automatic**: Sync happens in the background (configurable interval)


### Manual Sync


Tap the **Sync with Google Drive** button on the home screen to manually trigger a sync.


### Sync Frequency


Default: Every 30 minutes (configurable in settings)


### What Gets Synced


- ✅ Products

- ✅ Categories

- ✅ Modifiers

- ✅ Business information

- ✅ Tax/service charge settings

- ✅ Users

- ✅ Sales data

- ✅ Reports

- ❌ Active orders (POS-specific)

- ❌ Table states (Restaurant mode)

---


## Use Cases



### Remote Menu Management


**Scenario**: Restaurant owner wants to update menu prices from home

1. Open Backend Manager on phone
2. Navigate to Products Management
3. Find product and edit price
4. Tap "Sync with Google Drive"
5. Changes automatically appear on POS device within sync interval


### Multi-Location Management


**Scenario**: Coffee chain with 5 locations wants centralized product management

1. Install Backend Manager on manager's tablet
2. Install POS app on each location's POS terminal
3. All devices connect to same Google account
4. Manager updates products → all locations sync automatically
5. Reports aggregate data from all locations


### Mobile Product Updates


**Scenario**: Cafe owner needs to add seasonal items while at supplier

1. Open Backend Manager on phone
2. Add new products with photos
3. Assign to seasonal category
4. Sync to cloud
5. Products appear on cafe POS immediately

---


## Workflow Diagrams



### Backend → POS Sync Flow



```text
[Backend Manager] 
    ↓ (1. Edit product)
[Local SQLite DB]
    ↓ (2. Manual/auto sync)
[Google Drive Backup]
    ↓ (3. Auto sync on POS)
[POS Device]
    ↓ (4. Product available)
[Customers see updated menu]

```text


### Multi-Device Setup



```text
┌─────────────────┐
│ Backend Manager │ (Manager's tablet)
│  - Add products │

│  - View reports │

└────────┬────────┘
         │
         ↓ (Google Drive)
         │
    ┌────┴────┬────────┬────────┐
    ↓         ↓        ↓        ↓
┌───────┐ ┌───────┐ ┌───────┐ ┌───────┐
│POS #1 │ │POS #2 │ │POS #3 │ │ KDS   │
└───────┘ └───────┘ └───────┘ └───────┘

```text

---


## Best Practices



### Security


- **Use Strong PINs**: Protect access to backend management

- **Limit Access**: Only give backend access to trusted managers

- **Regular Backups**: Enable automatic Google Drive sync

- **Audit Trail**: Check reports for unauthorized changes


### Data Management


- **Sync Before Major Changes**: Ensure latest data before bulk edits

- **Test on One Device**: Verify changes before syncing to all devices

- **Schedule Reports**: Set up automated daily/weekly reports

- **Export Regularly**: Download CSV backups of critical data


### Performance


- **Wi-Fi Recommended**: Use stable Wi-Fi for large syncs

- **Off-Peak Hours**: Schedule major updates during slow business hours

- **Image Optimization**: Compress product images before upload

- **Clean Up**: Regularly archive old reports and orders

---


## Troubleshooting



### Sync Not Working


**Problem**: Changes not appearing on POS device

**Solutions**:

1. Check Google account connection (Settings → Google Account)
2. Verify internet connection on both devices
3. Manually trigger sync on both devices
4. Check sync interval settings
5. Verify both devices use same Google account


### Cannot Add Products


**Problem**: "Add Product" button not responding

**Solutions**:

1. Check database permissions
2. Restart the app
3. Verify setup is complete
4. Check for error messages in reports


### Sync Conflicts


**Problem**: Different data on different devices

**Solutions**:

1. Identify which device has correct data
2. On that device, tap "Sync with Google Drive"
3. On other devices, restore from Google Drive backup
4. Newest backup will overwrite older data


### License Expired


**Problem**: App shows activation screen

**Solutions**:

1. Enter valid license key
2. Contact support if license should be active
3. License is shared across all flavors

---


## Technical Details



### File Locations


**Entry Point**: `lib/main_backend.dart`  
**Home Screen**: `lib/screens/backend_home_screen.dart`  
**Gradle Config**: `android/app/build.gradle.kts`


### Build Configuration



```kotlin
backendApp {
    dimension = "appType"
    applicationIdSuffix = ".backend"
    versionNameSuffix = "-backend"
    resValue("string", "app_name", "FlutterPOS Backend Manager")
}

```text


### Services Used


- `GoogleServices`: OAuth 2.0, Gmail API, Drive API

- `BackupService`: Database backup/restore

- `BusinessSessionService`: Session management

- `ThemeService`: UI theming

- `ConfigService`: App configuration

- `LicenseService`: License validation


### Excluded Services


- `DualDisplayService`: Not needed for backend

- `CustomerDisplayService`: POS-specific

- `PrinterService`: No printing in backend

- `GuideService`: Simplified UI

---


## Changelog



### v1.0.14-backend (2025-01-XX)


- ✨ **NEW**: Initial release of Backend Manager flavor

- ✅ Categories management

- ✅ Products management

- ✅ Modifiers management

- ✅ Advanced reports viewing

- ✅ Google Drive synchronization

- ✅ Responsive layout (mobile + desktop)

- ✅ Same license as POS flavor

- ✅ Shared database schema

---


## Support



### Getting Help


- **Documentation**: See `docs/` folder for detailed guides

- **Issues**: Check existing issues before creating new ones

- **License**: Contact support for license issues


### Related Guides


- `GOOGLE_SERVICES_INTEGRATION.md` - Google Drive setup

- `ADVANCED_REPORTING_GUIDE.md` - Reports features

- `PRODUCT_FLAVORS_GUIDE.md` - All flavors overview

- `DATABASE_SCHEMA.md` - Database structure

---


## Future Enhancements


Planned features for future versions:


- [ ] Real-time sync notifications

- [ ] Conflict resolution UI

- [ ] Multi-user access control

- [ ] Audit log for changes

- [ ] Backend-specific analytics

- [ ] Bulk import/export

- [ ] Image upload from camera

- [ ] Offline mode with queue

- [ ] Role-based permissions

- [ ] Change history tracking

---


## License


This is part of the FlutterPOS system. Same license applies to all flavors (POS, KDS, Backend).

---

**Last Updated**: 2025-01-XX  
**Version**: 1.0.14-backend  
**Author**: FlutterPOS Development Team
