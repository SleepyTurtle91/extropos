import 'package:extropos/models/app_theme_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app theme/color scheme
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeIdKey = 'app_theme_id';

  AppTheme _currentTheme = AppThemes.classicBlue;

  /// Get current theme
  AppTheme get currentTheme => _currentTheme;

  /// Get current ThemeData
  ThemeData get themeData => _currentTheme.toThemeData();

  /// Initialize theme service
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeId = prefs.getString(_themeIdKey);

      if (savedThemeId != null) {
        final theme = AppThemes.getThemeById(savedThemeId);
        if (theme != null) {
          _currentTheme = theme;
          notifyListeners();
        }
      }
    } catch (e) {
      // Use default theme on error
      debugPrint('Failed to load theme: $e');
    }
  }

  /// Set theme by ID
  Future<void> setTheme(String themeId) async {
    final theme = AppThemes.getThemeById(themeId);
    if (theme == null) return;

    _currentTheme = theme;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeIdKey, themeId);
    } catch (e) {
      debugPrint('Failed to save theme: $e');
    }
  }

  /// Set theme by object
  Future<void> setThemeObject(AppTheme theme) async {
    await setTheme(theme.id);
  }

  /// Reset to default theme
  Future<void> resetToDefault() async {
    await setTheme(AppThemes.classicBlue.id);
  }
}
