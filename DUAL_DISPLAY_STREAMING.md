# Dual Display Stream-Based Communication

## Overview

The FlutterPOS dual display now uses proper stream-based data communication via the `imin_vice_screen` package. This replaces the previous text-based display approach with a robust event-driven architecture that transmits structured cart data between the main app and the customer-facing vice screen.

## Architecture

### Problem with Previous Approach

- Vice screen runs on a **separate Flutter engine**

- Cannot access main app state (Provider, Riverpod, etc.)

- Simple text commands (`displayOnViceScreen()`) don't support dynamic cart updates

- No real-time synchronization between screens

### Stream-Based Solution

The vice screen requires **bidirectional data streaming**:

- **Main Screen** → Sends cart data via `sendMsgToViceScreen()`

- **Vice Screen** → Listens via `viceStream.listen()`

## Implementation Details

### 1. CartItem JSON Serialization

**Location:** `lib/models/cart_item.dart`

Added two methods to CartItem:

```dart
/// Serialize to JSON for streaming
Map<String, dynamic> toJson() {
  return {
    'productName': product.name,
    'productPrice': product.price,
    'quantity': quantity,
    'modifiers': modifiers.map((m) => m.name).toList(),
    'priceAdjustment': priceAdjustment,
    'discountPerUnit': discountPerUnit,
    'finalPrice': finalPrice,
    'totalPrice': totalPrice,
    'seatNumber': seatNumber,
  };
}

/// Deserialize from JSON (for vice screen)
factory CartItem.fromDisplayJson(Map<String, dynamic> json) {
  // Creates minimal Product + ModifierItem objects for display
  // Reconstructs CartItem from JSON data
}

```

### 2. DualDisplayService Stream Communication

**Location:** `lib/services/dual_display_service.dart`

**Sending cart updates:**

```dart
Future<void> showCartItems(
  List<Map<String, dynamic>> items,
  double subtotal,
  String currency,
) async {
  final cartData = {
    'items': items,
    'subtotal': subtotal,
    'currency': currency,
  };
  
  await _viceScreenPlugin.sendMsgToViceScreen(
    'CART_UPDATE',
    params: {'cartData': jsonEncode(cartData)},
  );
}

```

**Convenience method for CartItem objects:**

```dart
Future<void> showCartItemsFromObjects(
  List<CartItem> cartItems,
  String currency,
) async {
  final items = cartItems.map((item) => item.toJson()).toList();
  final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  await showCartItems(items, subtotal, currency);
}

```

### 3. Vice Screen Stream Listener

**Location:** `lib/screens/vice_customer_display_screen.dart`

**Listening for cart updates:**

```dart
@override
void initState() {
  super.initState();
  
  // Listen to cart updates from main screen
  _viceScreenPlugin.viceStream.listen((event) {
    try {
      // Extract cart data from event
      final String? cartDataString = event['cartData'] as String?;
      
      if (cartDataString != null) {
        final Map<String, dynamic> cartData = jsonDecode(cartDataString);
        final List<dynamic> itemsJson = cartData['items'] as List;
        
        setState(() {
          _cartItems = itemsJson
              .map((data) => CartItem.fromDisplayJson(data as Map<String, dynamic>))
              .toList();
          _subtotal = (cartData['subtotal'] as num).toDouble();
          _currency = cartData['currency'] as String;
          _welcomeTimer?.cancel(); // Stop welcome screen when cart active
        });
      }
    } catch (e) {
      developer.log('Vice: Error handling stream event: $e');
    }
  });
}

```

**UI Display:**

- Shows **welcome screen** when cart is empty

- Shows **cart items** with modifiers, quantity, prices when active

- Updates **subtotal footer** in real-time

- Clean card-based layout with proper scrolling

### Promotional Image and Slideshow

The vice/customer display supports multiple display modes:

#### Promotional Image

- **Local File Support**: Images/videos can be stored locally on device in `app_documents/promo_images/` directory

- **URL Support**: Remote URLs are still supported for backward compatibility

- **Configuration**: Set via Dual Display Settings → "Promotional Image/Video" section

