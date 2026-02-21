# FlutterPOS Product Flavors - Visual Architecture

```text
┌─────────────────────────────────────────────────────────────────────────┐
│                         FlutterPOS Codebase                             │
│                      (Single Source Repository)                         │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Gradle Build
                                    ▼
                    ┌───────────────┴───────────────┐
                    │                               │
                    ▼                               ▼
        ┌──────────────────────┐        ┌──────────────────────┐
        │    POS App Flavor    │        │    KDS App Flavor    │
        │     (posApp)         │        │     (kdsApp)         │
        └──────────────────────┘        └──────────────────────┘
                    │                               │
                    │                               │
        ┌───────────┴────────────┐      ┌──────────┴───────────┐
        │                        │      │                      │
        ▼                        │      ▼                      │
┌────────────────┐               │  ┌────────────────┐        │
│ Package Name:  │               │  │ Package Name:  │        │
│ .extropos.pos  │               │  │ .extropos.kds  │        │
└────────────────┘               │  └────────────────┘        │
        │                        │          │                 │
        ▼                        │          ▼                 │
┌────────────────┐               │  ┌────────────────┐        │
│ App Name:      │               │  │ App Name:      │        │
│ FlutterPOS     │               │  │ FlutterPOS KDS │        │
└────────────────┘               │  └────────────────┘        │
        │                        │          │                 │
        ▼                        │          ▼                 │
┌────────────────┐               │  ┌────────────────┐        │
│ Version:       │               │  │ Version:       │        │
│ 1.0.14-pos+14  │               │  │ 1.0.14-kds+14  │        │
└────────────────┘               │  └────────────────┘        │
        │                        │          │                 │
        ▼                        │          ▼                 │
┌────────────────┐               │  ┌────────────────┐        │
│ Features:      │               │  │ Features:      │        │
│ • Retail       │               │  │ • Kitchen View │        │
│ • Cafe         │               │  │ • Order Queue  │        │
│ • Restaurant   │               │  │ • Status Update│        │
│ • Checkout     │               │  │ • Timer        │        │
│ • Reports      │               │  │ • Landscape    │        │
│ • Analytics    │               │  │   Only         │        │
└────────────────┘               │  └────────────────┘        │
        │                        │          │                 │
        ▼                        │          ▼                 │
┌────────────────┐               │  ┌────────────────┐        │
│ Output:        │               │  │ Output:        │        │
│ app-posApp-    │               │  │ app-kdsApp-    │        │

│ release.apk    │               │  │ release.apk    │        │
└────────────────┘               │  └────────────────┘        │
                                 │                            │
                                 ▼                            ▼
                    ┌────────────────────────────────────────┐
                    │   Both APKs can be installed on        │
                    │   SAME DEVICE simultaneously!          │
                    └────────────────────────────────────────┘

                    ┌──────────────────────┐
                    │   Dealer Portal      │
                    │   Web-Only Flavor    │
                    │     (dealer)         │
                    └──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Package Name:        │
                    │ N/A (Web Only)       │
                    └──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ App Name:            │
                    │ ExtroPOS Dealer      │
                    │ Portal (Web)         │
                    └──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Features:            │
                    │ • Tenant Onboarding  │
                    │ • License Generation │
                    │ • Offline APK Gen    │
                    │ • Client Management  │
                    │ • Dealer Analytics   │
                    │ • Email Registration │
                    │ • Web-Only Access    │
                    └──────────────────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Output:              │
                    │ build/web/           │
                    │ (Web Build)          │
                    └──────────────────────┘

```

---

## Resource Merge Flow

```text
┌─────────────────────────────────────────────────────────────┐
│                      Build POS App                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │   Gradle Flavor Resolution    │
              └───────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
                ▼                           ▼
    ┌──────────────────┐         ┌──────────────────┐
    │  Main Resources  │         │  POS Resources   │
    │  (Base/Shared)   │         │  (Override)      │
    └──────────────────┘         └──────────────────┘
    │                            │
    │ • AndroidManifest.xml      │ • AndroidManifest.xml
    │ • strings.xml (base)       │ • strings.xml (POS)
    │ • Default icons            │ • POS icons
    │ • Shared layouts           │ • POS-specific res
    │                            │
    └────────────┬───────────────┘
                 │
                 ▼
        ┌─────────────────┐
        │  Merged Result  │
        └─────────────────┘
                 │
                 │ Priority: POS > Main
                 │
                 ▼
        ┌─────────────────┐
        │  Final POS APK  │
        └─────────────────┘
        • App Name: "FlutterPOS"
        • Package: .extropos.pos
        • Icons: POS icons
        • Manifest: Merged

```

---

## Flavor Detection Flow

