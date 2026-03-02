part of 'sales_history_screen.dart';

/// Extension containing void order dialog
extension SalesHistoryVoidDialog on _SalesHistoryScreenState {
  /// Show void order confirmation dialog
  void showVoidDialog(Map<String, dynamic> order) {
    final currentContext = context; // capture for async UI calls
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Void Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to void order ${order['order_number']}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: ${FormattingService.currency((order['total'] as num?)?.toDouble() ?? 0.0)}',
            ),
            const SizedBox(height: 16),
            const Text(
              'This will mark the order as voided. No refund transaction will be created.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                border: OutlineInputBorder(),
                hintText: 'Enter reason for voiding',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ToastHelper.showToast(currentContext, 'Please enter a reason');
                return;
              }

              Navigator.pop(dialogContext);

              final success = await DatabaseService.instance.voidOrder(
                order['id'].toString(),
                reason: reason,
              );

              if (success) {
                if (!mounted) return;
                ToastHelper.showToast(currentContext, 'Order voided successfully');
                loadOrders(page: _page);
              } else {
                if (!mounted) return;
                ToastHelper.showToast(currentContext, 'Failed to void order');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Void Order'),
          ),
        ],
      ),
    );
  }
}
