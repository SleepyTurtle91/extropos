# FlutterPOS - Complete Four-Flavor Architecture

## Overview

FlutterPOS now consists of **four distinct product flavors**, each serving a specific purpose in the restaurant/cafe/retail ecosystem.

---

## The Four Flavors

### 1. POS Flavor (Point of Sale)

**Package**: `com.extrotarget.extropos.pos`  
**Purpose**: Main cashier terminal for taking orders and processing sales  
**Users**: Cashiers, waitstaff, counter staff

**Key Features**:

- Order taking (Retail, Cafe, Restaurant modes)

- Payment processing

- Receipt printing

- Customer display

- Table management (Restaurant)

- Order numbers (Cafe)

- Reports and analytics

- Dual display support

**Entry Point**: `lib/main.dart`

---

### 2. KDS Flavor (Kitchen Display System)

**Package**: `com.extrotarget.extropos.kds`  
**Purpose**: Kitchen display for order management  
**Users**: Kitchen staff, cooks

**Key Features**:

- Real-time order display

- Order status management

- Preparation timers

- Order prioritization

- Kitchen-optimized UI

- Large text for readability

**Entry Point**: `lib/main_kds.dart`

---

### 3. Backend Flavor (Management)

**Package**: `com.extrotarget.extropos.backend`  
**Purpose**: Remote management of products, categories, and reports  
**Users**: Restaurant owners, managers

**Key Features**:

- Categories management

- Products management

- Modifiers management

- Business info configuration

- Advanced reports viewing

- Google Drive sync

- Desktop-friendly UI

**Entry Point**: `lib/main_backend.dart`

---

### 4. Key Generator Flavor (License Management)

**Package**: `com.extrotarget.extropos.keygen`  
**Purpose**: Generate and validate license keys  
**Users**: System administrators, sales team

**Key Features**:

- 1-month trial key generation

- 3-month trial key generation

- Lifetime key generation

- Key validation

- Batch generation (1-100 keys)

- Clipboard integration

- Offline operation

**Entry Point**: `lib/main_keygen.dart`

---

## Architecture Comparison

| Feature | POS | KDS | Backend | KeyGen |
|---------|-----|-----|---------|--------|
| **Purpose** | Sales | Kitchen | Management | Licensing |

| **Users** | Cashiers | Cooks | Managers | Admins |

| **Orders** | ✅ Take | ✅ View | ❌ No | ❌ No |

| **Payments** | ✅ Process | ❌ No | ❌ No | ❌ No |

| **Products** | ✅ Use | ✅ View | ✅ Manage | ❌ No |

| **Reports** | ✅ Full | ❌ No | ✅ View | ❌ No |

| **Printing** | ✅ Full | ✅ Kitchen | ❌ No | ❌ No |

| **Drive Sync** | ✅ Yes | ❌ No | ✅ Yes | ❌ No |

| **Activation** | ✅ Required | ✅ Required | ✅ Required | ❌ No |

| **Window Mode** | Fullscreen | Fullscreen | Resizable | Resizable |

| **Size** | 85.5MB | ~80MB | 178MB | 178MB |

---

## Build Commands

### Build Individual Flavors

```bash

# POS

./build_flavors.sh pos release


# KDS

./build_flavors.sh kds release


# Backend

./build_flavors.sh backend release


# Key Generator

./build_flavors.sh keygen release

```text


### Build All Flavors



```bash

# Build all four flavors at once

./build_flavors.sh all release

```text

---


## Package IDs


All flavors share the base package with different suffixes:


```text
com.extrotarget.extropos
├── .pos        # POS app

├── .kds        # KDS app

├── .backend    # Backend app

└── .keygen     # Key Generator app

```text

**Benefit**: All four apps can coexist on the same device.

---


## Typical Deployment Scenarios



### Scenario 1: Small Cafe


**Setup**:


- 1 tablet with **POS** (counter)

