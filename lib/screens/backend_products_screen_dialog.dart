part of 'backend_products_screen.dart';

extension _BackendProductsDialogBuilders on _BackendProductsScreenState {
  Future<void> _showProductDialog({BackendProductModel? product}) async {
    final nameController = TextEditingController(text: product?.name ?? '');
    final descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    final skuController = TextEditingController(text: product?.sku ?? '');
    final basePriceController = TextEditingController(
      text: product?.basePrice.toStringAsFixed(2) ?? '',
    );
    final costPriceController = TextEditingController(
      text: product?.costPrice?.toStringAsFixed(2) ?? '',
    );
    final imageUrlController = TextEditingController(
      text: product?.imageUrl ?? '',
    );

    String selectedCategoryId =
        product?.categoryId ??
        (_categories.isNotEmpty ? _categories.first.id ?? '' : '');
    bool isActive = product?.isActive ?? true;
    bool trackInventory = product?.trackInventory ?? true;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<BackendProductModel>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? 'Add Product' : 'Edit Product'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 520,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name *',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: skuController,
                      decoration: const InputDecoration(labelText: 'SKU'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: basePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Base Price *',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Base price is required';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: costPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Cost Price',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId.isEmpty
                          ? null
                          : selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                      ),
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          selectedCategoryId = value;
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageUrlController,
                      decoration: const InputDecoration(labelText: 'Image URL'),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: isActive,
                      title: const Text('Active'),
                      onChanged: (value) => isActive = value,
                    ),
                    SwitchListTile(
                      value: trackInventory,
                      title: const Text('Track Inventory'),
                      onChanged: (value) => trackInventory = value,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                final now = DateTime.now().millisecondsSinceEpoch;
                final category = _categories.firstWhere(
                  (c) => c.id == selectedCategoryId,
                );

                final newProduct = BackendProductModel(
                  id: product?.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  sku: skuController.text.trim().isEmpty
                      ? null
                      : skuController.text.trim(),
                  basePrice: double.parse(basePriceController.text),
                  costPrice: costPriceController.text.trim().isEmpty
                      ? null
                      : double.parse(costPriceController.text),
                  categoryId: selectedCategoryId,
                  categoryName: category.name,
                  isActive: isActive,
                  trackInventory: trackInventory,
                  imageUrl: imageUrlController.text.trim().isEmpty
                      ? null
                      : imageUrlController.text.trim(),
                  createdAt: product?.createdAt ?? now,
                  updatedAt: now,
                );

                Navigator.pop(context, newProduct);
              },
              child: Text(product == null ? 'Create' : 'Update'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    setState(() => _isLoading = true);
    try {
      if (product == null) {
        await _productService.createProduct(result);
      } else {
        await _productService.updateProduct(result);
      }
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save product: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
