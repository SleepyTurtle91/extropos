# Android Product Flavors Guide - POS & KDS Apps

## Overview

FlutterPOS now supports building two separate applications from a single codebase using **Gradle Product Flavors**:

1. **POS App** (`posApp`) - Point of Sale application

2. **KDS App** (`kdsApp`) - Kitchen Display System application

---

## Configuration Details

### Flavor Specifications

#### `posApp` Flavor

- **Application ID**: `com.extrotarget.extropos.pos`

- **Version Name Suffix**: `-pos` (e.g., `1.0.14-pos`)

- **App Name**: "FlutterPOS"

- **Dimension**: `appType`

#### `kdsApp` Flavor

- **Application ID**: `com.extrotarget.extropos.kds`

- **Version Name Suffix**: `-kds` (e.g., `1.0.14-kds`)

- **App Name**: "FlutterPOS Kitchen Display"

- **Dimension**: `appType`

---

## Directory Structure

### Flavor-Specific Code Organization

Create the following directory structure under `android/app/src/`:

```
android/app/src/
├── main/                          # Shared code (used by both flavors)

│   ├── AndroidManifest.xml
│   ├── kotlin/
│   └── res/
│
├── posApp/                        # POS-specific code

│   ├── AndroidManifest.xml        # POS-specific manifest (merged with main)

│   ├── kotlin/                    # POS-specific Kotlin/Java code

│   │   └── com/extrotarget/extropos/
│   │       └── MainActivity.kt    # Override if needed

│   └── res/                       # POS-specific resources

│       ├── values/
│       │   └── strings.xml        # POS-specific strings

│       ├── mipmap-*/              # POS app icons

│       └── drawable/              # POS-specific images

│
└── kdsApp/                        # KDS-specific code

    ├── AndroidManifest.xml        # KDS-specific manifest

    ├── kotlin/                    # KDS-specific Kotlin/Java code

    │   └── com/extrotarget/extropos/
    │       └── MainActivity.kt    # Override if needed

    └── res/                       # KDS-specific resources

        ├── values/
        │   └── strings.xml        # KDS-specific strings

        ├── mipmap-*/              # KDS app icons

        └── drawable/              # KDS-specific images

```

### Flutter Code Organization

For Flutter-specific flavor logic, use the following structure:

```
lib/
├── main.dart                      # Common entry point (detects flavor)

├── main_pos.dart                  # POS-specific entry (optional)

├── main_kds.dart                  # KDS-specific entry (optional)

│
├── config/
│   ├── flavor_config.dart         # Flavor detection and configuration

│   └── app_config.dart            # App-wide configuration

│
├── screens/
│   ├── pos/                       # POS-specific screens

│   │   ├── pos_home_screen.dart
│   │   └── retail_pos_screen.dart
│   │
│   └── kds/                       # KDS-specific screens

│       ├── kds_home_screen.dart
│       └── kitchen_display_screen.dart
│
└── shared/                        # Shared widgets/models

    ├── models/
    └── widgets/

```

---

## Building Flavor-Specific APKs

### Command Line Builds

#### Build POS App (Debug)

```bash
flutter build apk --debug --flavor posApp

```

#### Build POS App (Release)

```bash
flutter build apk --release --flavor posApp

```

#### Build KDS App (Debug)

```bash
flutter build apk --debug --flavor kdsApp

```

#### Build KDS App (Release)

```bash
flutter build apk --release --flavor kdsApp

```

### Build All Flavors at Once

```bash

# Build both POS and KDS release APKs

flutter build apk --release --flavor posApp && flutter build apk --release --flavor kdsApp

```

### Output Locations

After building, APKs will be located at:

- **POS Release**: `build/app/outputs/flutter-apk/app-posApp-release.apk`

- **KDS Release**: `build/app/outputs/flutter-apk/app-kdsApp-release.apk`

- **POS Debug**: `build/app/outputs/flutter-apk/app-posApp-debug.apk`

- **KDS Debug**: `build/app/outputs/flutter-apk/app-kdsApp-debug.apk`

---

## Running Flavors During Development

### Run POS App on Device

```bash
flutter run --flavor posApp

```

### Run KDS App on Device

```bash
flutter run --flavor kdsApp

```

### Run Specific Flavor on Specific Device

```bash

# List devices

adb devices


# Run POS on specific device

flutter run --flavor posApp -d <device-id>


# Run KDS on specific device

flutter run --flavor kdsApp -d <device-id>

```

---

## Flavor Detection in Flutter Code

