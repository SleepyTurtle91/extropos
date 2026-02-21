import 'package:extropos/theme/spacing.dart';
import 'package:flutter/material.dart';

/// Small design-system helpers: shadows, subtle elevations and common shapes.
class AppTokens {
  AppTokens._();

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0A000000), // subtle black at 4% opacity
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const double productTileMinWidth = 180; // preferred min width for product tiles
  static const double tableCardMinWidth = 220; // min width for table cards
}

extension ThemeExt on ThemeData {
  /// Modern elevated card decoration used across product & table tiles
  BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: AppSpacing.cardRadius,
        boxShadow: [AppTokens.cardShadow],
      );

  /// Title text style for dense small cards
  TextStyle get cardTitle => textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w600);

  /// Secondary small text used for captions inside cards
  TextStyle get cardCaption => textTheme.bodySmall!.copyWith(color: textTheme.bodySmall!.color?.withOpacity(0.8));
}
