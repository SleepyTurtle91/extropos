import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/modifier_group_model.dart';
import 'package:extropos/models/modifier_item_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/appwrite_backend_service.dart';
import 'package:extropos/widgets/modifier_selection_widget.dart';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatefulWidget {
  final Item item;
  final Function(CartItem) onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final AppwriteBackendService _backendService =
      AppwriteBackendService.instance;
  List<ModifierGroup> _modifierGroups = [];
  final Map<String, List<ModifierItem>> _modifierItems = {};
  final Map<String, List<String>> _selectedModifiers = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadModifiers();
  }

  Future<void> _loadModifiers() async {
    try {
      setState(() => _isLoading = true);

      // Load modifier groups for this item's category
      final groups = await _backendService.getModifierGroupsForCategory(
        widget.item.categoryId,
      );
      setState(() => _modifierGroups = groups);

      // Load modifier items for each group
      for (final group in groups) {
        final items = await _backendService.getModifierItems(group.id);
        setState(() {
          _modifierItems[group.id] = items;
          // Initialize selected modifiers with defaults
          _selectedModifiers[group.id] = items
              .where((item) => item.isDefault)
              .map((item) => item.id)
              .toList();
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      developer.log('ProductDetail: Failed to load modifiers: $e');
      setState(() {
        _errorMessage = 'Failed to load customization options';
        _isLoading = false;
      });
    }
  }

  bool _canAddToCart() {
    // Check if all required modifier groups have valid selections
    for (final group in _modifierGroups) {
      if (!group.isRequired) continue;

      final selected = _selectedModifiers[group.id] ?? [];
      final minSelection = group.minSelection ?? 0;

      if (selected.length < minSelection) {
        return false;
      }
    }
    return true;
  }

  void _onModifierChanged(String groupId, List<String> selectedIds) {
    setState(() => _selectedModifiers[groupId] = selectedIds);
  }

  void _addToCart() {
    if (!_canAddToCart()) return;

    // Create the product with selected modifiers
    final selectedModifierItems = <ModifierItem>[];
    for (final group in _modifierGroups) {
      final selectedIds = _selectedModifiers[group.id] ?? [];
      final items = _modifierItems[group.id] ?? [];
      selectedModifierItems.addAll(
        items.where((item) => selectedIds.contains(item.id)),
      );
    }

    // Calculate total price including modifiers
    double totalPrice = widget.item.price;
    for (final modifier in selectedModifierItems) {
      totalPrice += modifier.priceAdjustment;
    }

    final cartItem = CartItem(
      Product(
        widget.item.name,
        totalPrice,
        '', // Category will be set by parent
        widget.item.icon,
        imagePath: widget.item.imageUrl,
      ),
      1,
      modifiers: selectedModifierItems,
    );

    widget.onAddToCart(cartItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadModifiers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  if (widget.item.imageUrl != null)
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.item.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 250,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Icon(
                        widget.item.icon,
                        size: 100,
                        color: Colors.grey[600],
                      ),
                    ),

                  // Product Info
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${BusinessInfo.instance.currencySymbol}${widget.item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.item.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            widget.item.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Modifier Groups
                  if (_modifierGroups.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Customize Your Order',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._modifierGroups.map(
                      (group) => ModifierSelectionWidget(
                        group: group,
                        items: _modifierItems[group.id] ?? [],
                        selectedIds: _selectedModifiers[group.id] ?? [],
                        onSelectionChanged: (selectedIds) =>
                            _onModifierChanged(group.id, selectedIds),
                      ),
                    ),
                  ],

                  // Add to Cart Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _canAddToCart() ? _addToCart : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Add to Cart'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
