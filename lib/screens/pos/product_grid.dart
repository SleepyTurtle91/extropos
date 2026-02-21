import 'package:extropos/models/product.dart';
import 'package:extropos/screens/pos/product_tile.dart';
import 'package:flutter/material.dart';

class ProductGrid extends StatelessWidget {
  final List<Product> products;
  final void Function(Product) onAdd;

  const ProductGrid({super.key, required this.products, required this.onAdd});

  int _columnsForWidth(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1200) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = _columnsForWidth(constraints.maxWidth);
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 3 / 4,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final p = products[index];
          return ProductTile(product: p, onAdd: () => onAdd(p));
        },
      );
    });
  }
}
