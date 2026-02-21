import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Display mode for Backend app
enum DisplayMode {
  touchscreen, // Optimized for tablets and touchscreens (larger buttons, more spacing)
  desktop, // Optimized for keyboard and mouse (compact, efficient layout)
}

/// Service to manage display mode preference for Backend app
class DisplayModeService {
  static final DisplayModeService _instance = DisplayModeService._internal();
  static DisplayModeService get instance => _instance;

  DisplayModeService._internal();

  static const String _displayModeKey = 'backend_display_mode';
  DisplayMode _currentMode = DisplayMode.desktop; // Default to desktop mode

  /// Get current display mode
  DisplayMode get currentMode => _currentMode;

  /// Check if current mode is touchscreen
  bool get isTouchscreenMode => _currentMode == DisplayMode.touchscreen;

  /// Check if current mode is desktop
  bool get isDesktopMode => _currentMode == DisplayMode.desktop;

  /// Initialize display mode from SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_displayModeKey);

    if (modeString != null) {
      _currentMode = DisplayMode.values.firstWhere(
        (mode) => mode.name == modeString,
        orElse: () => DisplayMode.desktop,
      );
    }
  }

  /// Set display mode and persist to SharedPreferences
  Future<void> setDisplayMode(DisplayMode mode) async {
    _currentMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayModeKey, mode.name);
  }

  /// Toggle between modes
  Future<void> toggleMode() async {
    final newMode = _currentMode == DisplayMode.touchscreen
        ? DisplayMode.desktop
        : DisplayMode.touchscreen;
    await setDisplayMode(newMode);
  }

  /// Get icon size based on current mode
  double get iconSize => isTouchscreenMode ? 32.0 : 24.0;

  /// Get button padding based on current mode
  EdgeInsets get buttonPadding => isTouchscreenMode
      ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
      : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  /// Get list tile padding based on current mode
  EdgeInsets get listTilePadding => isTouchscreenMode
      ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
      : const EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  /// Get card padding based on current mode
  EdgeInsets get cardPadding =>
      isTouchscreenMode ? const EdgeInsets.all(20) : const EdgeInsets.all(16);

  /// Get spacing between elements
  double get spacing => isTouchscreenMode ? 24.0 : 16.0;

  /// Get grid item aspect ratio
  double get gridAspectRatio => isTouchscreenMode ? 1.3 : 1.5;

  /// Get minimum touch target size (following Material Design guidelines)
  double get minTouchTarget => isTouchscreenMode ? 56.0 : 48.0;

  /// Get font size multiplier
  double get fontSizeMultiplier => isTouchscreenMode ? 1.1 : 1.0;

  /// Get sidebar width
  double get sidebarWidth => isTouchscreenMode ? 320.0 : 280.0;
}
