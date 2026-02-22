import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';import 'package:flutter/material.dart'

// --- Theme Colors ---
class AppColors {
  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber800 = Color(0xFF92400E);
  static const Color indigo600 = Color(0xFF4F46E5);
}

// --- Models ---
enum RefundView { lookup, details, auth, success }

class TransactionItem {
  final int id;
  final String name;
  final double price;
  final int qty;
  final String category;

  TransactionItem(this.id, this.name, this.price, this.qty, this.category);
}

class Transaction {
  final String id;
  final String date;
  final String time;
  final String cashier;
  final String customer;
  final String customerPhone;
  final double total;
  final String paymentMethod;
  final String status;
  final List<TransactionItem> items;

  Transaction(this.id, this.date, this.time, this.cashier, this.customer,
      this.customerPhone, this.total, this.paymentMethod, this.status, this.items);
}

// --- Refund Service Screen ---
class RefundServiceScreen extends StatefulWidget {
  const RefundServiceScreen({super.key});

  @override
  State<RefundServiceScreen> createState() => _RefundServiceScreenState();
}

class _RefundServiceScreenState extends State<RefundServiceScreen> {
  RefundView _currentView = RefundView.lookup;
  String _searchQuery = "";
  Transaction? _selectedTransaction;
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoadingTransactions = false;

  Set<int> _refundItems = {};
  Map<int, bool> _restockMap = {};

  String _refundReason = "";
  String _refundMethod = "";
  String _internalNotes = "";
  String _managerPin = "";

  @override
  void initState() {
    super.initState();
    _loadRecentTransactions();
  }

