# FlutterPOS License Key Generator - Complete Guide

## Overview

The **Key Generator Flavor** is a dedicated application for generating and validating license keys for the FlutterPOS system. It provides a secure, offline key generation system with support for trial and lifetime licenses.

**Version**: 1.0.14-keygen  
**Package ID**: com.extrotarget.extropos.keygen  
**App Name**: FlutterPOS License Generator

---

## Purpose

The Key Generator allows administrators to:

- **Generate 1-Month Trial Keys**: 30-day trial licenses

- **Generate 3-Month Trial Keys**: 90-day trial licenses  

- **Generate Lifetime Keys**: Permanent licenses with no expiration

- **Validate License Keys**: Check if a key is valid and view its details

- **Batch Generation**: Create multiple keys at once (1-100 keys)

- **Copy Keys**: Easy clipboard integration for sharing

---

## License Key Format

### Structure

Keys follow the format: **EXTRO-XXXX-XXXX-XXXX-XXXX**

```text
EXTRO-1MTR-A3B2-0000-X7Y9
│     │    │    │    │
│     │    │    │    └─ Checksum (HMAC-SHA256 based)
│     │    │    └────── Device/Instance ID (0000 = universal)
│     │    └─────────── Expiry Date (encoded) or "LIFE" for lifetime
│     └──────────────── License Type Code
└────────────────────── Constant Prefix

```text


### License Type Codes


| Type | Code | Duration | Description |
|------|------|----------|-------------|
| 1 Month Trial | `1MTR` | 30 days | Trial license for testing |
| 3 Month Trial | `3MTR` | 90 days | Extended trial period |
| Lifetime | `LIFE` | Unlimited | Permanent license |


### Example Keys



```text
EXTRO-1MTR-9F2A-0000-X7Y9  # 1-month trial

EXTRO-3MTR-A1B3-0000-K2M5  # 3-month trial

EXTRO-LIFE-LIFE-0000-P8Q4  # Lifetime license

```text

---


## Security Features



### HMAC-SHA256 Checksum


Each key includes a cryptographic checksum that:


- Prevents key forgery

- Validates key integrity

- Uses a secret salt for added security


### Offline Validation


Keys are validated entirely offline:


- No internet connection required

- No external API calls

- No license server needed

- Works in air-gapped environments


### Expiry Encoding


Trial keys encode expiry dates as:


- Base36 format (compact representation)

- Year + Month + Day

- Automatically checked on validation

---


## Building the Key Generator



### Using Build Script



```bash

# Debug build (for testing)

./build_flavors.sh keygen debug


# Release build (for distribution)

./build_flavors.sh keygen release


# Build all flavors including keygen

./build_flavors.sh all release

```text


### Manual Build



```bash

# Debug

flutter build apk --debug --flavor keygenApp --dart-define=FLAVOR=keygen


# Release

flutter build apk --release --flavor keygenApp --dart-define=FLAVOR=keygen

```text


### Output Location


- **APK Path**: `build/app/outputs/flutter-apk/app-keygenapp-release.apk`

- **Desktop Copy**: `~/Desktop/FlutterPOS-v1.0.14-YYYYMMDD-keygen.apk`

---


## Installation & Usage



### Installation


1. Build the APK using the build script
2. Install on Android device or run on desktop (Windows/Linux/macOS)
3. No setup required - app is ready to use immediately

4. No license activation needed for the generator itself


### Desktop Support


The key generator runs natively on desktop platforms:


- **Windows**: 900x700 resizable window

- **Linux**: Same as Windows

- **macOS**: Same as Windows

- **Android**: Full-screen mobile interface


### First Launch


The app opens directly to the key generator interface - no setup screens, no activation required.

---


## User Interface Guide



### Home Screen Components



#### 1. Header Card


- Shows application title and description

- Displays quick info about license types

- Visual chips for each license type


#### 2. Generate License Keys Section


**License Type Selection**:


- Segmented button with 3 options:

  - 🕐 **1 Month** - 30-day trial

  - 📅 **3 Months** - 90-day trial

  - ♾️ **Lifetime** - Permanent license

**Number of Keys**:


- Dropdown selector: 1, 5, 10, 25, 50, 100 keys

- Useful for batch generation

**Generate Button**:


- Blue button to generate keys

- Adds keys to the list below

- Shows success notification


#### 3. Validate License Key Section


**Input Field**:


- Enter any license key

- Format: EXTRO-XXXX-XXXX-XXXX-XXXX

**Validate Button**:


- Checks key validity

- Shows detailed results

**Validation Results**:


- ✅ **Valid Key**: Green background

  - Shows license type

  - Shows expiry date (if trial)

  - Shows days remaining

- ❌ **Invalid Key**: Red background

  - Shows error message


