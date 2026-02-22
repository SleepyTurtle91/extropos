# FlutterPOS Product Flavors - Quick Reference Card

## 🚀 Quick Commands

### Build Commands

```bash

# Build both POS and KDS (release)

./build_flavors.sh both release


# Build POS only

./build_flavors.sh pos release


# Build KDS only

./build_flavors.sh kds release


# Debug builds

./build_flavors.sh pos debug
./build_flavors.sh kds debug

```

### Run Commands

```bash

# Run POS on device

flutter run --flavor posApp --dart-define=FLAVOR=pos


# Run KDS on device

flutter run --flavor kdsApp --dart-define=FLAVOR=kds

```

### Install Commands

```bash

# Install POS

adb install -r build/app/outputs/flutter-apk/app-posApp-release.apk


# Install KDS

adb install -r build/app/outputs/flutter-apk/app-kdsApp-release.apk

```

---

## 📱 App Specifications

| | POS App | KDS App |
|---|---------|---------|
| **Package** | com.extrotarget.extropos.pos | com.extrotarget.extropos.kds |

| **Name** | FlutterPOS | FlutterPOS Kitchen Display |

| **Version** | 1.0.14-pos+14 | 1.0.14-kds+14 |

| **Orientation** | Any | Landscape Only |

| **APK** | app-posApp-release.apk | app-kdsApp-release.apk |

---

## 📂 Directory Structure

```
android/app/src/
├── main/               # Shared code

├── posApp/             # POS overrides

│   ├── AndroidManifest.xml
│   └── res/
│       ├── values/strings.xml
│       └── mipmap-*/ic_launcher.png
└── kdsApp/             # KDS overrides

    ├── AndroidManifest.xml
    └── res/
        ├── values/strings.xml
        └── mipmap-*/ic_launcher.png

```

---

## 💻 Flavor Detection in Code

```dart
import 'package:flutterpos/config/flavor_config.dart';

// Check flavor
if (FlavorConfig.isPOS) {
  // POS-specific code
}

if (FlavorConfig.isKDS) {
  // KDS-specific code
}

// Get app name
String name = FlavorConfig.appName;

// Feature flags
if (FlavorConfig.features.enableTableManagement) {
  // POS only
}

if (FlavorConfig.features.enableKitchenDisplay) {
  // KDS only
}

```

---

## 🎨 Flavor-Specific Resources

### POS strings.xml

```xml
<resources>
    <string name="app_name">FlutterPOS</string>
</resources>

```

### KDS strings.xml

```xml
<resources>
    <string name="app_name">FlutterPOS Kitchen Display</string>
</resources>

```

---

## 🔧 Gradle Configuration

```kotlin
flavorDimensions += "appType"

productFlavors {
    create("posApp") {
        dimension = "appType"
        applicationIdSuffix = ".pos"
        versionNameSuffix = "-pos"
    }
    create("kdsApp") {
        dimension = "appType"
        applicationIdSuffix = ".kds"
        versionNameSuffix = "-kds"
    }
}

```

---

## ✅ Checklist

Before building:

- [ ] Flavor directories exist

- [ ] strings.xml files configured

- [ ] App icons added (5 densities each)

- [ ] FlavorConfig imported in main.dart

- [ ] Both APKs build successfully

- [ ] Both apps install simultaneously

- [ ] App names correct on device

---

## 📖 Full Documentation

- **Complete Guide**: `PRODUCT_FLAVORS_GUIDE.md`

- **Directory Structure**: `FLAVOR_DIRECTORY_STRUCTURE.md`

- **Implementation Summary**: `FLAVOR_IMPLEMENTATION_SUMMARY.md`

- **Flavor Config**: `lib/config/flavor_config.dart`

---

## 🐛 Common Issues

**"No flavor dimensions defined"**  

→ Already configured in build.gradle.kts ✅

**"Flavor not recognized"**  

→ Use exact names: `posApp` or `kdsApp`

**"Cannot install both apps"**  

→ Different package names allow both ✅

---

## 📊 Build Variants

| Variant | Command |
|---------|---------|
| posAppDebug | `./build_flavors.sh pos debug` |
| posAppRelease | `./build_flavors.sh pos release` |
| kdsAppDebug | `./build_flavors.sh kds debug` |
| kdsAppRelease | `./build_flavors.sh kds release` |

---

**Status**: ✅ Ready to Build  
**Date**: November 26, 2025  
**Version**: 1.0.14+14
