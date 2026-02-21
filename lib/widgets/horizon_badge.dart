import 'package:extropos/design_system/horizon_colors.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Badge/Tag Component
enum HorizonBadgeType { success, warning, error, info, neutral }

class HorizonBadge extends StatelessWidget {
  final String text;
  final HorizonBadgeType type;
  final IconData? icon;

  const HorizonBadge({
    super.key,
    required this.text,
    this.type = HorizonBadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: colors['text'],
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors['text'],
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColors() {
    switch (type) {
      case HorizonBadgeType.success:
        return {
          'background': HorizonColors.emerald.withOpacity(0.1),
          'text': HorizonColors.emeraldDark,
        };
      
      case HorizonBadgeType.warning:
        return {
          'background': HorizonColors.amber.withOpacity(0.1),
          'text': HorizonColors.amberDark,
        };
      
      case HorizonBadgeType.error:
        return {
          'background': HorizonColors.rose.withOpacity(0.1),
          'text': HorizonColors.roseDark,
        };
      
      case HorizonBadgeType.info:
        return {
          'background': HorizonColors.electricIndigo.withOpacity(0.1),
          'text': HorizonColors.electricIndigoDark,
        };
      
      case HorizonBadgeType.neutral:
        return {
          'background': HorizonColors.surfaceGrey,
          'text': HorizonColors.textSecondary,
        };
    }
  }
}

/// Status-specific badges for common use cases
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    
    if (normalized.contains('paid') || normalized.contains('completed') || normalized.contains('in stock')) {
      return HorizonBadge(
        text: status,
        type: HorizonBadgeType.success,
        icon: Icons.check_circle_outline,
      );
    }
    
    if (normalized.contains('pending') || normalized.contains('low stock')) {
      return HorizonBadge(
        text: status,
        type: HorizonBadgeType.warning,
        icon: Icons.info_outline,
      );
    }
    
    if (normalized.contains('failed') || normalized.contains('out of stock')) {
      return HorizonBadge(
        text: status,
        type: HorizonBadgeType.error,
        icon: Icons.error_outline,
      );
    }
    
    return HorizonBadge(text: status, type: HorizonBadgeType.neutral);
  }
}
