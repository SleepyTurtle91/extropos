import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:extropos/widgets/refund_dialog.dart';
import 'package:extropos/widgets/void_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RefundScreen extends StatefulWidget {
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  final _searchController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTimeRange? _dateRange;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Default to last 7 days
    _dateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 7)),
      end: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _searchOrders() async {
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      List<Map<String, dynamic>> results = [];

      if (_searchController.text.trim().isNotEmpty) {
        // Search by order number
        final order = await DatabaseService.instance.getOrderByNumber(
          _searchController.text.trim(),
        );
        if (order != null) {
          results.add(order);
        }
      } else if (_phoneController.text.trim().isNotEmpty) {
        // Search by customer phone
        results = await DatabaseService.instance.getOrdersByCustomerPhone(
          _phoneController.text.trim(),
          _dateRange!,
        );
      } else if (_dateRange != null) {
        // Search by date range
        results = await DatabaseService.instance.getOrdersInDateRange(
          _dateRange!.start,
          _dateRange!.end,
        );
      }

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      if (results.isEmpty && mounted) {
        ToastHelper.showToast(context, 'No orders found');
      }
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ToastHelper.showToast(context, 'Search failed: $e');
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2563EB)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _processRefund(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (context) => RefundDialog(orderData: orderData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Refunds & Returns'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Search Orders',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Order number search
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Order/Receipt Number',
                      prefixIcon: Icon(Icons.receipt),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _phoneController.clear();
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Customer phone search
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Customer Phone',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        _searchController.clear();
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // Date range selector
                  OutlinedButton.icon(
                    onPressed: _selectDateRange,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _dateRange != null
                          ? '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}'
                          : 'Select Date Range',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Search button
                  ElevatedButton(
                    onPressed: _isSearching ? null : _searchOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSearching
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Search Orders'),
                  ),
                ],
              ),
            ),
          ),

          // Results Section
          if (_searchResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_searchResults.length} order(s) found',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
          ],

          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Search for orders to process refunds',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final order = _searchResults[index];
                      return _OrderCard(
                        order: order,
                        onTap: () => _processRefund(order),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currency = BusinessInfo.instance.currencySymbol;
    final orderDate = DateTime.parse(order['created_at'] as String);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2563EB),
              child: const Icon(Icons.receipt_long, color: Colors.white),
            ),
            title: Text(
              order['order_number'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${DateFormat('MMM dd, yyyy HH:mm').format(orderDate)}\n'
              '${order['customer_name'] ?? 'Walk-in'} • ${order['payment_method'] ?? 'Cash'}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency ${(order['total'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${order['item_count'] ?? 0} items',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            isThreeLine: true,
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Item Return'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Process void
                      showDialog(
                        context: context,
                        builder: (context) => VoidDialog(orderData: order),
                      );
                    },
                    icon: const Icon(Icons.delete_forever, size: 18),
                    label: const Text('Void Sale'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
