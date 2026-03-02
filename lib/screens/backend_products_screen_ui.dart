part of 'backend_products_screen.dart';

extension _BackendProductsUIBuilders on _BackendProductsScreenState {
  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final children = [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by name or SKU',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('All Categories'),
                ),
                ..._categories.map(
                  (category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                _selectedCategoryId = value;
                _applyFilters();
              },
            ),
          ),
        ];

        return isNarrow
            ? Column(
                children: [
                  children[0],
                  const SizedBox(height: 12),
                  children[2],
                ],
              )
            : Row(children: children);
      },
    );
  }

  Widget _buildProductCard(BackendProductModel product, String currency) {
    final margin = (product.basePrice - (product.costPrice ?? 0)).toDouble();
    final marginPct = product.basePrice == 0
        ? 0
        : (margin / product.basePrice) * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Checkbox(
                  value: _selectedProductIds.contains(product.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true && product.id != null) {
                        _selectedProductIds.add(product.id!);
                      } else if (product.id != null) {
                        _selectedProductIds.remove(product.id!);
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              product.sku ?? 'No SKU',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              product.categoryName ?? 'Uncategorized',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '$currency ${product.basePrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Margin: $currency ${margin.toStringAsFixed(2)} (${marginPct.toStringAsFixed(1)}%)',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatusChip(product.isActive),
                const Spacer(),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => _showProductDialog(product: product),
                  icon: const Icon(Icons.edit, size: 18),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => _confirmDelete(product),
                  icon: const Icon(Icons.delete, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('Page ${_currentPage + 1} of $_totalPages'),
          const Spacer(),
          IconButton(
            onPressed: _currentPage == 0
                ? null
                : () => setState(() => _currentPage -= 1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _currentPage >= _totalPages - 1
                ? null
                : () => setState(() => _currentPage += 1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      width: double.infinity,
      color: Colors.blueGrey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('${_selectedProductIds.length} selected'),
          const Spacer(),
          TextButton.icon(
            onPressed: _isLoading ? null : _applyBulkDeactivate,
            icon: const Icon(Icons.visibility_off, size: 18),
            label: const Text('Deactivate'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              setState(() => _selectedProductIds.clear());
            },
            icon: const Icon(Icons.clear, size: 18),
            label: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
