# Launch Go-Live Checklist - FlutterPOS v1.0.27

**Project**: FlutterPOS Unified Consumer Launch
**Version**: 1.0.27
**Target Launch Date**: March 16-22, 2026
**Current Phase**: Release Preparation (Step 9)
**Status**: IN PROGRESS

---

## Pre-Release Requirements (Step 9: Release Packaging)

### ✅ Code Readiness
- [x] All regression tests passing (27/27)
- [x] Responsive layouts complete (Retail/Cafe/Restaurant)
- [x] Session/shift guards functional
- [x] Payment result parser unified
- [x] Split-bill totals corrected (include tax/service)
- [x] Discount semantics standardized (flat RM)
- [ ] Dart SDK upgraded to 3.9.0+ (BLOCKING)
- [ ] Final analyzer pass (0 warnings)
- [ ] Final dart_format pass (all files)

### 🟨 Device Testing
- [ ] Android tablet physical device test (shift access, checkout)
- [ ] Windows desktop physical device test (payment flow)
- [ ] Thermal printer integration test (58mm receipt)
- [ ] Network latency test (Appwrite sync)
- [ ] Battery stress test (Android, 4+ hours POS usage)

### 🟨 Security Validation
- [ ] PIN entry field masked correctly
- [ ] User session isolation verified
- [ ] Database encryption enabled
- [ ] API credentials not exposed in logs
- [ ] SharePreferences sensitive data secured

### 🟨 Performance Baseline
- [ ] 100+ orders loaded in memory
- [ ] Product grid scroll smooth (60fps)
- [ ] Payment processing <3 seconds
- [ ] Receipt generation <2 seconds
- [ ] Database queries <500ms

### 📋 Documentation
- [x] REGRESSION_TEST_RESULTS_MAR2026.md created
- [x] UNIFIED_POS_CONSUMER_LAUNCH_PLAN_MAR2026.md created
- [ ] API Integration Guide (Appwrite sync)
- [ ] Deployment Instructions (Windows/Android)
- [ ] Troubleshooting Guide (common issues)
- [ ] Release Notes (v1.0.27 changes)

---

## Step 9a: SDK & Toolchain Upgrade

### Current State
```
Local Dart: 3.6.2
Project requires: ^3.9.0
Status: MISMATCH (blocks analyzer)
```

### Action Items
- [ ] Download Flutter v3.19+/Dart 3.9.0+
- [ ] Update ~/.bashrc or PATH to new Flutter location
- [ ] Run `flutter --version` to verify
- [ ] Run `flutter doctor` to check environment
- [ ] Clear cache: `flutter clean && flutter pub get`

### Verification
```bash
cd /home/user/Documents/flutterpos
flutter analyze lib/screens/*.dart    # Should show 0 warnings
flutter test --coverage               # Should show all tests passing
```

**Timeline**: 30 minutes
**Blocker**: YES (required before APK build)

---

## Step 9b: Build Release Artifacts

### Android APK Build

#### Pre-Build Checklist
- [ ] `flutter clean` executed
- [ ] `flutter pub get` refreshed
- [ ] `pubspec.yaml` versions pinned
- [ ] `build.gradle` release signing configured
- [ ] Keystore file secure location identified

#### Build Command
```bash
cd /home/user/Documents/flutterpos
flutter build apk --release \
  --flavor pos \
  --split-per-abi \
  --obfuscate \
  --split-debug-info=build/app/outputs/
```

#### Output Locations
- `build/app/outputs/flutter-apk/app-release.apk` (universal)
- `build/app/outputs/app/release/app-armeabi-v7a-release.apk` (32-bit)
- `build/app/outputs/app/release/app-arm64-v8a-release.apk` (64-bit)

#### Sign & Align
```bash
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore ~/.android/release.keystore \
  -storepass <PASSWORD> \
  build/app/outputs/flutter-apk/app-release.apk \
  flutterpos-key

zipalign -v 4 build/app/outputs/flutter-apk/app-release.apk \
  ~/Desktop/FlutterPOS-v1.0.27-$(date +%Y%m%d).apk
```

#### Validation
- [ ] APK size <150MB
- [ ] Obfuscation enabled
- [ ] Signed with production key
- [ ] Installable on test device

**Timeline**: 45 minutes
**Deliverable**: Signed APK ready for Play Store/direct distribution

### Windows Executable Build

#### Build Command
```bash
cd /home/user/Documents/flutterpos
flutter build windows --release
```

#### Output Locations
- `build/windows/runner/Release/flutter_windows.dll`
- `build/windows/runner/Release/extropos.exe`