- 1 phone with **Backend** (owner's device)

- 1 PC with **KeyGen** (office)

**Workflow**:

1. Owner generates license with KeyGen
2. Owner activates POS with license
3. Cashier takes orders on POS
4. Owner manages menu remotely with Backend

---


### Scenario 2: Full-Service Restaurant


**Setup**:


- 2 tablets with **POS** (front counter + bar)

- 1 display with **KDS** (kitchen)

- 1 tablet with **Backend** (manager's office)

- 1 PC with **KeyGen** (admin office)

**Workflow**:

1. Admin generates licenses with KeyGen
2. POS terminals activated
3. Waitstaff takes orders on POS
4. Kitchen views orders on KDS
5. Manager updates menu with Backend
6. All data syncs via Google Drive

---


### Scenario 3: Multi-Location Chain


**Setup**:


- Multiple **POS** (each location)

- Multiple **KDS** (each kitchen)

- 1 central **Backend** (HQ)

- 1 **KeyGen** (licensing department)

**Workflow**:

1. HQ generates licenses for all locations
2. Each location activates POS/KDS
3. HQ manages centralized product catalog
4. Changes sync to all locations via Drive
5. HQ monitors reports from all locations

---


## Data Flow



### License Activation Flow



```text
[KeyGen App]
    ↓ Generate license key
[Clipboard]
    ↓ Copy/paste
[POS/KDS/Backend]
    ↓ Validate key
[LicenseService]
    ↓ Check with LicenseKeyGenerator
[Activated]

```text


### Product Management Flow



```text
[Backend App]
    ↓ Edit product/category
[Local Database]
    ↓ Save changes
[Google Drive Sync]
    ↓ Upload database
[Cloud Storage]
    ↓ Download to POS
[POS App]
    ↓ Updated menu
[Customers see changes]

```text


### Order Flow



```text
[POS App]
    ↓ Take order
[Local Database]
    ↓ Save order
[KDS App]
    ↓ Display order
[Kitchen Staff]
    ↓ Prepare food
[KDS App]
    ↓ Mark complete
[POS App]
    ↓ Update status
[Customer served]

```text

---


## Shared Components


All four flavors share:


### Services


- `LicenseService` - License validation

- `LicenseKeyGenerator` - Key generation/validation

- `DatabaseService` - SQLite operations

- `BackupService` - Database backup/restore

- `ThemeService` - UI theming


### Models


- `Product` - Product catalog

- `Category` - Product categories

- `ModifierGroup` - Product modifiers

- `BusinessInfo` - Business configuration


### Database Schema


- All flavors use the same SQLite schema (v23)

- Compatible for sync via Google Drive

---


## Version Information


| Flavor | Version | Build |
|--------|---------|-------|
| POS | 1.0.14-pos | 14 |
| KDS | 1.0.14-kds | 14 |
| Backend | 1.0.14-backend | 14 |
| KeyGen | 1.0.14-keygen | 14 |

**Base Version**: 1.0.14 (defined in `pubspec.yaml`)

---


## Documentation Index



### Complete Guides


- `KEYGEN_FLAVOR_GUIDE.md` - Key Generator complete guide

- `BACKEND_FLAVOR_GUIDE.md` - Backend Manager complete guide

- `PRODUCT_FLAVORS_GUIDE.md` - All flavors overview

- `GOOGLE_SERVICES_INTEGRATION.md` - Drive sync setup


### Quick Start Guides


- `KEYGEN_QUICK_START.md` - Key Generator quick reference

- `BACKEND_QUICK_START.md` - Backend quick reference

- `QUICK_ACTION_CHECKLIST.md` - Development workflow


### Implementation Summaries


- `KEYGEN_IMPLEMENTATION_SUMMARY.md` - Key Generator details

- `BACKEND_IMPLEMENTATION_SUMMARY.md` - Backend details


### Database & Schema


- `DATABASE_SCHEMA.md` - Database structure

- `DATABASE_ER_DIAGRAM.md` - Entity relationships

- `DATABASE_MIGRATION_GUIDE.md` - Version migration

---


## Build Process



### Complete Build Workflow



```bash

# 1. Clean previous builds

flutter clean


# 2. Get dependencies

flutter pub get


# 3. Build all flavors

./build_flavors.sh all release


# 4. Output locations

# - build/app/outputs/flutter-apk/app-posapp-release.apk

# - build/app/outputs/flutter-apk/app-kdsapp-release.apk

# - build/app/outputs/flutter-apk/app-backendapp-release.apk

# - build/app/outputs/flutter-apk/app-keygenapp-release.apk



# 5. Desktop copies

# - ~/Desktop/FlutterPOS-v1.0.14-YYYYMMDD-pos.apk

# - ~/Desktop/FlutterPOS-v1.0.14-YYYYMMDD-kds.apk

# - ~/Desktop/FlutterPOS-v1.0.14-YYYYMMDD-backend.apk

# - ~/Desktop/FlutterPOS-v1.0.14-YYYYMMDD-keygen.apk

```text

---


## Development Guidelines



### When to Use Each Flavor


**Use POS Flavor** when:


- Developing order-taking features

- Testing payment processing

- Working on table management

- Testing customer display

- Debugging receipt printing

**Use KDS Flavor** when:


- Developing kitchen display

- Testing order routing

- Working on kitchen workflow

- Testing order status updates

**Use Backend Flavor** when:


- Developing product management

- Testing category management

- Working on business config

- Testing Google Drive sync

- Debugging remote updates

**Use KeyGen Flavor** when:


- Generating trial licenses

- Creating lifetime licenses

- Testing license validation

- Debugging activation flow

- Managing customer licenses

---


## Testing Checklist



### Integration Testing


- [ ] Generate key in KeyGen

- [ ] Activate POS with key

- [ ] Activate KDS with key

- [ ] Activate Backend with key

- [ ] Add product in Backend

- [ ] Sync to Google Drive

- [ ] Verify product appears in POS

- [ ] Take order in POS

- [ ] Verify order appears in KDS

- [ ] Mark order complete in KDS

- [ ] Verify status updates in POS


### Cross-Flavor Testing


- [ ] All flavors install simultaneously

- [ ] Database compatibility across flavors

- [ ] License activation works in all

- [ ] Theme consistency

- [ ] No package conflicts

---


## Maintenance



### Updating All Flavors


When making changes that affect all flavors:

1. **Update shared code** (`lib/services/`, `lib/models/`)

2. **Test in one flavor** (usually POS)

3. **Build all flavors**: `./build_flavors.sh all debug`
4. **Test each flavor** individually

5. **Document changes** in all relevant guides

6. **Increment version** in `pubspec.yaml`

7. **Build release**: `./build_flavors.sh all release`


### Version Bumping



```yaml

# pubspec.yaml

version: 1.0.14+14  # Change to 1.0.15+15

```text

This affects all four flavors automatically.

---


## Summary


FlutterPOS's four-flavor architecture provides:

✅ **Separation of Concerns**: Each app serves specific users  
✅ **Code Reuse**: 90% shared codebase  
✅ **Scalability**: Easy to add new flavors  
✅ **Flexibility**: Mix and match for different setups  
✅ **Maintainability**: Single codebase, multiple outputs  
✅ **Professional**: Enterprise-grade architecture  

**Total Lines of Code**: ~50,000+ lines  
**Flavors**: 4  
**Shared Services**: 20+  
**Documentation**: 3,000+ lines  

---

**Last Updated**: 2025-11-26  
**Version**: 1.0.14  
**Author**: FlutterPOS Development Team
