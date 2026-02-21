import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/refund_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Refund item tracking for partial returns
class RefundItem {
  final CartItem originalItem;
  int quantityToRefund;
  bool isSelected;

  RefundItem({
    required this.originalItem,
    required this.quantityToRefund,
    this.isSelected = false,
  });

  double get refundAmount => originalItem.finalPrice * quantityToRefund;
}

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
      builder: (context) => _RefundDialog(orderData: orderData),
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
                        builder: (context) => _VoidDialog(orderData: order),
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

// Void Dialog - Full Bill Cancellation
class _VoidDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const _VoidDialog({required this.orderData});

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  String _selectedReason = 'Customer Request';
  final _notesController = TextEditingController();
  bool _managerApprovalRequired = false;
  bool _managerApproved = false;
  bool _isProcessing = false;

  final List<String> _voidReasons = [
    'Customer Request',
    'Order Error',
    'Duplicate Order',
    'Payment Issue',
    'System Error',
    'Other',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _processVoid() async {
    // Check manager approval if required
    if (_managerApprovalRequired && !_managerApproved) {
      ToastHelper.showToast(context, 'Manager approval required for void');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Load all order items as CartItems for full void
      final orderId = widget.orderData['id'];
      final orderIdStr = orderId is int ? orderId.toString() : orderId as String;
      
      final items = await DatabaseService.instance.getOrderItemsAsCartItems(
        orderIdStr,
      );

      if (items.isEmpty) {
        throw Exception('No items found in order');
      }

      // Get payment method (default to cash)
      final paymentMethods = await DatabaseService.instance.getPaymentMethods();
      final cashMethod = paymentMethods.firstWhere(
        (pm) => pm.name.toLowerCase().contains('cash'),
        orElse: () => paymentMethods.first,
      );

      // Get userId safely
      final userId = widget.orderData['cashier_id'];
      final userIdStr = userId != null
          ? (userId is int ? userId.toString() : userId as String)
          : null;

      // Process full bill void
      final result = await RefundService.instance.processFullBillRefund(
        orderId: orderIdStr,
        orderNumber: widget.orderData['order_number'] as String,
        originalTotal: (widget.orderData['total'] as num).toDouble(),
        originalItems: items,
        refundMethod: cashMethod,
        reason:
            '$_selectedReason${_notesController.text.trim().isEmpty ? '' : ': ${_notesController.text.trim()}'}',
        userId: userIdStr,
        managerApprovalCode: _managerApproved ? 'APPROVED' : null,
      );

      if (!mounted) return;

      if (result.success) {
        ToastHelper.showToast(
          context,
          'Void successful! Receipt ${result.receiptPrinted ? "printed" : "not printed"}',
        );
        Navigator.pop(context, true);
      } else {
        ToastHelper.showToast(context, result.errorMessage ?? 'Void failed');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = BusinessInfo.instance.currencySymbol;
    final total = widget.orderData['total'] as num;

    return AlertDialog(
      title: const Text('Void Full Sale'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order: ${widget.orderData['order_number']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: $currency ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.orderData['item_count'] ?? 0} items',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will void the entire sale and restore all items to stock.',
                      style: TextStyle(color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Void Reason
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Void Reason',
                border: OutlineInputBorder(),
              ),
              items: _voidReasons.map((reason) {
                return DropdownMenuItem(value: reason, child: Text(reason));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedReason = value);
                }
              },
            ),

            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),

            const SizedBox(height: 12),

            // Manager Approval
            CheckboxListTile(
              value: _managerApprovalRequired,
              onChanged: (value) {
                setState(() {
                  _managerApprovalRequired = value ?? false;
                  if (!_managerApprovalRequired) _managerApproved = false;
                });
              },
              title: const Text('Requires Manager Approval'),
              contentPadding: EdgeInsets.zero,
            ),

            if (_managerApprovalRequired)
              CheckboxListTile(
                value: _managerApproved,
                onChanged: (value) {
                  setState(() => _managerApproved = value ?? false);
                },
                title: const Text('Manager Approved'),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _processVoid,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Void Sale'),
        ),
      ],
    );
  }
}

