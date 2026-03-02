// Part of retail_pos_screen_modern.dart
// Small widget builders

part of 'retail_pos_screen_modern.dart';

extension RetailPOSSmallWidgets on _RetailPOSScreenModernState {
  Widget _buildPortraitLayout() {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Product Grid - takes most of the space
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: _buildProductGrid(),
                      ),
                      const SizedBox(height: 12),
                      // Current Order - smaller section
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                        child: _buildCurrentOrderSection(),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionsRow(),
                      const SizedBox(height: 8),
                      _buildPaymentMethodsRow(),
                      const SizedBox(height: 8),
                      _buildCategoriesRow(),
                      const SizedBox(height: 8),
                      SizedBox(height: 320, child: _buildNumberPad()),
                      const SizedBox(height: 8),
                      _buildBottomActions(),
                      SizedBox(height: bottomPadding + 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionButton(
          'New Sale',
          Icons.add_circle_outline,
          accentBlue,
          _clearCart,
        ),
        _buildActionButton(
          'Customers',
          Icons.people_outline,
          accentGreen,
          () => ToastHelper.showToast(context, 'Customers (Coming Soon)'),
        ),
        _buildActionButton(
          'Orders',
          Icons.receipt_long_outlined,
          accentOrange,
          () => ToastHelper.showToast(context, 'Orders (Coming Soon)'),
        ),
        _buildActionButton(
          'Reports',
          Icons.bar_chart_outlined,
          accentOrange,
          () => ToastHelper.showToast(context, 'Reports (Coming Soon)'),
        ),
      ],
    );
  }

  Widget _buildPaymentStack() {
    return const SizedBox.shrink(); // Placeholder, payment methods moved to main UI
  }

  Widget _buildFavoriteProductTile(Product product) {
    return InkWell(
      onTap: () {
        _addToCart(product);
        Navigator.pop(context);
        _cartAddAnimController.forward().then(
          (_) => _cartAddAnimController.reverse(),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentGreen),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(product.icon, size: 32, color: accentGreen),
            const SizedBox(height: 8),
            Text(
              product.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              '${BusinessInfo.instance.currencySymbol}${product.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    if (product.imagePath != null && product.imagePath!.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: accentGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(product.imagePath!),
            fit: BoxFit.cover,
            cacheWidth: 120,
            cacheHeight: 120,
            errorBuilder: (context, error, stackTrace) =>
                Icon(product.icon, color: accentGreen, size: 32),
          ),
        ),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: accentGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(product.icon, color: accentGreen, size: 32),
    );
  }

  Widget _buildTotalsSection() {
    final info = BusinessInfo.instance;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkNavyLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal', getSubtotal()),
          if (info.isTaxEnabled) _buildTotalRow('Tax', getTaxAmount()),
          if (info.isServiceChargeEnabled)
            _buildTotalRow('Service', getServiceChargeAmount()),
          if (billDiscount > 0) _buildTotalRow('Discount', -billDiscount),
          const Divider(color: Colors.white24, height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TOTAL:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${BusinessInfo.instance.currencySymbol} ${getTotal().toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: accentGreen,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            '${BusinessInfo.instance.currencySymbol} ${amount.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'New Sale',
              Icons.add_circle_outline,
              accentBlue,
              _clearCart,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Customers',
              Icons.people_outline,
              accentGreen,
              () => ToastHelper.showToast(context, 'Customers (Coming Soon)'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Orders',
              Icons.receipt_long_outlined,
              accentOrange,
              () => ToastHelper.showToast(context, 'Orders (Coming Soon)'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              'Reports',
              Icons.bar_chart_outlined,
              accentOrange,
              () => ToastHelper.showToast(context, 'Reports (Coming Soon)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          const Text(
            'Payment Methods',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPaymentMethodChip(
                paymentMethods[0],
                Icons.money,
                accentGreen,
              ),
              _buildPaymentMethodChip(
                paymentMethods[1],
                Icons.credit_card,
                accentBlue,
              ),
              _buildPaymentMethodChip(
                paymentMethods[3],
                Icons.wallet_membership,
                accentPurple,
              ),
              _buildPaymentMethodChip(
                PaymentMethod(id: 'cheque', name: 'Cheque'),
                Icons.receipt_long,
                accentOrange,
              ),
              _buildPaymentMethodChip(
                PaymentMethod(id: 'split', name: 'Split'),
                Icons.call_split,
                const Color(0xFF6C63FF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChip(
    PaymentMethod method,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    return InkWell(
      onTap: () => _selectPaymentMethod(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.2),
          border: Border.all(
            color: color,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              color: isSelected ? Colors.white : color,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              method.name,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEWalletOption(String name, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ToastHelper.showToast(context, '$name payment initiated');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitPaymentInput(String method, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            method,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: '0.00',
              prefixText: 'RM ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(String label, IconData icon) {
    return InkWell(
      onTap: () => _showCategoryProductsPopup(label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selectedCategory == label ? accentGreen : darkNavyLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedCategory == label ? accentGreen : Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButtonFromCategory(Category category) {
    return InkWell(
      onTap: () => _showCategoryProductsPopup(category.name),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selectedCategory == category.name
              ? accentGreen
              : darkNavyLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selectedCategory == category.name
                ? accentGreen
                : Colors.white24,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(
    String number) {

}
