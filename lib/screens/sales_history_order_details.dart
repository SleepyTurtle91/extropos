part of 'sales_history_screen.dart';

/// Extension containing order details dialog
extension SalesHistoryOrderDetails on _SalesHistoryScreenState {
  /// Show detailed order information dialog
  void showOrderDetails(Map<String, dynamic> order) async {
    final orderId = order['id'].toString();
    final items = await DatabaseService.instance.getOrderItems(orderId);
    final transactions = await DatabaseService.instance.getTransactionsForOrder(
      orderId,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        final status = order['status'] as String? ?? 'completed';
        Color? statusColor;
        if (status == 'voided') statusColor = Colors.orange;
        if (status == 'refunded') statusColor = Colors.red;

        return AlertDialog(
          title: Row(
            children: [
              Expanded(
                child: Text('Order ${order['order_number'] ?? orderId}'),
              ),
              if (status != 'completed')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor?.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor ?? Colors.grey),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order['order_number'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Date: ${order['created_at'] ?? 'N/A'}'),
                          if (order['customer_name'] != null) ...[
                            Text('Customer: ${order['customer_name']}'),
                          ],
                          if (order['table_id'] != null) ...[
                            Text('Table: ${order['table_id']}'),
                          ],
                          if (order['merchant_id'] != null && (order['merchant_id'] ?? '').toString().isNotEmpty && (order['merchant_id'] ?? '') != 'none') ...[
                            Text('Merchant: ${MerchantHelper.displayName((order['merchant_id'] ?? '').toString())}'),
                          ],
                          Text('Type: ${order['order_type'] ?? 'N/A'}'),
                          Text('Status: ${order['status'] ?? 'N/A'}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...items.map(
                    (it) => ListTile(
                      dense: true,
                      title: Text(it['item_name'] as String),
                      subtitle: Text(
                        'Qty: ${it['quantity']} • @ ${FormattingService.currency((it['item_price'] as num).toDouble())}${it['seat_number'] != null ? ' • Seat: ${it['seat_number']}' : ''}',
                      ),
                      trailing: Text(
                        FormattingService.currency(
                          (it['subtotal'] as num).toDouble(),
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const Divider(),
                  // Totals
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text(
                              FormattingService.currency(
                                (order['subtotal'] as num?)?.toDouble() ?? 0.0,
                              ),
                            ),
                          ],
                        ),
                        if (((order['tax'] as num?)?.toDouble() ?? 0.0) >
                            0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tax:'),
                              Text(
                                FormattingService.currency(
                                  (order['tax'] as num?)?.toDouble() ?? 0.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (((order['discount'] as num?)?.toDouble() ?? 0.0) >
                            0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount:'),
                              Text(
                                FormattingService.currency(
                                  (order['discount'] as num?)?.toDouble() ??
                                      0.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              FormattingService.currency(
                                (order['total'] as num?)?.toDouble() ?? 0.0,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (transactions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Transactions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...transactions.map(
                      (t) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.payment, size: 20),
                        title: Text(t['payment_method_id'] ?? 'Unknown'),
                        subtitle: Text(t['transaction_date'] ?? ''),
                        trailing: Text(
                          FormattingService.currency(
                            (t['amount'] as num).toDouble(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (order['status'] == 'completed') ...[
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showVoidDialog(order);
                },
                icon: const Icon(Icons.cancel, color: Colors.orange),
                label: const Text(
                  'Void',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showRefundDialog(order);
                },
                icon: const Icon(Icons.money_off, color: Colors.red),
                label: const Text(
                  'Refund',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
            TextButton.icon(
              onPressed: () => reprintReceipt(order, items),
              icon: const Icon(Icons.print),
              label: const Text('Reprint'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
