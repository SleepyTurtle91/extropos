import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/refund_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// Dialog for processing full bill voids
class VoidDialog extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const VoidDialog({super.key, required this.orderData});

  @override
  State<VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<VoidDialog> {
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
