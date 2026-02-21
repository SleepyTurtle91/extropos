// MODERN RETAIL POS SCREEN - SIDEBAR TEMPLATE DESIGN
// Following the modern POS system template with left sidebar navigation

import 'dart:async';
import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/category_model.dart';
import 'package:extropos/models/customer_model.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/screens/analytics_dashboard_screen.dart';
import 'package:extropos/screens/category_analysis_screen.dart';
import 'package:extropos/screens/customers_management_screen.dart';
import 'package:extropos/screens/items_management_screen.dart';
import 'package:extropos/screens/loyalty_dashboard_screen.dart';
import 'package:extropos/screens/order_queue_screen.dart';
import 'package:extropos/screens/payment_screen.dart';
import 'package:extropos/screens/sales_dashboard_screen.dart';
import 'package:extropos/screens/sales_history_screen.dart';
import 'package:extropos/screens/settings_screen.dart';
import 'package:extropos/screens/shift_reports_screen.dart';
import 'package:extropos/screens/stock_management_screen.dart';
import 'package:extropos/services/cart_service.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/widgets/customer_info_widget.dart';
import 'package:flutter/material.dart';

class RetailPOSScreenTemplate extends StatefulWidget {
  const RetailPOSScreenTemplate({super.key});

  @override
  State<RetailPOSScreenTemplate> createState() => _RetailPOSScreenTemplateState();
}

class _RetailPOSScreenTemplateState extends State<RetailPOSScreenTemplate> {
  // Cart management
  late final CartService cartService;
  
  // Categories and products
  List<Category> categories = [];
  List<Product> products = [];
  String selectedCategory = 'All';
  
  // Search
  final TextEditingController _searchController = TextEditingController();

  // Customer details
  Customer? _selectedCustomer;
  String? _customerName;
  String? _customerPhone;
  String? _customerEmail;
  String? _specialInstructions;
  
  // Colors matching the template
  static const Color primaryBg = Color(0xFFF5F5F5);
  static const Color sidebarBg = Color(0xFFFAFAFA);
  static const Color white = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color accent = Color(0xFF6C5CE7);
  
  // Category colors from template
  static const Color foodsColor = Color(0xFF8B6C3F);
  static const Color shoesColor = Color(0xFFEB6B6B);
  static const Color undergarmentColor = Color(0xFFFFD93D);
  static const Color backpackColor = Color(0xFF52C89B);
  static const Color fastFoodColor = Color(0xFF74B9FF);
  static const Color ingredientsColor = Color(0xFFD084E8);
  
  @override
  void initState() {
    super.initState();
    cartService = CartService();
    cartService.addListener(_onCartChanged);
    _loadData();
  }
  
  void _onCartChanged() {
    if (mounted) setState(() {});
  }
  
  Future<void> _loadData() async {
    try {
      // Load categories
      final dbCategories = await DatabaseService.instance.getCategories();
      final dbItems = await DatabaseService.instance.getItems();
      
      if (dbCategories.isNotEmpty) {
        final Map<String, Category> catById = {
          for (final c in dbCategories) c.id: c,
        };
        
        final List<Product> loadedProducts = dbItems.map((it) {
          final catName = catById[it.categoryId]?.name ?? 'Uncategorized';
          return Product(
            it.name,
            it.price,
            catName,
            Icons.inventory_2,
          );
        }).toList();
        
        if (mounted) {
          setState(() {
            categories = dbCategories;
            products = loadedProducts;
          });
        }
      }
    } catch (e) {
      print('Error loading data: $e');
    }
  }
  
