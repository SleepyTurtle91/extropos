import 'package:extropos/design_system/horizon_colors.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Toast Notifications
/// Shows temporary messages at the bottom of the screen
class HorizonToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? HorizonColors.deepMidnight,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: HorizonColors.emerald,
    );
  }

  static void error(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: HorizonColors.rose,
    );
  }

  static void warning(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: HorizonColors.amber,
    );
  }

  static void info(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: HorizonColors.electricIndigo,
    );
  }
}
