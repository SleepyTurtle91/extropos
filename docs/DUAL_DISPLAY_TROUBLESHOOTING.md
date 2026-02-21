# Dual Display Troubleshooting Guide

## 🔴 Issue: Customer Display Stuck on Welcome Screen

**Symptom**: Customer-facing display shows "Welcome" message but does NOT update when cart items are added on the main POS screen.

**Last Known Working**: v1.0.6 (confirmed real-time updates worked)  
**Current Version**: v1.0.7 (YouTube feature added)  
**Date Reported**: 2025-11-25

---

## 🔍 Root Cause Analysis

### Architecture Overview

```text
┌─────────────────────────────────────────────────────────────┐
│                     MAIN POS SCREEN                          │
│  (Retail/Cafe/Restaurant POS Screen)                        │
│                                                              │
│  addToCart() ──► _updateDualDisplay()                       │
│                         │                                    │
│                         ▼                                    │
│  DualDisplayService.showCartItemsFromObjects()              │
│                         │                                    │
│                         ▼                                    │
│  IminViceScreen.sendMsgToViceScreen('CART_UPDATE', ...)    │
│                         │                                    │
└─────────────────────────┼──────────────────────────────────┘
                          │
                          │ IPC Stream (imin_vice_screen plugin)
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              CUSTOMER DISPLAY (Vice Screen)                  │
│  ViceCustomerDisplayScreen                                  │
│                                                              │
│  _viceScreenPlugin.viceStream.listen((event) {...})        │
│                         │                                    │
│                         ▼                                    │
│  Parse 'CART_UPDATE' event                                  │
│                         │                                    │
│                         ▼                                    │
│  setState(() { _cartItems = ... })                          │
│                         │                                    │
│                         ▼                                    │
│  Render cart display OR YouTube video                       │
└─────────────────────────────────────────────────────────────┘

```text


### Potential Failure Points



#### 1. **Main POS Screen - Event Dispatch**


**File**: `lib/screens/retail_pos_screen.dart` (or cafe/restaurant variants)

**Check**: Is `_updateDualDisplay()` being called?


```dart
// Line 258-268
Future<void> _updateDualDisplay() async {
  try {
    await DualDisplayService().showCartItemsFromObjects(
      cartItems,
      BusinessInfo.instance.currencySymbol,
    );
  } catch (e) {
    developer.log('DualDisplay cart update failed: $e'); // ← Check logs!
  }
}

```text

**Verification Steps**:

1. Open ADB logcat: `adb logcat | grep "DualDisplay"`
2. Add item to cart on main screen
3. Look for: `"DualDisplay cart update failed"` (indicates exception)

**Common Causes**:


- ❌ Exception thrown in `_updateDualDisplay()` (silent failure)

- ❌ `cartItems` list is empty (no data to send)

- ❌ `BusinessInfo.instance.currencySymbol` is null

---


#### 2. **DualDisplayService - Data Transmission**


**File**: `lib/services/dual_display_service.dart`

**Check**: Is the service sending data correctly?


```dart
// Line 230-262
Future<void> showCartItems(
  List<Map<String, dynamic>> items,
  double subtotal,
  String currency,
) async {
  developer.log('DualDisplay: showCartItems called - items: ${items.length}'); // ← Should appear in logs

  if (!isAvailable) {
    developer.log('DualDisplay: Not available, skipping'); // ← Fatal if this appears!
    return;
  }

  try {
    await _viceScreenPlugin.doubleScreenOpen();
    
    final cartData = {
      'items': items,
      'subtotal': subtotal,
      'currency': currency,
    };

    await _viceScreenPlugin.sendMsgToViceScreen(
      'CART_UPDATE',
      params: {'cartData': jsonEncode(cartData)},
    );

    developer.log('DualDisplay: Cart data sent via stream'); // ← Success indicator
  } catch (e) {
    developer.log('DualDisplay: Failed to send cart data: $e'); // ← Exception!
  }
}

```text

**Verification Steps**:


```bash
adb logcat | grep "DualDisplay:"

```text

**Expected Logs** (when cart item added):


```text
DualDisplay: showCartItems called - items: 1, subtotal: 12.50

DualDisplay: Cart data sent via stream

```text

**Common Causes**:


- ❌ `isAvailable` is `false` (dual display not detected)

