import 'package:extropos/models/inventory_models.dart';
import 'package:flutter/material.dart';

/// Purchase Orders Screen
/// Manage purchase orders for restocking and supplier management
class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  final List<PurchaseOrder> _purchaseOrders = [];
  late List<PurchaseOrder> _filteredOrders;
  String _statusFilter = 'all'; // all, draft, sent, confirmed, received, cancelled

  @override
  void initState() {
    super.initState();
    _filteredOrders = _purchaseOrders;
    _loadPurchaseOrders();
  }

  void _loadPurchaseOrders() {
    setState(() {
      // TODO: Load from service
      _applyFilters();
    });
  }

  void _applyFilters() {
    if (_statusFilter == 'all') {
      _filteredOrders = _purchaseOrders;
    } else {
      _filteredOrders = _purchaseOrders
          .where((po) => po.status.name == _statusFilter)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPurchaseOrders,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('All', 'all'),
                  _buildStatusChip('Draft', 'draft'),
                  _buildStatusChip('Sent', 'sent'),
                  _buildStatusChip('Confirmed', 'confirmed'),
                  _buildStatusChip('Received', 'received'),
                  _buildStatusChip('Cancelled', 'cancelled'),
                ],
              ),
            ),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Showing ${_filteredOrders.length} orders',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Purchase orders list
          Expanded(
            child: _filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _filteredOrders.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      return _buildPOCard(_filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePODialog(),
        tooltip: 'Create New PO',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String label, String status) {
    final isSelected = _statusFilter == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _statusFilter = selected ? status : 'all';
            _applyFilters();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No purchase orders',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create one to start restocking',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPOCard(PurchaseOrder po) {
    final statusColor = _getStatusColor(po.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      po.poNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      po.supplierName,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    po.status.name.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  label: 'Order Date',
                  value: _formatDate(po.orderDate),
                ),
                _buildDetailItem(
                  label: 'Items',
                  value: po.items.length.toString(),
                ),
                _buildDetailItem(
                  label: 'Total',
                  value: 'RM ${po.totalAmount.toStringAsFixed(2)}',
                  highlight: true,
                ),
              ],
            ),
            if (po.expectedDeliveryDate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Expected Delivery: ${_formatDate(po.expectedDeliveryDate!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Items preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items (${po.items.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...po.items.take(3).map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.productName,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${item.quantity} x RM ${item.unitCost.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (po.items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '+ ${po.items.length - 3} more items',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('View'),
                  onPressed: () => _showPODetails(po),
                ),
                const SizedBox(width: 8),
                if (po.status == PurchaseOrderStatus.draft ||
                    po.status == PurchaseOrderStatus.sent) ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: () => _showEditPODialog(po),
                  ),
                  const SizedBox(width: 8),
                ],
                if (po.status == PurchaseOrderStatus.draft)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    onPressed: () => _sendPO(po),
                  ),
                if (po.status == PurchaseOrderStatus.confirmed ||
                    po.status == PurchaseOrderStatus.sent)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Receive'),
                    onPressed: () => _receivePO(po),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            color: highlight ? Colors.green : Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(PurchaseOrderStatus status) {
    switch (status) {
      case PurchaseOrderStatus.draft:
        return Colors.grey;
      case PurchaseOrderStatus.sent:
        return Colors.blue;
      case PurchaseOrderStatus.confirmed:
        return Colors.orange;
      case PurchaseOrderStatus.partiallyReceived:
        return Colors.amber;
      case PurchaseOrderStatus.received:
        return Colors.green;
      case PurchaseOrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

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

  void _sendPO(PurchaseOrder po) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send PO feature coming soon')),
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
