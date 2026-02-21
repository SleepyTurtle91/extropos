import 'package:flutter/material.dart';

/// App spacing tokens — central place for consistent paddings and gaps.
class AppSpacing {
  AppSpacing._();

  // Small spacing used for tight layouts, icon gaps
  static const double s = 6.0;

  // Regular spacing used across most layouts
  static const double m = 12.0;

  // Large spacing used for separation of major sections
  static const double l = 20.0;

  // Extra large spacing used for large gutters and desktop paddings
  static const double xl = 32.0;

  // Rounded corner sizes
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius dialogRadius = BorderRadius.all(Radius.circular(10.0));
}