- ❌ `_viceScreenPlugin.doubleScreenOpen()` fails

- ❌ `sendMsgToViceScreen()` throws exception

- ❌ JSON encoding fails (malformed cart data)

---


#### 3. **Vice Screen Stream - Event Reception**


**File**: `lib/screens/vice_customer_display_screen.dart`

**Check**: Is the customer display receiving events?


```dart
// Line 44-135
_viceScreenPlugin.viceStream.listen((event) {
  try {
    developer.log('Vice: Received stream event: $event'); // ← Should log ALL events

    String? method;
    dynamic arguments;

    if (eventData is MethodCall) {
      method = eventData.method;
      arguments = eventData.arguments;
    } else if (eventData is Map) {
      method = eventData['method'] ?? eventData['data'];
      arguments = eventData['params'] ?? eventData['arguments'];
    }

    developer.log('Vice: Stream event method: $method, args: $arguments'); // ← Debug parsing

    if (method != 'CART_UPDATE') {
      return; // ← Ignoring non-cart events
    }

    final String? cartDataString = (arguments is Map)
        ? (arguments['cartData'] ?? arguments['params']?['cartData'])
        : null;

    if (cartDataString != null) {
      final cartData = jsonDecode(cartDataString);
      setState(() {
        _cartItems = ...; // ← Should trigger rebuild
      });
      developer.log('Vice: Cart updated with ${_cartItems.length} items'); // ← Success!
    }
  } catch (e) {
    developer.log('Vice: Error handling stream event: $e'); // ← Parse error
  }
});

```text

**Verification Steps**:


```bash
adb logcat | grep "Vice:"

```text

**Expected Logs** (when cart item added):


```text
Vice: Received stream event: {method: CART_UPDATE, params: {...}}
Vice: Stream event method: CART_UPDATE, args: {cartData: "{...}"}
Vice: Cart updated with 1 items

```text

**Common Causes**:


- ❌ Stream listener not active (vice display not initialized)

- ❌ Event format mismatch (method name parsing fails)

- ❌ JSON decode fails (corrupted data)

