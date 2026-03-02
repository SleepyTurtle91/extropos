// Part of advanced_reports_screen.dart
// UI helper methods

part of 'advanced_reports_screen.dart';

extension AdvancedReportsUIHelpers on _AdvancedReportsScreenState {
  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF2563EB)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconciliationRow(
    String label,
    double amount, {
    bool isTotal = false,
    bool isVariance = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isVariance
                    ? (amount >= 0 ? Colors.green : Colors.red)
                    : null,
              ),
            ),
          ),
          Text(
            FormattingService.currency(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isVariance
                  ? (amount >= 0 ? Colors.green : Colors.red)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
