part of 'backend_categories_screen.dart';

/// UI extension for BackendCategoriesScreen
extension BackendCategoriesScreenUI on _BackendCategoriesScreenState {
  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCategories();
    final productCounts = _buildProductCounts();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories Management'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _isLoading ? null : () => _showCategoryDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Category',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(padding: const EdgeInsets.all(16), child: _buildFilters()),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _buildCategoryTree(filtered, productCounts),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 700;
        final children = [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search categories',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SwitchListTile(
              value: _showInactive,
              title: const Text('Show inactive'),
              onChanged: (value) {
                setState(() => _showInactive = value);
              },
            ),
          ),
        ];

        return isNarrow
            ? Column(
                children: [children[0], const SizedBox(height: 8), children[2]],
              )
            : Row(children: children);
      },
    );
  }

  Widget _buildCategoryTree(
    List<BackendCategoryModel> categories,
    Map<String, int> productCounts,
  ) {
    if (categories.isEmpty) {
      return const Center(child: Text('No categories found'));
    }

    final rootCategories = categories.where((c) => c.isRootCategory).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: rootCategories.length,
      itemBuilder: (context, index) {
        final root = rootCategories[index];
        final children =
            categories.where((c) => c.parentCategoryId == root.id).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return Card(
          child: ExpansionTile(
            title: _buildCategoryRow(root, productCounts),
            children: [
              if (children.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 16, bottom: 12),
                  child: Text('No subcategories'),
                )
              else
                ...children.map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: _buildCategoryRow(child, productCounts),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryRow(
    BackendCategoryModel category,
    Map<String, int> productCounts,
  ) {
    final count = productCounts[category.id] ?? 0;

    return ListTile(
      title: Text(category.name),
      subtitle: Text(
        'Order: ${category.sortOrder} • Products: $count',
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            onPressed: _isLoading ? null : () => _adjustSortOrder(category, -1),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 18),
            onPressed: _isLoading ? null : () => _adjustSortOrder(category, 1),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: _isLoading
                ? null
                : () => _showCategoryDialog(category: category),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            onPressed: _isLoading ? null : () => _confirmDelete(category),
          ),
        ],
      ),
      leading: _buildIconPreview(category),
    );
  }

  Widget _buildIconPreview(BackendCategoryModel category) {
    final color = _parseColor(category.colorHex);
    return CircleAvatar(
      backgroundColor: color ?? Colors.blueGrey.shade100,
      child: Icon(
        _iconMap[category.iconName] ?? Icons.category,
        color: color != null ? Colors.white : Colors.blueGrey,
        size: 18,
      ),
    );
  }
}
