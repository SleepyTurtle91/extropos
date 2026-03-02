import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/services/horizon_data_service.dart';
import 'package:flutter/material.dart';

class InventoryDeleteDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final HorizonDataService dataService;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const InventoryDeleteDialog({
    required this.product,
    required this.dataService,
    required this.onSuccess,
    required this.onError,
    super.key,
  });

  @override
  State<InventoryDeleteDialog> createState() => _InventoryDeleteDialogState();
}

class _InventoryDeleteDialogState extends State<InventoryDeleteDialog> {
  bool _isProcessing = false;

  Future<void> _deleteProduct() async {
    setState(() => _isProcessing = true);

    try {
      final productId = widget.product['\$id'] ?? widget.product['id'];
      final success = await widget.dataService.deleteProduct(productId);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        widget.onError('Failed to delete product. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        widget.onError('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.product['name'] ?? 'Product';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: HorizonColors.rose),
          const SizedBox(width: 8),
          const Text('Delete Product'),
        ],
      ),
      content: Text(
        'Are you sure you want to delete "$productName"?\n\nThis action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete, size: 18),
          label: const Text('Delete'),
          style: ElevatedButton.styleFrom(
            backgroundColor: HorizonColors.rose,
          ),
          onPressed: _isProcessing ? null : _deleteProduct,
        ),
      ],
    );
  }
}
