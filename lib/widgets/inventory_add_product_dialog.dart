import 'package:extropos/design_system/horizon_colors.dart';
import 'package:extropos/services/horizon_data_service.dart';
import 'package:flutter/material.dart';

class InventoryAddProductDialog extends StatefulWidget {
  final List<String> categories;
  final HorizonDataService dataService;
  final VoidCallback onSuccess;
  final Function(String) onError;

  const InventoryAddProductDialog({
    required this.categories,
    required this.dataService,
    required this.onSuccess,
    required this.onError,
    super.key,
  });

  @override
  State<InventoryAddProductDialog> createState() =>
      _InventoryAddProductDialogState();
}

class _InventoryAddProductDialogState extends State<InventoryAddProductDialog> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _qtyController;
  late String _selectedCategory;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _qtyController = TextEditingController();
    _selectedCategory = widget.categories
            .where((c) => c != 'All')
            .firstOrNull ??
        'Beverages';
  }

  @override
  void dispose() {
    _nameController.dispose();
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

  Future<void> _createProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text);
    final qty = int.tryParse(_qtyController.text);

    if (name.isEmpty || price == null || qty == null) {
      widget.onError('Please fill in all fields with valid data.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final success = await widget.dataService.createProduct({
        'name': name,
        'category': _selectedCategory,
        'price': price,
        'quantity': qty,
        'minStock': 5,
        'status': 'Active',
      });

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        widget.onSuccess();
      } else {
        widget.onError('Failed to create product. Please try again.');
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
    final filterCategories =
        widget.categories.where((c) => c != 'All').toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.add_circle, color: HorizonColors.emerald),
          const SizedBox(width: 8),
          const Text('Add New Product'),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField(
                'Product Name',
                _nameController,
                'Enter product name',
              ),
              const SizedBox(height: 16),
              _buildEditField('Price (RM)', _priceController, 'Enter price'),
              const SizedBox(height: 16),
              _buildEditField(
                'Initial Quantity',
                _qtyController,
                'Enter quantity',
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: HorizonColors.surfaceGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: HorizonColors.border,
                      width: 1,
                    ),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: filterCategories
                        .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        ))
                        .toList(),
                    onChanged: _isProcessing
                        ? null
                        : (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing
              ? null
              : () {
                Navigator.pop(context);
              },
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create'),
          style: ElevatedButton.styleFrom(
            backgroundColor: HorizonColors.emerald,
          ),
          onPressed: _isProcessing ? null : _createProduct,
        ),
      ],
    );
  }
}