- **Storage**: Local files are copied to app storage, path stored in `vice_promo_image_url` SharedPreferences

- **Fallback**: If unset, uses `BusinessInfo.instance.logo`

- **File Types**: Supports JPG, PNG, GIF, MP4, and other common image/video formats

#### Product Slideshow

- **Idle Display**: When cart is empty, shows slideshow of product images

- **Configuration**: Enable via Dual Display Settings → "Product Slideshow" toggle

- **Image Management**: Add/remove images via file picker, stored in `app_documents/slideshow_images/`

- **Storage**: Image paths stored in `vice_slideshow_images` SharedPreferences as StringList

- **Timing**: Auto-advances every 5 seconds, pauses when cart has items, resumes when cart cleared

- **Error Handling**: Shows broken image icon if file is missing/corrupted

- **Navigation**: Visual indicator dots show current position in slideshow

#### Product Images in Cart

- **Optional Display**: Enable via "Show Product Images in Cart" setting

- **Storage**: Product images stored in `Product.imagePath` field (local file paths)

- **Layout**: When enabled, shows 60x60 product image instead of quantity number in cart display

- **Fallback**: If image unavailable, falls back to quantity display

- **Performance**: Images cached by Flutter's Image widget for smooth scrolling

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      MAIN SCREEN (POS)                       │
│                                                              │
│  User adds items to cart                                    │
│         ↓                                                    │
│  DualDisplayService.showCartItemsFromObjects()              │
│         ↓                                                    │
│  CartItem.toJson() → JSON serialization                     │
│         ↓                                                    │
│  sendMsgToViceScreen('CART_UPDATE', params: {...})          │
└─────────────────────────────────────────────────────────────┘
                          ↓ (Stream Message)
┌─────────────────────────────────────────────────────────────┐
│                   VICE SCREEN (Customer)                     │
│                                                              │
│  viceStream.listen((event) { ... })                         │
│         ↓                                                    │
│  jsonDecode(event['cartData'])                              │
│         ↓                                                    │
│  CartItem.fromDisplayJson() → CartItem objects              │
│         ↓                                                    │
│  setState() → UI updates with cart data                     │
└─────────────────────────────────────────────────────────────┘

```

## Usage in POS Screens

### Retail Mode

```dart
void _checkout() async {
  final dualDisplay = DualDisplayService();
  await dualDisplay.showCartItemsFromObjects(
    cartItems,
    BusinessInfo.instance.currencySymbol,
  );
  // ... checkout logic
}

```

### Cafe Mode

```dart
void _placeOrder() async {
  final dualDisplay = DualDisplayService();
  await dualDisplay.showCartItemsFromObjects(
    cartItems,
    BusinessInfo.instance.currencySymbol,
  );
  // ... order placement
}

```

### Restaurant Mode

```dart
void _updateTableCart() async {
  final dualDisplay = DualDisplayService();
  await dualDisplay.showCartItemsFromObjects(
    table.orders,
    BusinessInfo.instance.currencySymbol,
  );
}

