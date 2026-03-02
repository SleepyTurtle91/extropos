import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/services/horizon_data_service.dart';
import 'package:flutter/material.dart';

class InventoryQuickEditDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final HorizonDataService dataService;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const InventoryQuickEditDialog({
    required this.product,
    required this.dataService,
    required this.onSuccess,
    required this.onError,
    super.key,
  });

  @override
  State<InventoryQuickEditDialog> createState() =>
      _InventoryQuickEditDialogState();
}

class _InventoryQuickEditDialogState extends State<InventoryQuickEditDialog> {
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final currentPrice = double.tryParse(
            widget.product['price']?.toString() ?? '0') ??
        0.0;
    final currentQty =
        int.tryParse(widget.product['quantity']?.toString() ?? '0') ?? 0;

    _priceController =
        TextEditingController(text: currentPrice.toStringAsFixed(2));
    _qtyController = TextEditingController(text: currentQty.toString());
  }

  @override
  void dispose() {
    _priceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: !_isProcessing,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          keyboardType: label.contains('Price') || label.contains('Quantity')
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
        ),
      ],
    );
  }

  Future<void> _saveChanges() async {
    final newPrice = double.tryParse(_priceController.text);
    final newQty = int.tryParse(_qtyController.text);

    if (newPrice == null || newQty == null) {
      widget.onError('Invalid input. Please check your entries.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final productId = widget.product['\$id'] ?? widget.product['id'];
      final success = await widget.dataService.updateProduct(productId, {
        'price': newPrice,
        'quantity': newQty,
      });

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        widget.onError('Failed to update product. Please try again.');
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.edit, color: HorizonColors.electricIndigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Edit: ${widget.product['name'] ?? 'Product'}'),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditField('Price (RM)', _priceController, 'Enter price'),
            const SizedBox(height: 16),
            _buildEditField('Quantity', _qtyController, 'Enter quantity'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.save, size: 18),
          label: const Text('Save'),
          onPressed: _isProcessing ? null : _saveChanges,
        ),
      ],
    );
  }
}