### Method 1: Dart Define (Recommended)

**Pass flavor as build argument:**

```bash
flutter run --flavor posApp --dart-define=FLAVOR=pos
flutter run --flavor kdsApp --dart-define=FLAVOR=kds

```

**Detect in code:**

```dart
// lib/config/flavor_config.dart
enum Flavor { pos, kds }

class FlavorConfig {
  static Flavor get currentFlavor {
    const flavorString = String.fromEnvironment('FLAVOR', defaultValue: 'pos');
    return flavorString == 'kds' ? Flavor.kds : Flavor.pos;
  }

  static bool get isPOS => currentFlavor == Flavor.pos;
  static bool get isKDS => currentFlavor == Flavor.kds;

  static String get appName => isPOS ? 'FlutterPOS' : 'FlutterPOS Kitchen Display';
}

```

### Method 2: Platform Channel

**Detect flavor from native side:**

```dart
// lib/config/flavor_config.dart
import 'package:flutter/services.dart';

class FlavorConfig {
  static const platform = MethodChannel('com.extrotarget.extropos/flavor');

  static Future<String> getFlavor() async {
    try {
      final String flavor = await platform.invokeMethod('getFlavor');
      return flavor; // Returns 'posApp' or 'kdsApp'
    } catch (e) {
      return 'posApp'; // Default
    }
  }
}

```

### Method 3: Package Name Detection

```dart
import 'package:package_info_plus/package_info_plus.dart';

Future<bool> isKDSApp() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.packageName.endsWith('.kds');
}

```

---

## Example: Flavor-Specific App Initialization

### lib/main.dart

```dart
import 'package:flutter/material.dart';
import 'config/flavor_config.dart';
import 'screens/pos/pos_home_screen.dart';
import 'screens/kds/kds_home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: FlavorConfig.appName,
      theme: ThemeData(
        primarySwatch: FlavorConfig.isPOS ? Colors.blue : Colors.green,
      ),
      home: FlavorConfig.isPOS ? const POSHomeScreen() : const KDSHomeScreen(),
    );
  }
}

```

---

## Example: Flavor-Specific Resources

### android/app/src/posApp/res/values/strings.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">FlutterPOS</string>
    <string name="flavor_message">Point of Sale Application</string>
</resources>

```

### android/app/src/kdsApp/res/values/strings.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">FlutterPOS Kitchen Display</string>
    <string name="flavor_message">Kitchen Display System</string>
</resources>

```

---

## Example: Flavor-Specific Android Manifest

### android/app/src/posApp/AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- POS-specific permissions -->
    <uses-permission android:name="android.permission.BLUETOOTH" />
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
    
    <application
        android:icon="@mipmap/ic_launcher_pos"
        android:label="@string/app_name">
        <!-- POS-specific configurations -->
    </application>
</manifest>

```

### android/app/src/kdsApp/AndroidManifest.xml

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- KDS might not need Bluetooth -->
    
    <application
        android:icon="@mipmap/ic_launcher_kds"
        android:label="@string/app_name"
        android:screenOrientation="landscape">
        <!-- KDS-specific configurations (e.g., landscape-only) -->
    </application>
</manifest>

```

---

## Creating Flavor-Specific App Icons

### Step 1: Generate Icon Assets

Use a tool like [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/) or Flutter's `flutter_launcher_icons` package:

#### pubspec.yaml (for icon generation)

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: false # Disable default

  flavors:
    posApp:
      android: true
      image_path: "assets/icons/pos_icon.png"
    kdsApp:
      android: true
      image_path: "assets/icons/kds_icon.png"

```

Run:

```bash
flutter pub run flutter_launcher_icons

```

### Step 2: Manual Placement

Place generated icons in:

- `android/app/src/posApp/res/mipmap-*/ic_launcher.png`

- `android/app/src/kdsApp/res/mipmap-*/ic_launcher.png`

---

## Version Management with Flavors

### Current Setup

With the configuration in place:

- **Base Version**: `1.0.14+14` (from `pubspec.yaml`)

- **POS Version**: `1.0.14-pos+14`

- **KDS Version**: `1.0.14-kds+14`

Both apps can be installed **simultaneously** on the same device because they have different package names:

- POS: `com.extrotarget.extropos.pos`

- KDS: `com.extrotarget.extropos.kds`

---

## Testing Both Flavors

### Install Both Apps on Same Device

```bash

# Build and install POS

flutter build apk --release --flavor posApp
adb install -r build/app/outputs/flutter-apk/app-posApp-release.apk


