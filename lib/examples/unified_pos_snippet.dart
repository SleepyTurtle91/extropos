import 'package:flutter/material.dart';

void main() {
  runApp(const ExtroPOSApp());
}

class ExtroPOSApp extends StatelessWidget {
  const ExtroPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExtroPOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
          surface: Colors.white,
        ),
        fontFamily: 'sans-serif',
      ),
      home: const MainPOSScreen(),
    );
  }
}

// --- Models ---

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

// --- Main Screen ---

class MainPOSScreen extends StatefulWidget {
  const MainPOSScreen({super.key});

  @override
  State<MainPOSScreen> createState() => _MainPOSScreenState();
}

class _MainPOSScreenState extends State<MainPOSScreen> {
  // State variables for UI control
  POSMode activeMode = POSMode.cafe;
  String activeTab = 'POS';
  bool isSidebarCollapsed = false;
  List<CartItem> cart = [];
  String searchQuery = '';
  String activeCategory = 'All';

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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ExtroPOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Terminal #01', style: TextStyle(color: Colors.grey, fontSize: 10)),
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

  Widget _sidebarItem(IconData icon, String label, {bool isActive = false}) {
    return InkWell(
      onTap: () => setState(() => activeTab = label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: isActive ? Colors.white : Colors.grey.shade600, size: 20),
            if (!isSidebarCollapsed) ...[
              const SizedBox(width: 12),
              Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w500, fontSize: 14)),
            ]
          ],
        ),
      ),
    );
  }

ing culprits...) but not executed earlier.


}