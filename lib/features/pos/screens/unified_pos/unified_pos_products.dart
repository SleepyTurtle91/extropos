part of 'unified_pos_screen.dart';

extension UnifiedPOSProducts on _UnifiedPOSScreenState {
  Widget _buildMainView() {
    if (activeMode == POSMode.restaurant && activeTab == 'POS' && selectedTableId == null) {
      return _buildTableSelectionView();
    }

    switch (activeTab) {
      case 'POS':
        return _buildProductGrid();
      default:
        return Center(child: Text('$activeTab View (Database Integration Required)'));
    }
  }

  Widget _buildProductGrid() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final filtered = products
        .where((p) => (activeCategory == 'All' || p.category == activeCategory) && p.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryFilter(),
          const SizedBox(height: 24),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No products found in database.'))
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Adaptive columns based on screen width (following ProductGridWidget pattern)
                      int columns;
                      double aspectRatio;
                      if (constraints.maxWidth < 600) {
                        columns = 2;
                        aspectRatio = 1.0;
                      } else if (constraints.maxWidth < 900) {
                        columns = 3;
                        aspectRatio = 1.1;
                      } else if (constraints.maxWidth < 1200) {
                        columns = 4;
                        aspectRatio = 1.2;
                      } else {
                        columns = 5;
                        aspectRatio = 1.3;
                      }

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          childAspectRatio: aspectRatio,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          return InkWell(
                            onTap: () => addToCart(p),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.category.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                  const Spacer(),
                                  Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  Text('RM ${p.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', ...categories].map((cat) {
          bool isSelected = activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (s) => _updateState(() => activeCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTableSelectionView() {
    return const Center(
      child: Text('Select a Table to Begin - Coming Soon'),
    );
  }
}
