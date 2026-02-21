import 'dart:convert';
import 'dart:developer' as developer;

import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/merchant_model.dart';
import 'package:extropos/models/payment_method_model.dart';
import 'package:extropos/services/database_service.dart';
import 'package:extropos/services/formatting_service.dart';
import 'package:extropos/services/printer_service_clean.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

// Note: writes CSV to `exports/` folder in project root.

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  DateTime? _from;
  DateTime? _to;
  String? _selectedPaymentMethodId;
  List<PaymentMethod> _paymentMethods = [];

  int _page = 0;
  final int _pageSize = 50;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _loadOrders();
  }

  Future<void> _loadPaymentMethods() async {
    final methods = await DatabaseService.instance.getPaymentMethods();
    if (!mounted) return;
    setState(() {
      _paymentMethods = methods;
    });
  }

  Future<void> _loadOrders({int page = 0}) async {
    setState(() => _loading = true);
    final offset = page * _pageSize;
    final orders = await DatabaseService.instance.getOrders(
      from: _from,
      to: _to,
      paymentMethodId: _selectedPaymentMethodId,
      offset: offset,
      limit: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _orders = orders;
      _page = page;
      _hasMore = orders.length == _pageSize;
      _loading = false;
    });
  }

  void _showOrderDetails(Map<String, dynamic> order) async {
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
                  _showVoidDialog(order);
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
                  _showRefundDialog(order);
                },
                icon: const Icon(Icons.money_off, color: Colors.red),
                label: const Text(
                  'Refund',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
            TextButton.icon(
              onPressed: () => _reprintReceipt(order, items),
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

  Future<void> _reprintReceipt(
    Map<String, dynamic> order,
    List<Map<String, dynamic>> items,
  ) async {
    final currentContext = context;
    try {
      developer.log('REPRINT: Starting receipt reprint', name: 'sales_history');

      // Load printers
      final printers = await DatabaseService.instance.getPrinters();
      if (printers.isEmpty) {
        ToastHelper.showToast(currentContext, 'No printers configured');
        return;
      }

      // Find default printer
      final printer = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );

      developer.log(
        'REPRINT: Using printer ${printer.name}',
        name: 'sales_history',
      );

      // Build receipt data
      final info = BusinessInfo.instance;
      final receiptData = {
        'businessName': info.businessName,
        'address': info.fullAddress,
        'taxNumber': info.taxNumber ?? '',
        'orderNumber': order['order_number'] ?? '',
        'dateTime': order['created_at'] ?? DateTime.now().toIso8601String(),
        'items': items
            .map(
              (item) => {
                'name': item['item_name'],
                'quantity': item['quantity'],
                'price': (item['item_price'] as num).toDouble(),
                'total': (item['subtotal'] as num).toDouble(),
                'modifiers': _parseModifiersFromNotes(item),
              },
            )
            .toList(),
        'subtotal': (order['subtotal'] as num?)?.toDouble() ?? 0.0,
        'tax': (order['tax'] as num?)?.toDouble() ?? 0.0,
        'serviceCharge': 0.0, // Not stored separately in old schema
        'total': (order['total'] as num?)?.toDouble() ?? 0.0,
        'paymentMethod': order['payment_method_id'] ?? 'Cash',
        'amountPaid': (order['total'] as num?)?.toDouble() ?? 0.0,
        'change': 0.0,
        'currency': info.currencySymbol,
      };

      developer.log('REPRINT: Sending to printer', name: 'sales_history');
      final printerService = PrinterService();
      await printerService.printReceipt(printer, receiptData);

      developer.log('REPRINT: Print successful', name: 'sales_history');
      ToastHelper.showToast(currentContext, 'Receipt sent to printer');
    } catch (e) {
      developer.log('REPRINT: Failed - $e', name: 'sales_history');
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Failed to reprint: $e');
    }
  }

  void _showVoidDialog(Map<String, dynamic> order) {
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
                _loadOrders(page: _page);
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

  void _showRefundDialog(Map<String, dynamic> order) {
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
                  _loadOrders(page: _page);
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

  Future<void> _exportCsv() async {
    final currentContext = context; // capture early for toast/UI calls
    try {
      // Let the OS-native dialog handle filename and location in one step
      // Build a slug for the business name to make the filename filesystem-safe
      final bizSlug = BusinessInfo.instance.businessName
          .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .trim();
      String dateRangeSegment = '';
      if (_from != null || _to != null) {
        final f = _from != null
            ? _from!.toIso8601String().split('T').first
            : 'any';
        final t = _to != null ? _to!.toIso8601String().split('T').first : 'any';
        dateRangeSegment = '_${f}_to_$t';
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final suggestedName =
          'sales_history_$bizSlug${dateRangeSegment}_$timestamp.csv';
      final location = await getSaveLocation(
        suggestedName: suggestedName,
        acceptedTypeGroups: [
          const XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );
      if (location == null) return; // user cancelled

      // Generate CSV (per-order-item rows)
      final csv = await DatabaseService.instance.exportOrdersCsv(
        from: _from,
        to: _to,
        paymentMethodId: _selectedPaymentMethodId,
        limit: 100000,
      );

      if (csv.trim().isEmpty) {
        if (!mounted) return;
        ToastHelper.showToast(currentContext, 'No orders to export');
        return;
      }

      final file = File(location.path);
      await file.writeAsString(csv);

      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Exported orders to ${location.path}');
    } catch (e) {
      if (!mounted) return;
      ToastHelper.showToast(currentContext, 'Export failed: $e');
    }
  }

  List<Map<String, dynamic>> _parseModifiersFromNotes(
    Map<String, dynamic> item,
  ) {
    final notes = item['notes'];
    if (notes == null) return [];
    try {
      final decoded = jsonDecode(notes);
      if (decoded is Map<String, dynamic> && decoded['modifiers'] is List) {
        final mods = (decoded['modifiers'] as List)
            .map<Map<String, dynamic>>(
              (m) => {
                'name': m['name'] ?? m['item_name'] ?? '',
                'price': (m['priceAdjustment'] as num?)?.toDouble() ?? 0.0,
              },
            )
            .toList();
        return mods;
      }
    } catch (e) {
      developer.log(
        'Failed to parse modifiers from notes: $e',
        name: 'sales_history',
      );
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
            icon: const Icon(Icons.download),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOrders,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    _from ??
                                    DateTime.now().subtract(
                                      const Duration(days: 7),
                                    ),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && mounted) {
                                setState(() => _from = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'From',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _from == null
                                    ? 'Any'
                                    : _from!.toIso8601String().split('T').first,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _to ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null && mounted) {
                                setState(() => _to = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'To',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _to == null
                                    ? 'Any'
                                    : _to!.toIso8601String().split('T').first,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String?>(
                            initialValue: _selectedPaymentMethodId,
                            decoration: const InputDecoration(
                              labelText: 'Payment Method',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All'),
                              ),
                              ..._paymentMethods.map(
                                (m) => DropdownMenuItem(
                                  value: m.id,
                                  child: Text(m.name),
                                ),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedPaymentMethodId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _loadOrders(page: 0),
                          child: const Text('Apply'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _orders.isEmpty
                        ? ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(child: Text('No orders found')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final o = _orders[index];
                              final date = o['created_at'] as String? ?? '';
                              final merchantId = (o['merchant_id'] ?? '').toString();
                              final merchantName = MerchantHelper.displayName(merchantId);
                              final total =
                                  (o['total'] as num?)?.toDouble() ?? 0.0;
                              final status =
                                  o['status'] as String? ?? 'completed';

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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                subtitle: Text(merchantName.isNotEmpty ? '$date • $merchantName' : date),
                                trailing: Text(
                                  FormattingService.currency(total),
                                  style: TextStyle(
                                    decoration: status != 'completed'
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: statusColor,
                                  ),
                                ),
                                onTap: () => _showOrderDetails(o),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _page > 0
                              ? () => _loadOrders(page: _page - 1)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                          label: const Text('Previous'),
                        ),
                        Text('Page ${_page + 1}'),
                        TextButton.icon(
                          onPressed: _hasMore
                              ? () => _loadOrders(page: _page + 1)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                          label: const Text('Next'),
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
