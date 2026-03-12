part of 'items_management_screen.dart';

extension _ItemsManagementUIBuilders on _ItemsManagementScreenState {
  Widget _buildItemsManagementScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items Management'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'import') {
                _showImportDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 18, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Import'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // If narrow, stack vertically instead of forcing side-by-side inputs
                if (constraints.maxWidth < 700) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search items',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _selectedCategoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(
                                cat.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryFilter = value;
                            _filterItems();
                          });
                        },
                      ),
                    ],
                  );
                }

                // Wider screens: show search and dropdown in a Row
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search items',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _selectedCategoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ..._categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat.id,
                              child: Text(
                                cat.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryFilter = value;
                            _filterItems();
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: _filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isEmpty &&
                                  _selectedCategoryFilter == null
                              ? 'No items yet'
                              : 'No items found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty &&
                                  _selectedCategoryFilter == null
                              ? 'Tap + to add your first item'
                              : 'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Adaptive columns based on screen width (following ProductGridWidget pattern)
                      int columns;
                      if (constraints.maxWidth < 600) {
                        columns = 1;
                      } else if (constraints.maxWidth < 900) {
                        columns = 2;
                      } else if (constraints.maxWidth < 1200) {
                        columns = 3;
                      } else {
                        columns = 4;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.m),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisSpacing: AppSpacing.m,
                          crossAxisSpacing: AppSpacing.m,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return Card(
                            child: InkWell(
                              onTap: () => _editItem(item),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: item.color.withAlpha(
                                                  (0.2 * 255).round(),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                item.icon,
                                                color: item.color,
                                                size: 24,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (item.isFeatured)
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 20,
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          item.description,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getCategoryName(item.categoryId),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        // Avoid forcing vertical expansion inside tight grid cells
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              '${BusinessInfo.instance.currencySymbol}${item.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: item.isAvailable
                                                    ? Color.fromRGBO(
                                                        76,
                                                        175,
                                                        80,
                                                        0.1,
                                                      )
                                                    : Color.fromRGBO(
                                                        244,
                                                        67,
                                                        54,
                                                        0.1,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                item.isAvailable
                                                    ? 'Available'
                                                    : 'Unavailable',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: item.isAvailable
                                                      ? Colors.green[700]
                                                      : Colors.red[700],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item.trackStock) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                item.stock == 0
                                                    ? Icons.cancel
                                                    : item.stock <=
                                                          item.lowStockThreshold
                                                    ? Icons.warning
                                                    : Icons.inventory_2,
                                                size: 12,
                                                color: item.stock == 0
                                                    ? Colors.red
                                                    : item.stock <=
                                                          item.lowStockThreshold
                                                    ? Colors.orange
                                                    : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.stock == 0
                                                    ? 'Out of stock'
                                                    : item.stock <=
                                                          item.lowStockThreshold
                                                    ? 'Low stock: ${item.stock}'
                                                    : 'Stock: ${item.stock}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: item.stock == 0
                                                      ? Colors.red
                                                      : item.stock <=
                                                            item.lowStockThreshold
                                                      ? Colors.orange
                                                      : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 20,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editItem(item);
                                        } else if (value == 'delete') {
                                          _deleteItem(item);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit,
                                                size: 18,
                                                color: Colors.blue,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Delete'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }
}
