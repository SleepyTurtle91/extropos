import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/models/role_model.dart';
import 'package:extropos/services/access_control_service.dart';
import 'package:flutter/material.dart';

/// Card widget for displaying a single inventory item
///
/// Shows:
/// - Product name and SKU
/// - Current quantity and status
/// - Reorder level and max stock
/// - Quick action buttons (Adjust, Stock Take)
typedef InventoryActionCallback = Function(bool canAdjust);

class InventoryCardWidget extends StatefulWidget {
  final InventoryModel inventory;
  final InventoryActionCallback onAdjustStock;
  final InventoryActionCallback onStockTake;

  const InventoryCardWidget({
    super.key,
    required this.inventory,
    required this.onAdjustStock,
    required this.onStockTake,
  });

  @override
  State<InventoryCardWidget> createState() => _InventoryCardWidgetState();
}

class _InventoryCardWidgetState extends State<InventoryCardWidget> {
  late AccessControlService _accessControl;

  @override
  void initState() {
    super.initState();
    _accessControl = AccessControlService.instance;
  }

  Color _getStatusColor(InventoryModel inventory) {
    if (inventory.isOutOfStock()) return Colors.red;
    if (inventory.isLowStock()) return Colors.orange;
    if (inventory.isOverstock()) return Colors.amber;
    return Colors.green;
  }

  String _getStatusLabel(InventoryModel inventory) {
    if (inventory.isOutOfStock()) return 'Out of Stock';
    if (inventory.isLowStock()) return 'Low Stock';
    if (inventory.isOverstock()) return 'Overstock';
    return 'In Stock';
  }

  IconData _getStatusIcon(InventoryModel inventory) {
    if (inventory.isOutOfStock()) return Icons.error;
    if (inventory.isLowStock()) return Icons.warning;
    if (inventory.isOverstock()) return Icons.trending_up;
    return Icons.check_circle;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.inventory);
    final statusLabel = _getStatusLabel(widget.inventory);
    final statusIcon = _getStatusIcon(widget.inventory);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product name
            Text(
              widget.inventory.productName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // SKU
            if (widget.inventory.sku != null)
              Text(
                'SKU: ${widget.inventory.sku}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            // Status chip
            Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, size: 14, color: statusColor),
                  const SizedBox(width: 4),
                  Text(statusLabel),
                ],
              ),
              backgroundColor: statusColor.withOpacity(0.2),
              labelStyle: TextStyle(color: statusColor, fontSize: 11),
            ),
            const SizedBox(height: 8),
            // Quantity info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      widget.inventory.currentQuantity.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Min',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      '${widget.inventory.minStockLevel.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Max',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    Text(
                      '${widget.inventory.maxStockLevel.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FutureBuilder<bool>(
                    future: _accessControl.hasPermission(
                      Permission.ADJUST_INVENTORY,
                    ),
                    builder: (context, snapshot) {
                      final canAdjust = snapshot.data ?? false;
                      return SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: canAdjust
                              ? () => widget.onAdjustStock(true)
                              : null,
                          icon: const Icon(Icons.edit, size: 14),
                          label: const Text('Adjust'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<bool>(
                    future: _accessControl.hasPermission(
                      Permission.ADJUST_INVENTORY,
                    ),
                    builder: (context, snapshot) {
                      final canAdjust = snapshot.data ?? false;
                      return SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: canAdjust
                              ? () => widget.onStockTake(true)
                              : null,
                          icon: const Icon(Icons.fact_check, size: 14),
                          label: const Text('Count'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.teal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
