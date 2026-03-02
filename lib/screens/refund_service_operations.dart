part of 'refund_service_screen.dart';

/// Extension containing business logic and data operations for refund service
extension RefundServiceOperations on _RefundServiceScreenState {
  /// Load recent transactions from database
  Future<void> loadRecentTransactions() async {
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
  Future<void> handleSearch() async {
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
        final transaction = mapOrderToTransaction(matchingOrder, items);
        
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
  Transaction mapOrderToTransaction(
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
    String date = DateFormat('yyyy-MM-dd').format(createdAt);
    String time = DateFormat('HH:mm').format(createdAt);
    
    try {
      if (order['created_at'] != null) {
        createdAt = DateTime.parse(order['created_at'] as String);
        date = DateFormat('yyyy-MM-dd').format(createdAt);
        time = DateFormat('HH:mm').format(createdAt);
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

  /// Handle transaction selection from recent list
  Future<void> handleTransactionSelect(Map<String, dynamic> tx) async {
    final orderId = tx['id'].toString();
    final items = await DatabaseService.instance.getOrderItems(orderId);
    final transaction = mapOrderToTransaction(tx, items);
    if (mounted) {
      setState(() {
        _selectedTransaction = transaction;
        _currentView = RefundView.details;
      });
    }
  }

  /// Toggle item selection for refund
  void toggleItem(int itemId) {
    setState(() {
      if (_refundItems.contains(itemId)) {
        _refundItems.remove(itemId);
      } else {
        _restockMap[itemId] = true;
        _refundItems.add(itemId);
      }
    });
  }

  /// Select all items for refund
  void selectAllItems() {
    if (_selectedTransaction != null) {
      setState(() {
        final allIds = _selectedTransaction!.items.map((e) => e.id).toSet();
        _refundItems = allIds;
        _restockMap = {for (var id in allIds) id: true};
      });
    }
  }

  /// Reset refund selection
  void resetSelection() {
    setState(() {
      _refundItems.clear();
      _restockMap.clear();
      _refundMethod = '';
      _refundReason = '';
      _internalNotes = '';
    });
  }

  /// Calculate total refund amount
  double get refundTotal {
    if (_selectedTransaction == null) return 0.0;
    return _selectedTransaction!.items
        .where((i) => _refundItems.contains(i.id))
        .fold(0.0, (sum, i) => sum + (i.price * i.qty));
  }

  /// Check if refunding whole bill
  bool get isWholeBill {
    if (_selectedTransaction == null) return false;
    return _refundItems.length == _selectedTransaction!.items.length;
  }
}
