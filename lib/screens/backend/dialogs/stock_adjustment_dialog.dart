import 'package:flutter/material.dart';
import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/services/phase1_inventory_service.dart';

/// Dialog for adjusting stock levels
///
/// Features:
/// - Enter quantity change (positive or negative)
/// - Select reason (Received, Damage, Loss, Sold, Waste, Transfer, Other)
/// - Optional reference number
/// - Form validation
/// - Auto-logs to audit service
class StockAdjustmentDialog extends StatefulWidget {
  final InventoryModel inventory;

  const StockAdjustmentDialog({
    super.key,
    required this.inventory,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  late Phase1InventoryService _inventoryService;

  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _referenceController = TextEditingController();

  String _selectedReason = 'Adjustment';
  bool _isLoading = false;

  static const List<String> _reasons = [
    'Received',
    'Damage',
    'Loss',
    'Waste',
    'Transfer',
    'Adjustment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _inventoryService = Phase1InventoryService.instance;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Quantity is required';
    }
    try {
      final qty = double.parse(value);
      if (qty == 0) {
        return 'Quantity cannot be zero';
      }
      return null;
    } catch (e) {
      return 'Invalid quantity';
    }
  }

  Future<void> _adjustStock() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final quantity = double.parse(_quantityController.text);

      await _inventoryService.adjustStock(
        inventoryId: widget.inventory.id,
        quantityChange: quantity,
        reason: _selectedReason,
        referenceNumber:
            _referenceController.text.isNotEmpty
                ? _referenceController.text
                : null,
        adjustedBy: 'system',
        adjustedByName: 'System',
      );

      if (mounted) {
        final action = quantity > 0 ? 'added' : 'removed';
        print('✅ ${quantity.abs().toStringAsFixed(1)} units $action to inventory');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('❌ Error adjusting stock: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adjust Stock'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Product',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.inventory.productName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                                widget.inventory.currentQuantity
                                    .toStringAsFixed(1),
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
                                widget.inventory.minStockLevel
                                    .toStringAsFixed(0),
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
                                widget.inventory.maxStockLevel
                                    .toStringAsFixed(0),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Quantity change
                TextFormField(
                  controller: _quantityController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                  decoration: InputDecoration(
                    labelText: 'Quantity Change (+ or -) *',
                    hintText: '10 (add) or -5 (remove)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: _validateQuantity,
                ),
                const SizedBox(height: 16),
                // Reason
                DropdownButtonFormField<String>(
                  value: _selectedReason,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Reason *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value ?? _selectedReason;
                    });
                  },
                  items: _reasons.map((reason) {
                    return DropdownMenuItem(value: reason, child: Text(reason));
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Reference number (optional)
                TextFormField(
                  controller: _referenceController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Reference Number (Optional)',
                    hintText: 'PO-12345, INV-001, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _adjustStock,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Adjust Stock'),
        ),
      ],
    );
  }
}