```

## Testing Checklist

### On Swan 2 Hardware

1. **Initial State**

   - [ ] Vice screen shows welcome message when no cart data

   - [ ] Business name/logo displays correctly

   - [ ] Screen stays awake (keep-alive timer working)

2. **Adding Items**

   - [ ] Add item to cart on main screen

   - [ ] Vice screen receives update immediately

   - [ ] Item name, price, quantity display correctly

   - [ ] Subtotal calculates correctly

   - [ ] Product images display in cart when enabled

3. **Modifiers**

   - [ ] Items with modifiers show modifier names

   - [ ] Modifier-adjusted prices calculate correctly

   - [ ] Multiple modifiers display properly

4. **Quantity Updates**

   - [ ] Increase quantity → Vice screen updates

   - [ ] Decrease quantity → Vice screen updates

   - [ ] Remove item → Vice screen updates

5. **Multiple Items**

   - [ ] Multiple different items display in list

   - [ ] Scrolling works for many items

   - [ ] Subtotal sums all items correctly

6. **Promotional Features**

   - [ ] Local promo image displays correctly in cart view

   - [ ] Slideshow starts when cart is empty

   - [ ] Slideshow pauses when cart has items

   - [ ] Slideshow resumes when cart cleared

   - [ ] Slideshow advances every 5 seconds

   - [ ] Slideshow indicator dots work correctly

   - [ ] Missing slideshow images show error icon

7. **File Management**

   - [ ] File picker works for promo images

   - [ ] File picker works for slideshow images

   - [ ] Files are copied to app storage correctly

   - [ ] Settings persist across app restarts

   - [ ] Product image paths work in cart display

8. **Edge Cases**

   - [ ] Clear cart → Returns to welcome screen or slideshow

   - [ ] Checkout → Clear vice display or show thank you

   - [ ] App restart → Vice screen reconnects and reloads settings

   - [ ] Network latency → Updates eventually sync

   - [ ] Corrupted image files → Graceful fallback

   - [ ] Empty slideshow → Falls back to welcome screen

## Debug Logging

Stream events are logged for troubleshooting:

```dart
// Main screen (sending)
developer.log('DualDisplay: Cart data sent via stream');
developer.log('DualDisplay: Failed to send cart data: $e');

// Vice screen (receiving)
developer.log('Vice: Received stream event: $event');
developer.log('Vice: Cart updated with ${_cartItems.length} items');
developer.log('Vice: Error handling stream event: $e');

```

Use `adb logcat` to monitor stream communication:

```bash
adb logcat | grep -E "(DualDisplay|Vice)"

```

## Known Limitations

1. **Event Structure Uncertainty:** The exact structure of events from `viceStream` is not well-documented in imin_vice_screen. Current implementation uses dynamic access with error handling.

2. **One-Way Communication:** Currently only main → vice. Vice screen doesn't send data back to main screen (can be added using `sendMsgToMainScreen()` if needed).

3. **No Persistence:** Vice screen state is in-memory. If vice screen crashes, it resets to welcome screen until next cart update.

4. **Performance:** Large carts (100+ items) may have slight delay in JSON serialization. Consider pagination for extreme cases.

5. **Video Support:** While MP4 files can be selected and stored, the current implementation only displays static images. Video playback would require additional video player integration.

6. **File Size Limits:** No explicit file size limits enforced. Large images may impact performance or storage.

## Future Enhancements

- Add checkout confirmation message to vice screen

- Show promotional content on welcome screen

- Display QR codes for payment

- Customer-facing order number display for cafe mode

- Animated transitions for cart updates

- Touch interaction on vice screen (if hardware supports)

- Video playback support for promotional content

- Bulk image import for slideshow

- Image compression/optimization for storage efficiency

- Slideshow transition animations

- Product image upload in product management screens

## Related Files

- `lib/models/cart_item.dart` - JSON serialization

- `lib/models/product.dart` - Added imagePath field for product images

- `lib/services/dual_display_service.dart` - Stream message sending

- `lib/screens/vice_customer_display_screen.dart` - Stream listener, slideshow, local file support

- `lib/screens/dual_display_settings_screen.dart` - File management UI, slideshow controls

- `lib/main.dart` - Vice screen entry point detection

## SharedPreferences Keys

- `vice_promo_image_url` - Path to promotional image/video (local or URL)

- `vice_slideshow_enabled` - Boolean toggle for slideshow feature

- `vice_slideshow_images` - StringList of local file paths for slideshow

- `vice_show_product_images` - Boolean toggle for product images in cart

## File Storage Structure

```
app_documents/
├── promo_images/          # Promotional images/videos

│   └── [filename]        # Copied from user selection

└── slideshow_images/     # Product slideshow images

    └── [filename]        # Copied from user selection

```

## Commit History

**Latest Commit:** Enhanced vice display with local media support  
**Features Added:** Local file storage, product slideshow, cart image display  
**Files Modified:** Product model, settings screen, vice screen, documentation

---

**Last Updated:** Session 13 Part 12 - Local Media Implementation Complete  
**Hardware:** Imin Swan 2 Dual Display POS  
**Package:** imin_vice_screen ^1.0.0
