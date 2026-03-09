import 'package:extropos/features/auth/screens/user/sign_out_dialog_simple.dart';
import 'package:extropos/features/auth/services/user_session_service.dart';
import 'package:extropos/features/pos/screens/payment/payment_screen.dart';
import 'package:extropos/models/cart_item.dart' as pos_cart;
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/models/product.dart' as pos_product;
import 'package:extropos/screens/reports_screen.dart';
import 'package:extropos/screens/settings_screen.dart';
import 'package:extropos/screens/tables_management_screen.dart';
import 'package:extropos/services/config_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

part 'unified_pos_models.dart';
part 'unified_pos_operations.dart';
part 'unified_pos_sidebar.dart';
part 'unified_pos_header.dart';
part 'unified_pos_cart.dart';
part 'unified_pos_tables.dart';
part 'unified_pos_products.dart';

/// Main POS screen demonstrating a unified interface for all business modes.
/// Replace database placeholder logic with real repository calls.
class UnifiedPOSScreen extends StatefulWidget {
  const UnifiedPOSScreen({super.key});

  @override
  State<UnifiedPOSScreen> createState() => _UnifiedPOSScreenState();
}

class _UnifiedPOSScreenState extends State<UnifiedPOSScreen> {
  POSMode activeMode = POSMode.cafe;
  String activeTab = 'POS';
  bool isSidebarCollapsed = false;
  List<CartItem> cart = [];
  String searchQuery = '';
  String activeCategory = 'All';
  List<PaymentMethod> paymentMethods = [];

  String? selectedTableId;
  List<Map<String, dynamic>> availableTables = [];

  List<Product> products = [];
  List<String> categories = [];
  bool isLoading = false;

  void _updateState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
    _loadPaymentMethods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFF8FAFC), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50.withOpacity(0.5),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (activeTab == 'POS') _buildCartSection(),
                              Expanded(child: _buildMainView()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (cart.isNotEmpty) _buildCartFAB(),
          ],
        ),
      ),
    );
  }
}
