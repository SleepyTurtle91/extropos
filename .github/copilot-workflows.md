# FlutterPOS Development Workflows


Build, Test, Debug, and Deployment Processes


## Build Commands



### Flavor-Specific Builds

```bash
cd /home/abber/Documents/flutterpos


# Build individual flavors

./build_flavors.sh pos release      # POS only

./build_flavors.sh kds release      # KDS only

./build_flavors.sh backend release  # Backend only

./build_flavors.sh keygen release   # Key Generator only



# Build all flavors at once

./build_flavors.sh all release


# Debug builds

./build_flavors.sh pos debug
./build_flavors.sh backend debug
./build_flavors.sh keygen debug

```


### Running Specific Flavors

```bash

# Running specific flavors

flutter run -d windows  # Run POS flavor (default)

flutter run -d windows lib/main_kds.dart  # Run KDS flavor

flutter run -d windows lib/main_backend.dart  # Run Backend flavor

flutter run -d windows lib/main_keygen.dart  # Run KeyGen flavor

```


### APK Output Locations

```
build/app/outputs/flutter-apk/
├── app-posapp-release.apk         # POS flavor (~85MB)

├── app-kdsapp-release.apk         # KDS flavor (~80MB)

├── app-backendapp-release.apk     # Backend flavor (~85MB)

└── app-keygenapp-release.apk      # KeyGen flavor (~85MB)

```


## Testing Strategy



### Unit & Integration Tests

```bash

# Run all tests

flutter test


# Run specific test file

flutter test test/specific_test.dart


# Run with coverage

flutter test --coverage


# Run tests in verbose mode

flutter test -v

```


### Test Categories

- **Unit Tests**: Business logic, calculations, model operations

- **Integration Tests**: Database operations, service interactions

- **Widget Tests**: UI components, screen layouts

- **Golden Tests**: Visual regression testing


### Test Data Generation

```dart
// Use ReportsTestDataGenerator for realistic test data
final generator = ReportsTestDataGenerator();
await generator.generateSampleData();

```


## Debugging Workflows



### VS Code Debugger

1. **Set breakpoints** in Dart code

2. **Run in debug mode**: `F5` or `flutter run --debug`
3. **Hot reload**: `Ctrl+S` (save) or `Ctrl+F5`
4. **Inspect variables** in debug panel

5. **Step through code**: F10 (step over), F11 (step into)


### Print Statement Debugging

```dart
// Extensive print statements throughout codebase
print('🔧 Debug: variable = $variable');
print('⚠️ Warning: condition failed');
print('✅ Success: operation completed');

```


### Database Debugging

```dart
// Inspect database contents
final db = await DatabaseHelper.instance.database;
final products = await db.query('products');
print('Products in DB: ${products.length}');

// Use test database for isolation
DatabaseHelper.instance.testDatabase = testDb;

```


### Hardware Debugging

```dart
// Printer debugging
PrinterService().printerLogStream.listen((msg) {
  print('Printer: $msg');
});

// Dual display debugging
DualDisplayService().showMessage('Debug message');

```


## Release Workflow



### APK Build and Release Workflow


**CRITICAL**: Every time you compile an APK, you MUST follow this complete workflow:


#### 1. Build APK

```bash
flutter build apk --release

```


#### 2. Copy to Desktop

```bash

# Copy with descriptive filename including version and date

cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/FlutterPOS-v[VERSION]-$(date +%Y%m%d)-[description].apk

```

**Naming Convention**:

- Include version number (e.g., v1.0.2)

- Include date stamp (YYYYMMDD format)

- Include brief description if it's a fix (e.g., "pin-fix", "database-fix")

- Example: `FlutterPOS-v1.0.2-20251125-database-schema-fix.apk`


#### 3. Create Git Tag

```bash
git tag -a v[VERSION]-$(date +%Y%m%d) -m "FlutterPOS v[VERSION] - [Description]"

git push origin v[VERSION]-$(date +%Y%m%d)

```


#### 4. Create GitHub Release

```bash
gh release create v[VERSION]-$(date +%Y%m%d) \
  build/app/outputs/flutter-apk/app-release.apk \
  --title "FlutterPOS v[VERSION] - [Title]" \
  --notes "[Detailed release notes with changelog]"

```


#### 5. Verify Release

```bash
gh release view v[VERSION]-$(date +%Y%m%d)

```


### Complete Example Workflow

