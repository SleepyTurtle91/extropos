part of 'horizon_inventory_grid_screen.dart';

/// Extension containing data table UI
extension HorizonInventoryTable on _HorizonInventoryGridScreenState {
  /// Build inventory data table
  Widget buildInventoryTable(List<Map<String, dynamic>> filteredProducts) {
    return HorizonDataTable(
      title: 'Products (${filteredProducts.length})',
      columns: [
        DataColumn(
          label: SizedBox(
            width: 24,
            child: Checkbox(
              value: _selectAll,
              onChanged: (value) {
                setState(() {
                  _selectAll = value ?? false;
                  if (_selectAll) {
                    _selectedProductIds.addAll(
                      filteredProducts.map((p) => (p['\$id'] ?? p['id']).toString())
                    );
                  } else {
                    _selectedProductIds.clear();
                  }
                });
              },
            ),
          ),
        ),
        const DataColumn(
          label: HorizonTableCell('SKU'),
        ),
        const DataColumn(
          label: HorizonTableCell('Product Name'),
        ),
        const DataColumn(
          label: HorizonTableCell('Category'),
        ),
        const DataColumn(
          label: HorizonTableCell('Price', isNumeric: true),
        ),
        const DataColumn(
          label: HorizonTableCell('Quantity', isNumeric: true),
        ),
        const DataColumn(
          label: HorizonTableCell('Min Stock', isNumeric: true),
        ),
        const DataColumn(
          label: HorizonTableCell('Status'),
        ),
        const DataColumn(
          label: HorizonTableCell('Actions'),
        ),
      ],
      rows: filteredProducts.map((product) {
        final id = (product['\$id'] ?? product['id'] ?? '').toString();
        final name = (product['name'] ?? '').toString();
        final category = (product['category'] ?? '').toString();
        final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0.0;
        final status = (product['status'] ?? '').toString();
        final minStockStr = (product['minStock'] ?? '0').toString();
        
        final quantity = int.tryParse(product['quantity']?.toString() ?? '0') ?? 0;
        final minStock = int.tryParse(minStockStr) ?? 0;
        final stockPercent = minStock > 0 ? (quantity / minStock * 100).clamp(0, 100) : 100;

        return DataRow(
          cells: [
            DataCell(
              SizedBox(
                width: 24,
                child: Checkbox(
                  value: _selectedProductIds.contains(id),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _selectedProductIds.add(id);
                      } else {
                        _selectedProductIds.remove(id);
                        _selectAll = false;
                      }
                    });
                  },
                ),
              ),
            ),
            DataCell(HorizonTableCell(id)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: HorizonColors.surfaceGrey,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 16,
                      color: HorizonColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  HorizonTableCell(name),
                ],
              ),
            ),
            DataCell(HorizonTableCell(category)),
            DataCell(HorizonTableCell('RM ${price.toStringAsFixed(2)}', isNumeric: true)),
            DataCell(
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HorizonTableCell(
                    quantity.toString(),
                    isNumeric: true,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      width: 60,
                      height: 4,
                      child: LinearProgressIndicator(
                        value: stockPercent / 100,
                        backgroundColor: HorizonColors.border,
                        valueColor: AlwaysStoppedAnimation(
                          stockPercent > 50 ? HorizonColors.emerald : 
                          stockPercent > 25 ? HorizonColors.amber :
                          HorizonColors.rose,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DataCell(HorizonTableCell(minStockStr, isNumeric: true)),
            DataCell(HorizonStatusCell(status)),
            // Actions column
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick edit button
                  Tooltip(
                    message: 'Quick Edit',
                    child: IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: HorizonColors.electricIndigo,
                      onPressed: () => showQuickEditDialog(product),
                      splashRadius: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  Tooltip(
                    message: 'Delete',
                    child: IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: HorizonColors.rose,
                      onPressed: () => showDeleteConfirmation(product),
                      splashRadius: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
