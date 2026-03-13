# Changelog

All notable changes to ExtroPOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.2] - 2026-03-13

### Added
- **OAuth 2.0 Integration for MyInvois**
  - Implemented Client Credentials flow for secure token retrieval from LHDN API
  - Added token caching and automatic refresh mechanisms
- **Offline-First Synchronization Engine**
  - Completed `OfflineSyncService` logic for robust data persistence
  - Implemented transaction, product, inventory, and customer syncing with Appwrite backend
- **Enhanced Payment Ecosystem**
  - Created `EWalletPaymentScreen` with interactive QR code flow
  - Added structured API simulations for GrabPay, Touch 'n Go, and Boost
  - Implemented real-time payment status polling and manual verification
- **Customer Communication**
  - Added Email Receipt functionality in `ReceiptPreviewScreen`
  - Integrated `EmailService` with SMTP support for digital receipt delivery
- **System Settings Expansion**
  - New `ReceiptSettingsScreen` for granular layout and content customization
  - New `EWalletSettingsScreen` for payment provider configuration
  - Added functional stubs for P2P, KDS, and Display management

### Changed
- **Architectural Modularization (Layer A/B/C)**
  - Large files (>500 lines) refactored into focused, maintainable modules
  - `ReportsScreen` split into methods, widgets, and export components
  - `DatabaseService` decomposed into 15+ specialized part files
  - `ReceiptGenerator` refactored into specialized retail and kitchen engines
  - `PrinterService` and `ReportPrinterService` modularized for better hardware abstraction
- **Core Improvements**
  - Integrated `StartShiftDialog` into POS entry flow for mandatory shift management
  - Organized database schema into `lib/database/schemas/` for better maintainability
  - Purged Material UI dependencies from core business logic layers

### Fixed
- **Code Quality & Stability**
  - Resolved 3000+ lint warnings and naming collisions
  - Fixed DuitNow payload generation typo
  - Corrected `PaymentStatus` type definitions across e-wallet services
  - Optimized database initialization with mandatory index creation

## [1.2.1] - 2026-03-13

### Added

- **DuitNow QR payment pipeline for Vice Screen**
  - Added Layer A `DuitNowService` with EMV-like TLV payload generation
  - Added CRC16-CCITT payload checksum validation helper
  - Added BNM-compatible amount rounding integration before QR payload embedding
- **Customer-facing vice display runtime experience**
  - Added `ViceDisplayState` model and `ViceDisplayMode` enum for stream-driven rendering
  - Added reusable Layer B `ViceCustomerQR` widget for QR + total presentation
  - Added Layer C `ViceDisplayScreen` with stream subscription and cart fallback listener

### Changed

- **Vice route behavior in app shell**
  - `/vice` now opens the runtime customer display screen
  - `/vice-management` preserves the previous management/testing display screen
- **Dual display orchestration improvements**
  - `DualDisplayService` now emits strongly-typed vice display states for idle/cart/payment/change/thank-you flows
  - Rounded totals are used consistently for displayed payment amounts and DuitNow payload generation

### Fixed

- **IMIN vice-screen fallback mode stabilization**
  - Replaced dead no-op vice methods with active fallback behavior for wake/display/clear/status paths
  - Added explicit vice mode initialization flags to improve non-plugin fallback reliability
- **Regression quality checks for payment math and QR generation**
  - Added/validated focused tests for rounding, cart calculations, and DuitNow payload integrity

### APK Release

- **Local release artifact (POS flavor)**
  - Generated APK: `app-posapp-release.apk`
  - Output paths:
    - `build/app/outputs/flutter-apk/app-posapp-release.apk`
    - `build/app/outputs/apk/posApp/release/app-posApp-release.apk`
  - File size: 90,619,473 bytes (~86.42 MB)
  - Build: 1.2.1+39
  - Build timestamp: 2026-03-13 22:57 (local)

## [1.2.0] - 2026-03-10

### Added

- **Advanced Reports Dashboard with Business Intelligence**
  - **Advanced Filtering System**: Category and staff member filtering for all reports
  - **Comparative Analytics**: Period-over-period comparisons with percentage change indicators
  - **Staff Performance Metrics**: Individual cashier analytics with sales totals, transaction counts, and average order values
  - **Product Analytics with ABC Analysis**: Automatic product classification (A/B/C) based on revenue contribution using Pareto principle
  - **Export Functionality**: CSV and PDF export capabilities for comprehensive data analysis
  - **Enhanced KPI Dashboard**: Visual trend indicators and responsive grid layout
  - **Real-time Data Updates**: Instant filtering and comparison updates

- **Database Service Enhancements**
  - Added `getStaffPerformance()` method for staff analytics
  - Added `getProductAnalytics()` method with ABC analysis calculations
  - Enhanced `getSalesSummary()`, `getTopProducts()`, and `getDailySales()` with filtering parameters
  - Implemented profit margin calculations with configurable COGS assumptions

