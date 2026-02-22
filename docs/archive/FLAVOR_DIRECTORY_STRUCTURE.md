# Flavor-Specific Directory Structure

## Required Android Directory Structure

Create these directories under `android/app/src/`:

```
android/app/src/
│
├── main/                              # Shared code for both flavors

│   ├── AndroidManifest.xml            # Base manifest (merged with flavor manifests)

│   ├── kotlin/
│   │   └── com/extrotarget/extropos/
│   │       └── MainActivity.kt        # Main activity (shared)

│   └── res/
│       ├── values/
│       │   ├── strings.xml
│       │   └── styles.xml
│       └── drawable/
│
├── posApp/                            # POS-specific overrides

│   ├── AndroidManifest.xml            # POS-specific manifest additions

│   │   # Example: Additional permissions, screen orientation

│   │
│   ├── kotlin/                        # POS-specific code (optional)

│   │   └── com/extrotarget/extropos/
│   │       └── MainActivity.kt        # Override MainActivity if needed

│   │
│   └── res/                           # POS-specific resources

│       ├── values/
│       │   ├── strings.xml            # POS app name: "FlutterPOS"

│       │   └── colors.xml             # POS-specific colors

│       ├── mipmap-mdpi/
│       │   └── ic_launcher.png        # POS icon (48x48)

│       ├── mipmap-hdpi/
│       │   └── ic_launcher.png        # POS icon (72x72)

│       ├── mipmap-xhdpi/
│       │   └── ic_launcher.png        # POS icon (96x96)

│       ├── mipmap-xxhdpi/
│       │   └── ic_launcher.png        # POS icon (144x144)

│       ├── mipmap-xxxhdpi/
│       │   └── ic_launcher.png        # POS icon (192x192)

│       └── drawable/
│           └── splash_screen.xml      # POS splash screen

│
└── kdsApp/                            # KDS-specific overrides

    ├── AndroidManifest.xml            # KDS-specific manifest additions

    │   # Example: Landscape orientation lock, different permissions

    │
    ├── kotlin/                        # KDS-specific code (optional)

    │   └── com/extrotarget/extropos/
    │       └── MainActivity.kt        # Override MainActivity if needed

    │
    └── res/                           # KDS-specific resources

        ├── values/
        │   ├── strings.xml            # KDS app name: "FlutterPOS Kitchen Display"

        │   └── colors.xml             # KDS-specific colors

        ├── mipmap-mdpi/
        │   └── ic_launcher.png        # KDS icon (48x48)

        ├── mipmap-hdpi/
        │   └── ic_launcher.png        # KDS icon (72x72)

        ├── mipmap-xhdpi/
        │   └── ic_launcher.png        # KDS icon (96x96)

        ├── mipmap-xxhdpi/
        │   └── ic_launcher.png        # KDS icon (144x144)

        ├── mipmap-xxxhdpi/
        │   └── ic_launcher.png        # KDS icon (192x192)

        └── drawable/
            └── splash_screen.xml      # KDS splash screen

```

---

## Recommended Flutter Directory Structure

```
lib/
│
├── main.dart                          # Common entry point

│   # Detects flavor and routes to appropriate home screen

│
├── config/
│   ├── flavor_config.dart             # ✓ Already created

│   └── app_config.dart                # App-wide configuration

│
├── screens/
│   ├── common/                        # Shared screens

│   │   ├── settings_screen.dart
│   │   ├── users_management_screen.dart
│   │   └── business_info_screen.dart
│   │
│   ├── pos/                           # POS-only screens

│   │   ├── mode_selection_screen.dart
│   │   ├── retail_pos_screen.dart
│   │   ├── cafe_pos_screen.dart
│   │   ├── restaurant/
│   │   │   ├── table_selection_screen.dart
│   │   │   └── pos_order_screen.dart
│   │   ├── checkout_screen.dart
│   │   ├── refund_screen.dart
│   │   └── reports_screen.dart
│   │
│   └── kds/                           # KDS-only screens

│       ├── kds_home_screen.dart
│       ├── kitchen_display_screen.dart
│       ├── order_queue_screen.dart
│       └── kitchen_settings_screen.dart
│
├── models/                            # Shared data models

│   ├── product.dart
│   ├── cart_item.dart
│   ├── order.dart
│   └── user_model.dart
│
├── services/                          # Shared services

│   ├── database_service.dart
│   ├── payment_service.dart
│   └── printer_service.dart
│
├── widgets/                           # Shared widgets

│   ├── cart_item_widget.dart
│   └── product_card.dart
│
└── utils/                             # Utilities

    ├── toast_helper.dart
    └── constants.dart

```

---

## Quick Setup Commands

### 1. Create Android Flavor Directories

