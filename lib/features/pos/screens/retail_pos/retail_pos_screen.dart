import 'dart:async';
import 'dart:developer' as developer;

import 'package:extropos/features/auth/services/shift_service.dart';
import 'package:extropos/features/pos/screens/retail_pos/widgets/cart_panel_widget.dart';
import 'package:extropos/features/pos/screens/retail_pos/widgets/product_grid_widget.dart';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/item_model.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/models/product_models.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/dual_display_service.dart';
import 'package:extropos/services/lock_manager.dart';
import 'package:extropos/widgets/variant_selection_dialog.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

part 'retail_pos_screen_data_ops.dart';
part 'retail_pos_screen_cart_ops.dart';
part 'retail_pos_screen_ui.dart';
part 'retail_pos_screen_dialogs.dart';

class RetailPOSScreen extends StatefulWidget {
  const RetailPOSScreen({super.key});

  @override
  State<RetailPOSScreen> createState() => _RetailPOSScreenState();
}

class _RetailPOSScreenState extends State<RetailPOSScreen> {
  String selectedCategory = 'All';
  final List<CartItem> cartItems = [];
  final Map<String, List<Product>> _productFilterCache = {};
  Timer? _categoryDebounceTimer;

  List<String> categories = ['All'];
  List<Category> _categoryObjects = [];

  List<Product> products = [];
  String selectedMerchant = 'none';

  final List<PaymentMethod> paymentMethods = [
    PaymentMethod(id: '1', name: 'Cash', isDefault: true),
    PaymentMethod(id: '2', name: 'Credit Card'),
    PaymentMethod(id: '3', name: 'Debit Card'),
  ];

  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? specialInstructions;
  Customer? selectedCustomer;

  double billDiscount = 0.0;

  void _updateState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadFromDatabase();
    BusinessInfo.instance.addListener(_onBusinessInfoChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkShiftStatus();
    });
  }

  @override
  void dispose() {
    _categoryDebounceTimer?.cancel();
    BusinessInfo.instance.removeListener(_onBusinessInfoChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProductsSync(selectedCategory);
    return Material(
      color: Colors.transparent,
      child: SizedBox.expand(
        child: Row(
          children: [
            _buildProductsArea(filteredProducts),
            _buildCartArea(),
          ],
        ),
      ),
    );
  }
}
