import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/refund_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

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

/// Dialog for processing partial item-level refunds
class RefundDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const RefundDialog({super.key, required this.orderData});

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
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
