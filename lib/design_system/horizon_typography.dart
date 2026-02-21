import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Horizon Admin Design System - Typography
/// Using Inter font family with tabular figures for numbers
class HorizonTypography {
  // Base font family
  static TextTheme getTextTheme() {
    return GoogleFonts.interTextTheme().copyWith(
      // Display styles (large headings)
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w600,
      ),
      
      // Headline styles (section headings)
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      
      // Title styles (card headers, dialog titles)
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      
      // Body styles (main content)
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
      ),
      
      // Label styles (buttons, tabs)
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
  
  // Tabular figures for numbers (aligned columns)
  static TextStyle tabularNumbers(TextStyle base) {
    return base.copyWith(
      fontFeatures: [
        const FontFeature.tabularFigures(),
      ],
    );
  }
  
  // Monospace for codes (SKU, Order IDs)
  static TextStyle monoCode(TextStyle base) {
    return GoogleFonts.jetBrainsMono(
      fontSize: base.fontSize,
      fontWeight: base.fontWeight,
      color: base.color,
      letterSpacing: 0,
    );
  }
}