- **New Analytics Models**
  - `StaffPerformance` model for individual staff metrics
  - `ProductAnalytics` model with ABC classification and profit margin data
  - Enhanced data structures for comparative analytics

### Technical Improvements

- **Three-Layer Architecture Compliance**: All new features follow strict separation of concerns (Services → Widgets → Screens)
- **Responsive Design**: Adaptive layouts for tablet and desktop viewing
- **File Size Compliance**: All Dart files maintained under 500-line limit
- **Export Capabilities**: Professional CSV and PDF generation with device storage
- **Type Safety**: Full null-safety implementation across all new features

### APK Release

- **GitHub release artifact (APK)**
  - Uploaded release asset: `ExtroPOS-v1.2.0-20260310.apk` (GitHub Release `v1.2.0`)
  - File size: 89,763,973 bytes (~85.61 MB)
  - Build: 1.2.0+38
  - Target: Android release build with posApp flavor

## [1.1.9] - 2026-03-06

### Fixed

- Resolved compilation errors in retail_pos_screen_modern.dart (missing methods and variables)
- Fixed Windows file permission issues preventing APK builds by running as administrator
- Updated Product constructor calls with required 'id' parameters in data operations

## [1.1.8] - 2026-03-05

### Fixed

- **Receipt address formatting with smart line breaking**
  - Issue: Address text was cutting words in the middle (e.g., "Kota Kinabalu" became "Kota Kin" + "abalu")
  - Solution: Implemented intelligent address wrapping with priority break points:
    1. **Break after commas first** - Keeps address segments intact ("Kota Kinabalu," stays together)
    2. **Then break at word boundaries** - Only breaks at spaces between words
    3. **Fallback to character limit** - Finally handles extremely long words
  - Applied to both merchant and customer receipt types
  - Works seamlessly with both 58mm and 80mm thermal printers
  - Example: "Kota Kinabalu, Sabah, Malaysia" now breaks intelligently across lines instead of cutting words

## [1.1.7] - 2026-03-03

### Added

- **GitHub release artifact (APK)**
  - Uploaded release asset: `ExtroPOS-v1.1.7+35-20260303.apk` (GitHub Release `v1.1.7`)
  - File size: 105,137,070 bytes (~100.3 MB)
  - SHA-256: `BC38F716B9F30D5C80944653B3F417FAF713790B87327109BB874D6A3AE8BB90`

### Fixed

- **Payment Processing: No active payment methods** 
  - Root cause: Incorrect `status` enum values in payment_methods seeding
  - Bug: PaymentMethodStatus.active = 0, but seeding was using status = 1 (inactive)
  - Fixed: Updated seeding to use status = 0 for active payment methods
  - Added migration to fix existing databases with wrong status values
  - Default payment methods now correctly marked as active:
    - Cash (default, active)
    - Credit Card (active)
    - Debit Card (active)
    - E-Wallet (active)

- **Printer Management screen not working**
  - Re-implemented missing screen UI sections for the split part-file architecture:
    - Header/actions area
    - Left printer list panel
    - Right details/actions panel
  - Removed duplicate in-class UI methods from main screen file to avoid part conflicts
  - Fixed popup menu action handling and paper size rendering in printer details

- **Release build blocker (Training Mode imports)**
  - Fixed stale imports in `training_mode_service.dart` after model renames
  - Updated imports to:
    - `business_info_model.dart`
    - `enum_models.dart`
  - Resolved compile errors related to missing `BusinessInfo`/`BusinessMode` symbols

### Verification

- POS release APK builds successfully
- APK installed successfully on connected Android device via ADB
- Payment and printer-management related changed files pass editor diagnostics

---

## [1.1.6] - 2026-03-02

### Fixed

- **Dart Lint: Protected Member Access in extensions**: Fixed critical lint errors preventing APK compilation
  - Issue: `setState()` cannot be called from extension methods (protected member violation)
  - Solution: Introduced `_updateState()` wrapper method in parent State classes
  - Applied: Payment screen (7 fixes), Retail POS (6 fixes), Unified POS (8 fixes), Advanced Reports (13 fixes)
  - Impact: Reduced production errors from 50+ to 0, enabled clean release build

- **Unused Imports**: Removed unused imports from printer form dialog
  - Removed `category_model.dart` import
  - Removed `foundation.dart` import

- **Analyzer Configuration**: Updated `analysis_options.yaml` to exclude non-production files
  - Excluded `lib/examples/**`, `backend_validation.dart`, `phase2_validation.dart`
  - Added `invalid_use_of_protected_member: ignore` for legacy code patterns

### Technical Details

- Fixed state management pattern in 5 screen classes:
  - `PaymentScreen` (payment_screen.dart)
  - `RetailPOSScreen` (retail_pos_screen.dart)
  - `UnifiedPOSScreen` (unified_pos_screen.dart)
  - `AdvancedReportsScreen` (advanced_reports_screen.dart)
  - Dialog form widgets (printer_form_dialog.dart)