  @override
  void dispose() {
    cartService.removeListener(_onCartChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _addToCart(Product product) {
    cartService.addProduct(product, quantity: 1);
  }

  bool get _hasCustomerDetails {
    return _selectedCustomer != null ||
        (_customerName?.trim().isNotEmpty ?? false) ||
        (_customerPhone?.trim().isNotEmpty ?? false) ||
        (_customerEmail?.trim().isNotEmpty ?? false);
  }

  bool get _canShowPaymentValues {
    return cartService.items.isNotEmpty && _hasCustomerDetails;
  }

  Future<void> _openCustomerDialog() async {
    final customerInfo = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CustomerInfoDialog(
        initialName: _selectedCustomer?.name ?? _customerName,
        initialPhone: _selectedCustomer?.phone ?? _customerPhone,
        initialEmail: _selectedCustomer?.email ?? _customerEmail,
        initialNotes: _specialInstructions,
      ),
    );

    if (customerInfo != null && mounted) {
      setState(() {
        _customerName = customerInfo['customerName'] as String?;
        _customerPhone = customerInfo['customerPhone'] as String?;
        _customerEmail = customerInfo['customerEmail'] as String?;
        _specialInstructions = customerInfo['specialInstructions'] as String?;
        _selectedCustomer = customerInfo['selectedCustomer'] as Customer?;
      });
    }
  }
  
  void _proceedToPayment() async {
    if (cartService.items.isEmpty) return;
    
    // Calculate totals
    final info = BusinessInfo.instance;
    final subtotal = cartService.getSubtotal();
    final tax = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
    final serviceCharge = info.isServiceChargeEnabled ? subtotal * info.serviceChargeRate : 0.0;
    final total = subtotal + tax + serviceCharge;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          cartItems: cartService.items,
          totalAmount: total,
          availablePaymentMethods: const [],
          orderType: 'retail',
        ),
      ),
    );
    
    if (result == true && mounted) {
      cartService.clearCart();
    }
  }
  
  int _getCategoryStock(String categoryName) {
    return products.where((p) => p.category == categoryName).length;
  }
  
  Color _getCategoryColor(int index) {
    const colors = [
      foodsColor,
      shoesColor,
      undergarmentColor,
      backpackColor,
      fastFoodColor,
      ingredientsColor,
    ];
    return colors[index % colors.length];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
            _buildSidebar(),
            
            // Main Content
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildCategoryGrid(),
                        ),
                        
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final rightPanelWidth = constraints.maxWidth > 1200 ? 380.0 : 320.0;
                            return SizedBox(
                              width: rightPanelWidth,
                              child: _buildRightPanel(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: sidebarBg,
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo/Brand
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.store, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ExtroPOS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Menu',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              
              // Menu Items
              _buildMenuItem(
                Icons.dashboard_outlined,
                'Dashboard',
                false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesDashboardScreen()),
                  );
                },
              ),
              _buildMenuItemExpanded(Icons.point_of_sale, 'Pos System', true),
              _buildMenuItem(
                Icons.receipt_long,
                'Orders',
                false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                  );
                },
              ),
              _buildMenuItem(
                Icons.analytics_outlined,
                'Analytics',
                false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AnalyticsDashboardScreen(),
                    ),
                  );
                },
              ),
              _buildMenuItem(
                Icons.inventory_2_outlined,
                'Products',
                false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ItemsManagementScreen()),
                  );
                },
              ),
              _buildMenuItem(
                Icons.warehouse_outlined,
                'Inventory',
                false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StockManagementScreen()),
                  );
                },
              ),
              _buildMenuItem(
                Icons.campaign_outlined,
                'Marketing',
                false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoyaltyDashboardScreen()),
                  );
                },
              ),
              _buildMenuItem(
                Icons.people_outline,
                'Customers',
                false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomersManagementScreen(),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 100),
              
              _buildMenuItem(Icons.settings_outlined, 'Settings', false, onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(IconData icon, String label, bool selected, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? accent : textSecondary,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? accent : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuItemExpanded(IconData icon, String label, bool selected) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? accent : textSecondary,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? accent : textPrimary,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: selected ? accent : textSecondary,
              ),
            ],
          ),
        ),
        _buildSubMenuItem(
          'Product Insights',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryAnalysisScreen()),
            );
          },
        ),
        _buildSubMenuItem(
          'Quick Sale',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quick Sale is available on the POS screen.')),
            );
          },
        ),
        _buildSubMenuItem(
          'Open Orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderQueueScreen()),
            );
          },
        ),
        _buildSubMenuItem(
          'Shift Summary',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShiftReportsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubMenuItem(String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 60, top: 2, bottom: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondary.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Container(
      height: 80,
      color: white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Text(
            'POS System',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 40),
          
          // Search Bar
          Expanded(
            flex: 2,
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: primaryBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search Here',
                  hintStyle: TextStyle(color: textSecondary.withOpacity(0.5)),
                  prefixIcon: Icon(Icons.search, color: textSecondary.withOpacity(0.5)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          const Spacer(),
          
          // Action Icons
          IconButton(
            icon: const Icon(Icons.filter_list, color: textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: textSecondary),
            onPressed: () {},
          ),
          
          const SizedBox(width: 16),
          
          // User Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: accent.withOpacity(0.2),
            child: const Icon(Icons.person, color: accent, size: 24),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryGrid() {
    return Container(
      color: white,
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Get unique categories with products
          final categoryList = categories.where((cat) => 
            products.any((p) => p.category == cat.name)
          ).toList();
          
          // Responsive column count based on available width
          int crossAxisCount = 3;
          if (constraints.maxWidth < 600) {
            crossAxisCount = 1;
          } else if (constraints.maxWidth < 900) {
            crossAxisCount = 2;
          }
          
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
            ),
            itemCount: categoryList.length,
            itemBuilder: (context, index) {
              final category = categoryList[index];
              final stock = _getCategoryStock(category.name);
              final color = _getCategoryColor(index);
              
              return InkWell(
                onTap: () => _showCategoryProducts(category.name),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$stock item${stock != 1 ? 's' : ''} in stock',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  void _showCategoryProducts(String categoryName) {
    final categoryProducts = products.where((p) => p.category == categoryName).toList();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive column count for product grid
                    int productColumns = 4;
                    if (constraints.maxWidth < 600) {
                      productColumns = 2;
                    } else if (constraints.maxWidth < 900) {
                      productColumns = 3;
                    }
                    
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: productColumns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: categoryProducts.length,
                      itemBuilder: (context, index) {
                        final product = categoryProducts[index];
                        return InkWell(
                          onTap: () {
                            _addToCart(product);
                            Navigator.pop(context);
                          },
                          child: Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(product.icon, size: 48, color: accent),
                                  const SizedBox(height: 8),
                                  Text(
                                    product.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RM ${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRightPanel() {
    return Column(
      children: [
        // Items Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: primaryBg, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () {},
                    color: textSecondary,
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, size: 20),
                    onPressed: () {},
                    color: textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Items List
        Expanded(
          child: cartService.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 64, color: textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No items in cart',
                        style: TextStyle(color: textSecondary.withOpacity(0.5)),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Column Headers
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Order ID',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 3,
                            child: Text(
                              'Name',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Text(
                              'Price',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Items
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartService.items.length,
                        itemBuilder: (context, index) {
                          final item = cartService.items[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '#${(index + 8124).toString()}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'RM${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        
        // Payment Details (with scrollable wrapper for overflow protection)
        Flexible(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryBg.withOpacity(0.3),
                border: Border(
                  top: BorderSide(color: primaryBg, width: 1),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Payment details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.credit_card, size: 18),
                            onPressed: () {},
                            color: textSecondary,
                          ),
                          IconButton(
                            icon: const Icon(Icons.print, size: 18),
                            onPressed: () {},
                            color: textSecondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openCustomerDialog,
                      icon: Icon(
                        _hasCustomerDetails ? Icons.edit : Icons.person_add,
                        size: 16,
                        color: textSecondary,
                      ),
                      label: Text(
                        _hasCustomerDetails ? 'Edit customer' : 'Add customer',
                        style: const TextStyle(color: textSecondary),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildPaymentRow(
                    'Buyer Name',
                    _canShowPaymentValues
                        ? (_selectedCustomer?.name ?? _customerName ?? '')
                        : '',
                  ),
                  const SizedBox(height: 8),
                  () {
                    final subtotal = cartService.getSubtotal();
                    final value = _canShowPaymentValues
                        ? 'RM${subtotal.toStringAsFixed(2)}'
                        : '';
                    return _buildPaymentRow('Sub cost', value);
                  }(),
                  const SizedBox(height: 8),
                  () {
                    final info = BusinessInfo.instance;
                    final subtotal = cartService.getSubtotal();
                    final tax = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
                    final value = _canShowPaymentValues
                        ? 'RM${tax.toStringAsFixed(2)}'
                        : '';
                    return _buildPaymentRow('Tax', value);
                  }(),
                  
                  const Divider(height: 24),
                  
                  () {
                    final info = BusinessInfo.instance;
                    final subtotal = cartService.getSubtotal();
                    final tax = info.isTaxEnabled ? subtotal * info.taxRate : 0.0;
                    final serviceCharge = info.isServiceChargeEnabled ? subtotal * info.serviceChargeRate : 0.0;
                    final total = subtotal + tax + serviceCharge;
                    return _buildPaymentRow(
                      'Total',
                      _canShowPaymentValues ? 'RM${total.toStringAsFixed(2)}' : '',
                      isBold: true,
                    );
                  }(),
                  
                  const SizedBox(height: 16),
                  
                  // Proceed Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: cartService.items.isEmpty ? null : _proceedToPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Proceed',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textSecondary,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: textPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
