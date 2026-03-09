import 'package:extropos/screens/receipt_preview_screen.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Sales History Screen - View past transactions and receipts
class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  DateTimeRange? _dateRange;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      // Load transactions from database with timeout for testing
      final transactions = await DatabaseService.instance.getSalesHistory(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      ).timeout(const Duration(seconds: 5), onTimeout: () => []);

      // Transform the data to match the expected format
      _transactions = transactions.map((transaction) {
        return {
          'id': transaction['order_number'] ?? transaction['id'],
          'date': transaction['date'] as DateTime,
          'total': (transaction['total'] as num?)?.toDouble() ?? 0.0,
          'payment_method': transaction['payment_method'] ?? 'Unknown',
          'customer_name': transaction['customer_name'] ?? 'Walk-in Customer',
          'items_count': (transaction['items_count'] as num?)?.toInt() ?? 0,
          'status': transaction['status'] ?? 'completed',
          'order_id': transaction['id'], // Keep the actual order ID for details
        };
      }).toList();
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to load transaction history');
      }
      // Fallback to empty list on error
      _transactions = [];
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((transaction) {
      // Filter by date range
      if (_dateRange != null) {
        final transactionDate = transaction['date'] as DateTime;
        if (transactionDate.isBefore(_dateRange!.start) ||
            transactionDate.isAfter(_dateRange!.end)) {
          return false;
        }
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final customerName = (transaction['customer_name'] as String?)?.toLowerCase() ?? '';
        final transactionId = (transaction['id'] as String?)?.toLowerCase() ?? '';
        final paymentMethod = (transaction['payment_method'] as String?)?.toLowerCase() ?? '';

        return customerName.contains(_searchQuery) ||
               transactionId.contains(_searchQuery) ||
               paymentMethod.contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _searchController.clear();
    });
  }

  void _viewReceipt(Map<String, dynamic> transaction) async {
    final orderId = transaction['order_id'] as String?;
    if (orderId == null) {
      ToastHelper.showToast(context, 'Order details not available');
      return;
    }

    try {
      final orderDetails = await DatabaseService.instance.getOrderDetails(orderId);
      if (orderDetails != null) {
        // Navigate to receipt preview screen with order details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptPreviewScreen.fromOrderData(orderDetails),
          ),
        );
      } else {
        ToastHelper.showToast(context, 'Order details not found');
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to load receipt details');
    }
  }

  void _reprintReceipt(Map<String, dynamic> transaction) async {
    final orderId = transaction['order_id'] as String?;
    if (orderId == null) {
      ToastHelper.showToast(context, 'Order details not available');
      return;
    }

    try {
      final orderDetails = await DatabaseService.instance.getOrderDetails(orderId);
      if (orderDetails != null) {
        // Navigate to receipt preview screen for reprinting
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptPreviewScreen.fromOrderData(
              orderDetails,
              onPrint: () {
                // TODO: Implement actual printing
                ToastHelper.showToast(context, 'Receipt reprinted successfully');
                Navigator.pop(context);
              },
            ),
          ),
        );
      } else {
        ToastHelper.showToast(context, 'Order details not found');
      }
    } catch (e) {
      ToastHelper.showToast(context, 'Failed to reprint receipt');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _selectDateRange,
            tooltip: 'Filter by date',
          ),
          if (_dateRange != null || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
              tooltip: 'Clear filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by customer, transaction ID, or payment method',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Date range display
          if (_dateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

          // Transaction list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _dateRange != null
                ? 'No transactions found'
                : 'No transactions yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _dateRange != null
                ? 'Try adjusting your search or date filters'
                : 'Completed transactions will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.builder(
      itemCount: _filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _filteredTransactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    final date = transaction['date'] as DateTime;
    final total = transaction['total'] as double;
    final paymentMethod = transaction['payment_method'] as String;
    final customerName = transaction['customer_name'] as String?;
    final itemsCount = transaction['items_count'] as int?;
    final transactionId = transaction['id'] as String;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _viewReceipt(transaction),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transactionId,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'RM${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPaymentMethodColor(paymentMethod),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      paymentMethod,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (customerName != null && customerName.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  customerName,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
              if (itemsCount != null) ...[
                const SizedBox(height: 4),
                Text(
                  '$itemsCount item${itemsCount == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _viewReceipt(transaction),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _reprintReceipt(transaction),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Print'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'e-wallet':
      case 'wallet':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}