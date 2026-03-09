import 'package:extropos/models/cart_item.dart';
import 'package:extropos/models/payment_models.dart';
import 'package:extropos/models/product.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/services/receipt_service.dart';
import 'package:extropos/utils/toast_helper.dart';
import 'package:flutter/material.dart';

/// Receipt Preview Screen - Shows receipt before printing
class ReceiptPreviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double tax;
  final double serviceCharge;
  final double total;
  final PaymentResult paymentResult;
  final VoidCallback? onPrint;
  final VoidCallback? onEmail;
  final VoidCallback? onComplete;

  // Alternative constructor for order data from database
  factory ReceiptPreviewScreen.fromOrderData(Map<String, dynamic> orderData, {
    VoidCallback? onPrint,
    VoidCallback? onEmail,
    VoidCallback? onComplete,
  }) {
    // Convert order data to the expected format
    final items = (orderData['items'] as List<dynamic>?)?.map((item) {
      return {
        'name': item['name'] as String? ?? 'Unknown Item',
        'quantity': item['quantity'] as int? ?? 1,
        'price': item['price'] as double? ?? 0.0,
        'total': item['total'] as double? ?? 0.0,
        'notes': item['notes'] as String?,
      };
    }).toList() ?? [];

    // Create a mock PaymentResult from order data
    final paymentResult = PaymentResult(
      success: true,
      transactionId: orderData['id'] as String? ?? 'N/A',
      receiptNumber: orderData['id'] as String? ?? 'N/A',
      amountPaid: orderData['total'] as double? ?? 0.0,
      change: 0.0,
      paymentSplits: [
        PaymentSplit(
          paymentMethod: PaymentMethod(
            id: 'unknown',
            name: orderData['payment_method'] as String? ?? 'Unknown',
          ),
          amount: orderData['total'] as double? ?? 0.0,
        ),
      ],
    );

    return ReceiptPreviewScreen(
      cartItems: items,
      subtotal: orderData['subtotal'] as double? ?? 0.0,
      tax: orderData['tax'] as double? ?? 0.0,
      serviceCharge: 0.0, // Not stored in current order data
      total: orderData['total'] as double? ?? 0.0,
      paymentResult: paymentResult,
      onPrint: onPrint,
      onEmail: onEmail,
      onComplete: onComplete,
    );
  }

  const ReceiptPreviewScreen({
    super.key,
    required this.cartItems,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.total,
    required this.paymentResult,
    this.onPrint,
    this.onEmail,
    this.onComplete,
  });

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  Map<String, dynamic>? _receiptData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceiptData();
  }

  Future<void> _loadReceiptData() async {
    try {
      // Convert cart items to CartItem objects for the service
      final cartItems = widget.cartItems.map((item) {
        final product = Product(
          item['name'] ?? '',
          item['price'] ?? 0.0,
          item['category_id'] ?? '',
          Icons.shopping_cart, // Default icon
          id: item['product_id'] ?? '',
        );
        
        return CartItem(
          product,
          item['quantity'] ?? 1,
        );
      }).toList();

      _receiptData = await ReceiptService.prepareReceiptData(
        cartItems,
        widget.subtotal,
        widget.tax,
        widget.serviceCharge,
        widget.total,
        widget.paymentResult,
      );
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to load receipt data');
        Navigator.of(context).pop();
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _handlePrint,
            tooltip: 'Print Receipt',
          ),
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: _handleEmail,
            tooltip: 'Email Receipt',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _receiptData == null
              ? const Center(child: Text('Failed to load receipt'))
              : _buildReceiptContent(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildReceiptContent() {
    final data = _receiptData!;
    final currency = data['currency'] ?? 'RM';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Store Header
              Text(
                data['store_name'] ?? '',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ...(data['address'] as List<dynamic>? ?? []).map(
                (line) => Text(
                  line.toString(),
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Receipt Title
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  data['title'] ?? 'RECEIPT',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date/Time and Bill Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${data['date']}'),
                      Text('Time: ${data['time']}'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Bill No: ${data['bill_no']}'),
                      Text('Payment: ${data['payment_mode']}'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Items Table
              _buildItemsTable(data, currency),

              // Totals Section
              const Divider(height: 32),
              _buildTotalsSection(data, currency),

              // Footer
              const SizedBox(height: 24),
              const Text(
                'Thank you for your business!',
                style: TextStyle(fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsTable(Map<String, dynamic> data, String currency) {
    final items = data['items'] as List<dynamic>? ?? [];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3), // Name
        1: FlexColumnWidth(1), // Qty
        2: FlexColumnWidth(2), // Amount
      },
      children: [
        // Header
        TableRow(
          children: [
            _buildTableCell('Item', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Amount', isHeader: true),
          ],
        ),
        // Items
        ...items.map((item) => TableRow(
              children: [
                _buildTableCell(item['name'] ?? ''),
                _buildTableCell(item['qty']?.toString() ?? '1'),
                _buildTableCell(
                  '$currency${(item['amt'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                ),
              ],
            )),
      ],
    );
  }

  Widget _buildTotalsSection(Map<String, dynamic> data, String currency) {
    final taxes = data['taxes'] as List<dynamic>? ?? [];
    final serviceCharge = data['service_charge'] as num? ?? 0.0;
    final total = data['total'] as num? ?? 0.0;
    final amountPaid = data['amount_paid'] as num? ?? 0.0;
    final change = data['change'] as num? ?? 0.0;

    return Column(
      children: [
        // Subtotal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal:'),
            Text('$currency${data['sub_total_amt']?.toStringAsFixed(2) ?? '0.00'}'),
          ],
        ),

        // Taxes
        ...taxes.map((tax) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${tax['name']}:'),
                Text('$currency${(tax['amt'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              ],
            )),

        // Service Charge
        if (serviceCharge > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Service Charge:'),
              Text('$currency${serviceCharge.toStringAsFixed(2)}'),
            ],
          ),

        const Divider(),

        // Total
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              '$currency${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Payment Details
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Paid:'),
            Text('$currency${amountPaid.toStringAsFixed(2)}'),
          ],
        ),
        if (change > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Change:'),
              Text('$currency${change.toStringAsFixed(2)}'),
            ],
          ),
      ],
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 14 : 12,
        ),
        textAlign: isHeader ? TextAlign.center : TextAlign.left,
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _handleComplete,
                icon: const Icon(Icons.check),
                label: const Text('Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePrint() async {
    if (_receiptData == null) return;

    try {
      await ReceiptService.printReceipt(_receiptData!);
      if (mounted) {
        ToastHelper.showToast(context, 'Receipt printed successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastHelper.showToast(context, 'Failed to print receipt');
      }
    }

    widget.onPrint?.call();
  }

  void _handleEmail() {
    // TODO: Implement email functionality
    ToastHelper.showToast(context, 'Email receipt not yet implemented');
    widget.onEmail?.call();
  }

  void _handleComplete() {
    widget.onComplete?.call();
    Navigator.of(context).pop(true); // Return success
  }
}