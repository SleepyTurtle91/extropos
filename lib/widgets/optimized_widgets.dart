import 'package:flutter/material.dart';

/// Optimized widgets for better performance
class OptimizedWidgets {
  /// Efficient product card with const constructors where possible
  static Widget buildProductCard({
    required String name,
    required String price,
    String? imageUrl,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? Colors.blue[50] : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image placeholder - in real app would use ImageOptimizationService
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: imageUrl != null
                    ? const Icon(Icons.image, color: Colors.grey)
                    : const Icon(Icons.inventory, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Optimized cart item widget with efficient rebuilds
  static Widget buildCartItem({
    required String productName,
    required String unitPrice,
    required int quantity,
    required String lineTotal,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onRemove,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$unitPrice × $quantity',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Quantity controls
            Row(
              children: [
                IconButton(
                  onPressed: onDecrement,
                  icon: const Icon(Icons.remove),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 40),
                  child: Text(
                    quantity.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add),
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),

            // Line total and remove
            Column(
              children: [
                Text(
                  lineTotal,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Efficient grid view builder for products
  static Widget buildProductGrid({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required int crossAxisCount,
    double childAspectRatio = 0.8,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Performance optimizations
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }

  /// Optimized list view for cart items
  static Widget buildCartList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Performance optimizations
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
    );
  }

  /// Efficient loading indicator
  static Widget buildLoadingIndicator({String message = 'Loading...'}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Optimized button for POS actions
  static Widget buildPOSButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    double? width,
    double? height,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: width,
      height: height ?? 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(text),
      ),
    );
  }

  /// Memory-efficient text widget with overflow protection
  static Widget buildOptimizedText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
    bool softWrap = true,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      // Performance: avoid unnecessary text measurements
      textWidthBasis: TextWidthBasis.parent,
    );
  }

  /// Efficient container with conditional rendering
  static Widget buildConditionalContainer({
    required bool condition,
    required Widget child,
    Widget? fallback,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    if (!condition) {
      return fallback ?? const SizedBox.shrink();
    }

    return Container(
      padding: padding,
      margin: margin,
      child: child,
    );
  }

  /// Optimized row with flexible children
  static Widget buildFlexibleRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  /// Optimized column with flexible children
  static Widget buildFlexibleColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
    MainAxisSize mainAxisSize = MainAxisSize.min,
  }) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }
}