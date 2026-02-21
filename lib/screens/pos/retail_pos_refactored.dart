import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// -----------------------------------------------------------------------------
// Simple refactored POS screen extracted from the sample the user provided.
// Each logical section is broken into its own widget and all callbacks are
// wired through the top–level state class.  You can drop this file into the
// `screens/pos` folder and push a route to `RetailPosRefactorScreen` from
// anywhere (for example, by adding it to UnifiedPOSScreen for retail mode).
// -----------------------------------------------------------------------------

// --- Models (would normally live in models/ but kept here for brevity) ---
class Product {
  final int id;
  final String name;
  final double price;
  final String category;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final String barcode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.barcode,
  });
}

class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, this.qty = 1});
}

// --- Sample data ---
final List<String> _kCategories = [
  'All',
  'Beverages',
  'Pastries',
  'Food',
  'Desserts',
];

final List<Product> _kMockProducts = [
  Product(
      id: 1,
      name: 'Espresso',
      price: 3.50,
      category: 'Beverages',
      barcode: '100001',
      icon: Icons.coffee,
      bgColor: Colors.orange[100]!,
      iconColor: Colors.orange[800]!),
  Product(
      id: 2,
      name: 'Cappuccino',
      price: 4.50,
      category: 'Beverages',
      barcode: '100002',
      icon: Icons.coffee,
      bgColor: Colors.orange[100]!,
      iconColor: Colors.orange[800]!),
  Product(
      id: 3,
      name: 'Iced Latte',
      price: 5.00,
      category: 'Beverages',
      barcode: '100003',
      icon: Icons.coffee_maker,
      bgColor: Colors.orange[100]!,
      iconColor: Colors.orange[800]!),
  Product(
      id: 4,
      name: 'Matcha Green Tea',
      price: 5.50,
      category: 'Beverages',
      barcode: '100004',
      icon: Icons.emoji_food_beverage,
      bgColor: Colors.green[100]!,
      iconColor: Colors.green[800]!),
  Product(
      id: 5,
      name: 'Butter Croissant',
      price: 3.00,
      category: 'Pastries',
      barcode: '200001',
      icon: Icons.bakery_dining,
      bgColor: Colors.amber[100]!,
      iconColor: Colors.amber[900]!),
  Product(
      id: 6,
      name: 'Chocolate Muffin',
      price: 3.50,
      category: 'Pastries',
      barcode: '200002',
      icon: Icons.cake,
      bgColor: Colors.amber[100]!,
      iconColor: Colors.amber[900]!),
  Product(
      id: 7,
      name: 'Blueberry Danish',
      price: 4.00,
      category: 'Pastries',
      barcode: '200003',
      icon: Icons.pie_chart,
      bgColor: Colors.amber[100]!,
      iconColor: Colors.amber[900]!),
  Product(
      id: 8,
      name: 'Turkey Sandwich',
      price: 8.50,
      category: 'Food',
      barcode: '300001',
      icon: Icons.lunch_dining,
      bgColor: Colors.red[100]!,
      iconColor: Colors.red[800]!),
  Product(
      id: 9,
      name: 'Avocado Toast',
      price: 9.00,
      category: 'Food',
      barcode: '300002',
      icon: Icons.breakfast_dining,
      bgColor: Colors.green[100]!,
      iconColor: Colors.green[800]!),
  Product(
      id: 10,
      name: 'Caesar Salad',
      price: 7.50,
      category: 'Food',
      barcode: '300003',
      icon: Icons.local_dining,
      bgColor: Colors.green[100]!,
      iconColor: Colors.green[800]!),
  Product(
      id: 11,
      name: 'Vanilla Sundae',
      price: 4.50,
      category: 'Desserts',
      barcode: '400001',
      icon: Icons.icecream,
      bgColor: Colors.pink[100]!,
      iconColor: Colors.pink[800]!),
  Product(
      id: 12,
      name: 'Cheesecake Slice',
      price: 6.00,
      category: 'Desserts',
      barcode: '400002',
      icon: Icons.cake,
      bgColor: Colors.pink[100]!,
      iconColor: Colors.pink[800]!),
];

// -----------------------------------------------------------------------------
// Main screen that hosts the refactored widgets.
// -----------------------------------------------------------------------------
class RetailPosRefactorScreen extends StatefulWidget {
  const RetailPosRefactorScreen({super.key});

  @override
  State<RetailPosRefactorScreen> createState() => _RetailPosRefactorScreenState();
}

