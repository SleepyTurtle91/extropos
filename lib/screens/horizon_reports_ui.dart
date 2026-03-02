part of 'horizon_reports_screen.dart';

/// Extension providing widget builder methods for Horizon reports UI components
extension _HorizonReportsScreenUIBuilders on _HorizonReportsScreenState {
  Widget _buildReportTypeChip(String label) {
    final isSelected = _reportType == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _reportType = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? HorizonColors.electricIndigo : HorizonColors.surfaceGrey,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? HorizonColors.electricIndigo : HorizonColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : HorizonColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow(String name, String revenue, int units, int percent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HorizonColors.textPrimary,
              ),
            ),
            Text(
              revenue,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: HorizonColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            minHeight: 6,
            value: percent / 100,
            backgroundColor: HorizonColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(
              HorizonColors.electricIndigo,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$units units • $percent%',
            style: const TextStyle(
              fontSize: 11,
              color: HorizonColors.textTertiary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String method, String amount, int percent) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                method,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HorizonColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$percent% of total',
                style: const TextStyle(
                  fontSize: 11,
                  color: HorizonColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: HorizonColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String change, Color color) {
    final isPositive = change.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: HorizonColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
