import 'package:extropos/models/inventory_model.dart';
import 'package:flutter/material.dart';

/// Widget for displaying a low stock alert chip
///
/// Shows product name and current quantity in alert styling
class LowStockAlertWidget extends StatelessWidget {
  final InventoryModel inventory;

  const LowStockAlertWidget({
    super.key,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            inventory.productName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${inventory.currentQuantity.toStringAsFixed(1)} / ${inventory.minStockLevel.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 10, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}
