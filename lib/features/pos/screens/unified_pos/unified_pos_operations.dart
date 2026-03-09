part of 'unified_pos_screen.dart';

extension UnifiedPOSOperations on _UnifiedPOSScreenState {
  Future<void> _fetchData() async {
    _updateState(() => isLoading = true);

    try {
      final dbCategories = await DatabaseService.instance.getCategories();
      final categoryNames = dbCategories.map((cat) => cat.name).toList();
      final dbItems = await DatabaseService.instance.getItems();

      final loadedProducts = dbItems.map((item) {
        return Product(
          id: item.id,
          name: item.name,
          price: item.price,
          category: _getCategoryName(item.categoryId, dbCategories),
          mode: activeMode,
          color: item.color,
        );
      }).toList();

      _updateState(() {
        categories = ['All', ...categoryNames];
        products = loadedProducts;
        isLoading = false;
      });

      print('✅ Loaded ${products.length} products and ${categories.length} categories');
    } catch (e) {
      print('❌ Error loading data: $e');
      _updateState(() => isLoading = false);
    }
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await DatabaseService.instance.getPaymentMethods();
      final activeMethods = methods
          .where((method) => method.status == PaymentMethodStatus.active)
          .toList();
      if (!mounted) return;
      _updateState(() => paymentMethods = activeMethods);
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(context, 'Failed to load payment methods');
    }
  }

  String _getCategoryName(String categoryId, List<dynamic> categories) {
    try {
      final category = categories.firstWhere(
        (cat) => cat.id == categoryId,
        orElse: () => null,
      );
      return category?.name ?? 'Uncategorized';
    } catch (e) {
      return 'Uncategorized';
    }
  }

  void addToCart(Product product) {
    _updateState(() {
      final index = cart.indexWhere((item) => item.product.id == product.id);
      if (index != -1) {
        cart[index].quantity++;
      } else {
        cart.add(CartItem(product: product));
      }
    });
  }

  void updateQuantity(String productId, int delta) {
    _updateState(() {
      final index = cart.indexWhere((item) => item.product.id == productId);
      if (index != -1) {
        cart[index].quantity += delta;
        if (cart[index].quantity <= 0) {
          cart.removeAt(index);
        }
      }
    });
  }

  double get subtotal => cart.fold(0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;

  List<pos_cart.CartItem> _buildPaymentCartItems() {
    return cart
        .map(
          (item) => pos_cart.CartItem(
            pos_product.Product(
              item.product.name,
              item.product.price,
              item.product.category,
              Icons.shopping_cart,
              id: item.product.id,
            ),
            item.quantity,
          ),
        )
        .toList();
  }

  Future<void> _startPayment() async {
    if (cart.isEmpty) {
      ToastHelper.showToast(context, 'Cart is empty');
      return;
    }

    if (paymentMethods.isEmpty) {
      ToastHelper.showToast(context, 'No active payment methods');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalAmount: total,
          availablePaymentMethods: paymentMethods,
          cartItems: _buildPaymentCartItems(),
          orderType: activeMode.name,
        ),
      ),
    );

    if (!mounted) return;

    if (result is Map && result['success'] == true) {
      _updateState(() => cart.clear());
      ToastHelper.showToast(context, 'Payment completed');
    }
  }
}
