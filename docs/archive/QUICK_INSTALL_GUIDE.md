# Quick Start: Install & Launch APK on Android Device
## FlutterPOS v1.0.27 Device Testing

---

## 🚀 Installation Methods (Choose One)

### **Method 1: Flutter Install (Recommended)**
Most direct approach - installs and opens app on device.

```powershell
# From project root directory
flutter run -d 8bab44b57d88 --flavor posApp
```

**Expected Output**:
```
Installing and launching...
app-posapp-release.apk installed
Launching app on 24075RP89G...
I/flutter: App started successfully
```

**Timeline**: ~30-60 seconds

---

### **Method 2: Manual ADB Install**
If Flutter method has issues.

```powershell
# Find ADB location
$adb = "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe"

# Check device connected
& $adb devices
# Output should show: 8bab44b57d88    device

# Install APK
& $adb -s 8bab44b57d88 install -r build\app\outputs\flutter-apk\app-posapp-release.apk

# Launch app
& $adb -s 8bab44b57d88 shell am start -n com.extrotarget.extropos.posApp/com.extrotarget.extropos.MainActivity
```

**Expected Output**:
```
Success
```

---

### **Method 3: Copy APK to Device**
If command-line install fails.

```powershell
# Copy to device downloads
& $adb -s 8bab44b57d88 push build\app\outputs\flutter-apk\app-posapp-release.apk /sdcard/Download/

# Then on device:
# 1. Open Files app
# 2. Navigate to Download folder
# 3. Tap app-posapp-release.apk
# 4. Tap Install
# 5. Wait for completion
# 6. Launch app from app drawer
```

---

## ✅ Verification Steps

### Device Ready Check
```powershell
flutter devices
```

**Expected Output**:
```
24075RP89G (mobile) • 8bab44b57d88 • android-arm64 • Android 15 (API 35)
```

If NOT showing:
1. Check USB cable is plugged firmly
2. Unlock device screen
3. Check "Always allow from this computer" on device USB prompt
4. Restart ADB: `adb kill-server && adb start-server`

---

## 🎯 App Launch Sequence

### On Device After Installation

**You should see** (in order):

1. **Splash Screen** (1-2 seconds)
   - FlutterPOS logo
   - Loading animation

2. **Lock Screen** (if enabled)
   - PIN or unlock gesture
   - OR: Auto-unlock to main screen

3. **Business Session Check**
   - "Business Closed" message
   - OR: Proceed directly if business open

4. **Shift Management** (if first launch)
   - "Start Shift" dialog
   - Enter opening cash amount
   - Tap "Start Shift"

5. **Main POS Screen** ✓
   - Product grid visible
   - Cart section at bottom
   - Ready for transactions

---

## ⚙️ Initial Setup (One-Time)

If app shows setup prompts:

### Business Info Setup
- [ ] Business Name: Enter your store name
- [ ] Address: (Optional)
- [ ] Phone: (Optional)
- [ ] Tax ID: (Optional)
- [ ] Currency: Default is RM
- [ ] Save

### Business Mode Selection
- [ ] Choose: **Retail** for testing retail flow
  - OR: **Cafe** for cafe testing
  - OR: **Restaurant** for restaurant table testing
- [ ] Confirm

---

## 🧪 Quick Sanity Check (5 minutes)

After app launches, do this quick test:

1. **Add Item**
   - Tap any product
   - Should add to cart with qty=1

2. **View Cart**
   - Cart should show product name, price, quantity
   - Should show total at bottom

3. **Adjust Quantity**
   - Tap + button
   - Quantity should increase to 2
   - Total should update

4. **Proceed to Checkout**
   - Look for "Checkout" or "Proceed" button
   - Tap it
   - Should show payment screen

5. **Payment**
   - Select "Cash" (safest for testing)
   - Enter amount (e.g., $50, $100)
   - Should calculate change
   - Tap "Pay"

6. **Receipt**
   - Receipt screen should appear
   - Should show items, total, change
   - Tap back/close

7. **Return to POS**
   - Cart should be empty
   - Ready for next transaction
   - ✓ **PASS** = App is working!

---

## 🚨 Troubleshooting

### "App won't install"
**Solution**:
```powershell
# Uninstall old version first
flutter uninstall -d 8bab44b57d88

# Try install again
flutter run -d 8bab44b57d88 --flavor posApp
```

### "Installation cancelled by user"
**Cause**: Device security prompt  
**Solution**:
1. On device, check notification
2. Confirm installation permission
3. Retry from terminal

### "Device not found"
**Solution**:
```powershell
# Kill and restart ADB
adb kill-server
Start-Sleep 2
adb start-server

# Check again
flutter devices
```

If still not found:
1. Unlock device
2. Check USB connection
3. On device: Settings → Developer Options → USB Debugging (enable)
4. On device: Revoke existing USB debugging authorizations
5. Unplug and replug USB cable

### "App crashes on startup"
Check device logcat:
```powershell
$adb = "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe"
& $adb -s 8bab44b57d88 logcat | Select-String "flutter"
```

Look for error messages. Common causes:
- Missing business setup
- Shift not started
- Permission denied

### "Products don't show"
- Check database initialized (takes 2-3 seconds on first launch)
- Try scrolling the product grid
- Check Settings → Reload Products

---

## 📊 Expected Behavior

### First Launch
- [ ] Splash screen (1-2 sec)
- [ ] Lock screen (if configured)
- [ ] Business session check
- [ ] Shift start dialog
- [ ] Main POS screen loads

### Success Indicators
- ✅ No crashes
- ✅ Products visible
- ✅ Calculations correct
- ✅ Payment processes
- ✅ Receipt generates
- ✅ Can complete transaction

### Red Flags
- ❌ App crashes on launch
- ❌ Products don't load after 5 seconds
- ❌ Tapping items doesn't work
- ❌ Totals calculating wrong
- ❌ Can't proceed to payment
- ❌ Can't complete checkout

---

## 📝 Testing Log

```
Installation Method Used: [ ] Flutter [ ] ADB [ ] Manual
Time Started: ____:____
Device Ready: [ ] YES [ ] NO
App Installed: [ ] YES [ ] NO
App Launching:[ ] YES [ ] NO
Main POS Screen: [ ] YES [ ] NO

Quick Sanity Check:
- Add Item: [ ] PASS [ ] FAIL
- View Cart: [ ] PASS [ ] FAIL
- Adjust Quantity: [ ] PASS [ ] FAIL
- Checkout: [ ] PASS [ ] FAIL
- Payment: [ ] PASS [ ] FAIL
- Receipt: [ ] PASS [ ] FAIL
- Return to POS: [ ] PASS [ ] FAIL

Overall Result: [ ] PASS [ ] FAIL
Time Completed: ____:____
Duration: ___ minutes
```

---

## 🎯 Next Steps After Launch

Once app is running and sanity check passes:

1. **Open Full Testing Checklist**
   - See: [DEVICE_TESTING_CHECKLIST.md](DEVICE_TESTING_CHECKLIST.md)

2. **Test All 3 Modes**
   - Retail Mode (30-45 min)
   - Cafe Mode (20-30 min)
   - Restaurant Mode (20-30 min)

3. **Document Results**
   - Record any crashes or issues
   - Note unexpected behavior
   - Collect screenshots if problems

4. **Final Report**
   - Mark PASS/FAIL for each mode
   - List any bugs found
   - Make recommendation for release

---

**Ready to test? Let's go! 🚀**

Device: 24075RP89G  
APK: app-posapp-release.apk (93.7 MB)  
Status: Ready for installation

