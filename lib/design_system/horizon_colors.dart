import 'package:flutter/material.dart';

/// Horizon Admin Design System - Color Palette
/// Professional, Airy, "SaaS Minimalist"
class HorizonColors {
  // Primary Action (Buttons/Links)
  static const Color electricIndigo = Color(0xFF4F46E5);
  static const Color electricIndigoLight = Color(0xFF6366F1);
  static const Color electricIndigoDark = Color(0xFF4338CA);
  
  // Background & Surfaces
  static const Color paleSlate = Color(0xFFF1F5F9);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF8FAFC);
  
  // Sidebar/Navigation
  static const Color deepMidnight = Color(0xFF0F172A);
  static const Color deepMidnightLight = Color(0xFF1E293B);
  
  // Status Indicators
  static const Color emerald = Color(0xFF10B981); // Success/In Stock
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldDark = Color(0xFF059669);
  
  static const Color amber = Color(0xFFF59E0B); // Warning/Low Stock
  static const Color amberLight = Color(0xFFFBBF24);
  static const Color amberDark = Color(0xFFD97706);
  
  static const Color rose = Color(0xFFE11D48); // Critical/Error
  static const Color roseLight = Color(0xFFF43F5E);
  static const Color roseDark = Color(0xFFBE123C);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnDark = Color(0xFFF8FAFC);
  
  // Border & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderDark = Color(0xFFCBD5E1);
  
  // Overlays
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color overlayLight = Color(0x40000000); // 25% black
  
  // Chart Colors (for analytics)
  static const List<Color> chartColors = [
    electricIndigo,
    emerald,
    amber,
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
  ];
}