```bash

# Navigate to android/app/src/

cd android/app/src


# Create POS flavor directories

mkdir -p posApp/res/values
mkdir -p posApp/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}
mkdir -p posApp/res/drawable


# Create KDS flavor directories

mkdir -p kdsApp/res/values
mkdir -p kdsApp/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}
mkdir -p kdsApp/res/drawable


# Create Kotlin directories (if needed)

mkdir -p posApp/kotlin/com/extrotarget/extropos
mkdir -p kdsApp/kotlin/com/extrotarget/extropos

```

### 2. Create Flutter Flavor Directories

```bash

# Navigate to lib/

cd lib


# Create POS-specific screens

mkdir -p screens/pos/restaurant


# Create KDS-specific screens

mkdir -p screens/kds


# Create common screens directory

mkdir -p screens/common

```

---

## Minimum Required Files

### 1. POS Strings (android/app/src/posApp/res/values/strings.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">FlutterPOS</string>
</resources>

```

### 2. KDS Strings (android/app/src/kdsApp/res/values/strings.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">FlutterPOS Kitchen Display</string>
</resources>

```

### 3. POS Manifest (android/app/src/posApp/AndroidManifest.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- POS-specific configurations -->
    <application>
        <!-- Will merge with main manifest -->
    </application>
</manifest>

```

### 4. KDS Manifest (android/app/src/kdsApp/AndroidManifest.xml)

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- KDS-specific configurations -->
    <application
        android:screenOrientation="landscape">
        <!-- Force landscape for KDS -->
    </application>
</manifest>

```

---

## File Merge Priority

When building a flavor, Gradle merges resources in this order (highest priority first):

1. **Build Type** (debug/release) specific resources

2. **Flavor** specific resources (posApp/kdsApp)

3. **Main** shared resources

Example:

- If `posApp/res/values/strings.xml` defines `app_name`, it overrides `main/res/values/strings.xml`

- If `posApp` doesn't define a resource, it falls back to `main`

---

## Testing Your Setup

### Verify Flavor Directories Exist

```bash

# Check POS directories

ls -la android/app/src/posApp/res/values/
ls -la android/app/src/posApp/res/mipmap-hdpi/


# Check KDS directories

ls -la android/app/src/kdsApp/res/values/
ls -la android/app/src/kdsApp/res/mipmap-hdpi/

```

### Build to Test

```bash

# Build POS (should use posApp resources)

flutter build apk --release --flavor posApp --dart-define=FLAVOR=pos


# Build KDS (should use kdsApp resources)

flutter build apk --release --flavor kdsApp --dart-define=FLAVOR=kds


# Check APK names

ls -lh build/app/outputs/flutter-apk/

```

---

## What Happens During Build

### POS Build (`flutter build apk --flavor posApp`)

1. Gradle reads `build.gradle.kts` and finds `posApp` flavor
2. Sets `applicationId = "com.extrotarget.extropos.pos"`
3. Sets `versionName = "1.0.14-pos"`
4. Merges manifests: `main/AndroidManifest.xml` + `posApp/AndroidManifest.xml`

5. Merges resources: `main/res/*` + `posApp/res/*` (posApp wins conflicts)

6. Flutter compiles with `--dart-define=FLAVOR=pos`
7. Generates: `app-posApp-release.apk`

### KDS Build (`flutter build apk --flavor kdsApp`)

1. Gradle reads `build.gradle.kts` and finds `kdsApp` flavor
2. Sets `applicationId = "com.extrotarget.extropos.kds"`
3. Sets `versionName = "1.0.14-kds"`
4. Merges manifests: `main/AndroidManifest.xml` + `kdsApp/AndroidManifest.xml`

5. Merges resources: `main/res/*` + `kdsApp/res/*` (kdsApp wins conflicts)

6. Flutter compiles with `--dart-define=FLAVOR=kds`
7. Generates: `app-kdsApp-release.apk`

---

## Common Mistakes to Avoid

❌ **Don't** create directories with wrong names:

- Wrong: `android/app/src/pos/`

- Correct: `android/app/src/posApp/`

❌ **Don't** forget the `res/` directory:

- Wrong: `android/app/src/posApp/values/strings.xml`

- Correct: `android/app/src/posApp/res/values/strings.xml`

❌ **Don't** use different package structures:

- Wrong: `posApp/kotlin/com/example/pos/MainActivity.kt`

- Correct: `posApp/kotlin/com/extrotarget/extropos/MainActivity.kt`

✅ **Do** keep the same package structure across flavors

✅ **Do** place only overrides in flavor directories (not duplicates)

✅ **Do** test both flavors after setup

---

## Next Steps

1. ✅ Gradle configuration (already done)
2. ⏳ Create flavor directories (use commands above)
3. ⏳ Add flavor-specific resources (strings, icons)
4. ⏳ Implement flavor detection in Flutter code
5. ⏳ Build and test both flavors

---

**Reference**: See `PRODUCT_FLAVORS_GUIDE.md` for complete documentation.