#### 4. Generated Keys List


**For Each Key**:


- Sequential number

- Full license key (monospace font)

- License type

- Expiry date and days remaining

- Copy button

**List Actions**:


- **Copy All**: Copy all keys to clipboard

- **Clear**: Remove all keys from list

---


## Usage Examples



### Example 1: Generate Single Lifetime Key


1. Select **Lifetime** license type

2. Keep number of keys at **1**
3. Click **Generate Keys**
4. Key appears in list below
5. Click **Copy** icon to copy key

6. Paste into POS activation screen

**Generated Key Example**:


```text
EXTRO-LIFE-LIFE-0000-P8Q4

```text


### Example 2: Generate 10 Trial Keys


1. Select **1 Month** license type

2. Change number of keys to **10**
3. Click **Generate Keys**
4. 10 keys added to list
5. Click **Copy All** to copy all keys

6. Distribute to customers

**Generated Keys Example**:


```text
EXTRO-1MTR-9F2A-0000-X7Y9
EXTRO-1MTR-9F2A-A1B2-K3M4
EXTRO-1MTR-9F2A-C5D6-L7N8
...

```text


### Example 3: Validate a Customer's Key


1. Customer provides key: `EXTRO-3MTR-A1B3-0000-K2M5`
2. Paste into validation field
3. Click **Validate Key**
4. Result shows:

   - ✅ Valid Key

   - Type: 3 Month Trial

   - Expires: 2025-02-26

   - Days Remaining: 85

---


## Integration with POS System



### How Validation Works in POS


1. **User enters key** in POS activation screen

2. **LicenseService** calls `LicenseKeyGenerator.validateKey()`

3. **Key structure** is checked (format, prefix, length)

4. **Checksum** is verified using HMAC-SHA256

5. **Expiry date** is decoded and checked

6. **Result** is returned (valid/invalid)


### Code Integration


The POS system uses these methods:


```dart
// In activation_screen.dart
LicenseService.instance.activate(userEnteredKey);

// In license_service.dart
bool isValid = LicenseKeyGenerator.validateKey(key);
if (isValid) {
  // Activate the license
  await _prefs!.setBool(_keyActivated, true);
  await _prefs!.setString(_keyLicenseKey, key);
}

```text


### Key Expiry Checks


Trial keys are automatically checked:


```dart
// Check if license is expired
bool isExpired = LicenseKeyGenerator.isExpired(key);

// Get days remaining
int? daysRemaining = LicenseKeyGenerator.getDaysRemaining(key);

// Lifetime keys return null for expiry date
DateTime? expiryDate = LicenseKeyGenerator.getExpiryDate(key);

```text

---


## Best Practices



### Key Generation


✅ **DO**:


- Generate keys in batches for efficiency

- Keep a record of generated keys for support

- Use lifetime keys for paid customers

- Use trial keys for demos and testing

- Clear the list after copying keys

❌ **DON'T**:


- Share the key generator app with customers

- Generate too many unused keys

- Reuse the same key across multiple devices (use device-specific keys)


### Key Distribution


✅ **DO**:


- Copy keys one at a time for individual customers

- Use "Copy All" for bulk distribution

- Verify keys before sending to customers

- Document which keys are assigned to which customers

❌ **DON'T**:


- Send screenshots (keys should be text)

- Distribute expired trial keys

- Share keys publicly online


### Security


✅ **DO**:


- Keep the key generator app secure

- Use strong passwords on devices with the generator

- Generate new keys regularly

- Validate suspicious keys

❌ **DON'T**:


- Install generator on customer-facing devices

- Share the app package publicly

- Hardcode keys in your app (use validation)

---


## Technical Details



### File Structure



```text
lib/
├── main_keygen.dart                      # Key generator entry point

├── screens/
│   └── keygen_home_screen.dart          # Main UI (465 lines)

└── services/
    ├── license_key_generator.dart       # Key generation logic (240 lines)

    └── license_service.dart             # Updated validation (uses generator)

```text


### Key Generation Algorithm


1. **Type Code**: Select based on license type (1MTR/3MTR/LIFE)
2. **Expiry Part**:

   - Trial: Encode expiry date as base36

   - Lifetime: Use "LIFE" string

3. **Device Part**: Random 4-character ID or "0000" for universal
4. **Checksum**:

   - Combine type + expiry + device

   - Generate HMAC-SHA256 with secret

   - Take first 3 bytes

   - Convert to base36

   - Pad to 4 characters


### Validation Algorithm


1. **Format Check**: Verify EXTRO-XXXX-XXXX-XXXX-XXXX format
2. **Length Check**: Must be exactly 21 characters (without dashes)
3. **Prefix Check**: Must start with "EXTRO"
4. **Type Code Check**: Must be valid type (1MTR/3MTR/LIFE)
5. **Checksum Verification**: Recalculate and compare
6. **Expiry Check**: Decode date and verify not expired
7. **Result**: Return true/false