```text
┌────────────────────────────────────────────────────────────┐
│              App Launch (main.dart)                        │
└────────────────────────────────────────────────────────────┘
                            │
                            ▼
              ┌──────────────────────────┐
              │   FlavorConfig.current   │
              │   (reads FLAVOR env)     │
              └──────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │   FLAVOR=pos     │    │   FLAVOR=kds     │
    │   isPOS = true   │    │   isKDS = true   │
    └──────────────────┘    └──────────────────┘
                │                       │
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │ ModeSelection    │    │ KitchenDisplay   │
    │ Screen           │    │ Screen           │
    └──────────────────┘    └──────────────────┘
                │                       │
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │ Features:        │    │ Features:        │
    │ • Retail Mode    │    │ • Order Queue    │
    │ • Cafe Mode      │    │ • Kitchen Timer  │
    │ • Restaurant     │    │ • Status Update  │
    │ • Table Mgmt     │    │ • Multi-Kitchen  │
    │ • Checkout       │    │ • Auto-refresh   │
    │ • Reports        │    │                  │
    └──────────────────┘    └──────────────────┘

```

---

## Build Variants Matrix

```text
┌──────────────────────────────────────────────────────────────┐
│                    Build Variants                            │
└──────────────────────────────────────────────────────────────┘

Flavor Dimension: appType
├── posApp
│   ├── Debug   → posAppDebug
│   │   • Package: com.extrotarget.extropos.pos
│   │   • Version: 1.0.14-pos+14
│   │   • Debuggable: true
│   │   • APK: app-posApp-debug.apk
│   │
│   └── Release → posAppRelease
│       • Package: com.extrotarget.extropos.pos
│       • Version: 1.0.14-pos+14
│       • Debuggable: false
│       • Minified: true
│       • APK: app-posApp-release.apk
│
├── kdsApp
│   ├── Debug   → kdsAppDebug
│   │   • Package: com.extrotarget.extropos.kds
│   │   • Version: 1.0.14-kds+14
│   │   • Debuggable: true
│   │   • APK: app-kdsApp-debug.apk
│   │
│   └── Release → kdsAppRelease
│       • Package: com.extrotarget.extropos.kds
│       • Version: 1.0.14-kds+14
│       • Debuggable: false
│       • Minified: true
│       • APK: app-kdsApp-release.apk
│
├── backend (Web Only)
│   ├── Debug   → backendDebug
│   │   • Platform: Web
│   │   • Version: 1.0.14-backend+14
│   │   • Debuggable: true
│   │   • Output: build/web/
│   │
│   └── Release → backendRelease
│       • Platform: Web
│       • Version: 1.0.14-backend+14
│       • Debuggable: false
│       • Minified: true
│       • Output: build/web/
│
└── dealer (Web Only)
    ├── Debug   → dealerDebug
    │   • Platform: Web
    │   • Version: 1.0.14-dealer+14
    │   • Debuggable: true
    │   • Output: build/web/
    │
    └── Release → dealerRelease
        • Platform: Web
        • Version: 1.0.14-dealer+14
        • Debuggable: false
        • Minified: true
        • Output: build/web/

```

---

## Directory Inheritance

```text
android/app/src/
│
├── main/                     ← Shared base (lowest priority)
│   ├── AndroidManifest.xml
│   ├── kotlin/
│   │   └── MainActivity.kt
│   └── res/
│       ├── values/strings.xml
│       └── mipmap-*/ic_launcher.png
│
├── posApp/                   ← POS overrides (medium priority)
│   ├── AndroidManifest.xml   ⚠️ Merges with main
│   └── res/
│       ├── values/
│       │   └── strings.xml   ✓ Overrides main
│       └── mipmap-*/
│           └── ic_launcher.png ✓ Overrides main
│
└── kdsApp/                   ← KDS overrides (medium priority)
    ├── AndroidManifest.xml   ⚠️ Merges with main
    └── res/
        ├── values/
        │   └── strings.xml   ✓ Overrides main
        └── mipmap-*/
            └── ic_launcher.png ✓ Overrides main

Build Type (debug/release)    ← Highest priority

```

**Merge Priority (Highest to Lowest)**:

1. Build Type specific (debug/release)
2. Flavor specific (posApp/kdsApp)
3. Main (shared)

---

## Feature Flag Architecture

```text
┌────────────────────────────────────────────────────────────┐
│                    FlavorConfig                            │
│              (lib/config/flavor_config.dart)               │
└────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │   POS Features   │    │   KDS Features   │
    └──────────────────┘    └──────────────────┘
                │                       │
                ▼                       ▼
┌─────────────────────────┐  ┌─────────────────────────┐
│ Enabled:                │  │ Enabled:                │
│ ✓ Mode Selection        │  │ ✓ Kitchen Display       │
│ ✓ Retail Mode           │  │ ✓ Order Queue           │
│ ✓ Cafe Mode             │  │ ✓ Status Update         │
│ ✓ Restaurant Mode       │  │ ✓ Kitchen Timer         │
│ ✓ Table Management      │  │ ✓ Multi-Kitchen Support │
│ ✓ Checkout              │  │ ✓ Landscape Lock        │
│ ✓ Printer Settings      │  │                         │
│ ✓ Payment Methods       │  │ Disabled:               │
│ ✓ Customer Mgmt         │  │ ✗ Checkout              │
│ ✓ Refunds               │  │ ✗ Payments              │
│ ✓ Reports               │  │ ✗ Table Management      │
│ ✓ Analytics             │  │ ✗ Customer Management   │
│ ✓ Employee Perf         │  │ ✗ Refunds               │
│                         │  │ ✗ Full Reports          │
│ Disabled:               │  │                         │
│ ✗ Kitchen Display       │  │                         │
│ ✗ Order Queue           │  │                         │
└─────────────────────────┘  └─────────────────────────┘

```

