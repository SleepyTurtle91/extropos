# Changelog

All notable changes to ExtroPOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
