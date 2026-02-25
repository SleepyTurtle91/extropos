# ExtroPOS v1.1.4 Release Notes

**Version:** 1.1.4+32  
**Release Date:** February 23, 2026  
**Build Status:** ✅ Complete

---

## 📦 Build Information

| Item | Details |
|------|---------|
| **APK File** | `app-posapp-release.apk` (100.6 MB) |
| **Version Code** | 32 |
| **Version Name** | 1.1.4 |
| **Flavor** | posApp |
| **Build Type** | Release |
| **Installation Status** | ✅ Successfully Installed |

---

## ✨ What's New in v1.1.4

### 🔧 Critical Fixes

#### 1. **App Icon Issue** ✅ FIXED
- **Problem**: Broken app icon on home screen and app drawer
- **Solution**: Generated launcher icons using `flutter_launcher_icons` package
- **Details**:
  - Created adaptive icons for Android with background color #121212
  - Generated iOS launcher icons
  - All icon variants properly generated

#### 2. **Products Not Showing on POS Screen** ✅ FIXED
- **Problem**: Categories and products didn't display on UnifiedPOSScreen
- **Solution**: Implemented database fetching logic
- **Details**:
  - Connected `UnifiedPOSScreen._fetchData()` to `DatabaseService`
  - Loads categories and items from SQLite database
  - Proper mapping from Item model to Product model
  - Added error handling and loading states
  
#### 3. **Icons Inside App Rendering Issue** ✅ FIXED
- **Problem**: All icons showing as the same icon (category icon)
- **Solution**: Fixed `_iconFromDb()` method to properly convert icon code points
- **Details**:
  - Now converts database icon code points to proper IconData objects
  - Supports custom font families if specified
  - Falls back to MaterialIcons for standard icons
  - All product/category icons now display correctly

---

## 📋 Changelog Access

Users can now view the full changelog directly in the app:

**Navigation Path:**
```
Settings → About → Changelog
```

The changelog includes:
- Current version (1.1.4) with all fixes
- Previous version history (1.1.3, 1.1.2, 1.1.1)
- Detailed technical notes
- Feature descriptions

---

## 🔄 Version History

### Previous Version: 1.1.3+31
- Initial multi-mode POS system
- Business session management
- User authentication
- Training mode support

---

## 📝 Files Modified/Created

| File | Change | Type |
|------|--------|------|
| `pubspec.yaml` | Bumped version to 1.1.4+32 | Modified |
| `pubspec.yaml` | Added flutter_markdown dependency | Added |
| `pubspec.yaml` | Added CHANGELOG.md to assets | Modified |
| `CHANGELOG.md` | Created main changelog file | Created |
| `lib/screens/changelog_screen.dart` | Created changelog UI screen | Created |
| `lib/screens/settings_screen.dart` | Added Changelog menu item | Modified |
| `lib/services/database_service.dart` | Fixed icon conversion method | Modified |
| `lib/screens/unified_pos_screen.dart` | Implemented product loading | Modified |
| `flutter_launcher_icons-posApp.yaml` | Icon configuration | Existing |

---

## 🚀 Installation Instructions

### For Testing on Physical Device

1. **Via ADB (Command Line):**
   ```powershell
   adb install -r app-posapp-release.apk
   ```

2. **Via Android Studio:**
   - Open Device File Explorer
   - Drag and drop APK onto device
   - Grant permissions if prompted

3. **Via USB File Transfer:**
   - Copy APK to device via USB
   - Use file manager to navigate to APK
   - Tap to install

### Device Requirements

- **Minimum Android Version:** Android 8.0+
- **RAM Required:** 2GB minimum, 4GB recommended
- **Storage:** ~150MB free space
- **Permissions Needed:**
  - WRITE_EXTERNAL_STORAGE
  - READ_EXTERNAL_STORAGE
  - INTERNET
  - CAMERA (optional, for QR scanning)

---

## ✅ Testing Checklist

- [x] App installs successfully
- [x] App icon displays correctly on home screen
- [x] Products load and display on POS screen
- [x] Category icons show correctly
- [x] Product icons show correctly
- [x] Settings screen works
- [x] Changelog screen is accessible
- [x] No crashes on startup
- [x] Database loads without errors

---

## 🐛 Known Issues

None reported for v1.1.4

---

## 📞 Support

For issues or questions:
1. Check the in-app Changelog (Settings → About → Changelog)
2. Review console logs for error details
3. Verify database integrity using database test tools

---

## 📍 Build Location

**APK File Path:**
```
build/app/outputs/flutter-apk/app-posapp-release.apk
```

**Desktop Copy:**
```
~/Desktop/ExtroPOS-v1.1.4-build32-[timestamp].apk
```

---

## 🔐 Security & Quality

- ✅ Release build (optimized)
- ✅ No tree-shaking issues with icons
- ✅ All dependencies verified
- ✅ Code analyzed for errors
- ✅ Complies with Android requirements

---

**Release Notes Generated:** 2026-02-23  
**Status:** Ready for Distribution ✨
