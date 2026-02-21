import 'package:extropos/design_system/horizon_colors.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Button Components
enum HorizonButtonType { primary, secondary, danger, success }

class HorizonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final HorizonButtonType type;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const HorizonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = HorizonButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle();
    
    final buttonChild = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(text),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonChild,
    );

    return fullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  ButtonStyle _getButtonStyle() {
    switch (type) {
      case HorizonButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: HorizonColors.electricIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        );
      
      case HorizonButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: HorizonColors.textPrimary,
          elevation: 0,
          side: const BorderSide(color: HorizonColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        );
      
      case HorizonButtonType.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: HorizonColors.rose,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        );
      
      case HorizonButtonType.success:
        return ElevatedButton.styleFrom(
          backgroundColor: HorizonColors.emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        );
    }
  }
}
