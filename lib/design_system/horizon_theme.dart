import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/design_system/horizon_typography.dart';
import 'package:flutter/material.dart';

/// Horizon Admin Design System - Theme Configuration
class HorizonTheme {
  static ThemeData lightTheme() {
    final textTheme = HorizonTypography.getTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      
      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: HorizonColors.electricIndigo,
        onPrimary: Colors.white,
        primaryContainer: HorizonColors.electricIndigoLight,
        onPrimaryContainer: HorizonColors.deepMidnight,
        
        secondary: HorizonColors.deepMidnight,
        onSecondary: Colors.white,
        
        error: HorizonColors.rose,
        onError: Colors.white,
        
        surface: HorizonColors.surfaceWhite,
        onSurface: HorizonColors.textPrimary,
        
        outline: HorizonColors.border,
        outlineVariant: HorizonColors.borderLight,
      ),
      
      // Scaffold & Background
      scaffoldBackgroundColor: HorizonColors.paleSlate,
      
      // Typography
      textTheme: textTheme.apply(
        bodyColor: HorizonColors.textPrimary,
        displayColor: HorizonColors.textPrimary,
      ),
      
      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: HorizonColors.surfaceWhite,
        foregroundColor: HorizonColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: HorizonColors.textPrimary,
        ),
      ),
      
      // Card
      cardTheme: const CardThemeData(
        color: HorizonColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: HorizonColors.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Elevated Button (Primary Action)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HorizonColors.electricIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      
      // Outlined Button (Secondary Action)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HorizonColors.textPrimary,
          side: const BorderSide(color: HorizonColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      
      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: HorizonColors.electricIndigo,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: textTheme.labelLarge,
        ),
      ),
      
      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HorizonColors.surfaceWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HorizonColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HorizonColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: HorizonColors.electricIndigo,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: HorizonColors.rose),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // Chip (Tags/Badges)
      chipTheme: ChipThemeData(
        backgroundColor: HorizonColors.surfaceGrey,
        selectedColor: HorizonColors.electricIndigoLight,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: HorizonColors.border,
        thickness: 1,
        space: 1,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: HorizonColors.surfaceWhite,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: HorizonColors.textPrimary,
        ),
      ),
      
      // SnackBar (Toast)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: HorizonColors.deepMidnight,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
