import 'package:extropos/models/reports_dashboard_models.dart';
import 'package:flutter/material.dart';

class InventoryValuationWidget extends StatelessWidget {
  final List<ReportsInventoryItem> inventory;
  final Color accentColor;
  final Function(String) onExport;
  final VoidCallback onAddStock;

  const InventoryValuationWidget({
    super.key,
    required this.inventory,
    required this.accentColor,
    required this.onExport,
    required this.onAddStock,
  });

  Widget _tableActionBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary ? Colors.white : Colors.blueGrey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.white : Colors.blueGrey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Inventory Valuation',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                Row(
                  children: [
                    _tableActionBtn(
                      Icons.file_present,
                      'Export CSV',
                      () => onExport('csv'),
                    ),
                    const SizedBox(width: 12),
                    _tableActionBtn(
                      Icons.add,
                      'Add Stock',
                      onAddStock,
                      isPrimary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (inventory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text('No inventory data found for this period.'),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 60,
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFFF8FAFC),
                ),
                columns: const [
                  DataColumn(
                    label: Text(
                      'ID / SKU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ITEM NAME',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CURRENT STOCK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'TOTAL VALUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'STATUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
                rows: inventory.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item.id,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            '${item.stock} ${item.unit ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            'RM ${(item.cost * item.stock).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.status,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class MainTitleHeaderWidget extends StatelessWidget {
  final ReportsTimeRange activeTimeRange;
  final Function(ReportsTimeRange) onTimeRangeChanged;
  final String modeName;
  final Widget? customDatePicker;
  final Widget? exportDropdown;

  const MainTitleHeaderWidget({
    super.key,
    required this.activeTimeRange,
    required this.onTimeRangeChanged,
    required this.modeName,
    this.customDatePicker,
    this.exportDropdown,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${modeName[0].toUpperCase()}${modeName.substring(1)} Analytics',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'Detailed intelligence for ExtroPOS $modeName owners',
                style: const TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: ReportsTimeRange.values.map((range) {
                  final isActive = activeTimeRange == range;
                  return GestureDetector(
                    onTap: () => onTimeRangeChanged(range),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        range.name[0].toUpperCase() + range.name.substring(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isActive ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (activeTimeRange == ReportsTimeRange.custom &&
                customDatePicker != null) ...[
              const SizedBox(height: 12),
              customDatePicker!,
            ],
            if (exportDropdown != null) ...[
              const SizedBox(height: 12),
              exportDropdown!,
            ],
          ],
        ),
      ],
    );
  }
}

class ReportModalOverlayWidget extends StatelessWidget {
  final String reportType;
  final VoidCallback onClose;

  const ReportModalOverlayWidget({
    super.key,
    required this.reportType,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isX = reportType == 'X';
    final themeColor = isX ? const Color(0xFF4F46E5) : Colors.red.shade600;

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: Container(
          width: 480,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(40),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$reportType-Report Detail',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      'Connect to Shift Table for Real-time Totals',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