  /// Load recent transactions from database
  Future<void> _loadRecentTransactions() async {
    setState(() => _isLoadingTransactions = true);
    try {
      final orders = await DatabaseService.instance.getOrders(
        limit: 20,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _recentTransactions = orders;
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      print('Error loading recent transactions: $e');
      if (mounted) {
        setState(() => _isLoadingTransactions = false);
      }
    }
  }

  /// Search for a transaction by order number/receipt ID
  Future<void> _handleSearch() async {
    if (_searchQuery.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a receipt ID'), duration: Duration(seconds: 2)),
      );
      return;
    }

    try {
      setState(() => _isLoadingTransactions = true);
      
      // Search through recent transactions for matching order number
      final matchingOrder = _recentTransactions.firstWhere(
        (order) {
          final orderNumber = order['order_number']?.toString() ?? '';
          final orderId = order['id']?.toString() ?? '';
          return orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              orderId.toLowerCase().contains(_searchQuery.toLowerCase());
        },
        orElse: () => <String, dynamic>{},
      );

      if (matchingOrder.isNotEmpty) {
        // Found a matching order, now load its items
        final orderId = matchingOrder['id'].toString();
        final items = await DatabaseService.instance.getOrderItems(orderId);
        
        // Convert to Transaction model
        final transaction = _mapOrderToTransaction(matchingOrder, items);
        
        if (mounted) {
          setState(() {
            _selectedTransaction = transaction;
            _currentView = RefundView.details;
            _isLoadingTransactions = false;
          });
        }
      } else {
        // No match found, show error
        if (mounted) {
          setState(() => _isLoadingTransactions = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt not found'), duration: Duration(seconds: 2)),
          );
        }
      }
    } catch (e) {
      print('Error searching transactions: $e');
      if (mounted) {
        setState(() => _isLoadingTransactions = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  /// Map database order and order items to Transaction model
  Transaction _mapOrderToTransaction(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> orderItems,
  ) {
    final items = <TransactionItem>[];
    for (int i = 0; i < orderItems.length; i++) {
      final item = orderItems[i];
      items.add(
        TransactionItem(
          i + 1, // id
          item['item_name'] as String? ?? 'Unknown Item',
          (item['item_price'] as num?)?.toDouble() ?? 0.0,
          (item['quantity'] as num?)?.toInt() ?? 1,
          'general', // category
        ),
      );
    }

    // Parse created_at to extract date and time
    DateTime createdAt = DateTime.now();
    String date = FormattingService.date(createdAt);
    String time = FormattingService.time(createdAt);
    
    try {
      if (order['created_at'] != null) {
        createdAt = DateTime.parse(order['created_at'] as String);
        date = FormattingService.date(createdAt);
        time = FormattingService.time(createdAt);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }

    return Transaction(
      order['order_number']?.toString() ?? order['id']?.toString() ?? 'N/A',
      date,
      time,
      order['created_by'] as String? ?? 'POS System',
      order['customer_name'] as String? ?? 'Walk-in Customer',
      order['customer_phone'] as String? ?? 'N/A',
      (order['total'] as num?)?.toDouble() ?? 0.0,
      order['payment_method'] as String? ?? 'Unknown',
      order['status'] as String? ?? 'completed',
      items,
    );
  }

  void _toggleItem(int itemId) {
    setState(() {
      if (_refundItems.contains(itemId)) {
        _refundItems.remove(itemId);
      } else {
        _restockMap[itemId] = true;
        _refundItems.add(itemId);
      }
    });
  }

  void _selectAllItems() {
    if (_selectedTransaction != null) {
      setState(() {
        final allIds = _selectedTransaction!.items.map((e) => e.id).toSet();
        _refundItems = allIds;
        _restockMap = {for (var id in allIds) id: true};
      });
    }
  }

  void _resetSelection() {
    setState(() {
      _refundItems.clear();
      _restockMap.clear();
      _refundMethod = "";
      _refundReason = "";
      _internalNotes = "";
    });
  }

  double get _refundTotal {
    if (_selectedTransaction == null) return 0.0;
    return _selectedTransaction!.items
        .where((i) => _refundItems.contains(i.id))
        .fold(0.0, (sum, i) => sum + (i.price * i.qty));
  }

  bool get _isWholeBill {
    if (_selectedTransaction == null) return false;
    return _refundItems.length == _selectedTransaction!.items.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Container(height: 1, color: AppColors.slate200),
          Expanded(
            child: Row(
              children: [
                _buildLeftPanel(),
                Container(width: 1, color: AppColors.slate200),
                Expanded(child: _buildRightPanel()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 80,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.rose50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.refresh, color: AppColors.rose600),
              ),
              const SizedBox(width: 16),
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Refund & Void Service", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                  Text("ORDER CORRECTION PROTOCOL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                ],
              ),
            ],
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.slate400, size: 18),
            label: const Text("Exit to POS", style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 400,
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("TRANSACTION LOOKUP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate400)),
          const SizedBox(height: 16),
          TextField(
            onChanged: (val) => _searchQuery = val,
            decoration: InputDecoration(
              hintText: "Scan receipt or enter ID (FP-...)",
              prefixIcon: const Icon(Icons.search, color: AppColors.slate400),
              filled: true,
              fillColor: AppColors.slate50,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.rose500)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _handleSearch,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Search", style: TextStyle(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RECENT TRANSACTIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate400)),
              Text("View All", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.indigo600)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingTransactions
                ? const Center(child: CircularProgressIndicator())
                : _recentTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, color: AppColors.slate200, size: 40),
                            const SizedBox(height: 12),
                            const Text("No transactions loaded", style: TextStyle(fontSize: 14, color: AppColors.slate400, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            const Text("Search by receipt ID to begin", style: TextStyle(fontSize: 12, color: AppColors.slate400)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _recentTransactions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final tx = _recentTransactions[index];
                          return InkWell(
                            onTap: () async {
                              final orderId = tx['id'].toString();
                              final items = await DatabaseService.instance.getOrderItems(orderId);
                              final transaction = _mapOrderToTransaction(tx, items);
                              if (mounted) {
                                setState(() {
                                  _selectedTransaction = transaction;
                                  _currentView = RefundView.details;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tx['order_number']?.toString() ?? tx['id']?.toString() ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                                      Text("${FormattingService.time(DateTime.parse(tx['created_at'] as String? ?? ''))} • ${tx['created_by'] as String? ?? 'POS'}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("RM ${((tx['total'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                                      Text(tx['payment_method'] as String? ?? 'Unknown', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.amber50, border: Border.all(color: AppColors.amber100), borderRadius: BorderRadius.circular(16)),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.amber600, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text("Refund Policy: Items returned after 24 hours require regional manager approval.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amber800))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: AppColors.slate50,
      padding: const EdgeInsets.all(48),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case RefundView.lookup:
        return _buildLookupEmptyState();
      case RefundView.details:
        return _selectedTransaction != null ? _buildDetailsPanel() : _buildLookupEmptyState();
      case RefundView.auth:
        return _buildAuthPanel();
      case RefundView.success:
        return _buildSuccessPanel();
    }
  }

  Widget _buildLookupEmptyState() {
    return Center(
      key: const ValueKey('lookup'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40), border: Border.all(color: AppColors.slate100)),
            child: const Icon(Icons.refresh, color: AppColors.slate200, size: 48),
          ),
          const SizedBox(height: 24),
          const Text("Ready for Refund", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slate400)),
          const SizedBox(height: 8),
          const Text("Search or select a transaction to start.", style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel() {
    final tx = _selectedTransaction!;
    final isFormValid = _refundItems.isNotEmpty && _refundReason.isNotEmpty && _refundMethod.isNotEmpty;

    return Column(
      key: const ValueKey('details'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.slate200)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildHeaderCol("RECEIPT ID", tx.id, isLarge: true),
              _buildHeaderCol("CUSTOMER", tx.customer),
              _buildHeaderCol("ORIGINAL TOTAL", "RM ${tx.total.toStringAsFixed(2)}", isLarge: true),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("PAID VIA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
                    child: Text(tx.paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  )
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Items List
              Expanded(
                flex: 5,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("SELECT ITEMS TO REFUND", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                        TextButton(
                          onPressed: _selectAllItems,
                          child: Text(_isWholeBill ? "ALL SELECTED" : "SELECT ALL", style: TextStyle(color: _isWholeBill ? AppColors.rose600 : AppColors.indigo600, fontWeight: FontWeight.w900)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        itemCount: tx.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = tx.items[index];
                          final selected = _refundItems.contains(item.id);
                          return InkWell(
                            onTap: () => _toggleItem(item.id),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.rose50 : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: selected ? AppColors.rose500 : AppColors.slate100, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(color: selected ? AppColors.rose600 : AppColors.slate100, borderRadius: BorderRadius.circular(12)),
                                    child: Icon(selected ? Icons.check : Icons.local_offer, color: selected ? Colors.white : AppColors.slate400),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(item.category.toUpperCase(), style: const TextStyle(fontSize: 12, color: AppColors.slate400, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    Column(
                                      children: [
                                        const Text("RESTOCK?", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                                        Switch(
                                          value: _restockMap[item.id] ?? true,
                                          activeColor: AppColors.emerald500,
                                          onChanged: (val) {
                                            setState(() => _restockMap[item.id] = val);
                                          },
                                        )
                                      ],
                                    ),
                                  const SizedBox(width: 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("RM ${(item.price * item.qty).toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                                      Text("Qty: ${item.qty}", style: const TextStyle(fontSize: 10, color: AppColors.slate400, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(width: 32),
              // Summary Sidebar
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), border: Border.all(color: AppColors.slate200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("SUMMARY", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                          if (_isWholeBill)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.rose100, borderRadius: BorderRadius.circular(4)),
                              child: const Text("FULL VOID", style: TextStyle(color: AppColors.rose600, fontSize: 8, fontWeight: FontWeight.w900)),
                            )
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text("REASON FOR RETURN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _refundReason.isEmpty ? null : _refundReason,
                        hint: const Text("Select a reason..."),
                        items: ["Damaged Goods", "Expired Item", "Wrong Order Taken", "Customer Change of Mind", "Full Bill Cancellation"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => _refundReason = val ?? ""),
                        decoration: InputDecoration(
                          filled: true, fillColor: AppColors.slate50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.rose500)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text("REFUND VIA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 3,
                          children: [
                            _buildMethodBtn("Original", Icons.refresh),
                            _buildMethodBtn("Cash", Icons.attach_money),
                            _buildMethodBtn("E-Wallet", Icons.account_balance_wallet),
                            _buildMethodBtn("Credit", Icons.person),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(height: 1, color: AppColors.slate100),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("ITEMS SELECTED", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate400)),
                          Text("${_refundItems.length}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL REFUND", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                          Text("RM ${_refundTotal.toStringAsFixed(2)}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.rose600)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (!_isWholeBill && _refundItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: SizedBox(
                            width: double.infinity, height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                _selectAllItems();
                                setState(() => _refundReason = "Full Bill Cancellation");
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                              child: const Text("Return Whole Bill", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity, height: 64,
                        child: ElevatedButton(
                          onPressed: isFormValid ? () => setState(() => _currentView = RefundView.auth) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isWholeBill ? AppColors.rose600 : AppColors.rose500,
                            disabledBackgroundColor: AppColors.slate200,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                          child: Text(_isWholeBill ? "Void Whole Bill" : "Authorize Refund", style: TextStyle(color: isFormValid ? Colors.white : AppColors.slate400, fontSize: 18, fontWeight: FontWeight.w900)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _resetSelection,
                          child: const Text("Reset Selection", style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildMethodBtn(String method, IconData icon) {
    final sel = _refundMethod == method;
    return InkWell(
      onTap: () => setState(() => _refundMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: sel ? AppColors.rose50 : AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.rose500 : Colors.transparent, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: sel ? AppColors.rose600 : AppColors.slate400),
            const SizedBox(width: 8),
            Text(method.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: sel ? AppColors.rose600 : AppColors.slate400)),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthPanel() {
    return Center(
      key: const ValueKey('auth'),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(48), border: Border.all(color: AppColors.slate100)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.rose600, borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.lock, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text("Security Verification", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slate900)),
            const SizedBox(height: 8),
            Text(_isWholeBill ? "CRITICAL: Full transaction void." : "Required for partial return.", style: const TextStyle(fontSize: 14, color: AppColors.slate400)),
            const SizedBox(height: 8),
            Text("RM ${_refundTotal.toStringAsFixed(2)} via $_refundMethod", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.rose600)),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                bool active = _managerPin.length > index;
                return Container(
                  width: 56, height: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: active ? AppColors.rose50 : AppColors.slate50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? AppColors.rose600 : AppColors.slate100, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: active ? const Text("•", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.rose600)) : null,
                );
              }),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 300,
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: ["1","2","3","4","5","6","7","8","9","C","0","DEL"].map((key) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (key == "C") {
                          _managerPin = "";
                        } else if (key == "DEL") {
                          if (_managerPin.isNotEmpty) _managerPin = _managerPin.substring(0, _managerPin.length - 1);
                        } else {
                          if (_managerPin.length < 4) {
                            _managerPin += key;
                            if (_managerPin.length == 4) {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                setState(() => _currentView = RefundView.success);
                              });
                            }
                          }
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.transparent),
                      child: Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.slate900)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => setState(() {
                _currentView = RefundView.details;
                _managerPin = "";
              }),
              child: const Text("GO BACK", style: TextStyle(color: AppColors.slate400, fontWeight: FontWeight.bold, letterSpacing: 1)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessPanel() {
    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 128, height: 128,
            decoration: BoxDecoration(color: AppColors.emerald100, borderRadius: BorderRadius.circular(40)),
            child: const Icon(Icons.check_circle, color: AppColors.emerald600, size: 64),
          ),
          const SizedBox(height: 32),
          Text(_isWholeBill ? "Receipt Voided" : "Refund Successful", style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.slate900)),
          const SizedBox(height: 16),
          Text("Balance of RM ${_refundTotal.toStringAsFixed(2)} has been issued via $_refundMethod.", style: const TextStyle(fontSize: 20, color: AppColors.slate400, fontWeight: FontWeight.w500)),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200, height: 64,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.print, color: Colors.white),
                  label: const Text("Print Note", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.slate900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200, height: 64,
                child: OutlinedButton(
                  onPressed: () {
                    _resetSelection();
                    setState(() {
                      _managerPin = "";
                      _selectedTransaction = null;
                      _searchQuery = "";
                      _currentView = RefundView.lookup;
                    });
                  },
                  style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: AppColors.slate200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: const Text("Back to Lookup", style: TextStyle(color: AppColors.slate900, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHeaderCol(String title, String value, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate400)),
        Text(value, style: TextStyle(fontSize: isLarge ? 18 : 14, fontWeight: isLarge ? FontWeight.w900 : FontWeight.bold)),
      ],
    );
  }
}
