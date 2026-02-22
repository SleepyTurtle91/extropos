# Changelog

All notable changes to this project will be documented in this file.

## [1.0.27] - 2026-01-14

### Fixed — Retail POS Improvements

- **Category Display Fix**: Removed 3-category limit in modern retail POS screen

  - All categories from database now display in the categories row

  - Previously limited to first 3 categories with `.take(3)` restriction

  - Categories now horizontally scrollable with fixed width (200px each)

  - Supports unlimited categories with smooth horizontal scrolling

- **Receipt Printing Fix**: Implemented proper payment processing with automatic receipt printing

  - Added `_processCashPayment()` and `_processCardPayment()` methods

  - Replaced placeholder toast messages with actual payment workflow

  - Integrated `PrinterService` for automatic receipt printing after payment

  - Added `_tryAutoPrint()` method following cafe POS pattern

  - Receipt includes all transaction details (items, subtotal, tax, service charge, total, payment method)

  - Validates printer configuration before attempting to print

  - Shows appropriate error messages if printing fails

  - Updates customer display with change amount and thank you message

  - Auto-clears cart after successful payment

### Fixed — User Status Toggle Bug

- **User Active/Inactive Status Fix**: Resolved critical bug where user status was reversed in the database

  - Fixed `getUserById()` method incorrectly mapping `is_active` database column to `UserStatus` enum

  - Previously: `is_active=1` mapped to `inactive`, `is_active=0` mapped to `active` (reversed!)

  - Now: `is_active=1` correctly maps to `active`, `is_active=0` correctly maps to `inactive`

  - Users can now be properly activated/deactivated from Users Management screen

  - Status toggle now works as expected with immediate UI feedback

### Changed — App Icon Update

