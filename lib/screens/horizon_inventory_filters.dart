part of 'horizon_inventory_grid_screen.dart';

/// Extension containing filter UI components
extension HorizonInventoryFilters on _HorizonInventoryGridScreenState {
  /// Build filters section with search and dropdowns
  Widget buildFiltersSection() {
    return Row(
      children: [
        // Search
        Expanded(
          flex: 2,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: HorizonColors.surfaceGrey,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: HorizonColors.border,
                width: 1,
              ),
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0; // Reset pagination on search
                });
                // Debounce search - wait 500ms before loading
                _searchDebounceTimer?.cancel();
                _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
                  loadProducts();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Category Filter
        buildFilterDropdown('Category', _categoryFilter, categories, (value) {
          setState(() {
            _categoryFilter = value;
            _currentPage = 0; // Reset pagination on filter change
          });
          loadProducts(); // Reload with new filter
        }),

        const SizedBox(width: 12),

        // Stock Status Filter
        buildFilterDropdown('Stock Status', _stockFilter, stockLevels, (value) {
          setState(() {
            _stockFilter = value;
            _currentPage = 0; // Reset pagination on filter change
          });
          loadProducts(); // Reload with new filter
        }),
      ],
    );
  }

  /// Build filter dropdown widget
  Widget buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HorizonColors.surfaceGrey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: HorizonColors.border, width: 1),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: (selected) {
          if (selected != null) {
            onChanged(selected);
          }
        },
      ),
    );
  }
}
