part of 'sales_history_screen.dart';

/// Extension containing refund order dialog
extension SalesHistoryRefundDialog on _SalesHistoryScreenState {
  /// Show refund order dialog with amount and payment method selection
  void showRefundDialog(Map<String, dynamic> order) {
    final currentContext = context; // capture BuildContext to use safely across async gaps
    final reasonController = TextEditingController();
    final amountController = TextEditingController(
      text: ((order['total'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2),
    );
    String? selectedPaymentMethodId = order['payment_method_id'] as String?;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Refund Order'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Refund order ${order['order_number']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Original Total: ${FormattingService.currency((order['total'] as num?)?.toDouble() ?? 0.0)}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'This will create a refund transaction and mark the order as refunded.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Refund Amount',
                    border: OutlineInputBorder(),
                    prefixText: 'RM ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedPaymentMethodId,
                  decoration: const InputDecoration(
                    labelText: 'Refund Method',
                    border: OutlineInputBorder(),
                  ),
                  items: _paymentMethods
                      .map(
                        (m) =>
                            DropdownMenuItem(value: m.id, child: Text(m.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedPaymentMethodId = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Reason (required)',
                    border: OutlineInputBorder(),
                    hintText: 'Enter reason for refund',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonController.text.trim();
                final amountText = amountController.text.trim();

                if (reason.isEmpty) {
                  ToastHelper.showToast(currentContext, 'Please enter a reason');
                  return;
                }

                if (selectedPaymentMethodId == null) {
                  ToastHelper.showToast(
                    currentContext,
                    'Please select a payment method',
                  );
                  return;
                }

                final refundAmount = double.tryParse(amountText);
                if (refundAmount == null || refundAmount <= 0) {
                  ToastHelper.showToast(currentContext, 'Invalid refund amount');
                  return;
                }

                Navigator.pop(dialogContext);

                final success = await DatabaseService.instance.refundOrder(
                  orderId: order['id'].toString(),
                  refundAmount: refundAmount,
                  paymentMethodId: selectedPaymentMethodId!,
                  reason: reason,
                );

                if (success) {
                  if (!mounted) return;
                  ToastHelper.showToast(
                    currentContext,
                    'Order refunded: ${FormattingService.currency(refundAmount)}',
                  );
                  loadOrders(page: _page);
                } else {
                  if (!mounted) return;
                  ToastHelper.showToast(currentContext, 'Failed to refund order');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Process Refund'),
            ),
          ],
        ),
      ),
    );
  }
}
