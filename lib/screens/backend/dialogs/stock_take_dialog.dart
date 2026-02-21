import 'package:extropos/models/inventory_model.dart';
import 'package:extropos/services/phase1_inventory_service.dart';
import 'package:flutter/material.dart';

/// Dialog for performing physical stock counts (stock takes)
///
/// Features:
/// - Enter physically counted quantity
/// - Shows system quantity for comparison
/// - Calculates variance
/// - Optional notes
/// - Form validation
/// - Auto-logs to audit service
class StockTakeDialog extends StatefulWidget {
  final InventoryModel inventory;

  const StockTakeDialog({
    super.key,
    required this.inventory,
  });

  @override
  State<StockTakeDialog> createState() => _StockTakeDialogState();
}

class _StockTakeDialogState extends State<StockTakeDialog> {
  late Phase1InventoryService _inventoryService;

  final _formKey = GlobalKey<FormState>();
  final _countedQuantityController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  double? _variance;

  @override
  void initState() {
    super.initState();
    _inventoryService = Phase1InventoryService.instance;
    _countedQuantityController.addListener(_calculateVariance);
  }

  @override
  void dispose() {
    _countedQuantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateVariance() {
    if (_countedQuantityController.text.isEmpty) {
      setState(() {
        _variance = null;
      });
      return;
    }

    try {
      final counted = double.parse(_countedQuantityController.text);
      final difference = counted - widget.inventory.currentQuantity;
      setState(() {
        _variance = difference;
      });
    } catch (e) {
      // Invalid number
    }
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.isEmpty) {
      return 'Counted quantity is required';
    }
    try {
      final qty = double.parse(value);
      if (qty < 0) {
        return 'Quantity cannot be negative';
      }
      return null;
    } catch (e) {
      return 'Invalid quantity';
    }
  }

  Future<void> _performStockTake() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final countedQuantity = double.parse(_countedQuantityController.text);

      await _inventoryService.performStockTake(
        inventoryId: widget.inventory.id,
        countedQuantity: countedQuantity,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        performedBy: 'system',
        performedByName: 'System',
      );

      if (mounted) {
        final variance = _variance ?? 0;
        final varianceStr = variance > 0 ? '+${variance.toStringAsFixed(1)}' : variance.toStringAsFixed(1);
        print('✅ Stock take completed. Variance: $varianceStr');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        print('❌ Error performing stock take: $e');
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
    final varianceColor = _variance == null
        ? Colors.grey
        : _variance! > 0
            ? Colors.green
            : _variance! < 0
                ? Colors.red
                : Colors.blue;

    final varianceIcon = _variance == null
        ? Icons.remove
        : _variance! > 0
            ? Icons.trending_up
            : _variance! < 0
                ? Icons.trending_down
                : Icons.check;

    return AlertDialog(
      title: const Text('Stock Take (Physical Count)'),
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
                                'System Stock',
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
                                'Last Variance',
                                style: TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              Text(
                                '0', // Would need to track this
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
                // Counted quantity
                TextFormField(
                  controller: _countedQuantityController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Physically Counted Quantity *',
                    hintText: widget.inventory.currentQuantity.toStringAsFixed(1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: _validateQuantity,
                ),
                const SizedBox(height: 16),
                // Variance display
                if (_variance != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: varianceColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: varianceColor),
                    ),
                    child: Row(
                      children: [
                        Icon(varianceIcon, color: varianceColor, size: 20),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Variance',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            Text(
                              _variance! > 0
                                  ? '+${_variance!.toStringAsFixed(1)}'
                                  : _variance!.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: varianceColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _variance! > 0
                                ? 'Surplus stock'
                                : _variance! < 0
                                    ? 'Missing stock'
                                    : 'Matches perfectly',
                            style: TextStyle(fontSize: 11, color: varianceColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                // Notes (optional)
                TextFormField(
                  controller: _notesController,
                  enabled: !_isLoading,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'e.g., Found items in wrong location, damaged items found, etc.',
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
          onPressed: _isLoading ? null : _performStockTake,
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm Stock Take'),
        ),
      ],
    );
  }
}
