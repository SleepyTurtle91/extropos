import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';

/// Enhanced product grid widget with responsive columns, images, and stock indicators
/// Uses LayoutBuilder for adaptive layout and supports business currency
class ProductGridWidget extends StatelessWidget {
  final List<Product> products;
  final Function(Product) onProductSelected;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;
  final bool showStockIndicators;
  final bool isLoading;
  final String? emptyStateMessage;

  const ProductGridWidget({
    required this.products,
    required this.onProductSelected,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
    this.showStockIndicators = true,
    this.isLoading = false,
    this.emptyStateMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Adaptive columns based on screen width
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
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(context, product);
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = constraints.maxWidth < 600 ? 2 : 4;
        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: 8, // Show 8 skeleton items
          itemBuilder: (context, index) {
            return _buildSkeletonCard();
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: textColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            emptyStateMessage ?? 'No products available',
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      color: cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 60,
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    final currencySymbol = BusinessInfo.instance.currencySymbol;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        color: cardColor,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => onProductSelected(product),
          borderRadius: BorderRadius.circular(12),
          splashColor: backgroundColor.withOpacity(0.1),
          highlightColor: backgroundColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Product image/icon with stock indicator
                Stack(
                  children: [
                    _buildProductImage(product),
                    if (showStockIndicators && product.stockQuantity <= 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.warning,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Product name
                Expanded(
                  child: Text(
                    product.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                // Product price with currency
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$currencySymbol${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Stock indicator
                if (showStockIndicators && product.stockQuantity > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Stock: ${product.stockQuantity}',
                      style: TextStyle(
                        color: textColor.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    // Check if product has an image
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          image: DecorationImage(
            image: NetworkImage(product.imagePath!),
            fit: BoxFit.cover,
            onError: (exception, stackTrace) {
              // Fallback to icon if image fails to load
            },
          ),
        ),
      );
    }

    // Fallback to icon
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Icon(
        product.icon,
        size: 28,
        color: textColor.withOpacity(0.7),
      ),
    );
  }
}