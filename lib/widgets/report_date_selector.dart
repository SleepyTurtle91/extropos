import 'package:extropos/models/sales_report.dart';
import 'package:flutter/material.dart';

/// Horizontal chip selector for quick report date range selection
class ReportDateSelector extends StatelessWidget {
  final ReportPeriod selectedPeriod;
  final Function(ReportPeriod) onPeriodChanged;

  const ReportDateSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildChip(
            context,
            label: 'Today',
            isSelected: selectedPeriod.label == 'Today',
            onTap: () => onPeriodChanged(ReportPeriod.today()),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: 'Yesterday',
            isSelected: selectedPeriod.label == 'Yesterday',
            onTap: () => onPeriodChanged(ReportPeriod.yesterday()),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: 'This Week',
            isSelected: selectedPeriod.label == 'This Week',
            onTap: () => onPeriodChanged(ReportPeriod.thisWeek()),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: 'This Month',
            isSelected: selectedPeriod.label == 'This Month',
            onTap: () => onPeriodChanged(ReportPeriod.thisMonth()),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: 'Last Month',
            isSelected: selectedPeriod.label == 'Last Month',
            onTap: () => onPeriodChanged(ReportPeriod.lastMonth()),
          ),
          const SizedBox(width: 8),
          _buildChip(
            context,
            label: 'Custom',
            isSelected: selectedPeriod.label == 'Custom',
            onTap: () => _showCustomDatePicker(context),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: selectedPeriod.startDate,
      end: selectedPeriod.endDate,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onPeriodChanged(
        ReportPeriod(
          label: 'Custom',
          startDate: picked.start,
          endDate: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        ),
      );
    }
  }
}
