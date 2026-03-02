import 'package:extropos/models/inventory_models.dart';
import 'package:flutter/material.dart';

part 'purchase_orders_screen_ui.dart';
part 'purchase_orders_screen_dialogs.dart';

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

  void _sendPO(PurchaseOrder po) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send PO feature coming soon')),
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

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError('See purchase_orders_screen_ui.dart');
  }
}
