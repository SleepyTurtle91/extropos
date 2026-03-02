part of 'sales_history_screen.dart';

/// Extension containing order list UI
extension SalesHistoryOrderList on _SalesHistoryScreenState {
  /// Build order list view
  Widget buildOrderList() {
    if (_orders.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: Text('No orders found')),
        ],
      );
    }

    return ListView.builder(
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final o = _orders[index];
        final date = o['created_at'] as String? ?? '';
        final merchantId = (o['merchant_id'] ?? '').toString();
        final merchantName = MerchantHelper.displayName(merchantId);
        final total = (o['total'] as num?)?.toDouble() ?? 0.0;
        final status = o['status'] as String? ?? 'completed';

        // Color coding for status
        Color? statusColor;
        IconData? statusIcon;
        if (status == 'voided') {
          statusColor = Colors.orange;
          statusIcon = Icons.cancel;
        } else if (status == 'refunded') {
          statusColor = Colors.red;
          statusIcon = Icons.money_off;
        }

        return ListTile(
          leading: statusIcon != null
              ? Icon(
                  statusIcon,
                  color: statusColor,
                  size: 20,
                )
              : null,
          title: Row(
            children: [
              Expanded(
                child: Text(o['order_number'] ?? 'Order'),
              ),
              if (status != 'completed')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor?.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle:
              Text(merchantName.isNotEmpty ? '$date • $merchantName' : date),
          trailing: Text(
            FormattingService.currency(total),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          onTap: () => showOrderDetails(o),
        );
      },
    );
  }
}