# Build and install KDS (on same device)

flutter build apk --release --flavor kdsApp
adb install -r build/app/outputs/flutter-apk/app-kdsApp-release.apk

```

### Wireless ADB Installation

```bash

# Connect to device

adb connect <device-ip>:5555


# Install POS

adb -s <device-id> install -r app-posApp-release.apk


# Install KDS

adb -s <device-id> install -r app-kdsApp-release.apk

```

---

## Gradle Build Variants

The Product Flavors create the following build variants:

| Flavor  | Build Type | Variant Name      | APK Name                    |
|---------|------------|-------------------|-----------------------------|
| posApp  | debug      | posAppDebug       | app-posApp-debug.apk        |
| posApp  | release    | posAppRelease     | app-posApp-release.apk      |
| kdsApp  | debug      | kdsAppDebug       | app-kdsApp-debug.apk        |
| kdsApp  | release    | kdsAppRelease     | app-kdsApp-release.apk      |

### Build Specific Variant

```bash

# Android Studio / Gradle

./gradlew assemblePosAppRelease
./gradlew assembleKdsAppRelease
./gradlew assemblePosAppDebug
./gradlew assembleKdsAppDebug

```

---

## VS Code Configuration

### .vscode/launch.json

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "FlutterPOS (POS Flavor)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug",
      "args": [
        "--flavor",
        "posApp",
        "--dart-define=FLAVOR=pos"
      ]
    },
    {
      "name": "FlutterPOS (KDS Flavor)",
      "request": "launch",
      "type": "dart",
      "flutterMode": "debug",
      "args": [
        "--flavor",
        "kdsApp",
        "--dart-define=FLAVOR=kds"
      ]
    }
  ]
}

```

---

## Common Use Cases

### 1. Different Navigation Flows

```dart
Widget _getHomeScreen() {
  if (FlavorConfig.isPOS) {
    return const ModeSelectionScreen(); // POS: Retail/Cafe/Restaurant
  } else {
    return const KitchenDisplayScreen(); // KDS: Kitchen orders only
  }
}

```

### 2. Feature Flags

```dart
class Features {
  static bool get enablePrinterSettings => FlavorConfig.isPOS;
  static bool get enableTableManagement => FlavorConfig.isPOS;
  static bool get enableOrderQueue => FlavorConfig.isKDS;
  static bool get enableKitchenTimer => FlavorConfig.isKDS;
}

```

### 3. Different API Endpoints

```dart
class ApiConfig {
  static String get baseUrl {
    if (FlavorConfig.isPOS) {
      return 'https://api.example.com/pos';
    } else {
      return 'https://api.example.com/kds';
    }
  }
}

```

---

## Troubleshooting

### Issue: "No flavor dimensions defined"

**Solution**: Ensure `flavorDimensions += "appType"` is present before `productFlavors` block.

### Issue: "Flavor not recognized by Flutter"

**Solution**: Always use `--flavor` flag with exact flavor name: `posApp` or `kdsApp` (case-sensitive).

### Issue: "Cannot install both apps"

**Solution**: This is expected! Different `applicationId` values allow simultaneous installation. If you want to replace, use `adb install -r`.

### Issue: "Manifest merger failed"

**Solution**: Check for conflicting attributes in flavor-specific manifests. Use `tools:replace` or `tools:remove` attributes.

---

## Next Steps

1. **Create flavor directories**: `android/app/src/posApp/` and `android/app/src/kdsApp/`
2. **Add app icons**: Place POS and KDS icons in respective `mipmap-*` folders
3. **Implement flavor detection**: Create `lib/config/flavor_config.dart`
4. **Build and test**: Run `flutter build apk --flavor posApp` and verify

---

## Benefits of This Approach

✅ **Single Codebase**: Maintain one codebase for both apps
✅ **Simultaneous Installation**: Install both apps on same device for testing
✅ **Independent Updates**: Update POS and KDS separately on Google Play
✅ **Resource Isolation**: Different icons, names, colors per flavor
✅ **Flexible Deployment**: Deploy only what customers need (POS-only or KDS-only licenses)

---

## Reference

- [Android Product Flavors Documentation](https://developer.android.com/build/build-variants#product-flavors)

- [Flutter Flavors Guide](https://docs.flutter.dev/deployment/flavors)

- [Gradle Build Variants](https://developer.android.com/build/build-variants)

---

**Date Created**: November 26, 2025  
**FlutterPOS Version**: 1.0.14+14  
**Configuration File**: `android/app/build.gradle.kts`
