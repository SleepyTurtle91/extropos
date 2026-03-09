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
                          return _buildProductCard(p);
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
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _updateState(() => activeCategory = cat),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [Colors.blue.shade500, Colors.blue.shade600],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.blue.shade200.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
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

  Widget _buildProductCard(Product p) {
    return ProductCard(
      product: p,
      onTap: () => addToCart(p),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, isPressed ? 2 : 0, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPressed
                ? [Colors.grey.shade100, Colors.grey.shade200]
                : [Colors.white, Colors.grey.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPressed ? Colors.blue.shade300 : Colors.grey.shade200,
            width: isPressed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPressed
                  ? Colors.blue.shade200.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isPressed ? 12 : 8,
              offset: Offset(0, isPressed ? 6 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPressed ? Colors.blue.shade100 : Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.product.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: isPressed ? Colors.blue.shade800 : Colors.indigo.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              widget.product.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isPressed ? Colors.blue.shade900 : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPressed ? Colors.blue.shade100 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'RM ${widget.product.price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isPressed ? Colors.blue.shade900 : Colors.blue.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