#### WIX Installer (Optional)
```bash
# Install WIX toolset first
choco install wixtoolset -y

# Build MSI installer
# (Custom WIX file needed)
wix build installer.wxs
```

#### Validation
- [ ] Executable runs on Windows 10/11
- [ ] Database path writable
- [ ] Receipts print on thermal printer
- [ ] Appwrite sync working

**Timeline**: 30 minutes
**Deliverable**: Executable ready for Windows deployment

---

## Step 9c: APK Version & Manifest Update

### Version Bump
Current: `version: 1.0.26+126` (pubspec.yaml)
Target: `version: 1.0.27+127`

### Changes
```yaml
# pubspec.yaml
version: 1.0.27+127

# android/app/build.gradle
versionCode = 127
versionName = "1.0.27"

# android/app/src/main/AndroidManifest.xml
<manifest android:versionCode="127" android:versionName="1.0.27">
  <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="34"/>
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-permission android:name="android.permission.BLUETOOTH"/>
  <!-- ... other permissions ... -->
</manifest>
```

### Testing
- [ ] `flutter pub get` succeeds
- [ ] Build completes without version errors
- [ ] APK info shows v1.0.27, build 127

**Timeline**: 15 minutes

---

## Step 9d: Release Notes & Documentation

### Release Notes Template (v1.0.27)

```markdown
# FlutterPOS v1.0.27 Release Notes

**Release Date**: March 16, 2026
**Target Platforms**: Android 7.0+, Windows 10/11

## New Features (M3: Consumer UX Revamp)
- Unified POS shell (single entry point for Retail/Cafe/Restaurant)
- Responsive layouts across all screen sizes (600/900/1200px breakpoints)
- Session/shift enforcement gates with recovery UX

## Improvements (M2: Shared Checkout Rules)
- Standardized payment result handling across all POS modes
- Unified Pricing helpers (subtotal, tax, service charge, total)
- Fixed discount semantics (flat RM amount, clamped to subtotal)
- Split-bill totals now include tax/service charges

## Bug Fixes
- Fixed RetailPOS product grids to be responsive (no more fixed 3-column layouts)
- Fixed Cafe merchant dropdown overflow on narrow screens
- Fixed Payment screen action buttons overflow on tablets <600px
- Fixed split-bill totals missing tax/service charges

## Testing
- 27 regression tests passing (100% success rate)
- Physical device UAT: Android tablet, Windows desktop
- Thermal printer integration verified

## Known Issues
- None (cleared for production)

## Security Updates
- Upgrade to Dart 3.9.0 (latest security patches)
- PIN field masking improved
- User session isolation verified

## Migration Notes
From v1.0.26 → v1.0.27:
- No database schema changes
- No configuration migration required
- Direct upgrade supported (install over existing version)

## Support
- Report issues: support@extropos.org
- Hotline: TBD

---
v1.0.27 Build 127 | March 16, 2026
```

### Deployment Instructions

**Windows Desktop Deployment**:
1. Extract `FlutterPOS-v1.0.27-windows.zip`
2. Run `extropos.exe`
3. Configure business settings (settings → business info)
4. Test shift/cashier sign-in

**Android Tablet Deployment**:
1. Download `FlutterPOS-v1.0.27-arm64-v8a.apk`
2. Install via ADB: `adb install -r FlutterPOS-v1.0.27-arm64-v8a.apk`
3. Allow app permissions (camera, Bluetooth)
4. Test shift/cashier sign-in

**Appwrite Sync Configuration** (if cloud backend):
```
Server: https://appwrite.extropos.org/v1
Project ID: 6940a64500383754a37f
Database: pos_db
```

**Timeline**: 30 minutes
**Deliverable**: User-facing documentation ready

---

## Step 9e: Build Verification

### Checklist Before Release
- [ ] Git tag created: `git tag -a v1.0.27-<YYYYMMDD> -m "Release v1.0.27"`
- [ ] Changelog.md updated with v1.0.27 changes
- [ ] APK signed with production key
- [ ] Windows exe tested on target OS versions
- [ ] All permissions granted in manifests
- [ ] Privacy policy accessible in-app
- [ ] Onboarding flow works (new user)
- [ ] Existing business data migrates correctly
- [ ] Payment methods all available
- [ ] Receipt printing works (if applicable)

### Smoke Test (Manual)
1. Open app → LockScreen appears
2. Enter PIN → UnifiedPOSScreen loads
3. Check mode selection (Retail/Cafe/Restaurant available)
4. Click "Start Shift" → ShiftDialog shows
5. Enter merchant/amount → shift started
6. Add product to cart → cart updates
7. Proceed to payment → PaymentScreen shows
8. Select payment method → process payment
9. Verify receipt displays → checkout complete
10. Check database → order saved

