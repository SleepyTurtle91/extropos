import 'package:extropos/theme/spacing.dart';
import 'package:flutter/material.dart';

/// App theme/color scheme model
class AppTheme {
  final String id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final Color errorColor;
  final Color successColor;
  final Brightness brightness;

  const AppTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    required this.errorColor,
    required this.successColor,
    this.brightness = Brightness.light,
  });

  /// Convert to Material ThemeData
  ThemeData toThemeData() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        brightness: brightness,
      ),
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      useMaterial3: true,
      // Use a modern sans-serif system font - Inter or fallback
      fontFamily: 'Inter',
      // Apply a compact, readable text theme
      textTheme: Typography.material2021().black.apply(fontFamily: 'Inter'),
      // Consistent card layout across the app
      // ThemeData.cardTheme expects CardThemeData in the project's Flutter SDK.
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.cardRadius),
        margin: const EdgeInsets.all(8),
      ),
      // Dialog visuals - rounded corners and comfortable padding
      // ThemeData.dialogTheme expects DialogThemeData in the project's Flutter SDK.
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.dialogRadius),
        elevation: 8,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
        contentTextStyle: TextStyle(fontSize: 14, color: textColor.withOpacity(0.9)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'primaryColor': primaryColor.value.toInt(),
      'secondaryColor': secondaryColor.value.toInt(),
      'accentColor': accentColor.value.toInt(),
      'backgroundColor': backgroundColor.value.toInt(),
      'cardColor': cardColor.value.toInt(),
      'textColor': textColor.value.toInt(),
      'errorColor': errorColor.value.toInt(),
      'successColor': successColor.value.toInt(),
      'brightness': brightness.name,
    };
  }

  /// Create from JSON
  factory AppTheme.fromJson(Map<String, dynamic> json) {
    return AppTheme(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      primaryColor: Color(json['primaryColor'] as int),
      secondaryColor: Color(json['secondaryColor'] as int),
      accentColor: Color(json['accentColor'] as int),
      backgroundColor: Color(json['backgroundColor'] as int),
      cardColor: Color(json['cardColor'] as int),
      textColor: Color(json['textColor'] as int),
      errorColor: Color(json['errorColor'] as int),
      successColor: Color(json['successColor'] as int),
      brightness: json['brightness'] == 'dark'
          ? Brightness.dark
          : Brightness.light,
    );
  }
}

/// Pre-defined color schemes for POS app
class AppThemes {
  // Classic Blue (Current Default)
  static const classicBlue = AppTheme(
    id: 'classic_blue',
    name: 'Classic Blue',
    description: 'Professional blue theme - default ExtroPOS look',
    primaryColor: Color(0xFF2563EB),
    secondaryColor: Color(0xFF3B82F6),
    accentColor: Color(0xFF60A5FA),
    backgroundColor: Color(0xFFF5F5F5),
    cardColor: Colors.white,
    textColor: Color(0xFF1F2937),
    errorColor: Color(0xFFDC2626),
    successColor: Color(0xFF10B981),
  );

  // Modern Purple
  static const modernPurple = AppTheme(
    id: 'modern_purple',
    name: 'Modern Purple',
    description: 'Elegant purple theme for upscale establishments',
    primaryColor: Color(0xFF7C3AED),
    secondaryColor: Color(0xFF8B5CF6),
    accentColor: Color(0xFFA78BFA),
    backgroundColor: Color(0xFFF5F3FF),
    cardColor: Colors.white,
    textColor: Color(0xFF1F2937),
    errorColor: Color(0xFFDC2626),
    successColor: Color(0xFF10B981),
  );

  // Fresh Green
  static const freshGreen = AppTheme(
    id: 'fresh_green',
    name: 'Fresh Green',
    description: 'Natural green theme - perfect for cafes & organic stores',
    primaryColor: Color(0xFF059669),
    secondaryColor: Color(0xFF10B981),
    accentColor: Color(0xFF34D399),
    backgroundColor: Color(0xFFF0FDF4),
    cardColor: Colors.white,
    textColor: Color(0xFF1F2937),
    errorColor: Color(0xFFDC2626),
    successColor: Color(0xFF059669),
  );

  // Bold Orange
  static const boldOrange = AppTheme(
    id: 'bold_orange',
    name: 'Bold Orange',
    description: 'Energetic orange theme - great for fast food & casual dining',
    primaryColor: Color(0xFFEA580C),
    secondaryColor: Color(0xFFF97316),
    accentColor: Color(0xFFFB923C),
    backgroundColor: Color(0xFFFFF7ED),
    cardColor: Colors.white,
    textColor: Color(0xFF1F2937),
    errorColor: Color(0xFFDC2626),
    successColor: Color(0xFF10B981),
  );

  // Elegant Teal
  static const elegantTeal = AppTheme(
    id: 'elegant_teal',
    name: 'Elegant Teal',
    description: 'Sophisticated teal theme - ideal for restaurants',
    primaryColor: Color(0xFF0D9488),
    secondaryColor: Color(0xFF14B8A6),
    accentColor: Color(0xFF2DD4BF),
    backgroundColor: Color(0xFFF0FDFA),
    cardColor: Colors.white,
    textColor: Color(0xFF1F2937),
    errorColor: Color(0xFFDC2626),
    successColor: Color(0xFF10B981),
  );

  // Dark Mode
  static const darkMode = AppTheme(
    id: 'dark_mode',
    name: 'Dark Mode',
    description: 'Dark theme - reduces eye strain in low light',
    primaryColor: Color(0xFF3B82F6),
    secondaryColor: Color(0xFF60A5FA),
    accentColor: Color(0xFF93C5FD),
    backgroundColor: Color(0xFF111827),
    cardColor: Color(0xFF1F2937),
    textColor: Color(0xFFF9FAFB),
    errorColor: Color(0xFFEF4444),
    successColor: Color(0xFF34D399),
    brightness: Brightness.dark,
  );

  // Midnight Purple (Dark)
  static const midnightPurple = AppTheme(
    id: 'midnight_purple',
    name: 'Midnight Purple',
    description: 'Dark purple theme - stylish for evening operations',
    primaryColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFFA78BFA),
    accentColor: Color(0xFFC4B5FD),
    backgroundColor: Color(0xFF1E1B4B),
    cardColor: Color(0xFF312E81),
    textColor: Color(0xFFF9FAFB),
    errorColor: Color(0xFFEF4444),
    successColor: Color(0xFF34D399),
    brightness: Brightness.dark,
  );

  // Cherry Red
  static const cherryRed = AppTheme(
    id: 'cherry_red',
    name: 'Cherry Red',
    description: 'Bold red theme - energetic and eye-catching',
    primaryColor: Color(0xFFDC2626),
    secondaryColor: Color(0xFFEF4444),
    accentColor: Color(0xFFF87171),
    backgroundColor: Color(0xFFFEF2F2),
    cardColor: Colors.white,
    textColor: Color(0xFF1F2937),
    errorColor: Color(0xFF991B1B),
    successColor: Color(0xFF10B981),
  );

  /// Get all available themes
  static List<AppTheme> get allThemes => [
    classicBlue,
    modernPurple,
    freshGreen,
    boldOrange,
    elegantTeal,
    cherryRed,
    darkMode,
    midnightPurple,
  ];

  /// Get theme by ID
  static AppTheme? getThemeById(String id) {
    try {
      return allThemes.firstWhere((theme) => theme.id == id);
    } catch (_) {
      return null;
    }
  }
}
