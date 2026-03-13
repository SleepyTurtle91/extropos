part of 'retail_pos_screen.dart';

extension _RetailPOSCartOps on _RetailPOSScreenState {
  Future<void> addToCart(Product p) async {
    if (p.hasVariants) {
      final selectedVariant = await showDialog<ProductVariant>(
        context: context,
        builder: (context) => VariantSelectionDialog(product: p),
      );
      if (selectedVariant == null) return;
      await _addProductWithVariantToCart(p, selectedVariant);
      return;
    }

    await _addProductToCart(p);
  }

  Future<void> _addProductToCart(Product p, {ProductVariant? variant}) async {
    double priceAdjustment = 0.0;
    if (selectedMerchant != 'none' && selectedMerchant != 'takeaway') {
      final items = await DatabaseService.instance.getItems();
      final match = items.firstWhere(
        (it) => it.name == p.name,
        orElse: () => Item(
          id: '',
          name: '',
          description: '',
          price: p.price,
          categoryId: '',
          icon: p.icon,
          color: Colors.blue,
        ),
      );
      if (match.id.isNotEmpty) {
        final mprice = match.merchantPrices[selectedMerchant];
        if (mprice != null) {
          priceAdjustment = mprice - p.price;
        }
      }
    }

    if (BusinessInfo.instance.isInHappyHourNow()) {
      final appliedBase = p.price + priceAdjustment;
      final hh = appliedBase * BusinessInfo.instance.happyHourDiscountPercent;
      priceAdjustment -= hh;
    }

    _updateState(() {
      final index = cartItems.indexWhere(
        (c) => c.hasSameConfigurationWithDiscount(
          p,
          [],
          0.0,
          otherPriceAdjustment: priceAdjustment,
          otherSeatNumber: null,
          otherVariant: variant,
        ),
      );
      if (index != -1) {
        cartItems[index].quantity++;
      } else {
        cartItems.add(
          CartItem(
            p,
            1,
            priceAdjustment: priceAdjustment,
            selectedVariant: variant,
          ),
        );
      }
    });

    await _updateDualDisplay();
  }

  Future<void> _addProductWithVariantToCart(Product p, ProductVariant variant) async {
    await _addProductToCart(p, variant: variant);
  }

  void _updateQuantity(CartItem item, int newQuantity) {
    _updateState(() {
      if (newQuantity <= 0) {
        cartItems.remove(item);
      } else {
        item.quantity = newQuantity;
      }
    });
  }

  double getSubtotal() => cartItems.fold(0.0, (s, c) => s + c.totalPrice);

  double getTaxAmount() {
    final info = BusinessInfo.instance;
    if (!info.isTaxEnabled) return 0.0;

    final afterDiscount = (getSubtotal() - billDiscount) < 0
        ? 0.0
        : (getSubtotal() - billDiscount);

    double totalTax = 0.0;
    for (final cartItem in cartItems) {
      final category = _categoryObjects.firstWhere(
        (cat) => cat.name == cartItem.product.category,
        orElse: () => Category(
          id: '',
          name: cartItem.product.category,
          description: '',
          icon: Icons.category,
          color: Colors.grey,
          taxRate: BusinessInfo.instance.taxRate,
        ),
      );

      final taxRate = category.taxRate > 0 ? category.taxRate : info.taxRate;
      final itemSubtotal = cartItem.totalPrice * (afterDiscount / getSubtotal());
      totalTax += itemSubtotal * taxRate;
    }

    return totalTax;
  }

  double getServiceChargeAmount() {
    final info = BusinessInfo.instance;
    final afterDiscount = (getSubtotal() - billDiscount) < 0
        ? 0.0
        : (getSubtotal() - billDiscount);
    return info.isServiceChargeEnabled
        ? afterDiscount * info.serviceChargeRate
        : 0.0;
  }

  Future<void> _checkout() async {
    if (cartItems.isEmpty) return;

    _updateState(() {
      cartItems.clear();
      customerName = null;
      customerPhone = null;
      customerEmail = null;
      specialInstructions = null;
      selectedCustomer = null;
      billDiscount = 0.0;
    });

    await _updateDualDisplay();
  }
}
