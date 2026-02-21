# Bluetooth Printer Troubleshooting Guide

## Quick Test (Android)

### Step 1: Test Bluetooth Permissions

1. Open the app on your Android device
2. Go to the Lock Screen (app start screen)
3. If in debug mode, you'll see debug buttons at the bottom:

   - Tap **"DEBUG: Request BT Permissions"**

   - Grant the permissions when prompted

   - Check console logs: should show `requestBluetoothPermissions result: true`

### Step 2: Discover Bluetooth Printers

1. Make sure your Bluetooth printer is:

   - **Powered on**

   - **In pairing/discoverable mode** (or already paired in Android Settings)

2. On Lock Screen, tap **"DEBUG: Discover BT Printers"**
3. Watch console logs:

   ```
   LockScreen: Bluetooth printers found: N
   LockScreen: BT Printer <Name> <ID> <Address>
   ```

### Step 3: Check Native Logs

Use `adb logcat` to see detailed plugin logs:

```bash
adb logcat -s PrinterPlugin

```text

Expected logs:


```text
D/PrinterPlugin: onMethodCall: discoverBluetoothPrinters
D/PrinterPlugin: === Starting Bluetooth Printer Discovery ===
D/PrinterPlugin: Bluetooth: Scanning paired devices
D/PrinterPlugin: Bluetooth: Found N paired devices
D/PrinterPlugin: Bluetooth Device Found:
D/PrinterPlugin:   - Name: <printer name>

D/PrinterPlugin:   - Address: XX:XX:XX:XX:XX:XX

D/PrinterPlugin:   - Is Printer: true

D/PrinterPlugin:   ✓ Added to discovery list
D/PrinterPlugin: === Bluetooth Discovery Complete: N printers ===

```text

---


## Common Issues & Solutions



### Issue 1: "No Bluetooth printers found"


**Possible Causes:**

1. **Printer not paired or discoverable**

   - Solution: Go to Android Settings → Bluetooth → Pair your printer

   - Or set printer to discoverable mode

2. **Bluetooth permissions not granted**

   - Solution: Tap "DEBUG: Request BT Permissions" and grant when prompted

   - Or manually: Settings → Apps → ExtroPOS → Permissions → Enable Nearby devices/Bluetooth

3. **Bluetooth disabled on phone**

   - Solution: Enable Bluetooth in Quick Settings or Android Settings

4. **Printer name doesn't match detection keywords**

   - Current keywords: `printer`, `receipt`, `thermal`, `pos`, `epson`, `star`, `citizen`, `bixolon`, `sewoo`, `custom`, `rongta`, `xprinter`

   - Solution: The plugin now adds ALL discovered devices as fallback, so check if your device appears even if not auto-detected as printer


### Issue 2: App crashes when discovering


**Possible Cause:** Missing AndroidManifest permissions

**Solution:** Verify `android/app/src/main/AndroidManifest.xml` contains:


```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

```text


### Issue 3: "Bluetooth permissions not granted, aborting discovery"


**Solution:**

1. Tap "DEBUG: Request BT Permissions" button
2. Accept all permission prompts
3. If permissions dialog doesn't appear:

   - On Android 12+: Grant permissions manually in Settings → Apps → ExtroPOS → Permissions

   - Enable "Nearby devices" permission


### Issue 4: Permission request fails silently


**Check:** Activity context is available


- The plugin needs an Activity to request permissions

- Ensure app is in foreground when requesting permissions

- Logs should show: `Bluetooth permission requested: true/false`


### Issue 5: Paired device appears but not recognized as printer


**Solution 1:** Add printer manually


- The plugin now returns ALL discovered devices as fallback

- Select your device from the list even if not auto-recognized

**Solution 2:** Update printer detection keywords


- Edit `PrinterPlugin.kt` → `isBluetoothPrinter()` function

- Add your printer's name pattern to the keyword list

---


## Testing Active Discovery (No Paired Devices)


If you have NO paired Bluetooth devices:

