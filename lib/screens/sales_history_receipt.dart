part of 'sales_history_screen.dart';

/// Extension containing receipt reprint functionality
extension SalesHistoryReceipt on _SalesHistoryScreenState {
  /// Reprint receipt for an order
  Future<void> reprintReceipt(
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
                'modifiers': parseModifiersFromNotes(item),
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
}
