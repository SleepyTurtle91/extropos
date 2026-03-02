import 'package:extropos/models/business_info_model.dart';
import 'package:flutter/material.dart';

class InventoryValuationWidget extends StatelessWidget {
  final List<dynamic> inventoryItems; // Accept dynamic to avoid circular imports
  final VoidCallback onExportCsv;
  final VoidCallback onAddStock;

  const InventoryValuationWidget({
    required this.inventoryItems,
    required this.onExportCsv,
    required this.onAddStock,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final inventory = inventoryItems;

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
                      onExportCsv,
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
              child: Center(child: Text('No inventory data found for this period.')),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 60,
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
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
                rows: inventory.map((dynamic item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          item.id as String,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.name as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            '${(item.stock as double).toStringAsFixed(0)} ${item.unit ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      DataCell(
                        Center(
                          child: Text(
                            '${BusinessInfo.instance.currencySymbol} ${((item.cost as double) * (item.stock as double)).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      DataCell(
                        Text(
                          item.status as String,
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

  Widget _tableActionBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isPrimary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? Colors.indigo : Colors.white,
        foregroundColor: isPrimary ? Colors.white : Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: isPrimary ? null : BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