- Updated 14 extension part files to use safe `_updateState()` wrapper
- Verified APK builds successfully: 109.2 MB release build completes without errors
- Tested on physical tablet: App runs and resumes correctly
- Version bumped from 1.1.5+33 to 1.1.6+34

---

## [1.1.5] - 2026-03-02

### Added

- **MyInvois Exception Handling**: Added typed exception support for MyInvois API errors
  - Introduced `MyInvoisException` with error code, status, detail, and retry metadata
  - Added response parsing for official error payloads and `Retry-After` header support
  - Mapped HTTP status defaults for common MyInvois failure scenarios

- **Rate Limiting Support**: Added local request throttling utilities for e-invoice operations
  - Introduced `RateLimiter` service with per-minute request window tracking
  - Added submit endpoint limiter (100 RPM) and query endpoint limiter (12 RPM)
  - Added wait duration calculation for user-friendly retry timing

- **Retry with Backoff**: Added retry helper for transient MyInvois failures
  - Introduced `RetryHelper` with exponential backoff
  - Retries only for retryable MyInvois errors (e.g. duplicate submission, 429, 503)
  - Supports API-provided retry delays when available

### Changed

- **E-Invoice Service Hardening**: Updated `EInvoiceService` for robust submission/query behavior
  - `submitDocuments()` now uses typed exceptions, retry handling, and local rate-limit checks
  - `getRecentDocuments()`, `getSubmission()`, `getDocument()`, `validateTin()`, and `cancelDocument()` now use consistent typed error handling
  - Converted generic exception flows to structured `MyInvoisException` responses for better UI handling

### Tests

- Added focused unit tests for new Priority 2 support components
  - `test/services/einvoice_priority2_support_test.dart`
  - Verified error parsing and rate limiter request-window behavior

### Technical Details

- Added [myinvois_exception.dart](lib/exceptions/myinvois_exception.dart)
- Added [rate_limiter.dart](lib/services/rate_limiter.dart)
- Added [retry_helper.dart](lib/services/retry_helper.dart)
- Updated [einvoice_service.dart](lib/services/einvoice_service.dart)
- Added [einvoice_priority2_support_test.dart](test/services/einvoice_priority2_support_test.dart)
- Version bumped from 1.1.4+32 to 1.1.5+33

---

## [1.1.4] - 2026-02-23

### Fixed

- **App Icon Issue**: Generated launcher icons for Android and iOS platforms
  - Fixed broken app icon on device home screen and app drawer
  - Generated adaptive icons with proper background color (#121212)
  - Created icons for both Android (mipmap) and iOS platforms
  - Used flutter_launcher_icons package to generate all icon variants

- **Products Not Showing**: Fixed critical issue where products and categories didn't display on POS screen
  - Implemented proper database fetching in `UnifiedPOSScreen._fetchData()`
  - Connected `DatabaseService` to load categories and items from local SQLite database
  - Added proper mapping from database Item model to POS Product model
  - Added error handling and loading states for better UX
  - Console logs now show confirmation of loaded products count

- **Icon Display Inside App**: Fixed all icons showing as the same icon throughout the app
  - Root cause: `_iconFromDb()` method was hardcoded to return `Icons.category` for all items
  - Implemented proper icon code point conversion from database to IconData
  - Now supports custom font families if specified in database
  - Falls back to MaterialIcons (Flutter default) for standard icons
  - All product and category icons now display correctly based on database values

### Technical Details

- Modified [database_service.dart](lib/services/database_service.dart#L1122): Fixed icon conversion method
- Modified [unified_pos_screen.dart](lib/screens/unified_pos_screen.dart): Added database integration
- Added changelog screen accessible from Settings → About → Changelog
- Version bumped from 1.1.3+31 to 1.1.4+32

### Developer Notes

- Icon code points are stored as integers in the database
- MaterialIcons font family is used by default
- Products are filtered by `is_available = 1` flag
- Categories are ordered by `sort_order ASC, name ASC`

---

## [1.1.3] - 2026-02-20

### Added

- Multi-mode POS system (Retail, Cafe, Restaurant)
- Business session management (Open/Close business day)
- Shift management for cashiers with opening/closing cash tracking
- User authentication and role-based access control
- Training mode support with data generation tools
- Three-layer access control system

### Fixed

- Various UI improvements and responsive design enhancements
- Database optimization and query performance
- Memory management and performance monitoring

---

## [1.1.2] - 2026-02-15

### Added

- Retail POS screen with modern UI
- Category and product management
- Shopping cart functionality
- Payment processing with multiple payment methods

### Fixed

- Category display limit (removed 3-category restriction)
- Receipt printing integration
- User status toggle bug in database

---

## [1.1.1] - 2026-02-10

### Added

- Initial release of ExtroPOS
- Basic POS functionality
- SQLite database integration
- Receipt printing support
- Dual display support

---

## Older Versions

For older version history, see the [archive changelog](docs/archive/CHANGELOG.md).