1. Ensure printer is in **discoverable mode**
2. Tap "DEBUG: Discover BT Printers"
3. Plugin will attempt active scan (startDiscovery)
4. Wait ~8 seconds for scan to complete
5. Check logs for:

   ```

   D/PrinterPlugin: Bluetooth: No paired devices found
   D/PrinterPlugin: Bluetooth: Attempting active discovery (scan) as fallback

   ```

**Note:** Active discovery requires:


- Android 12+: `BLUETOOTH_SCAN` permission

- Android <12: `ACCESS_FINE_LOCATION` permission

- Bluetooth enabled

- Location services enabled (Android <12)

---


## Verification Checklist


Before reporting issues, verify:


- [ ] Printer is powered on

- [ ] Printer is in pairing/discoverable mode

- [ ] Bluetooth is enabled on Android device

- [ ] App has Bluetooth permissions granted

- [ ] (Android <12) Location services are enabled

- [ ] Tried both: paired device discovery AND active scan

- [ ] Checked both Flutter logs AND adb logcat logs

---


## Debug Log Locations



### Flutter Console Logs


When running `flutter run -d <device>`, watch for:


```text
LockScreen: Bluetooth printers found: N
AndroidPrinterService: Starting Bluetooth printer discovery...
AndroidPrinterService: Discovered N Bluetooth printers

```text


### Native Android Logs



```bash
adb logcat -s PrinterPlugin

```text


### Check Permission Status



```bash
adb shell dumpsys package com.extrotarget.extropos | grep permission

```text

---


## Advanced: Manual Permission Grant


If permission dialog doesn't work, grant manually via adb:


```bash

# Android 12+

adb shell pm grant com.extrotarget.extropos android.permission.BLUETOOTH_SCAN
adb shell pm grant com.extrotarget.extropos android.permission.BLUETOOTH_CONNECT


# Android <12

adb shell pm grant com.extrotarget.extropos android.permission.ACCESS_FINE_LOCATION

```text

---


## Implementation Details



### Permission Flow


1. Dart calls `PermissionsHelper.requestBluetoothPermissions()`
2. Routes to `PrinterPlugin.requestBluetoothPermissions()`
3. Plugin checks current permissions via `ContextCompat.checkSelfPermission()`
4. If missing, calls `ActivityCompat.requestPermissions()`
5. User sees system permission dialog
6. Result returned via `ActivityPluginBinding.addRequestPermissionsResultListener()`
7. Dart receives `true` (granted) or `false` (denied)


### Discovery Flow


1. Check permissions → request if missing → abort if denied
2. Get `BluetoothAdapter` and verify it's enabled
3. Query `bondedDevices` (paired devices)
4. If paired devices found → filter by printer keywords → return
5. If NO paired devices → attempt `startDiscovery()` (active scan)
6. Register `BroadcastReceiver` for `ACTION_FOUND` and `ACTION_DISCOVERY_FINISHED`
7. Wait up to 8 seconds for discovery to complete
8. Filter discovered devices by printer keywords
9. If no matches → add ALL discovered devices as fallback
10. Return list of discovered printers to Dart

---


## File References


- Permission helper: `lib/services/permissions_helper.dart`

- Android service: `lib/services/android_printer_service.dart`

- Plugin implementation: `android/app/src/main/kotlin/com/extrotarget/extropos/PrinterPlugin.kt`

- Debug UI: `lib/screens/lock_screen.dart` (debug buttons)

- Manifest: `android/app/src/main/AndroidManifest.xml`

---


## Need More Help?


If Bluetooth discovery still fails after following this guide:

1. Capture full logs:

   ```bash
   adb logcat > bluetooth_debug.txt
   # (Trigger discovery, wait 10 seconds, then Ctrl+C)

   ```

1. Check printer compatibility:

   - Some printers require specific SDKs or proprietary protocols

   - Verify printer supports SPP (Serial Port Profile) for Bluetooth

2. Test with a known working Bluetooth printer app to confirm printer functionality

3. Review the plugin logs for specific error messages and share them for further diagnosis