```bash

# 1. Build

flutter build apk --release


# 2. Copy to desktop

cp build/app/outputs/flutter-apk/app-release.apk ~/Desktop/FlutterPOS-v1.0.2-$(date +%Y%m%d)-database-fix.apk


# 3. Tag and push

git tag -a v1.0.2-$(date +%Y%m%d) -m "FlutterPOS v1.0.2 - Database Schema Fix"

git push origin v1.0.2-$(date +%Y%m%d)


# 4. Create release

gh release create v1.0.2-$(date +%Y%m%d) build/app/outputs/flutter-apk/app-release.apk \
  --title "FlutterPOS v1.0.2 - Database Schema Fix" \
  --notes "## Critical Database Fix


Fixed SQLite error when storing PINs by adding missing 'pin' column to database schema.

See docs/PIN_STORAGE_BUG_FIX.md for details."


# 5. Verify

gh release view v1.0.2-$(date +%Y%m%d)

```


### Release Notes Best Practices

- Start with release type: 🐛 Bug Fix, ✨ Feature, ⚡ Performance, 🔒 Security

- Include problem description

- Explain root cause if it's a fix

- List what changed

- Mention affected versions

- Include build information (size, date, platform)

- Reference documentation if available


### NEVER:

- ❌ Build APK without copying to desktop

- ❌ Build APK without uploading to GitHub

- ❌ Create release without descriptive notes

- ❌ Use generic version numbers without dates

- ❌ Skip verification step


## Development Environment Setup



### Initial Setup

```bash

# Clone repository

git clone https://github.com/your-org/flutterpos.git
cd flutterpos


# Setup flavors (creates necessary directories and files)

./setup_flavors.sh


# Install dependencies

flutter pub get


# Run analysis

flutter analyze


# Run tests

flutter test

```


### Platform-Specific Setup



#### Android Development

```bash

# Enable Android development

flutter config --enable-android


# Check connected devices

flutter devices


# Run on Android device/emulator

flutter run -d android

```


#### Windows Development

```bash

# Enable Windows development

flutter config --enable-windows


# Build Windows executable

flutter build windows


# Run on Windows

flutter run -d windows

```


#### Linux Development

```bash

# Enable Linux development

flutter config --enable-linux


# Build Linux executable

flutter build linux


# Run on Linux

flutter run -d linux

```


## Code Quality Checks



### Analysis & Linting

```bash

# Run static analysis

flutter analyze


# Fix auto-fixable issues

dart fix --apply


# Format code

flutter format lib/

```


### Pre-commit Checks

```bash

# Run before committing

flutter analyze
flutter test
flutter format --set-exit-if-changed lib/

```


## Performance Monitoring



### Flutter DevTools

```bash

# Start DevTools

flutter pub global run devtools


# Run app with DevTools

flutter run --profile


# Open DevTools in browser

# http://localhost:9100

```


### Memory & Performance Profiling

- Use Flutter DevTools for memory analysis

- Profile widget rebuilds

- Monitor network requests

- Check database query performance


## Troubleshooting Common Issues



### Build Issues

```bash

# Clean build cache

flutter clean
flutter pub get


# Clear Gradle cache (Android)

cd android
./gradlew clean
cd ..


# Rebuild platform-specific code

flutter create --platforms=android,windows,linux .

```


### Database Issues

```bash

# Reset database (WARNING: destroys all data)

await DatabaseHelper.instance.resetDatabase();


# Check database integrity

final db = await DatabaseHelper.instance.database;
final tables = await db.query('sqlite_master');
print('Tables: ${tables.length}');

```


### Hardware Integration Issues

```bash

# Test printer connection

await PrinterService().discoverPrinters();


# Test dual display

await DualDisplayService().initialize();
DualDisplayService().showWelcome();

```


## Continuous Integration



### GitHub Actions Workflow

```yaml
name: FlutterPOS CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:

      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2

      - run: flutter pub get

      - run: flutter analyze

      - run: flutter test --coverage

      - uses: codecov/codecov-action@v3

```


### Automated Testing

- Unit tests run on every push

- Integration tests run on pull requests

- Code coverage reports uploaded to Codecov

- Static analysis enforced


## Deployment Environments



### Development

- Local SQLite database

- Mock external services

- Debug logging enabled

- Hot reload enabled


### Staging

- Remote Appwrite instance

- Real hardware testing

- Performance monitoring

- Beta user testing


### Production

- Production Appwrite instance

- Optimized builds

- Error monitoring (Sentry)

- Automated deployments
