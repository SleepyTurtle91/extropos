# Customer Display 70/30 Split Layout

## Overview

The **ViceCustomerDisplayScreen** has been completely refactored to provide a

premium dual-screen experience for POS devices. This implementation features a
**70/30 split layout** where media content occupies 70% of the screen and the

transaction cart appears as an animated overlay on the right 30%.

---

## Architecture

### Stack-Based Layout

```text
┌─────────────────────────────────────────────────────┐
│                    Scaffold                          │
│  ┌────────────────────────────────────────────────┐ │
│  │           Media Layer (Always Rendered)        │ │
│  │  - Slideshow (if enabled)                      │ │

│  │  - Video Player (future)                       │ │

│  │  - Welcome Screen (default)                    │ │

│  │                                                 │ │
│  │                                                 │ │
│  │                 70% Width                       │ │
│  │                                                 │ │
│  └────────────────────────────────────────────────┘ │
│                                                       │
│  ┌────────────────────┐                              │
│  │   Cart Overlay     │ ← AnimatedPositioned         │
│  │   (30% Width)      │   (slides from right)        │
│  │                    │                              │
│  │ • Header           │                              │
│  │ • Scrollable Items │                              │
│  │ • Fixed Totals     │                              │
│  └────────────────────┘                              │
└─────────────────────────────────────────────────────┘

```

### Key Components

1. **Base Layer**: Media content (never disposed, prevents flickering)
2. **Overlay Layer**: Animated cart panel (slides in when items added)

---

## Features

### 1. Full-Screen Media When Cart Empty

When `cartItems.isEmpty`:

- Media layer fills **entire screen** (100% width)

- No cart overlay visible

- Options:

  - **Slideshow**: Auto-rotating promotional images (5s interval)

  - **Welcome Screen**: Business branding with store icon

  - **Video Player**: YouTube/local video (future implementation)

### 2. Animated 70/30 Split When Cart Has Items

When `cartItems.isNotEmpty`:

- Media layer remains at 70% width (visible on left)

- Cart panel **slides in from right** (30% width)

- **Animation**: 400ms cubic easing

- **Opacity fade**: 300ms for premium feel

### 3. Dark Theme Cart Panel

#### Styling

- **Background**: `Colors.black87` (semi-transparent)

- **Text**: White with high contrast

- **Border**: Subtle white border (10% opacity)

#### Structure

```dart
┌─────────────────────────────┐
│  Your Order                 │
│  No. 12345                  │
│                             │
│  Item         Qty    Price  │ ← Header
├─────────────────────────────┤
│  [img] Coffee   x2   RM 10  │
│  [img] Burger   x1   RM 12  │ ← Scrollable
│  ...                        │
├─────────────────────────────┤
│  Subtotal         RM 22.00  │
│  Discount         RM  2.00  │ ← Fixed
│  Tax              RM  2.00  │   Bottom
│  ═══════════════════════    │   Totals
│  GRAND TOTAL      RM 22.00  │ ← Bold 24px
└─────────────────────────────┘

```

---

## Implementation Details

### Build Method

```dart
@override
Widget build(BuildContext context) {
  final bool hasCartItems = _cartItems.isNotEmpty;

  return Scaffold(
    backgroundColor: Colors.black,
    body: Stack(
      children: [
        // Base layer: Media (always rendered)
        Positioned.fill(
          child: _buildMediaLayer(),
        ),
        
        // Animated cart overlay (70/30 split)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
          right: hasCartItems ? 0 : -width * 0.3,
          width: width * 0.3,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: hasCartItems ? 1.0 : 0.0,
            child: _buildCartPanel(),
          ),
        ),
      ],
    ),
  );
}

```

### Media Layer Methods

- `_buildMediaLayer()`: Determines which content to show (slideshow/welcome/video)

- `_buildSlideshow()`: Full-screen image carousel with indicators

- `_buildWelcomeScreen()`: Branded welcome message with store icon

### Cart Panel Method

- `_buildCartPanel()`: Dark-themed cart with header, scrollable items, fixed totals

- `_buildTotalRow()`: Helper for consistent total row styling

---

## State Management

### Cart State Changes

When cart items are added/removed:

1. Main POS screen sends cart update via `IminViceScreen.viceStream`
2. `ViceCustomerDisplayScreen` receives stream event
3. `setState()` triggers rebuild
4. `AnimatedPositioned` animates cart position
5. `AnimatedOpacity` fades cart in/out

### Media Persistence

**CRITICAL**: Media layer is **always rendered** in the widget tree:

- Prevents disposal of video players or image widgets

- Eliminates flickering when cart appears/disappears

- Media continues playing seamlessly during transactions

---

## Responsive Behavior

### Portrait vs Landscape

The 70/30 split is **fixed** regardless of orientation:

- **Portrait**: Media on top 70%, cart overlays bottom 30%

- **Landscape**: Media on left 70%, cart overlays right 30%

### Screen Size Adaptation

- **Phone (< 600px)**: Cart width = 30% of screen width

- **Tablet (600-900px)**: Cart width = 30% of screen width

- **Desktop (> 900px)**: Cart width = 30% of screen width

**Consistent 30% cart width** across all device sizes ensures readable cart content.

---

## Animation Specifications

### Cart Slide-In

```dart
AnimatedPositioned(
  duration: const Duration(milliseconds: 400),
  curve: Curves.easeInOutCubic,
  right: hasCartItems ? 0 : -width * 0.3,
  // ...
)

```

- **Duration**: 400ms (premium feel)

- **Curve**: `easeInOutCubic` (smooth start/end)

- **Position**: Slides from off-screen right to `right: 0`

### Opacity Fade

```dart
AnimatedOpacity(
  duration: const Duration(milliseconds: 300),
  opacity: hasCartItems ? 1.0 : 0.0,
  // ...
)

```

- **Duration**: 300ms (faster than position for layered effect)

- **Opacity**: Fades from 0.0 to 1.0

---

## Cart Panel Details

### Header Section

- **Title**: "Your Order" (24px bold white)

- **Order Number**: "No. 12345" (16px white70)

- **Table Headers**: Item, Qty, Price (14px white70, letter-spacing 0.5)

### Scrollable Items List

Each item row contains:

- **Product Thumbnail** (50x50px, rounded corners, 20% white border) - if enabled

- **Item Name** (16px white, weight 500)

- **Modifiers** (13px white60) - if applicable

- **Quantity** (16px white, weight 600, center-aligned)

- **Price** (16px white, bold, right-aligned)

### Fixed Totals Section

- **Background**: `Colors.black.withOpacity(0.5)` (extra dark)

- **Top Border**: 2px white20

- **Rows**:

  - Subtotal (16px white70)

  - Discount (16px red.shade300) - only if > 0

  - Tax (16px white70)

  - **Grand Total** (24px white, bold, top border separator)

---

## Future Enhancements

### Video Player Integration

The architecture supports video players:

```dart
Widget _buildMediaLayer() {
  if (_videoEnabled && _videoController != null) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: VideoPlayer(_videoController!),
    );
  }
  // fallback to slideshow/welcome
}

```

**Recommended Packages**:

- `video_player`: Official Flutter video player

- `chewie`: Enhanced video player with controls

- `youtube_player_flutter`: YouTube integration

### Network Image Carousel

Replace slideshow images with network URLs:

```dart
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, progress) {
    return progress == null ? child : CircularProgressIndicator();
  },
)

```

### Promotional Overlay

Add promotional badges/banners over media:

```dart
Stack(
  children: [
    _buildMediaLayer(),
    Positioned(
      bottom: 20,
      right: 20,
      child: PromoBadge(text: '40% OFF', color: Colors.yellow),
    ),
  ],
)

```

---

## Hardware Integration

### Physical Dual-Screen Devices

**Supported Devices**:

- **Sunmi**: T2 mini, T2s, T3, D3 mini

- **Elo**: PayPoint Plus, I-Series

- **iMin**: Swan 2, M2 Max, D4 Pro

**Package**: `imin_vice_screen`

```dart
// Send cart update to vice screen
IminViceScreen().sendDataToVice(
  'CART_UPDATE',
  jsonEncode({
    'items': cartItems.map((item) => item.toJson()).toList(),
    'subtotal': subtotal,
    'totalNet': totalNet,
  }),
);

```

### Display Manager Setup

For devices with `presentation_displays`:

```dart
import 'package:presentation_displays/presentation_displays.dart';

// Get available displays
final displays = await PresentationDisplaysPlugin.listDisplay();

// Show on secondary display
await PresentationDisplaysPlugin.showPresentation(
  displayId: displays[1].displayId,
  routerName: 'vice_display',
);

```

---

## Testing

### Manual Testing Checklist

- [ ] Empty cart shows full-screen media

- [ ] Adding first item triggers smooth slide-in animation

- [ ] Cart panel displays correct item count and prices

- [ ] Product images show in cart (if enabled)

- [ ] Scrolling cart works with many items

- [ ] Grand total displays prominently at bottom

- [ ] Removing all items returns to full-screen media

- [ ] Slideshow auto-rotates every 5 seconds

- [ ] Welcome screen shows business name correctly

### Performance Testing

- Media layer never flickers during cart changes

- Animations are smooth (60fps)

- Large cart (50+ items) scrolls smoothly

- Image loading doesn't block UI thread

---

## Troubleshooting

### Cart Not Appearing

**Check**:

1. `_cartItems.isNotEmpty` is true
2. `AnimatedPositioned.right` is 0 (not negative)
3. Cart panel width is 30% of screen width

### Media Flickering

**Solution**: Ensure media layer is in `Stack` base layer, not conditionally rendered.

### Animation Stuttering

**Causes**:

- Heavy build methods in cart items

- Unoptimized images

- Slow database queries

**Fixes**:

- Use `const` widgets where possible

- Cache images with `Image.file(cacheWidth: 50, cacheHeight: 50)`

- Debounce cart updates

---

## Code Structure

```text
lib/screens/vice_customer_display_screen.dart
├── initState()
│   ├── _loadSlideshowSettings()
│   └── _viceScreenPlugin.viceStream.listen()
│
├── build()
│   └── Stack
│       ├── Positioned.fill → _buildMediaLayer()
│       └── AnimatedPositioned → _buildCartPanel()
│
├── _buildMediaLayer()
│   ├── _buildSlideshow() (if enabled)
│   └── _buildWelcomeScreen() (default)
│
├── _buildCartPanel()
│   ├── Header (Order title + number)

│   ├── Table headers (Item, Qty, Price)
│   ├── ListView.builder (cart items)
│   └── Fixed totals section
│
└── _buildTotalRow(label, amount, fontSize, color)

```

---

## Migration Guide

### From Old Layout

**Old Code**:

```dart
if (_cartItems.isNotEmpty) {
  return _buildCartDisplay(); // 40/60 split
} else {
  return _buildSlideshow(); // Full screen
}

```

**New Code**:

```dart
return Stack([
  Positioned.fill(_buildMediaLayer()), // Always rendered
  AnimatedPositioned(_buildCartPanel()), // Slides in
]);

```

### Breaking Changes

1. **Removed**: `_buildCartDisplay()` method (old 40/60 split)
2. **Removed**: `_buildTotalsRow()` helper (replaced with `_buildTotalRow()`)
3. **Removed**: `_isLocalFile()` method (not needed)
4. **Changed**: Cart panel is now overlay, not split-screen

---

## Best Practices

1. **Always render media layer**: Use `Stack` with `Positioned.fill`
2. **Use AnimatedPositioned**: For smooth cart slide-in/out
3. **Dark theme required**: Ensure high contrast for readability
4. **Cache images**: Use `cacheWidth`/`cacheHeight` for thumbnails
5. **Fixed totals at bottom**: Never let totals scroll out of view
6. **Test on real hardware**: Emulator doesn't reflect dual-screen behavior

---

## Related Documentation

- `docs/DUAL_DISPLAY_TROUBLESHOOTING.md` - Hardware setup guide

- `docs/YOUTUBE_DISPLAY_FEATURE.md` - Video player integration

- `docs/RESPONSIVE_LAYOUT_IMPROVEMENTS.md` - General layout patterns

- `FIREBASE_STREAMING_SETUP.md` - Real-time cart sync

---

## Credits

**Design Inspiration**: Modern POS systems (Square, Clover, Toast)
**Architecture**: Stack-based media persistence pattern
**Animation**: Material Design motion guidelines
**Hardware Support**: iMin Vice Screen SDK

---

**Version**: 1.0.21-dev
**Last Updated**: 2025-12-22
**Author**: FlutterPOS Development Team