---


## Troubleshooting



### Key Generation Issues


**Problem**: Generate button doesn't work

**Solutions**:


- Check that license type is selected

- Verify number of keys is set

- Restart the app

---

**Problem**: Generated keys are invalid

**Solutions**:


- Ensure you're using the latest version

- Check that crypto package is installed

- Verify secret key hasn't changed

---


### Validation Issues


**Problem**: Valid key shows as invalid

**Solutions**:


- Check key format (must be EXTRO-XXXX-XXXX-XXXX-XXXX)

- Ensure no extra spaces or characters

- Verify key hasn't expired (for trials)

- Try copying key again

---

**Problem**: Expired trial key

**Solutions**:


- Generate a new key

- Use lifetime key instead

- Check system date/time is correct

---


## Development



### Dependencies



```yaml
dependencies:
  crypto: ^3.0.3           # HMAC-SHA256 for checksums

  window_manager: ^0.3.7   # Desktop window management

```text


### Build Configuration


**Gradle** (`android/app/build.gradle.kts`):


```kotlin
keygenApp {
    dimension = "appType"
    applicationIdSuffix = ".keygen"
    versionNameSuffix = "-keygen"
    resValue("string", "app_name", "FlutterPOS License Generator")
}

```text

**Build Script** (`build_flavors.sh`):


```bash
build_keygen() {
    flutter build apk --$BUILD_TYPE --flavor keygenApp --dart-define=FLAVOR=keygen
    # APK: app-keygenapp-$BUILD_TYPE.apk

}

```text

---


## API Reference



### LicenseKeyGenerator Class



#### Static Methods


**generateKey()**


```dart
String generateKey(LicenseType type, {String? deviceId})

```text

Generate a single license key.

**generateKeys()**


```dart
List<String> generateKeys(LicenseType type, int count, {String? deviceId})

```text

Generate multiple license keys.

**validateKey()**


```dart
bool validateKey(String key)

```text

Validate a license key.

**getLicenseType()**


```dart
LicenseType? getLicenseType(String key)

```text

Get the license type from a key.

**getExpiryDate()**


```dart
DateTime? getExpiryDate(String key)

```text

Get expiry date (null for lifetime).

**getDaysRemaining()**


```dart
int? getDaysRemaining(String key)

```text

Get days remaining (null for lifetime).

**isExpired()**


```dart
bool isExpired(String key)

```text

Check if key is expired.

**getLicenseTypeName()**


```dart
String getLicenseTypeName(LicenseType type)

```text

Get human-readable type name.

**formatKey()**


```dart
String formatKey(String key)

```text

Format key with dashes.

---


## Changelog



### v1.0.14-keygen (2025-11-26)


- ✨ **NEW**: Initial release of Key Generator flavor

- ✅ 1-month trial key generation

- ✅ 3-month trial key generation

- ✅ Lifetime key generation

- ✅ Batch generation (1-100 keys)

- ✅ Key validation with detailed info

- ✅ Copy to clipboard functionality

- ✅ Desktop and mobile support

- ✅ HMAC-SHA256 secure checksums

- ✅ Offline validation

- ✅ Professional UI with Material 3

---


## Future Enhancements


Planned features:


- [ ] Key history/database

- [ ] Export keys to CSV/PDF

- [ ] Device-specific key generation

- [ ] Key revocation system

- [ ] Usage analytics

- [ ] Bulk import/export

- [ ] QR code generation

- [ ] Email key distribution

- [ ] Customer management integration

- [ ] Auto-expiry warnings

---


## Support



### Getting Help


- **Documentation**: This guide

- **Code**: `lib/services/license_key_generator.dart`

- **Issues**: Check existing issues before creating new ones


### Related Guides


- `BACKEND_FLAVOR_GUIDE.md` - Backend management app

- `PRODUCT_FLAVORS_GUIDE.md` - All flavors overview

- `QUICK_ACTION_CHECKLIST.md` - Development workflow

---


## Security Notice


⚠️ **IMPORTANT**:


- Keep the key generator app **secure and private**

- Do **NOT** distribute to customers

- Change the `_secret` constant in production

- Use device-specific keys for enhanced security

- Monitor key usage and revoke if necessary

The secret key is currently:


```dart
static const String _secret = 'FlutterPOS-License-Secret-2025';

```text

**For production**, change this to a unique, random secret and rebuild all apps.

---


## License


This is part of the FlutterPOS system. Proprietary software for internal use only.

---

**Last Updated**: 2025-11-26  
**Version**: 1.0.14-keygen  
**Author**: FlutterPOS Development Team
