import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/design_system/horizon_typography.dart';
import 'package:flutter/material.dart';

/// Horizon Design System - Metric Card for Dashboard
/// Shows a key metric with optional trend indicator and sparkline
class HorizonMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final double? percentageChange;
  final Widget? sparkline;
  final VoidCallback? onTap;

  const HorizonMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.iconColor,
    this.percentageChange,
    this.sparkline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositive = percentageChange != null && percentageChange! >= 0;
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? HorizonColors.electricIndigo)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor ?? HorizonColors.electricIndigo,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: HorizonColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Main Value (with tabular numbers)
              Text(
                value,
                style: HorizonTypography.tabularNumbers(
                  theme.textTheme.headlineMedium!.copyWith(
                    color: HorizonColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle + Percentage Change
              Row(
                children: [
                  if (subtitle != null)
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: HorizonColors.textTertiary,
                        ),
                      ),
                    ),
                  
                  if (percentageChange != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? HorizonColors.emerald.withOpacity(0.1)
                            : HorizonColors.rose.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 12,
                            color: isPositive
                                ? HorizonColors.emeraldDark
                                : HorizonColors.roseDark,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${percentageChange!.abs().toStringAsFixed(1)}%',
                            style: HorizonTypography.tabularNumbers(
                              theme.textTheme.labelSmall!.copyWith(
                                color: isPositive
                                    ? HorizonColors.emeraldDark
                                    : HorizonColors.roseDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              // Sparkline (mini chart)
              if (sparkline != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: sparkline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
