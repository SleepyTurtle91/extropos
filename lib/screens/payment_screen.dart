import 'package:extropos/models/business_info_model.dart';
import 'package:extropos/models/cart_item.dart';
import 'package:extropos/services/cart_calculation_service.dart';
import 'package:extropos/services/cart_service.dart';
import 'package:extropos/services/payment_service.dart';
import 'package:extropos/services/receipt_service.dart';
import 'package:extropos/widgets/number_pad_widget.dart';
import 'package:flutter/material.dart';

class PaymentScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double total;
  final double discount;
  final Function() onPaymentComplete;

  const PaymentScreen({
    super.key,
    required this.cartItems,
    required this.total,
    this.discount = 0.0,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double _paidAmount = 0.0;
  String _selectedPaymentMethod = 'Cash';

  final List<String> _paymentMethods = ['Cash', 'Card'];

  void _onNumberPressed(String value) {
    setState(() {
      if (value == 'C') {
        _paidAmount = 0.0;
      } else if (value == '.') {
        // Handle decimal
        String amountStr = _paidAmount.toString();
        if (!amountStr.contains('.')) {
          _paidAmount = double.parse('$amountStr.');
        }
      } else {
        String amountStr = _paidAmount.toString();
        if (amountStr.contains('.')) {
          // Already has decimal, add to decimal part
          List<String> parts = amountStr.split('.');
          if (parts[1].length < 2) {
            _paidAmount = double.parse('${parts[0]}.${parts[1]}$value');
          }
        } else {
          _paidAmount = double.parse('$amountStr$value');
        }
      }
    });
  }

  void _processPayment() async {
    if (_paidAmount < widget.total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient payment amount')),
      );
      return;
    }

    try {
      // For now, simulate payment success
      final success = true;

      if (success) {
        // Generate receipt
        final subtotal = CartCalculationService.calculateSubtotal(widget.cartItems);
        final discount = CartCalculationService.calculateDiscount(subtotal, widget.discount, 0.0);
        final subtotalAfterDiscount = subtotal - discount;
        final tax = CartCalculationService.calculateTax(subtotalAfterDiscount, BusinessInfo.instance);
        final serviceCharge = CartCalculationService.calculateServiceCharge(subtotalAfterDiscount, BusinessInfo.instance);
        
        final paymentResult = PaymentResult(
          success: true,
          amountPaid: _paidAmount,
          change: _paidAmount - widget.total,
          paymentSplits: [], // For now, single payment
        );
        
        final receiptData = await ReceiptService.prepareReceiptData(
          widget.cartItems,
          subtotal,
          tax,
          serviceCharge,
          widget.total,
          paymentResult,
        );
        await ReceiptService.printReceipt(receiptData);

        // Clear cart
        CartService.instance.clearCart();

        // Navigate back or to receipt
        widget.onPaymentComplete();
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final change = _paidAmount - widget.total;
    final businessInfo = BusinessInfo.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Row(
        children: [
          // Left panel - Payment details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: ${businessInfo.currencySymbol}${widget.total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Paid: ${businessInfo.currencySymbol}${_paidAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Change: ${businessInfo.currencySymbol}${change > 0 ? change.toStringAsFixed(2) : '0.00'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: change >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Payment method selection
                  const Text('Payment Method:'),
                  DropdownButton<String>(
                    value: _selectedPaymentMethod,
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Cart items summary
                  Expanded(
                    child: ListView.builder(
                      itemCount: widget.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = widget.cartItems[index];
                        return ListTile(
                          title: Text(item.product.name),
                          subtitle: Text('Qty: ${item.quantity}'),
                          trailing: Text(
                            '${businessInfo.currencySymbol}${(item.quantity * item.product.price).toStringAsFixed(2)}',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _paidAmount >= widget.total ? _processPayment : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Complete Payment'),
                  ),
                ],
              ),
            ),
          ),
          // Right panel - Number pad
          Expanded(
            flex: 1,
            child: NumberPadWidget(
              currentValue: _paidAmount.toStringAsFixed(2),
              onNumberPressed: _onNumberPressed,
              onClearPressed: () => setState(() => _paidAmount = 0.0),
              onBackspacePressed: () {
                setState(() {
                  String amountStr = _paidAmount.toString();
                  if (amountStr.contains('.')) {
                    // Remove last digit after decimal
                    List<String> parts = amountStr.split('.');
                    if (parts[1].isNotEmpty) {
                      parts[1] = parts[1].substring(0, parts[1].length - 1);
                      if (parts[1].isEmpty) {
                        _paidAmount = double.parse(parts[0]);
                      } else {
                        _paidAmount = double.parse('${parts[0]}.${parts[1]}');
                      }
                    }
                  } else if (amountStr.length > 1) {
                    _paidAmount = double.parse(amountStr.substring(0, amountStr.length - 1));
                  } else {
                    _paidAmount = 0.0;
                  }
                });
              },
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              buttonColor: Theme.of(context).primaryColor,
              textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}