- **New ExtroPOS Logo**: Updated POS app icon with professional ExtroPOS branding

  - Modern logo design featuring dynamic "E" with arrow and speed lines

  - White background with burgundy gradient logo for better visibility

  - Professional rounded corner design matching modern app standards

  - Generated adaptive icons for Android with dark background (#121212)

  - iOS icons generated with proper sizing and alpha channel handling

  - Applied to POS flavor (posApp) with full resolution support

### Technical Details

- Icon generation using flutter_launcher_icons package v0.14.4

- Source icon: 6MB high-resolution PNG (assets/icons/pos_icon.png)

- Generated all required Android mipmap sizes (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)

- Created adaptive icon resources with foreground and background layers

- iOS icon set generated for all required sizes (1024x1024 down to 20x20)

- Properly configured colors.xml for Android adaptive icon background

**Build Information:**

- APK File: `FlutterPOS-v1.0.26-20260114-pos-new-icon.apk`

- APK Size: 107MB

- Build Time: 488 seconds

- Build Date: January 14, 2026

## [1.0.26] - 2026-01-13

### Added — Category Navigation Enhancement

- **Category Popup Feature**: Implemented interactive category tiles that display products when tapped

  - Added `_showCategoryProductsPopup()` method in retail POS screen

  - Popup shows filtered products for selected category in grid layout

  - Includes category name in popup title and close button

  - Maintains consistent dark theme styling with existing UI

### Fixed — UI Layout Improvements

- **System Navigation Bar Fix**: Resolved number pad obstruction by system navigation bar on Android devices

  - Added `MediaQuery.of(context).viewPadding.bottom` padding to cart sidebar

  - Ensures number pad remains accessible when system navigation is enabled

  - Dynamic padding calculation adapts to different device configurations

- **Printer Setup Performance**: Eliminated loading lag in printer management screen

  - Removed automatic printer discovery on screen load

  - Implemented manual discovery via dedicated USB and Bluetooth buttons

  - Cached printers load immediately for instant UI responsiveness

  - Users control when discovery runs, improving perceived performance

### Changed — Professional iMin Vice Screen Refactoring

- **Enhanced Customer Display Design**: Complete refactoring of iMin vice (secondary display) screen to match professional coffee shop modern POS aesthetic

  - Color scheme updated from dark charcoal (#121212) to dark navy (#2C3E50) for better visual appeal

  - Card backgrounds refined to #1A2332 with 90% opacity for improved contrast

  - Order summary panel redesigned with 24px header, increased font sizes (17px items, 36px total), and cleaner layout

  - Featured product panel enhanced: 400x400 circular images (up from 350x350), white 4px borders, improved shadows (40px blur radius)

  - Center panel tagline now displays "Crafted Coffee & Culture" with better typography

  - AnimatedSwitcher added for smooth product image transitions during slideshow

- **Functional QR Code Generation**: Implemented real QR code generation for customer rewards/loyalty

  - Added `qr_flutter: ^4.1.0` dependency for proper QR code generation

  - QR code displays dynamically generated placeholder URL: `https://loyalty.extropos.app/scan?b={business}&o={order}`

  - QR code container styled as white rounded rectangle (200x200) with business name label below

  - Added pulse animation (TweenAnimationBuilder) to QR code for 1500ms cycle drawing customer attention

  - Dynamic text "JOIN [BUSINESS] REWARDS" above QR for personalization

  - Improved QR code styling with 20px container border-radius and professional shadows

- **Topographic Background Pattern Refinement**:

  - Increased line density: 20 horizontal + 15 vertical lines (up from 12+10) for richer background

  - Improved wave calculations using sine functions with multiple phases for organic appearance

  - Color refined to #1E2D3F with 40% opacity for primary lines, 25% for secondary layer

  - Added second pattern layer with phase offset and varied amplitudes for visual depth

  - Stroke width adjusted to 1.5px for primary, 1.0px for secondary lines

- **Animation and Polish**:

  - Cart items fade-in animation (300ms) when order summary appears (AnimatedOpacity)

  - Featured product image smooth transitions via AnimatedSwitcher on slideshow changes

  - QR code subtle pulse effect (1.0 to 1.05 scale, 1500ms) to attract attention without distraction

  - Improved shadows on all cards with 12px elevation and darker shadow colors

  - Enhanced visual hierarchy with adjusted spacing and font weights

- **Code Quality**:

  - Added math import as lowercase (`import 'dart:math' as math`) for proper linting

  - Removed unused `_displayText` field that was no longer used after modern layout

  - Cleaned up function structure with proper AnimatedOpacity wrapper

  - All 881 lines pass `flutter analyze` with zero errors

### Technical Details

- Category popup uses `showDialog` with `AlertDialog` for modal display

- Navigation bar padding uses `MediaQuery.viewPadding.bottom` for accurate system UI accommodation

- Printer discovery optimization removes async loading delays, improving user experience

- QR code generated with HMAC-SHA256 style placeholder URL (ready for backend integration)

- Order number extracted from cart data or uses timestamp as fallback

- QR URL format supports future loyalty program backend at `loyalty.extropos.app`

- All animations use platform-optimized Flutter widgets for 60fps performance on iMin hardware

- Color scheme based on reference image from modern coffee shop customer display

**Build Information:**

- APK File: `FlutterPOS-v1.0.26-20260113-pos.apk`

- APK Size: 107MB

- Build Time: 610 seconds

- Build Date: January 13, 2026

## [1.0.25] - 2026-01-10

### Added — Automatic iMin Printer Detection

- **Hardware-Aware Printer Discovery**: Implemented automatic detection and configuration of iMin built-in printers

  - Added `device_info_plus` dependency for hardware identification

  - Detects iMin Swan 2 and similar devices by model, manufacturer, and brand identifiers

  - Automatically creates iMin printer configuration with USB connection settings

  - Saves printer to database for persistence across app restarts

  - Includes proper error handling to prevent discovery failures

- **iMin Device Detection Logic**:

  - Checks for "imin", "swan", "d3", "d4" in device model

  - Identifies "imin" or "sunmi" manufacturers

  - Creates printer with ID 'imin_printer', name 'iMin Built-in Printer'

  - Configures for 80mm thermal paper with receipt printer type

### Fixed — Retail POS Layout Improvements

- **Responsive Layout Fixes**: Resolved layout issues in retail POS screens

  - Fixed analyzer warnings and null-aware operator issues

  - Improved code organization and import ordering

  - Enhanced error handling in printer service operations

### Technical Details

- Automatic iMin printer detection runs during `discoverPrinters()` on Android devices

- Printer configuration includes proper thermal paper size (80mm) and USB connection type

- Device detection uses Android device info API with fallback error handling

- All changes pass `flutter analyze` with zero errors

**Build Information:**

- APK File: `FlutterPOS-v1.0.25-20260110-pos.apk`

- APK Size: 107MB

- Build Time: 392 seconds

- Build Date: January 10, 2026

## [Unreleased]

### Changed — Professional iMin Vice Screen Refactoring

- **Enhanced Customer Display Design**: Complete refactoring of iMin vice (secondary display) screen to match professional coffee shop modern POS aesthetic

  - Color scheme updated from dark charcoal (#121212) to dark navy (#2C3E50) for better visual appeal

  - Card backgrounds refined to #1A2332 with 90% opacity for improved contrast

  - Order summary panel redesigned with 24px header, increased font sizes (17px items, 36px total), and cleaner layout

  - Featured product panel enhanced: 400x400 circular images (up from 350x350), white 4px borders, improved shadows (40px blur radius)

  - Center panel tagline now displays "Crafted Coffee & Culture" with better typography

  - AnimatedSwitcher added for smooth product image transitions during slideshow

- **Functional QR Code Generation**: Implemented real QR code generation for customer rewards/loyalty

  - Added `qr_flutter: ^4.1.0` dependency for proper QR code generation

  - QR code displays dynamically generated placeholder URL: `https://loyalty.extropos.app/scan?b={business}&o={order}`

  - QR code container styled as white rounded rectangle (200x200) with business name label below

  - Added pulse animation (TweenAnimationBuilder) to QR code for 1500ms cycle drawing customer attention

  - Dynamic text "JOIN [BUSINESS] REWARDS" above QR for personalization

  - Improved QR code styling with 20px container border-radius and professional shadows

- **Topographic Background Pattern Refinement**:

  - Increased line density: 20 horizontal + 15 vertical lines (up from 12+10) for richer background

  - Improved wave calculations using sine functions with multiple phases for organic appearance

  - Color refined to #1E2D3F with 40% opacity for primary lines, 25% for secondary layer

  - Added second pattern layer with phase offset and varied amplitudes for visual depth

  - Stroke width adjusted to 1.5px for primary, 1.0px for secondary lines

- **Animation and Polish**:

  - Cart items fade-in animation (300ms) when order summary appears (AnimatedOpacity)

  - Featured product image smooth transitions via AnimatedSwitcher on slideshow changes

  - QR code subtle pulse effect (1.0 to 1.05 scale, 1500ms) to attract attention without distraction

  - Improved shadows on all cards with 12px elevation and darker shadow colors

  - Enhanced visual hierarchy with adjusted spacing and font weights

- **Code Quality**:

  - Added math import as lowercase (`import 'dart:math' as math`) for proper linting

  - Removed unused `_displayText` field that was no longer used after modern layout

  - Cleaned up function structure with proper AnimatedOpacity wrapper

  - All 881 lines pass `flutter analyze` with zero errors

### Technical Details

- QR code generated with HMAC-SHA256 style placeholder URL (ready for backend integration)

- Order number extracted from cart data or uses timestamp as fallback

- QR URL format supports future loyalty program backend at `loyalty.extropos.app`

- All animations use platform-optimized Flutter widgets for 60fps performance on iMin hardware

- Color scheme based on reference image from modern coffee shop customer display

## [1.0.25] - 2025-12-26

### Changed — Pricing Consistency & Quality

- Centralized totals logic with `Pricing` helpers (subtotal, tax, service charge, discount-aware) and applied to Cafe POS, Restaurant POS, and Frontend screens for consistent BusinessInfo usage.

- Added POS test seams (injectable carts, skip DB/shift checks) plus new unit and widget tests covering pricing math and UI totals (BusinessInfo flags, discounts, variants).

- Introduced GitHub Actions CI workflow to run `flutter analyze` and `flutter test`; cleaned import ordering across project to keep lints green.

## [1.0.24] - 2025-12-24

### Added — Modern Retail POS UI

- **Modern Retail POS Interface**: Professional dark-themed UI with dual interface options

  - Complete UI redesign with dark navy background (#2C3E50) matching modern POS systems

  - Responsive portrait/landscape layouts for tablets and desktops

  - UI selection dialog when entering Retail mode (Modern vs Classic)

  - User preference saving with "Remember my choice" checkbox

  - Modern components: Search bar, Quick Actions, Payment buttons, Category selector, Number pad

  - Professional 3-panel layout: Order Summary | Quick Actions | Categories

  - Seamless integration with existing business logic (cart, tax, payments, dual display)

  - Zero breaking changes - Classic UI remains fully functional

  - Design inspired by industry leaders (Square, Toast, Loyverse)

- **Product Grid Display**: Beautiful product cards with responsive columns

  - Adaptive grid: 1-4 columns based on screen width breakpoints

  - Modern card design with icons, names, and prices

  - Touch-optimized with InkWell ripple effects

  - Instant cart updates with dual display sync

### Changed — App Settings Service

- **Retail UI Preference Storage**: Added preference management for UI selection

  - `preferModernRetailUI` boolean flag with getter/setter

  - Persistent storage using SharedPreferences

  - Auto-load on app initialization

  - Used by mode selection screen to show/hide dialog

### Technical Improvements (1.0.24)

- Created `retail_pos_screen_modern.dart` with 850+ lines of modern UI code

- Updated `mode_selection_screen.dart` with async UI selection dialog

- Enhanced `app_settings.dart` with retail UI preference methods

- Zero analysis issues - clean implementation with proper imports

- Maintained backward compatibility with all existing features

- Ready for production deployment

### Build Information

- **Release Date**: December 24, 2025

- **Build Number**: 24

- **APK Size**: 103MB (all flavors)

- **Build Time**: ~14 minutes

- **Font Optimization**: MaterialIcons tree-shaken (98.2% reduction: 1645KB → 30KB)

- **Flavors Built**: POS, KDS, Backend, KeyGen (4 APKs)

- **Output Location**: `build/app/outputs/flutter-apk/`

- **Desktop Copy**: `~/Desktop/FlutterPOS-v1.0.24-20251224-modern-retail-ui.apk`

- **Target Platforms**: Android 5.0+ (API 21+), Windows, Linux, macOS

## [1.0.23] - 2025-12-23

### Upgraded — Android & Flutter Modernization

- **Dependency Upgrades**: Updated 15 packages to latest stable versions

  - `csv`: 5.1.1 → 6.0.0 (major version update with improved performance)

  - `file_picker`: 10.3.3 → 10.3.8 (bug fixes and stability improvements)

  - `file_selector`: 1.0.4 → 1.1.0 (enhanced file dialog support)

  - `firebase_core`: 3.15.2 → 4.3.0 (major version update)

  - `firebase_database`: 11.3.10 → 12.1.1 (real-time database improvements)

  - `flutter_secure_storage`: 9.2.4 → 10.0.0 (enhanced encryption methods)

  - `fluttertoast`: 8.2.14 → 9.0.0 (Android 14 compatibility)

  - `http`: 1.5.0 → 1.6.0 (HTTP/3 support and performance improvements)

  - `intl`: 0.19.0 → 0.20.2 (internationalization updates)

  - `mobile_scanner`: 5.2.3 → 7.1.4 (barcode scanning performance boost)

  - `package_info_plus`: 8.3.1 → 9.0.0 (enhanced app info retrieval)

  - `shared_preferences`: 2.5.3 → 2.5.4 (storage optimizations)

  - `sqlite3_flutter_libs`: 0.5.40 → 0.5.41 (SQLite bug fixes)

  - `window_manager`: 0.3.9 → 0.5.1 (desktop window management improvements)

  - `flutter_lints`: 5.0.0 → 6.0.0 (latest Dart linting rules)

- **Android Build Modernization**

  - Updated Java target from 21 to 17 (LTS version for better compatibility)

  - Maintained Kotlin DSL build configuration

  - Ensured compatibility with Android 14 (API 34)

  - Optimized build performance and artifact size

- **Material Design 3**: Verified full Material 3 implementation

  - All app flavors (POS, KDS, Backend, KeyGen) using `useMaterial3: true`

  - Modern color schemes with ColorScheme.fromSeed()

  - Updated button styles, cards, and dialogs with Material 3 design

  - Consistent typography and spacing throughout the app

### Fixed — Lint warning (items_management_screen)

- Lint warning: Removed unnecessary multiple underscores in `items_management_screen.dart` separator builder

### Technical

- All 76 unit tests passing successfully

- Zero analysis issues after modernization

- Backward compatible with existing features and data

- Ready for Android 14+ deployment

## [1.0.22] - 2025-12-23

### Added — Modern Reports Dashboard (1.0.22)

- **Modern Reports Dashboard**: Complete visual analytics system with interactive charts and KPIs

  - Dashboard-first UI with 4 KPI cards (Gross Sales, Net Sales, Transactions, Average Ticket)

  - Interactive line chart showing 7-day sales trends with hover tooltips

  - Donut charts for category sales distribution and payment method breakdown

  - Top products list with units sold and revenue metrics

  - Quick date selector with Today, Yesterday, This Week, This Month, and Custom range options

  - Pull-to-refresh functionality for real-time data updates

  - CSV export capability with file picker integration

  - Responsive design adapting to desktop (4-column) and mobile (2-column) layouts

  - Professional animations and smooth transitions throughout the interface

  - Integration with existing analytics service and business logic

- **Test Data Generation System**: Comprehensive testing infrastructure for reports

  - GenerateTestDataScreen for creating realistic sales data (7-90 days, 5-50 orders/day)

  - ReportsTestDataGenerator service with configurable parameters

  - Automatic product, category, and payment method data generation

  - Realistic pricing, quantities, and temporal distribution

  - Debug-only access through Settings screen

- **Analytics Models & Services**: Enhanced data processing capabilities

  - AnalyticsModels with comprehensive data structures (SalesSummary, CategoryPerformance, ProductPerformance, etc.)

  - AnalyticsService with date range filtering and aggregation logic

  - Business logic integration with tax calculations and currency formatting

  - Optimized queries for performance with large datasets

- **UI Components**: Reusable widgets for consistent design

  - KpiCard widget with color-coded metrics and icons

  - ReportDateSelector with chip-based navigation

  - Professional styling with Material Design 3 principles

  - Responsive grid layouts with adaptive column counts

- **Documentation Suite**: Complete testing and implementation guides

  - MODERN_REPORTS_IMPLEMENTATION.md: Technical implementation details

  - REPORTS_READY_FOR_TESTING.md: Testing readiness checklist

  - REPORTS_TESTING_GUIDE.md: Step-by-step testing procedures

  - REPORTS_VISUAL_REFERENCE.md: Visual design specifications

  - SETTINGS_SCREEN_RESTORATION.md: Bug fix documentation

### Fixed — Documentation Quality

- **Markdown Formatting**: Comprehensive linting and formatting fixes across all documentation

  - Fixed 238 markdownlint violations across 4 documentation files

  - Added proper language identifiers to code blocks

  - Corrected heading spacing and list formatting

  - Standardized table styles and fence spacing

  - Ensured single trailing newlines and proper file endings

### Changed — Code Quality Improvements

- **Flutter Code Formatting**: Consistent spacing and style improvements

  - Applied dart format standards across modified files

  - Improved code readability and maintainability

  - Enhanced error handling and null safety practices

## [1.0.21] - 2025-12-22

### Added — Customer Display Refactor (1.0.21)

- **Customer Display Screen Refactor**: Complete UI/UX redesign for dual-screen POS devices

  - Implemented 70/30 split layout (media left 70%, cart right 30%)

  - Media layer always rendered to prevent flickering (slideshow/video/welcome screen)

  - Animated cart panel slides in from right when items are added

  - Full-screen media when cart is empty with smooth transition

  - Dark theme with semi-transparent cart overlay (Colors.black87)

  - High-contrast cart panel with proper header (Item, Qty, Price)

  - Scrollable cart items list with product image thumbnails

  - Fixed bottom totals section (Subtotal, Tax, Grand Total in bold large font)

  - Optimized for physical dual-screen hardware (Sunmi, Elo, iMin devices)

  - Professional premium animation using AnimatedPositioned and AnimatedOpacity

### Fixed — Customer Display Legacy Mode Conflict

- **Customer Display Legacy Mode Fix**: Resolved issue where secondary screen showed "old template" (LCD text mode) instead of new Flutter UI

  - Removed conflicting `CustomerDisplayService` calls from POS screens that were sending text commands and forcing LCD mode

  - Refactored `DualDisplayService` to send structured JSON status updates (`UPDATE_STATUS`) instead of direct LCD commands

  - Enhanced `ViceCustomerDisplayScreen` to handle payment, change, and thank you states natively in Flutter

  - Disabled automatic LCD initialization in `IminPrinterService` to prevent mode switching during app startup

  - Updated `AndroidManifest.xml` with dual-screen support attributes (`allowEmbedded`, `presentationTheme`, `singleInstance` launch mode)

  - Ensures exclusive use of Flutter-based 70/30 split UI for secondary display on iMin devices

### Changed — Java & Kotlin Build Tools

- **Java Runtime Upgrade**: Upgraded Android build toolchain from Java 8 to Java 21 LTS

  - Updated `compileOptions` sourceCompatibility and targetCompatibility to VERSION_21

  - Updated Kotlin `jvmTarget` to Java 21

  - Ensures compatibility with latest Android Gradle Plugin and build tools

  - Leverages Java 21 performance improvements and language features

## [1.0.20] - 2025-12-22

### Added — Product Image Support (1.0.20)

- **Product Image Support**: Local image storage and display for products

  - Upload product images through Items Management screen

  - Display product images in POS screens with caching and error fallbacks

  - Images stored locally in app directory without cloud dependencies

### Changed — Retail POS Layout

- **Retail POS Portrait Layout**: Improved responsive design for portrait orientation

  - Portrait mode now uses top-bottom layout (products on top, cart on bottom)

  - Categories displayed as dropdown in portrait mode for better usability

  - Maintains left-right layout in landscape orientation

  - Consistent with cafe screen layout patterns

  - Images stored locally in app documents directory (no cloud dependency)

  - Product cards display images with fallback to icons

  - Image caching for improved performance

  - Error handling with graceful fallback to default icons

  - Cross-platform compatibility (Android/iOS/Desktop)

### Technical Improvements (1.0.20)

- Product model updated with imagePath support

- Database integration for local image storage

- Image picker integration using file_picker package

- ProductCard widget enhanced with image display

- All POS screens updated to pass image data from database

- Optimized image loading with caching and error boundaries

## [1.0.19] - 2025-12-21

### Added — Product Image Support (1.0.19)

- **Product Image Support**: Local image storage and display for products

  - Upload product images through Items Management screen

  - Images stored locally in app documents directory (no cloud dependency)

  - Product cards display images with fallback to icons

  - Image caching for improved performance

  - Error handling with graceful fallback to default icons

  - Cross-platform compatibility (Android/iOS/Desktop)

### Technical Improvements (1.0.19)

- Product model updated with imagePath support

- Database integration for local image storage

- Image picker integration using file_picker package

- ProductCard widget enhanced with image display

- All POS screens updated to pass image data from database

- Optimized image loading with caching and error boundaries

## [1.0.18] - 2025-12-20

### Fixed

- **Transaction Saving Issue**: Resolved "failed to save transaction to database" error

  - Fixed sample products not being persisted to database, causing transaction failures

  - Added missing `order_id` and `amount` columns to `user_activity_log` table

  - Enhanced database schema with proper column definitions and migrations

  - Ensured sample data is properly inserted into database for transaction processing

### Technical Improvements (1.0.18)

- Database schema updates: Added missing columns to user_activity_log table

- Migration v28 enhancements: Proper column additions for activity logging

- Sample data persistence: Automatic insertion of sample products and categories

- Transaction processing reliability: Eliminated unmapped item failures

## [1.0.17] - 2025-12-20

### Added Features

- **Daily Staff Performance Report**: Comprehensive Malaysian SST-compliant staff performance analytics

  - Category-based tax rates (6% F&B, 8% other) with item-level calculation

  - Enhanced user activity logging with payment methods, discounts, and tax tracking

  - Multi-format report exports (PDF, CSV) with detailed staff metrics

  - No-Shift user tracking for security auditing and compliance

  - Advanced reports integration with professional formatting

### Technical Improvements (1.0.17)

- Database schema v28: Enhanced user_activity_log table with new columns

- Category-based tax calculation implementation across all POS modes

- Zero diagnostic warnings: Cleaned up duplicate imports and unused code

- Responsive layout fixes: Overflow-safe grids and dialogs

- Production-ready codebase with comprehensive testing

### Bug Fixes

- Resolved all Flutter analyzer warnings across multiple files

- Fixed database schema inconsistencies for tax compliance

- Eliminated unused variables and methods for maintainability