**Expected Time**: 5 minutes per device
**Devices**: Android tablet, Windows desktop minimum

---

## Risk Mitigation

### Risk 1: SDK Version Mismatch
- **Impact**: Analyzer doesn't run, hidden errors in code
- **Mitigation**: Upgrade Dart to 3.9.0 before build
- **Contingency**: Run manual code review if upgrade delayed
- **Owner**: DevOps

### Risk 2: APK Signing Issues
- **Impact**: APK won't install on devices
- **Mitigation**: Test signing process on development machine first
- **Contingency**: Build unsigned APK for UAT
- **Owner**: Dev Lead

### Risk 3: Network Latency (Appwrite)
- **Impact**: Slow sync, timeout errors
- **Mitigation**: Test with simulated network delay (<3G)
- **Contingency**: Implement offline-first caching
- **Owner**: Backend Dev

### Risk 4: Thermal Printer Driver Issues
- **Impact**: Receipts won't print on Windows
- **Mitigation**: Test with target printer model (58mm/80mm)
- **Contingency**: Provide PDF receipt fallback
- **Owner**: Hardware Integration

---

## Timeline & Owners

| Step | Task | Owner | Duration | Deadline |
| --- | --- | --- | --- | --- |
| 9a | SDK Upgrade | DevOps | 30 min | Mar 12 |
| 9b | APK Build | Dev Lead | 45 min | Mar 12 |
| 9b | Windows Build | Dev Lead | 30 min | Mar 12 |
| 9c | Version Bump | Build Eng | 15 min | Mar 13 |
| 9d | Release Notes & Docs | Tech Writer | 30 min | Mar 13 |
| 9e | Build Verification & Smoke Test | QA | 30 min | Mar 13 |
| 10 | UAT on Physical Devices (Step 8b) | QA + Pilot Stores | 4 hours | Mar 14 |
| 10 | Go-Live Checklist Sign-Off (Step 10) | Product Lead | 30 min | Mar 15 |
| **LAUNCH** | **Production Deploy** | **Ops** | **TBD** | **Mar 16-22** |

---

## Go/No-Go Decision Criteria

### Must Have (GO blockers)
- [x] All regression tests passing
- [ ] Physical device UAT completed with 0 P1 defects
- [ ] SDK version mismatch resolved
- [ ] APK signed and installable
- [ ] Windows executable tested

### Should Have (preferred)
- [ ] <5 warnings from analyzer
- [ ] Performance baseline met (60fps, <3s payment)
- [ ] Thermal printer tested
- [ ] All documentation complete

### Nice to Have (optional)
- [ ] MSI installer for Windows
- [ ] Auto-update mechanism
- [ ] Crash reporting dashboard

---

## Launch Go-Live Checklist (Step 10)

### Pre-Go-Live (Mar 15)
- [ ] Final backup of production database (if applicable)
- [ ] Emergency rollback plan documented
- [ ] Support team trained (shifts, payment flows)
- [ ] Customer comms prepared (launch announcement)
- [ ] Performance monitoring set up

### Go-Live Day (Mar 16-22)
- [ ] APK push to Play Store / Android devices
- [ ] Windows exe distributed to pilot stores
- [ ] Real-time monitoring dashboard active
- [ ] Support team on standby (24/7)
- [ ] Log aggregation active (crash reports)

### Post-Go-Live (Mar 23+)
- [ ] 48-hour stability monitoring
- [ ] Daily defect triage (if any P1/P2 issues)
- [ ] User feedback collection
- [ ] Analytics review (usage patterns, errors)
- [ ] Pilot store debrief & sign-off

---

## Success Criteria

**Launch is successful if**:
- ✅ APK installs on Android 7.0+ devices
- ✅ Windows exe runs on Windows 10/11
- ✅ POS checkout completes end-to-end (Retail/Cafe/Restaurant)
- ✅ Receipts print on thermal printer
- ✅ No P1 defects in first 24 hours
- ✅ <1% crash rate after 48 hours
- ✅ Customer feedback positive (shift access, payment smooth)

---

## Document Ownership

**Prepared By**: AI Agent (Feb 16, 2026)
**Reviewed By**: TBD
**Approved By**: TBD
**Status**: DRAFT - Awaiting Team Review

---

**Last Updated**: February 16, 2026, 12:00 UTC
**Next Review**: After UAT completion (Step 8b)

