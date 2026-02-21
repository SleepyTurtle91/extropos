# Backend Display Mode Guide

## Overview

The Backend flavor now supports **two display modes** to optimize the user experience for different hardware types:

### 1. **Touchscreen Mode** 🖐️

- Optimized for tablets and touchscreen devices (Android tablets, Windows touchscreen laptops)

- Larger buttons and touch targets (56px minimum)

- Increased spacing between elements

- Bigger icons and text (10% larger)

- Wider sidebar (320px vs 280px)

- More padding for easier touch interaction

### 2. **Desktop Mode** 🖱️

- Optimized for keyboard and mouse usage (Windows/Linux desktops)

- Compact layout for efficient screen usage

- Standard button sizes (48px minimum)

- Tighter spacing for more content density

- Standard text and icon sizes

- Narrower sidebar (280px)

---

## How to Switch Modes

### Method 1: Toggle Button in AppBar

1. Open the Backend app
2. Look at the top-right corner of the AppBar
3. You'll see a mode indicator badge showing either:

   - **Touch** with 🖐️ icon (Touchscreen Mode)

   - **Desktop** with 🖱️ icon (Desktop Mode)

4. Click the toggle button next to the sync button
5. The mode switches instantly and rebuilds the UI

### Method 2: Icon Button

- In **Touchscreen Mode**: Click the 🖱️ mouse icon to switch to Desktop

- In **Desktop Mode**: Click the 🖐️ touch icon to switch to Touchscreen

---

## Visual Differences

| Feature | Touchscreen Mode | Desktop Mode |
|---------|-----------------|--------------|
| **Icon Size** | 32px | 24px |

| **Button Padding** | 24px × 16px | 16px × 12px |

| **List Tile Padding** | 20px × 12px | 16px × 8px |

| **Card Padding** | 20px | 16px |

| **Spacing** | 24px | 16px |

| **Sidebar Width** | 320px | 280px |

| **Font Size** | 110% (×1.1) | 100% (×1.0) |

| **Min Touch Target** | 56px | 48px |

| **Grid Aspect Ratio** | 1.3 | 1.5 |

---

## Technical Details

### DisplayModeService

The display mode is managed by `DisplayModeService` (singleton):

```dart
// Get current mode
final mode = DisplayModeService.instance.currentMode;

// Check mode type
if (DisplayModeService.instance.isTouchscreenMode) {
  // Use touchscreen-optimized layout
}

// Toggle mode
await DisplayModeService.instance.toggleMode();
setState(() {}); // Rebuild to apply changes

```text


### Persistence


The selected mode is saved to **SharedPreferences** and persists across app restarts:


- Key: `backend_display_mode`

- Values: `touchscreen` or `desktop`

- Default: `desktop` (on first launch)


### Initialization


The service is initialized in `main_backend.dart`:


```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize display mode service
  await DisplayModeService.instance.init();
  
  // ... rest of initialization
}

```text

---


## When to Use Each Mode



### Use Touchscreen Mode When


- ✅ Using an Android tablet (like your iMin Swan 2)

- ✅ Using a Windows tablet or 2-in-1 device

- ✅ Touchscreen laptop in tablet mode

- ✅ Standing/walking while managing the app

- ✅ Using the app on a wall-mounted display

- ✅ Users have limited dexterity or prefer larger targets


### Use Desktop Mode When


- ✅ Using a traditional Windows/Linux desktop with mouse

- ✅ Laptop with trackpad (non-touch)

- ✅ Need to see more content at once

- ✅ Primarily using keyboard shortcuts (future feature)

- ✅ Working at a desk with precise mouse control

- ✅ Screen real estate is limited

---


## Future Enhancements


Potential improvements for the display mode system:

1. **Auto-Detection**:

   - Detect touchscreen capability on startup

   - Suggest appropriate mode on first launch

   - Remember preference per device

2. **Keyboard Shortcuts**:

   - Add keyboard shortcuts in Desktop Mode

   - Quick navigation with Tab/Arrow keys

   - Hotkeys for common actions

3. **Accessibility**:

   - High contrast themes

   - Larger text option (120-150%)

   - Screen reader optimization

4. **Custom Presets**:

   - Allow users to customize spacing/sizes

   - Save custom presets (e.g., "Extra Large Touch")

   - Export/import settings

---


## Implementation Notes



### Affected Files


1. **lib/services/display_mode_service.dart** (NEW)

   - Singleton service managing display mode state

   - Provides responsive sizing helpers

   - Persists mode to SharedPreferences

2. **lib/main_backend.dart** (MODIFIED)

   - Added `DisplayModeService.instance.init()` in main()

   - Initializes before app starts

3. **lib/screens/backend_home_screen.dart** (MODIFIED)

   - Added mode toggle button in AppBar

   - Added mode indicator badge

   - Updated all layouts to use DisplayModeService

   - Dynamic sizing for cards, buttons, lists, etc.


### Code Pattern


Throughout `backend_home_screen.dart`, all hardcoded sizes are replaced with:


```dart
final displayMode = DisplayModeService.instance;

// Instead of: const EdgeInsets.all(16)
EdgeInsets.all(displayMode.spacing)

// Instead of: const Icon(Icons.business, size: 24)
Icon(Icons.business, size: displayMode.iconSize)

// Instead of: fontSize: 16
fontSize: 16 * displayMode.fontSizeMultiplier

```text

---


## Testing Checklist


- [x] Mode toggle works in AppBar

- [x] Mode indicator updates correctly

- [x] Settings persist across app restarts

- [x] Touchscreen mode has larger touch targets

- [x] Desktop mode is more compact

- [x] All screens rebuild when mode changes

- [x] No layout overflow in either mode

- [x] Responsive on different screen sizes

- [x] APK builds successfully (76MB)

- [x] Installed on tablet (192.168.1.80)

---


## Version History


- **v1.0.14 (2025-11-27)**: Initial implementation of display modes for Backend flavor

---


## Related Documentation


- [Backend Flavor Architecture](../copilot-instructions.md#backend-flavor-management)

- [Responsive Design Standards](../copilot-instructions.md#responsive-design-standards)

- [Business Modes vs Display Modes](../copilot-instructions.md#business-mode-architecture-pos-flavor-only)

**Note**: Display modes are **Backend-only** and different from Business Modes (Retail/Cafe/Restaurant), which are **POS-only**.
