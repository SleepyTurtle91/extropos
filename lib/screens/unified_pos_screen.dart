import 'package:extropos/screens/kitchen_display_screen.dart';
import 'package:extropos/screens/refund_service_screen.dart';
import 'package:extropos/screens/reports_dashboard_screen.dart';
import 'package:extropos/screens/sales_dashboard_screen.dart';
import 'package:extropos/screens/sales_history_screen.dart';
import 'package:extropos/screens/settings_screen.dart';
import 'package:extropos/screens/tables_management_screen.dart';
import 'package:extropos/screens/user/sign_out_dialog_simple.dart';
import 'package:extropos/services/config_service.dart';
import 'package:flutter/material.dart';

// --- Models used by the unified POS screen ---

enum POSMode { retail, cafe, restaurant }

class Product {
  final String id; // Changed to String for DB compatibility (e.g., Firestore UID)
  final String name;
  final double price;
  final String category;
  final POSMode mode;
  final Color color;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.mode,
    required this.color,
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

/// Main POS screen demonstrating a unified interface for all business modes.
/// Replace database placeholder logic with real repository calls.
class UnifiedPOSScreen extends StatefulWidget {
  const UnifiedPOSScreen({super.key});

  @override
  State<UnifiedPOSScreen> createState() => _UnifiedPOSScreenState();
}

class _UnifiedPOSScreenState extends State<UnifiedPOSScreen> {
  // State variables for UI control
  POSMode activeMode = POSMode.cafe;
  String activeTab = 'POS';
  bool isSidebarCollapsed = false;
  List<CartItem> cart = [];
  String searchQuery = '';
  String activeCategory = 'All';

  // --- Restaurant Mode Table Selection ---
  String? selectedTableId; // Current table being ordered for in restaurant mode
  List<Map<String, dynamic>> availableTables = []; // Mock table data

  // --- Dynamic Data State ---
  // These will be populated by your database logic
  List<Product> products = []; 
  List<String> categories = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // PLACEHOLDER: Database Fetching Logic
  Future<void> _fetchData() async {
    setState(() => isLoading = true);
    
    // TODO: Implement your POS database fetch here.
    // 1. Fetch Categories based on activeMode
    // 2. Fetch Products based on activeMode
    
    setState(() => isLoading = false);
  }

  void addToCart(Product product) {
    setState(() {
      final index = cart.indexWhere((item) => item.product.id == product.id);
      if (index != -1) {
        cart[index].quantity++;
      } else {
        cart.add(CartItem(product: product));
      }
    });
  }

