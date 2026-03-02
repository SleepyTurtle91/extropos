part of 'purchase_orders_screen.dart';

extension PurchaseOrdersDialogs on _PurchaseOrdersScreenState {
  void _showCreatePODialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create PO feature coming soon')),
    );
  }

  void _showEditPODialog(PurchaseOrder po) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit PO feature coming soon')),
    );
  }

  void _showPODetails(PurchaseOrder po) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(po.poNumber),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Status', po.status.name.toUpperCase()),
              _buildDetailRow('Supplier', po.supplierName),
              _buildDetailRow('Order Date', _formatDate(po.orderDate)),
              if (po.expectedDeliveryDate != null)
                _buildDetailRow(
                  'Expected Delivery',
                  _formatDate(po.expectedDeliveryDate!),
                ),
              if (po.receivedDate != null)
                _buildDetailRow(
                  'Received Date',
                  _formatDate(po.receivedDate!),
                ),
              const SizedBox(height: 16),
              Text(
                'Items (${po.items.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...po.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.productName),
                      ),
                      Text(
                        '${item.quantity} x RM ${item.unitCost.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 12),
              Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'RM ${po.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (po.notes != null && po.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Notes: ${po.notes}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _receivePO(PurchaseOrder po) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Receive PO - ${po.poNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mark this purchase order as received?'),
              const SizedBox(height: 12),
              Text(
                'Total Items: ${po.items.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Total Amount: RM ${po.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${po.poNumber} marked as received'),
                ),
              );
              _loadPurchaseOrders();
            },
            child: const Text('Confirm Receipt'),
          ),
        ],
      ),
    );
  }
}