---

## Build Script Flow

```text
┌────────────────────────────────────────────────────────────┐
│                ./build_flavors.sh all release              │
└────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │   Build POS      │    │   Build KDS      │
    └──────────────────┘    └──────────────────┘
                │                       │
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │ flutter build    │    │ flutter build    │
    │ apk --release    │    │ apk --release    │
    │ --flavor posApp  │    │ --flavor kdsApp  │
    │ --dart-define=   │    │ --dart-define=   │
    │ FLAVOR=pos       │    │ FLAVOR=kds       │
    └──────────────────┘    └──────────────────┘
                │                       │
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │ APK: 85.3 MB     │    │ APK: ~85 MB      │
    │ Size optimized   │    │ Size optimized   │
    └──────────────────┘    └──────────────────┘
                │                       │
                ▼                       ▼
    ┌──────────────────┐    ┌──────────────────┐
    │ Copy to Desktop  │    │ Copy to Desktop  │
    │ FlutterPOS-      │    │ FlutterPOS-      │
    │ v1.0.14-pos.apk  │    │ v1.0.14-kds.apk  │
    └──────────────────┘    └──────────────────┘
                │                       │
                └───────────┬───────────┘
                            │
                            ▼
                ┌──────────────────┐
                │   Build Backend  │
                └──────────────────┘
                            │
                            ▼
                ┌──────────────────┐
                │ flutter build    │
                │ web --release    │
                │ --target main_   │
                │ backend.dart     │
                │ --no-tree-shake- │
                │ icons            │
                └──────────────────┘
                            │
                            ▼
                ┌──────────────────┐
                │ Web Build:       │
                │ build/web/       │
                │ Web Only         │
                └──────────────────┘
                            │
                            ▼
                ┌──────────────────┐
                │ Copy to Desktop  │
                │ FlutterPOS-      │
                │ v1.0.14-backend- │
                │ web/             │
                └──────────────────┘
                            │
                            ▼
                ┌──────────────────┐
                │   Build Dealer   │
                └──────────────────┘
                            │
                            ▼
                ┌──────────────────┐
                │ flutter build    │
                │ web --release    │
                │ --target main_   │
                │ dealer.dart      │
                └──────────────────┘
                            │
                            ▼
                ┌──────────────────┐
                │ Web Build:       │
                │ build/web/       │
                │ Web Only         │
                └──────────────────┘
                            │
                            ▼
                ┌──────────────────┐
                │ Copy to Desktop  │
                │ FlutterPOS-      │
                │ v1.0.14-dealer-  │
                │ web/             │
                └──────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │   Build Complete!    │
                │   All Flavors Ready  │
                │   4 APKs + 1 Web     │
                └──────────────────────┘

```

---

## Installation Scenarios

```text
┌────────────────────────────────────────────────────────────┐
│              Android Device (iMin Swan 2)                  │
└────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┴───────────────────┐
        │                                       │
        ▼                                       ▼
┌─────────────────┐                   ┌─────────────────┐
│   POS App       │                   │   KDS App       │
│   Installed     │                   │   Installed     │
└─────────────────┘                   └─────────────────┘
        │                                       │
        ▼                                       ▼
┌─────────────────┐                   ┌─────────────────┐
│ Package:        │                   │ Package:        │
│ .extropos.pos   │                   │ .extropos.kds   │
└─────────────────┘                   └─────────────────┘
        │                                       │
        ▼                                       ▼
┌─────────────────┐                   ┌─────────────────┐
│ Data Location:  │                   │ Data Location:  │
│ /data/data/     │                   │ /data/data/     │
│ com.extrotarget │                   │ com.extrotarget │
│ .extropos.pos/  │                   │ .extropos.kds/  │
└─────────────────┘                   └─────────────────┘
        │                                       │
        └───────────────────┬───────────────────┘
                            │
                            ▼
                ┌──────────────────────┐
                │  Isolated Data       │
                │  Separate Settings   │
                │  Independent Updates │
                └──────────────────────┘

```

---

**Architecture Date**: December 11, 2025  
**FlutterPOS Version**: 1.0.14+14  
**Updated**: KeyGen merged into Dealer Portal, Backend web-only
