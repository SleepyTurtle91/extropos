import 'package:extropos/models/pos_product.dart';
import 'package:extropos/repositories/product_repository.dart';
import 'package:extropos/scripts/extropos_setup.dart';

// ============================================================================
// ExtroPOS Database Integration - Quick Reference
// ============================================================================

void main() async {
  // SETUP (run once)
  await ExtroPOSSetup.runSetup();

  // ============================================================================
  // REPOSITORY USAGE EXAMPLES
  // ============================================================================

  final repository = DatabaseProductRepository();

  // --- Get Products by Mode ---
  final retailProducts = await repository.getProducts(mode: 'retail');
  final cafeProducts = await repository.getProducts(mode: 'cafe');
  final restaurantProducts = await repository.getProducts(mode: 'restaurant');
  final allProducts = await repository.getProducts(); // All modes

  print('Retail: ${retailProducts.length} products');
  print('Cafe: ${cafeProducts.length} products');
  print('Restaurant: ${restaurantProducts.length} products');

  // --- Get Products by Category ---
  final coffeeProducts = await repository.getProductsByCategory(
    'Coffee',
    mode: 'cafe',
  );
  print('Coffee products: ${coffeeProducts.length}');

  // --- Get Categories ---
  final cafeCategories = await repository.getCategories(mode: 'cafe');
  print('Cafe categories: $cafeCategories');

  // --- Find Product by Barcode ---
  final product = await repository.getProductByBarcode('8888001');
  print('Found: ${product?.name}');

  // --- Create Product ---
  final newProduct = POSProduct(
    id: '',
    name: 'Green Tea',
    price: 4.50,
    category: 'Beverages',
    mode: 'cafe',
    barcode: '8888100',
  );
  await repository.createProduct(newProduct);

  // --- Update Product ---
  final updatedProduct = newProduct.copyWith(price: 5.00);
  await repository.updateProduct(updatedProduct);

  // --- Delete Product ---
  await repository.deleteProduct(newProduct.id);

  // ============================================================================
  // INTEGRATION WITH EXISTING POS SCREENS
  // ============================================================================
  /*
  // In RetailPOSScreenModern, CafePOSScreen, or Restaurant screens
  import 'package:extropos/models/business_info_model.dart';

  class _POSScreenState extends State<POSScreen> {
    final ProductRepository _repository = DatabaseProductRepository();
    List<POSProduct> products = [];
    bool isLoading = false;

    Future<void> _fetchData() async {
      setState(() => isLoading = true);
      
      try {
        // Get mode from BusinessInfo singleton (controlled by UnifiedPOSScreen)
        final mode = BusinessInfo.instance.selectedBusinessMode.name;
        products = await _repository.getProducts(mode: mode);
        setState(() => isLoading = false);
      } catch (e) {
        setState(() => isLoading = false);
      }
    }

    @override
    void initState() {
      super.initState();
      _fetchData();
    }
  }
  */

  // ============================================================================
  // CART MANAGEMENT
  // ============================================================================
  /*
  class CartItem {
    final POSProduct product;
    int quantity;
    CartItem({required this.product, this.quantity = 1});
    double get total => product.price * quantity;
  }

  void addToCart(POSProduct product) {
    setState(() {
      final index = cart.indexWhere((item) => item.product.id == product.id);
      if (index != -1) {
        cart[index].quantity++;
      } else {
        cart.add(CartItem(product: product));
      }
    });
  }
  */

  // ============================================================================
  // DATABASE MAINTENANCE
  // ============================================================================

  // Re-seed all data
  // await ExtroPOSSetup.reseedData();

  // Clear all products
  // await ExtroPOSSetup.clearAllProducts();

  // Check if table exists
  // final exists = await POSProductsMigration.isTableExists();
}
