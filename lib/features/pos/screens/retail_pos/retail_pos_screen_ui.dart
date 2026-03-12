part of 'retail_pos_screen.dart';

extension _RetailPOSUi on _RetailPOSScreenState {
  Widget _buildSelectionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedCategory,
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _onCategorySelected(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Material(
              color: Colors.transparent,
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedMerchant,
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Dine-In')),
                  DropdownMenuItem(value: 'takeaway', child: Text('Takeaway')),
                  DropdownMenuItem(value: 'grabfood', child: Text('GrabFood')),
                  DropdownMenuItem(value: 'shopeefood', child: Text('ShopeeFood')),
                  DropdownMenuItem(value: 'foodpanda', child: Text('FoodPanda')),
                ],
                onChanged: (v) => _updateState(() => selectedMerchant = v ?? 'none'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsArea(List<Product> filteredProducts) {
    return Expanded(
      flex: 2,
      child: Column(
        children: [
          _buildSelectionBar(),
          Expanded(
            child: ProductGridWidget(
              filteredProducts: filteredProducts,
              onProductTapped: _addToCart,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartArea() {
    return SizedBox(
      width: 350,
      child: CartPanelWidget(
        cartItems: cartItems,
        subtotal: getSubtotal(),
        taxAmount: getTaxAmount(),
        serviceChargeAmount: getServiceChargeAmount(),
        billDiscount: billDiscount,
        currencySymbol: BusinessInfo.instance.currencySymbol,
        onQuantityChanged: _updateQuantity,
        onCheckout: _checkout,
      ),
    );
  }
}