class _RefundDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const _RefundDialog({required this.orderData});

  @override
  State<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<_RefundDialog> {
  List<RefundItem> _refundItems = [];
  String _selectedReason = 'Defective Product';
  final _notesController = TextEditingController();
  bool _managerApprovalRequired = false;
  bool _managerApproved = false;
  bool _isProcessing = false;

  final List<String> _refundReasons = [
    'Defective Product',
    'Wrong Item',
    'Customer Request',
    'Quality Issue',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrderItems();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderItems() async {
    try {
      // Safely handle order ID being either int or String
      final rawId = widget.orderData['id'];
      final orderIdStr = rawId is int ? rawId.toString() : rawId as String;

      final items = await DatabaseService.instance.getOrderItemsAsCartItems(
        orderIdStr,
      );

      setState(() {
        _refundItems = items.map((item) {
          return RefundItem(
            originalItem: item,
            quantityToRefund: item.quantity,
            isSelected: false,
          );
        }).toList();
      });
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to load order items: $e');
      }
    }
  }

  double get _totalRefundAmount {
    return _refundItems
        .where((item) => item.isSelected)
        .fold(0.0, (sum, item) => sum + item.refundAmount);
  }

  bool get _canProcessRefund {
    if (_refundItems.where((item) => item.isSelected).isEmpty) return false;
    if (_selectedReason == 'Other' && _notesController.text.trim().isEmpty) {
      return false;
    }
    if (_managerApprovalRequired && !_managerApproved) return false;
    return true;
  }

  void _updateManagerApprovalRequired() {
    setState(() {
      _managerApprovalRequired = _totalRefundAmount > 100.0;
      if (!_managerApprovalRequired) {
        _managerApproved = false;
      }
    });
  }

  Future<void> _processRefund() async {
    if (!_canProcessRefund) return;

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: Text(
          'Process refund of ${BusinessInfo.instance.currencySymbol} ${_totalRefundAmount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // Build CartItem list from selected RefundItems
      final selectedItems = _refundItems
          .where((item) => item.isSelected)
          .toList();

      final cartItemsList = selectedItems.map((item) {
        // Create a new CartItem with the refund quantity
        return CartItem(
          item.originalItem.product,
          item.quantityToRefund,
          modifiers: item.originalItem.modifiers,
          priceAdjustment: item.originalItem.priceAdjustment,
          discountPerUnit: item.originalItem.discountPerUnit,
          selectedVariant: item.originalItem.selectedVariant,
        );
      }).toList();

      // Get payment method (default to cash)
      final paymentMethods = await DatabaseService.instance.getPaymentMethods();
      final cashMethod = paymentMethods.firstWhere(
        (pm) => pm.name.toLowerCase().contains('cash'),
        orElse: () => paymentMethods.first,
      );

      // Get IDs safely - handle both int and String types
      final orderId = widget.orderData['id'];
      final orderIdStr = orderId is int ? orderId.toString() : orderId as String;
      
      final userId = widget.orderData['cashier_id'];
      final userIdStr = userId != null
          ? (userId is int ? userId.toString() : userId as String)
          : null;

      // Process item-level refund through RefundService
      final result = await RefundService.instance.processItemRefund(
        orderId: orderIdStr,
        orderNumber: widget.orderData['order_number'] as String,
        originalTotal: (widget.orderData['total'] as num).toDouble(),
        refundItems: cartItemsList,
        refundMethod: cashMethod,
        reason:
            '$_selectedReason${_notesController.text.trim().isEmpty ? '' : ': ${_notesController.text.trim()}'}',
        userId: userIdStr,
        managerApprovalCode: _managerApproved ? 'APPROVED' : null,
      );

      if (!mounted) return;

      if (result.success) {
        ToastHelper.showToast(
          context,
          'Refund successful! Receipt ${result.receiptPrinted ? "printed" : "not printed"}',
        );
        Navigator.pop(context, true);
      } else {
        ToastHelper.showToast(
          context,
          result.errorMessage ?? 'Refund processing failed',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Refund error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = BusinessInfo.instance.currencySymbol;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.undo, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Process Refund',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Order: ${widget.orderData['order_number']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Items to refund
                    const Text(
                      'Select Items to Refund',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ..._refundItems.map((refundItem) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: refundItem.isSelected,
                                    onChanged: (value) {
                                      setState(() {
                                        refundItem.isSelected = value ?? false;
                                        _updateManagerApprovalRequired();
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          refundItem.originalItem.product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$currency ${refundItem.originalItem.finalPrice.toStringAsFixed(2)} × ${refundItem.originalItem.quantity}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (refundItem.isSelected) ...[
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: refundItem.quantityToRefund > 1
                                          ? () {
                                              setState(() {
                                                refundItem.quantityToRefund--;
                                                _updateManagerApprovalRequired();
                                              });
                                            }
                                          : null,
                                    ),
                                    Text(
                                      refundItem.quantityToRefund.toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed:
                                          refundItem.quantityToRefund <
                                              refundItem.originalItem.quantity
                                          ? () {
                                              setState(() {
                                                refundItem.quantityToRefund++;
                                                _updateManagerApprovalRequired();
                                              });
                                            }
                                          : null,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Refund reason
                    DropdownButtonFormField<String>(
                      value: _selectedReason,
                      decoration: const InputDecoration(
                        labelText: 'Refund Reason',
                        border: OutlineInputBorder(),
                      ),
                      items: _refundReasons.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(reason),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedReason = value!);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: _selectedReason == 'Other'
                            ? 'Notes (Required)'
                            : 'Notes (Optional)',
                        border: const OutlineInputBorder(),
                        hintText: 'Enter additional details',
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Manager approval
                    if (_managerApprovalRequired) ...[
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.admin_panel_settings,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manager Approval Required',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                    Text(
                                      'Refunds over $currency 100.00 require manager approval',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: _managerApproved,
                                onChanged: (value) {
                                  setState(
                                    () => _managerApproved = value ?? false,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Refund total
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Refund Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$currency ${_totalRefundAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _canProcessRefund && !_isProcessing
                        ? _processRefund
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Process Refund'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
