import 'package:extropos/models/product.dart';
import 'package:flutter/material.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const ProductTile({super.key, required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: product.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.asset(
                        product.imagePath!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                      ),
                      child: Icon(product.icon, size: 40, color: Colors.grey[700]),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${Theme.of(context).platform == TargetPlatform.android ? 'RM' : 'RM'}${product.price.toStringAsFixed(2)}'),
                      if (product.hasVariants) Icon(Icons.layers, size: 14, color: Colors.orangeAccent),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