- ❌ `setState()` not called (UI doesn't rebuild)

- ❌ YouTube video takes priority (display logic bug)

---


#### 4. **Vice Screen Rendering - UI Display**


**File**: `lib/screens/vice_customer_display_screen.dart`

**Check**: Is the build method showing the cart?


```dart
// Line 203-245
@override
Widget build(BuildContext context) {
  // If cart is empty, show YouTube video or welcome screen
  if (_cartItems.isEmpty) {  // ← Bug: Cart might have items but condition is wrong!
    // Show YouTube if enabled
    if (_youtubeEnabled && _youtubeController != null && !_isLoadingVideo) {
      return YoutubePlayer(...); // ← YouTube takes priority
    }
    
    // Show loading
    if (_youtubeEnabled && _isLoadingVideo) {
      return CircularProgressIndicator(); // ← Stuck on loading?
    }
    
    // Default welcome screen
    return WelcomeScreen(); // ← This is what you're seeing
  }
  
  // Show cart display when items present
  return CartDisplayWidget(); // ← This SHOULD be shown
}

```text

**Verification Steps**:

1. Add debug log before `if (_cartItems.isEmpty)`:

   ```dart
   developer.log('Vice: Rendering - cart has ${_cartItems.length} items, YouTube: $_youtubeEnabled');
   ```

1. Check logs:

   ```bash
   adb logcat | grep "Vice: Rendering"
   ```

**Common Causes**:

- ❌ `_cartItems.isEmpty` is `true` despite receiving data (state not updated)

- ❌ YouTube loading state is stuck (`_isLoadingVideo = true` forever)

- ❌ YouTube controller is non-null but broken (blocks cart display)

- ❌ Widget tree doesn't rebuild after `setState()`

---

## 🛠️ Diagnostic Procedures

### Level 1: Quick Checks (5 minutes)

1. **Verify dual display is enabled**:

   - Settings → Dual Display Settings → Toggle should be ON

2. **Check device compatibility**:

   ```bash
   adb shell getprop ro.product.model
   # Expected: I24D02 (iMin Swan 2)

   ```

3. **Restart both screens**:

   - Close app completely

   - Reopen app

   - Navigate to POS screen

   - Check if vice screen initializes

---

### Level 2: Log Analysis (10 minutes)

**Full log capture**:

```bash
adb logcat -c  # Clear logs

adb logcat | grep -E "DualDisplay:|Vice:" > dual_display_debug.log

```text

**Add item to cart on main screen**

**Stop logging** (Ctrl+C)

**Analyze log file**:

**✅ Expected Sequence** (working scenario):


```text
DualDisplay: showCartItems called - items: 1, subtotal: 12.50

DualDisplay: Cart data sent via stream
Vice: Received stream event: {method: CART_UPDATE, ...}
Vice: Stream event method: CART_UPDATE, args: {...}
Vice: Cart updated with 1 items
Vice: Rendering - cart has 1 items, YouTube: true

Vice: YouTube paused - cart now active

```text

**❌ Failure Patterns**:

**Pattern A - No DualDisplay logs**:


```text

# Nothing appears

```text

→ **Problem**: `_updateDualDisplay()` not being called  
→ **Fix**: Check `addToCart()` method calls `_updateDualDisplay()`

**Pattern B - "Not available" error**:


```text
DualDisplay: Not available, skipping cart display

```text

→ **Problem**: Dual display not detected  
→ **Fix**: Check Settings → Enable dual display

**Pattern C - No Vice logs**:


```text
DualDisplay: Cart data sent via stream

# No "Vice: Received" logs

```text

→ **Problem**: Vice screen not listening or stream broken  
→ **Fix**: Restart vice display, check if initialized

**Pattern D - Parse error**:


```text
Vice: Received stream event: null
Vice: Error handling stream event: type 'Null' is not a subtype of type 'String'

```text

→ **Problem**: Event format mismatch  
→ **Fix**: Check `sendMsgToViceScreen()` params format

**Pattern E - State not updating**:


```text
Vice: Cart updated with 1 items
Vice: Rendering - cart has 0 items, YouTube: true

```text

→ **Problem**: `setState()` not working or race condition  
→ **Fix**: Check `setState()` is inside the stream listener

**Pattern F - YouTube blocking**:


```text
Vice: Cart updated with 1 items
Vice: Rendering - cart has 1 items, YouTube: true

Vice: YouTube paused - cart now active

# But screen still shows YouTube or loading

```text

→ **Problem**: UI rendering logic bug  
→ **Fix**: Check `build()` method cart display condition

---


### Level 3: Code Instrumentation (15 minutes)


**Add debug logs to key locations**:

**1. In `retail_pos_screen.dart` (line 160)**:


```dart
void addToCart(Product product) {
  developer.log('POS: Adding ${product.name} to cart'); // ← ADD THIS
  setState(() {
    final existingIndex = cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existingIndex >= 0) {
      cartItems[existingIndex].quantity++;
    } else {
      cartItems.add(CartItem(product: product));
    }
  });
  developer.log('POS: Cart now has ${cartItems.length} items'); // ← ADD THIS
  await _updateDualDisplay();
  developer.log('POS: Dual display update completed'); // ← ADD THIS
}

```text

**2. In `dual_display_service.dart` (line 240)**:


```dart
if (!isAvailable) {
  developer.log('DualDisplay: isAvailable = $isAvailable'); // ← ADD THIS
  developer.log('DualDisplay: Initialization status: ${_viceScreenPlugin.toString()}'); // ← ADD THIS
  return;
}

```text

**3. In `vice_customer_display_screen.dart` (line 90)**:


```dart
setState(() {
  developer.log('Vice: BEFORE setState - _cartItems.length = ${_cartItems.length}'); // ← ADD THIS
  _cartItems = itemsJson.map((data) => CartItem.fromDisplayJson(data)).toList();
  _subtotal = (cartData['subtotal'] as num).toDouble();
  _currency = cartData['currency'] as String;
  developer.log('Vice: AFTER setState - _cartItems.length = ${_cartItems.length}'); // ← ADD THIS

});

```text

**4. In `vice_customer_display_screen.dart` (line 203)**:


```dart
@override
Widget build(BuildContext context) {
  developer.log('Vice: build() called - _cartItems.length = ${_cartItems.length}, _youtubeEnabled = $_youtubeEnabled, _isLoadingVideo = $_isLoadingVideo'); // ← ADD THIS
  
  if (_cartItems.isEmpty) {
    developer.log('Vice: Showing welcome/YouTube (cart is empty)'); // ← ADD THIS
    // ...
  } else {
    developer.log('Vice: Showing cart display (${_cartItems.length} items)'); // ← ADD THIS
    // ...
  }
}

```text

**Rebuild and test**:


```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
adb logcat -c
adb logcat | grep -E "POS:|DualDisplay:|Vice:"

```text

---


### Level 4: YouTube Conflict Check (v1.0.7 specific)


**Hypothesis**: YouTube feature may be blocking cart display

**Test 1 - Disable YouTube**:

1. Settings → Dual Display Settings
2. Toggle **YouTube Video Display** to OFF

3. Save and restart vice display
4. Try adding cart items
5. Does cart display appear now?

**Test 2 - Check YouTube controller state**:

Add to `vice_customer_display_screen.dart` (line 205):


```dart
@override
Widget build(BuildContext context) {
  developer.log('Vice: YouTube controller state: ${_youtubeController?.value.playerState}'); // ← ADD THIS
  developer.log('Vice: YouTube URL: $_youtubeUrl'); // ← ADD THIS
  
  if (_cartItems.isEmpty) {
    // ...
  }
}

```text

**Expected**: If YouTube is causing issues, you'll see:


```text
Vice: YouTube controller state: playing
Vice: Cart updated with 1 items
Vice: Rendering - cart has 1 items, YouTube: true

Vice: YouTube paused - cart now active

# But screen still shows video frame

```text

**Fix**: Ensure `_youtubeController.pause()` is called AND cart widget is rendered

---


## 🔧 Common Fixes



### Fix 1: Dual Display Not Enabled


**Symptom**: `DualDisplay: Not available, skipping`

**Solution**:

1. Open Settings
2. Dual Display Settings
3. Toggle ON "Dual Display"
4. Toggle ON "Show Order Total"
5. Save

---


### Fix 2: Vice Screen Not Initialized


**Symptom**: No "Vice:" logs appear

**Solution**:

1. Completely close app (force stop)
2. Reopen app
3. Navigate to mode selection
4. Select business mode
5. Vice screen should auto-open

**Alternative**: Manually open vice screen:


```dart
// In main POS screen initState()
await DualDisplayService().initialize();
await IminViceScreen().doubleScreenOpen();

```text

---


### Fix 3: Stream Listener Not Active


**Symptom**:


```text
DualDisplay: Cart data sent via stream

# No "Vice: Received" logs

```text

**Solution**:
Check `vice_customer_display_screen.dart` line 44 - ensure listener is set up in `initState()`:


```dart
@override
void initState() {
  super.initState();
  _loadYouTubeSettings();
  _showWelcome();

  // THIS MUST BE HERE:
  _viceScreenPlugin.viceStream.listen((event) {
    // ... event handling
  });
}

```text

---


### Fix 4: JSON Parsing Error


**Symptom**:


```text
Vice: Error extracting cart data: type 'Null' is not a subtype of type 'String'

```text

**Solution**:
Ensure `cartData` is JSON-encoded in `dual_display_service.dart`:


```dart
await _viceScreenPlugin.sendMsgToViceScreen(
  'CART_UPDATE',
  params: {'cartData': jsonEncode(cartData)}, // ← Must use jsonEncode!
);

```text

---


### Fix 5: YouTube Blocking Cart Display


**Symptom**:


```text
Vice: Cart updated with 1 items
Vice: YouTube paused - cart now active

# But screen still shows YouTube

```text

**Solution**:
Update `vice_customer_display_screen.dart` build method to prioritize cart:


```dart
@override
Widget build(BuildContext context) {
  // PRIORITY: Show cart if items exist, regardless of YouTube
  if (_cartItems.isNotEmpty) {
    return CartDisplayWidget(); // ← Cart takes absolute priority
  }
  
  // ONLY show YouTube if cart is EMPTY
  if (_youtubeEnabled && _youtubeController != null && !_isLoadingVideo) {
    return YoutubePlayer(...);
  }
  
  return WelcomeScreen();
}

```text

---


### Fix 6: State Not Updating


**Symptom**:


```text
Vice: BEFORE setState - _cartItems.length = 0

Vice: AFTER setState - _cartItems.length = 0

# Cart items not being set

```text

**Solution**:
Ensure `setState()` is called with proper data:


```dart
setState(() {
  _cartItems = itemsJson
      .map((data) => CartItem.fromDisplayJson(data))
      .toList();
  _subtotal = (cartData['subtotal'] as num).toDouble();
  _currency = cartData['currency'] as String;
});

```text

---


## 📊 Comparison: v1.0.6 vs v1.0.7



### What Changed in v1.0.7?


**YouTube Feature Added**:


- New controller: `_youtubeController`

- New state variables: `_youtubeEnabled`, `_youtubeUrl`, `_isLoadingVideo`

- New UI logic: YouTube player in `build()` method

- New pause/resume logic: In cart stream listener


### Potential Regression Points


1. **Build Method Complexity**:

   - **v1.0.6**: Simple `if (_cartItems.isEmpty)` check

   - **v1.0.7**: Nested conditions (YouTube enabled → loading → cart → welcome)

   - **Risk**: Cart display might be skipped due to wrong condition order

2. **State Variables**:

   - **v1.0.6**: Only `_cartItems`, `_subtotal`, `_currency`

   - **v1.0.7**: Added `_youtubeController`, `_isLoadingVideo`, etc.

   - **Risk**: Race condition between YouTube initialization and cart update

3. **Widget Tree**:

   - **v1.0.6**: Direct cart display

   - **v1.0.7**: YoutubePlayer wrapping

   - **Risk**: YouTube widget might not dispose properly, blocking cart

---


## 🎯 Recommended Debug Flow



```text
START
  │
  ├─ 1. Check Settings (Dual Display enabled?)
  │    ├─ NO → Enable it → Test
  │    └─ YES → Continue
  │
  ├─ 2. Disable YouTube Feature (Temporary)
  │    ├─ Settings → YouTube Display OFF
  │    ├─ Test cart display
  │    ├─ WORKS? → YouTube conflict confirmed
  │    └─ FAILS? → Continue
  │
  ├─ 3. Capture Logs
  │    ├─ adb logcat | grep -E "DualDisplay:|Vice:"
  │    ├─ Add item to cart
  │    ├─ Analyze log patterns (see Level 2 above)
  │    └─ Identify failure point
  │
  ├─ 4. Add Debug Instrumentation
  │    ├─ Add logs to key methods
  │    ├─ Rebuild APK
  │    ├─ Test again
  │    └─ Pinpoint exact failure location
  │
  └─ 5. Apply Specific Fix
       ├─ Stream listener not active → Restart vice
       ├─ JSON parse error → Check data format
       ├─ YouTube blocking → Reorder build() logic
       └─ State not updating → Fix setState()

```text

---


## 🚨 Emergency Rollback


If dual display is critical and debugging takes too long:

**Rollback to v1.0.6**:


```bash

# Download v1.0.6 APK (last known working version)

wget https://github.com/Giras91/flutterpos/releases/download/v1.0.6-.../app-release.apk


# Install

adb install -r app-release.apk

```text

**Restore to working state** while YouTube issue is fixed offline.

---


## 📝 Report Template


When reporting the issue, include:


```text
**Version**: v1.0.7
**Device**: iMin Swan 2 (Model I24D02)
**Business Mode**: [Retail/Cafe/Restaurant]
**YouTube Enabled**: [Yes/No]

**Symptoms**:

- [ ] Vice screen shows welcome message only

- [ ] Vice screen shows YouTube video

- [ ] Vice screen shows loading spinner

- [ ] Vice screen is blank

**Logs Captured**:

```text

[Paste relevant logs here]


```text

**Steps to Reproduce**:
1. Open [Business Mode]
2. Add item "[Product Name]"
3. Check vice screen

**Expected**: Cart with 1 item shown
**Actual**: [Description]

```text

---


## 🔗 Related Documentation


- **Architecture**: `DUAL_DISPLAY_STREAMING.md`

- **YouTube Feature**: `docs/YOUTUBE_DISPLAY_FEATURE.md`

- **Code**:

  - `lib/services/dual_display_service.dart`

  - `lib/screens/vice_customer_display_screen.dart`

  - `lib/screens/retail_pos_screen.dart`

---

**Last Updated**: 2025-11-25  
**Status**: Active Investigation  
**Priority**: High (affects customer experience)