  void updateQuantity(String productId, int delta) {
    setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    children: [
                      if (activeTab == 'POS') _buildCartSection(),
                      Expanded(child: _buildMainView()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isSidebarCollapsed ? 80 : 260,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _sidebarSectionLabel('MAIN MENU'),
                _sidebarItem(Icons.grid_view_rounded, 'Dashboard'),
                _sidebarItem(Icons.shopping_bag_outlined, 'POS', isActive: activeTab == 'POS'),
                if (activeMode == POSMode.restaurant)
                  _sidebarItem(Icons.table_bar_outlined, 'Tables', isActive: activeTab == 'Tables'),
                _sidebarItem(Icons.bar_chart_rounded, 'Reports', isActive: activeTab == 'Reports'),
                _sidebarItem(Icons.history, 'Transactions'),
                if (activeMode != POSMode.retail)
                  _sidebarItem(Icons.restaurant_menu, 'Kitchen'),
                _sidebarItem(Icons.undo, 'Return & Void', highlight: true),
                
                const SizedBox(height: 24),
                _sidebarSectionLabel('SYSTEM MODE'),
                _modeButton(POSMode.retail, Icons.storefront, 'Retail'),
                _modeButton(POSMode.cafe, Icons.coffee, 'Cafe'),
                _modeButton(POSMode.restaurant, Icons.restaurant, 'Dining'),
              ],
            ),
          ),
          const Divider(height: 1),
          _sidebarItem(Icons.settings_outlined, 'Settings'),
          _sidebarItem(Icons.logout, 'Logout'),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('E', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            ),
          ),
          if (!isSidebarCollapsed) ...[
            const SizedBox(width: 12),
              Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  const Text(
                    'ExtroPOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  Text(
                    'Terminal ${ConfigService.instance.terminalId}',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _sidebarSectionLabel(String text) {
    if (isSidebarCollapsed) return const SizedBox(height: 16);
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 16),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Future<void> _handleSidebarAction(String label) async {
    if (label == 'POS') {
      setState(() => activeTab = label);
      return;
    }

    setState(() => activeTab = label);

    switch (label) {
      case 'Dashboard':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesDashboardScreen()),
        );
        break;
      case 'Reports':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReportsDashboardScreen()),
        );
        break;
      case 'Transactions':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
        );
        break;
      case 'Kitchen':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KitchenDisplayScreen()),
        );
        break;
      case 'Return & Void':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RefundServiceScreen()),
        );
        break;
      case 'Tables':
        if (activeMode == POSMode.restaurant) {
          // In restaurant mode, show table selection dialog instead of management
          _showTableSelectionDialog();
        } else {
          // In other modes, go to management screen
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TablesManagementScreen()),
          );
        }
        break;
      case 'Settings':
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
        break;
      case 'Logout':
        final didSignOut = await showDialog<bool>(
          context: context,
          builder: (_) => const SignOutDialogSimple(),
        );
        if (didSignOut == true && mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/lock', (_) => false);
        }
        break;
      default:
        break;
    }

    if (mounted) {
      setState(() => activeTab = 'POS');
    }
  }

  Widget _sidebarItem(IconData icon, String label, {bool isActive = false, bool highlight = false}) {
    return InkWell(
      onTap: () => _handleSidebarAction(label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFFFF1F2) : (isActive ? Theme.of(context).primaryColor : Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          border: highlight ? Border.all(color: const Color(0xFFF43F5E)) : null,
        ),
        child: Row(
          mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: highlight ? const Color(0xFFF43F5E) : (isActive ? Colors.white : Colors.grey.shade600), size: 20),
            if (!isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: highlight ? const Color(0xFFF43F5E) : (isActive ? Colors.white : Colors.grey.shade700), fontWeight: FontWeight.w500, fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _modeButton(POSMode mode, IconData icon, String label) {
    bool isActive = activeMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            activeMode = mode;
            activeTab = 'POS';
            activeCategory = 'All';
          });
          _fetchData(); // Refetch data for the new mode
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: isActive ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: isActive ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: isActive ? Theme.of(context).primaryColor : Colors.grey, size: 18),
              if (!isSidebarCollapsed) ...[
                const SizedBox(width: 12),
                Text(label, style: TextStyle(color: isActive ? Theme.of(context).primaryColor : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 13)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => isSidebarCollapsed = !isSidebarCollapsed),
            icon: const Icon(Icons.menu),
          ),
          const SizedBox(width: 16),
          if (activeMode == POSMode.restaurant && selectedTableId != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.green.shade50, border: Border.all(color: Colors.green), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.table_restaurant, color: Colors.green, size: 18),
                    const SizedBox(width: 8),
                    Text(selectedTableId ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => setState(() => selectedTableId = null),
                      child: Icon(Icons.close, color: Colors.green.shade400, size: 16),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.grey, size: 20),
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
            ),
          ),
          const Spacer(),
          CircleAvatar(backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCartSection() {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    if (activeMode == POSMode.restaurant && selectedTableId != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                          child: Text(
                            'Table ID: $selectedTableId',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
                  child: Text('${cart.length} Items', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)),
                )
              ],
            ),
          ),
          Expanded(
            child: cart.isEmpty 
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('Cart is empty', style: TextStyle(color: Colors.grey)),
                  ],
                ))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.length,
                  itemBuilder: (context, index) => _cartItemTile(cart[index]),
                ),
          ),
          _buildCartFooter(),
        ],
      ),
    );
  }

  Widget _cartItemTile(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: item.product.color, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(item.product.category.isNotEmpty ? item.product.category[0] : '?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3)))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('RM \\${item.total.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _qtyBtn(Icons.remove, () => updateQuantity(item.product.id, -1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    _qtyBtn(Icons.add, () => updateQuantity(item.product.id, 1)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 12),
      ),
    );
  }

  Widget _buildCartFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: Column(
        children: [
          _summaryRow('Subtotal', 'RM \\${subtotal.toStringAsFixed(2)}'),
          _summaryRow('SST (8%)', 'RM \\${tax.toStringAsFixed(2)}'),
          const Divider(height: 24),
          _summaryRow('Total', 'RM \\${total.toStringAsFixed(2)}', isTotal: true),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: cart.isEmpty ? null : () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: const Text('Process Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isTotal ? 24 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.bold)),
      ],
    );
  }

  void _showTableSelectionDialog() {
    // Mock table data - replace with actual database call
    final mockTables = [
      {'id': 'table-1', 'name': 'Table 1', 'capacity': 4, 'occupied': false},
      {'id': 'table-2', 'name': 'Table 2', 'capacity': 4, 'occupied': true},
      {'id': 'table-3', 'name': 'Table 3', 'capacity': 6, 'occupied': false},
      {'id': 'table-4', 'name': 'Table 4', 'capacity': 2, 'occupied': false},
      {'id': 'table-5', 'name': 'VIP Table', 'capacity': 8, 'occupied': false},
      {'id': 'table-6', 'name': 'Corner Booth', 'capacity': 6, 'occupied': true},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Table'),
        content: SizedBox(
          width: 400,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: mockTables.length,
            itemBuilder: (context, index) {
              final table = mockTables[index];
              final occupied = table['occupied'] as bool? ?? false;
              final tableName = table['name'] as String? ?? 'Table';
              final tableId = table['id'] as String? ?? '';
              final capacity = table['capacity'] as int? ?? 0;
              return InkWell(
                onTap: occupied ? null : () {
                  Navigator.pop(context);
                  setState(() => selectedTableId = tableId);
                  // Reset cart when switching tables
                  setState(() => cart.clear());
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: occupied ? Colors.grey.shade300 : Colors.green.shade50,
                    border: Border.all(
                      color: occupied ? Colors.grey : Colors.green,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        color: occupied ? Colors.grey : Colors.green,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tableName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: occupied ? Colors.grey : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '$capacity seats',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      if (occupied)
                        const Text(
                          'OCCUPIED',
                          style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    if (activeMode == POSMode.restaurant && activeTab == 'POS' && selectedTableId == null) {
      return _buildTableSelectionView();
    }

    switch (activeTab) {
      case 'POS': return _buildProductGrid();
      default: return Center(child: Text('$activeTab View (Database Integration Required)'));
    }
  }

  Widget _buildTableSelectionView() {
    // Mock table data
    final mockTables = [
      {'id': 'table-1', 'name': 'Table 1', 'capacity': 4, 'occupied': false},
      {'id': 'table-2', 'name': 'Table 2', 'capacity': 4, 'occupied': true},
      {'id': 'table-3', 'name': 'Table 3', 'capacity': 6, 'occupied': false},
      {'id': 'table-4', 'name': 'Table 4', 'capacity': 2, 'occupied': false},
      {'id': 'table-5', 'name': 'VIP Table', 'capacity': 8, 'occupied': false},
      {'id': 'table-6', 'name': 'Corner Booth', 'capacity': 6, 'occupied': true},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select a Table', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: mockTables.length,
              itemBuilder: (context, index) {
                final table = mockTables[index];
                final occupied = table['occupied'] as bool? ?? false;
                final tableName = table['name'] as String? ?? 'Table';
                final tableId = table['id'] as String? ?? '';
                final capacity = table['capacity'] as int? ?? 0;
                return InkWell(
                  onTap: occupied ? null : () {
                    setState(() => selectedTableId = tableId);
                    // Reset cart when switching tables
                    setState(() => cart.clear());
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: occupied ? Colors.grey.shade300 : Colors.green.shade50,
                      border: Border.all(
                        color: occupied ? Colors.grey : Colors.green,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          color: occupied ? Colors.grey : Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tableName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: occupied ? Colors.grey : Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Capacity: $capacity seats',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (occupied)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              'OCCUPIED',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    final filtered = products.where((p) => 
      (activeCategory == 'All' || p.category == activeCategory) && 
      p.name.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryFilter(),
          const SizedBox(height: 24),
          Expanded(
            child: filtered.isEmpty 
              ? const Center(child: Text('No products found in database.'))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220, childAspectRatio: 1.4, crossAxisSpacing: 16, mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final p = filtered[index];
                    return InkWell(
                      onTap: () => addToCart(p),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade100)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.category.toUpperCase(), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.indigo)),
                            const Spacer(),
                            Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2),
                            Text('RM \\${p.price.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['All', ...categories].map((cat) {
          bool isSelected = activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (s) => setState(() => activeCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }
}
