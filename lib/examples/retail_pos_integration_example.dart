import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/pos_product.dart';
import 'package:extropos/repositories/product_repository.dart';
import 'package:flutter/material.dart';

/// Example integration with existing RetailPOSScreenModern
/// This shows how to add repository to your EXISTING retail POS screen
/// 
/// File: lib/screens/pos/retail_pos_refactored.dart
/// 
/// Key changes:
/// 1. Add ProductRepository instance
/// 2. Replace mock products with repository.getProducts()
/// 3. Use BusinessInfo.instance to detect mode (no manual mode switching)

class RetailPOSIntegrationExample extends StatefulWidget {
  const RetailPOSIntegrationExample({super.key});

  @override
  State<RetailPOSIntegrationExample> createState() =>
      _RetailPOSIntegrationExampleState();
}

class _RetailPOSIntegrationExampleState
    extends State<RetailPOSIntegrationExample> {
  // ✅ Add repository instance
  final ProductRepository _repository = DatabaseProductRepository();

  // Existing cart state (keep as is)
  List<CartItem> cartItems = [];

  // ✅ Replace mock products with repository products
  List<POSProduct> products = [];
  List<String> categories = [];
  String selectedCategory = 'All';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  /// ✅ Load products from repository based on BusinessInfo mode
  Future<void> _loadProducts() async {
    setState(() => isLoading = true);

    try {
      // Get current mode from BusinessInfo singleton
      // BusinessInfo.instance.selectedBusinessMode returns BusinessMode enum
      final mode = BusinessInfo.instance.selectedBusinessMode.name; // 'retail'

      // Fetch products and categories concurrently
      final results = await Future.wait([
        _repository.getProducts(mode: mode),
        _repository.getCategories(mode: mode),
      ]);

      setState(() {
        products = results[0] as List<POSProduct>;
        categories = results[1] as List<String>;
        isLoading = false;
      });

      print('✅ Loaded ${products.length} products for $mode mode');
    } catch (e) {
      setState(() => isLoading = false);
      print('❌ Error loading products: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load products: $e')),
        );
      }
    }
  }

  /// Existing addToCart method (keep as is)
  void addToCart(POSProduct product) {
    setState(() {
      final existingIndex =
          cartItems.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        cartItems[existingIndex].quantity++;
      } else {
        cartItems.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  /// ✅ Filter products by selected category
  List<POSProduct> get filteredProducts {
    if (selectedCategory == 'All') return products;
    return products.where((p) => p.category == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retail POS')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                // Product Grid
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      // Category Filter
                      _buildCategoryChips(),
                      // Product Grid
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Cart Panel (existing implementation)
                Container(
                  width: 380,
                  color: Colors.grey[100],
                  child: _buildCartPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: ['All', ...categories].map((category) {
          final isSelected = selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => selectedCategory = category);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(POSProduct product) {
    return InkWell(
      onTap: () => addToCart(product),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: product.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  product.category.isNotEmpty ? product.category[0] : '?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: product.color,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'RM ${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Cart',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: cartItems.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return ListTile(
                      title: Text(item.product.name),
                      subtitle: Text('Qty: ${item.quantity}'),
                      trailing: Text(
                        'RM ${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
        ),
        // Cart footer with totals...
      ],
    );
  }
}

// Cart model (keep your existing implementation)
class CartItem {
  final POSProduct product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

// ============================================================================
// INTEGRATION STEPS FOR YOUR EXISTING SCREENS
// ============================================================================

/*

STEP 1: Add to RetailPOSScreenModern
-------------------------------------
1. Import repository:
   import 'package:extropos/repositories/product_repository.dart';
   import 'package:extropos/models/pos_product.dart';

2. Add repository instance:
   final ProductRepository _repository = DatabaseProductRepository();

3. Replace mock products with:
   List<POSProduct> products = [];
   
4. Add _loadProducts() method (see example above)

5. Call _loadProducts() in initState()


STEP 2: Add to CafePOSScreen
------------------------------
Same pattern as above, but mode is automatically 'cafe' from BusinessInfo


STEP 3: Add to TableSelectionScreen (Restaurant)
--------------------------------------------------
Same pattern, mode is automatically 'restaurant' from BusinessInfo


STEP 4: Mode Switching (Already Handled!)
------------------------------------------
Mode switching happens in:
- UnifiedPOSScreen checks BusinessInfo.instance.selectedBusinessMode
- User changes mode in Settings → Business Mode → BusinessInfo.updateInstance()
- No code changes needed - repository automatically filters by mode

*/