class _RetailPosRefactorScreenState extends State<RetailPosRefactorScreen> {
  List<CartItem> cart = [];
  String activeCategory = 'All';
  String searchQuery = '';
  bool isBusinessOpen = false;
  bool isShiftActive = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  // barcode scanner fields
  final FocusNode _keyboardFocusNode = FocusNode();
  String _barcodeBuffer = '';
  DateTime _lastKeystrokeTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // barcode handling
  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();
      if (now.difference(_lastKeystrokeTime).inMilliseconds > 100) {
        _barcodeBuffer = '';
      }
      _lastKeystrokeTime = now;
      if (event.logicalKey.keyLabel == 'Enter') {
        if (_barcodeBuffer.isNotEmpty) {
          _processScannedBarcode(_barcodeBuffer);
          _barcodeBuffer = '';
        }
      } else if (event.character != null) {
        _barcodeBuffer += event.character!;
      }
    }
  }

  void _processScannedBarcode(String barcode) {
    try {
      final prod = _kMockProducts.firstWhere((p) => p.barcode == barcode);
      _addToCart(prod);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${prod.name} via barcode'),
          backgroundColor: Colors.green,
          duration: const Duration(milliseconds: 1200),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode "$barcode" not found'),
          backgroundColor: Colors.red,
        ),
      );
    }
    _keyboardFocusNode.requestFocus();
  }

  List<Product> get _filteredProducts {
    return _kMockProducts.where((p) {
      final matchesCat = activeCategory == 'All' || p.category == activeCategory;
      final matchesSearch = p.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  double get _subtotal => cart.fold(0.0, (s, i) => s + i.product.price * i.qty);
  double get _tax => _subtotal * 0.06;
  double get _total => _subtotal + _tax;

  /// cart manipulation helpers – wired downwards
  void _addToCart(Product p) {
    setState(() {
      final idx = cart.indexWhere((c) => c.product.id == p.id);
      if (idx >= 0) {
        cart[idx].qty++;
      } else {
        cart.add(CartItem(product: p));
      }
    });
  }

  void _updateQty(int productId, int delta) {
    setState(() {
      final idx = cart.indexWhere((c) => c.product.id == productId);
      if (idx >= 0) {
        cart[idx].qty += delta;
        if (cart[idx].qty <= 0) cart.removeAt(idx);
      }
    });
  }

  void _clearCart() => setState(() => cart.clear());
  void _checkout() {
    if (cart.isEmpty) return;
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green[100], shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Payment Successful!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('The order for RM ${_total.toStringAsFixed(2)} has been processed.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  _clearCart();
                  Navigator.pop(context);
                },
                child: const Text('Start New Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Drawer and cash/shift reporting helpers (copied from original sample)
  // ---------------------------------------------------------------------------
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 24),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.storefront, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.indigo),
                  title: const Text('Reports', style: TextStyle(fontWeight: FontWeight.w500)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.settings, color: Colors.grey),
                  title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w500)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: Icon(Icons.schedule, color: isBusinessOpen ? Colors.red : Colors.green),
                  title: Text(isBusinessOpen ? 'Close Register' : 'Open Register',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => _showCashModal(false),
                ),
                ListTile(
                  leading: Icon(
                    isShiftActive ? Icons.stop_circle : Icons.play_circle_fill,
                    color: (!isBusinessOpen && !isShiftActive) ? Colors.grey[300] :
                        (isShiftActive ? Colors.orange : Colors.blue),
                  ),
                  title: Text(isShiftActive ? 'End Shift' : 'Start Shift',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: (!isBusinessOpen && !isShiftActive) ? Colors.grey[400] : Colors.black87,
                      )),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  enabled: isBusinessOpen || isShiftActive,
                  onTap: () => _showCashModal(true),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_open, color: Colors.grey),
                  title: const Text('Open Drawer', style: TextStyle(fontWeight: FontWeight.w500)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(context),
                ),
                const Divider(height: 32),
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.red),
                  title: const Text('Lock Terminal',
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.red)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
            child: const Text('ExtroPOS v1.0.0',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }

  void _showCashModal(bool isShiftManagement) {
    Navigator.pop(context); // close drawer
    final TextEditingController amountController = TextEditingController();
    bool isOpening = isShiftManagement ? !isShiftActive : !isBusinessOpen;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                isShiftManagement
                    ? (isOpening ? 'Start Shift' : 'End Shift')
                    : (isOpening ? 'Open Register' : 'Close Register'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isShiftManagement
                        ? (isOpening ? 'Enter the starting cash float for your shift.' : 'Enter the current cash amount in the drawer to close your shift.')
                        : (isOpening ? 'Enter the starting cash (opening balance) for today\'s shift.' : 'Enter the final cash amount in the drawer to close the register.'),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: 'RM ',
                      prefixStyle: TextStyle(color: Colors.grey[600], fontSize: 24),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (val) => setStateDialog(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isShiftManagement ? Colors.blue : Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: amountController.text.isEmpty
                      ? null
                      : () {
                          double amount = double.tryParse(amountController.text) ?? 0.0;
                          Navigator.pop(context);
                          _processCashConfirmation(isShiftManagement, amount);
                        },
                  child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _processCashConfirmation(bool isShiftManagement, double amount) {
    final now = DateTime.now();
    final dateStr = DateFormat('MM/dd/yyyy').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);

    setState(() {
      if (isShiftManagement) {
        if (isShiftActive) {
          _showReportModal(
            isZReport: false,
            title: 'X-Report',
            subtitle: '${now.hour < 12 ? 'Morning' : 'Evening'} Shift Summary',
            date: dateStr,
            time: timeStr,
            openingCash: 250.00,
            closingCash: amount,
            totalSales: 450.00,
            transactions: 12,
          );
        }
        isShiftActive = !isShiftActive;
      } else {
        if (isBusinessOpen) {
          _showReportModal(
            isZReport: true,
            title: 'Z-Report',
            subtitle: 'End of Day Summary',
            date: dateStr,
            time: timeStr,
            openingCash: 250.00,
            closingCash: amount,
            totalSales: 1450.50,
            transactions: 32,
          );
          if (isShiftActive) isShiftActive = false;
        }
        isBusinessOpen = !isBusinessOpen;
      }
    });
  }

  void _showReportModal({
    required bool isZReport,
    required String title,
    required String subtitle,
    required String date,
    required String time,
    required double openingCash,
    required double closingCash,
    required double totalSales,
    required int transactions,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                color: Colors.blueGrey[900],
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(isZReport ? Icons.receipt_long : Icons.assignment, color: Colors.white70, size: 40),
                    const SizedBox(height: 12),
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: DefaultTextStyle(
                  style: const TextStyle(fontFamily: 'monospace', color: Colors.black87, fontSize: 14),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Date:'), Text(date)]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Time:'), Text(time)]),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(style: ListTileStyle.list)),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isZReport ? 'Opening Cash:' : 'Shift Starting Cash:'), Text('RM ${openingCash.toStringAsFixed(2)}')]),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isZReport ? 'Closing Cash (Declared):' : 'Shift Ending Cash:', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('RM ${closingCash.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))
                        ]
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isZReport ? 'Total Transactions:' : 'Shift Transactions:'), Text('$transactions')]),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isZReport ? 'Net Sales:' : 'Shift Net Sales:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('RM ${totalSales.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                        ]
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      const SizedBox(height: 8),
                      const Text('END OF REPORT', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.grey[50],
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Close', style: TextStyle(color: Colors.black87)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printing report...')));
                        },
                        icon: const Icon(Icons.print, color: Colors.white, size: 20),
                        label: const Text('Print', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isZReport ? Colors.indigo : Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKey,
      autofocus: true,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _PosHeader(
                    searchController: _searchController,
                    onSearchChanged: (v) => setState(() => searchQuery = v),
                    onSearchTapOutside: () => _keyboardFocusNode.requestFocus(),
                    onMenuPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  _CategoryChips(
                    categories: _kCategories,
                    active: activeCategory,
                    onSelected: (c) => setState(() => activeCategory = c),
                  ),
                  Expanded(
                    child: _ProductGrid(
                      products: _filteredProducts,
                      onAdd: _addToCart,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 400,
              color: Colors.white,
              child: _CartPanel(
                cart: cart,
                subtotal: _subtotal,
                tax: _tax,
                total: _total,
                onQtyChange: _updateQty,
                onClear: _clearCart,
                onCheckout: _checkout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// small stateless widgets used by the screen

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    );
  }
}

class _PosHeader extends StatelessWidget {
  const _PosHeader({
    required this.searchController,
    required this.onSearchChanged,
    required this.onSearchTapOutside,
    required this.onMenuPressed,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSearchTapOutside;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: onMenuPressed,
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.storefront, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text('ExtroPOS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Spacer(),
          SizedBox(
            width: 300,
            child: TextField(
              controller: searchController,
              onTapOutside: (_) => onSearchTapOutside(),
              onSubmitted: (_) => onSearchTapOutside(),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: onSearchChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.active,
    required this.onSelected,
  });

  final List<String> categories;
  final String active;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isActive = cat == active;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
              selected: isActive,
              selectedColor: Colors.indigo,
              backgroundColor: Colors.grey[100],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onSelected: (_) => onSelected(cat),
            ),
          );
        },
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.products, required this.onAdd});
  final List<Product> products;
  final ValueChanged<Product> onAdd;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Try adjusting your search or category filter.', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        return InkWell(
          onTap: () => onAdd(p),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: p.bgColor, shape: BoxShape.circle),
                  child: Icon(p.icon, size: 40, color: p.iconColor),
                ),
                const SizedBox(height: 16),
                Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('RM ${p.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({
    required this.cart,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.onQtyChange,
    required this.onClear,
    required this.onCheckout,
  });

  final List<CartItem> cart;
  final double subtotal;
  final double tax;
  final double total;
  final void Function(int productId, int delta) onQtyChange;
  final VoidCallback onClear;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
              left: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.shopping_cart, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Current Order',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              if (cart.isNotEmpty)
                TextButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                  label: const Text('Clear', style: TextStyle(color: Colors.red)),
                )
            ],
          ),
        ),
        Expanded(
          child: cart.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration:
                            BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                        child: Icon(Icons.shopping_cart_outlined,
                            size: 48, color: Colors.grey[300]),
                      ),
                      const SizedBox(height: 16),
                      Text('Your cart is empty',
                          style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: item.product.bgColor,
============================================================================// they simply render pieces of UI and call the callbacks supplied by the state.
