import 'package:extropos/models/product.dart';
import 'package:extropos/models/product_variant.dart';
import 'package:flutter/material.dart';

class VariantSelectionDialog extends StatefulWidget {
  final Product product;

  const VariantSelectionDialog({super.key, required this.product});

  @override
  State<VariantSelectionDialog> createState() => _VariantSelectionDialogState();
}

class _VariantSelectionDialogState extends State<VariantSelectionDialog> {
  ProductVariant? _selectedVariant;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select ${widget.product.name} Variant'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose a variant for ${widget.product.name}:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ...widget.product.variants.map((variant) {
              final isSelected = _selectedVariant?.id == variant.id;
              final totalPrice = widget.product.price + variant.priceModifier;

              return Card(
                color: isSelected ? Colors.blue.shade50 : null,
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedVariant = variant);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Radio<ProductVariant>(
                          value: variant,
                          groupValue: _selectedVariant,
                          onChanged: (value) {
                            setState(() => _selectedVariant = value);
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                variant.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (variant.priceModifier != 0)
                                Text(
                                  variant.priceModifier > 0
                                      ? '+RM${variant.priceModifier.toStringAsFixed(2)}'
                                      : 'RM${variant.priceModifier.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: variant.priceModifier > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          'RM${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Base Price:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'RM${widget.product.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedVariant == null
              ? null
              : () => Navigator.pop(context, _selectedVariant),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
          ),
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }
}
